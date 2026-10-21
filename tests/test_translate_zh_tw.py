"""Protect document semantics and assets during Traditional Chinese conversion."""

from pathlib import Path
from contextlib import redirect_stderr, redirect_stdout
import io
import tempfile
import unittest
from unittest.mock import patch

from opencc import OpenCC

from tools import translate_zh_tw as translation


class ConversionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.converter = OpenCC('s2twp')

    def convert(self, text):
        return translation.convert_tex(text, self.converter)

    def test_prose_headings_and_interface_labels(self):
        self.assertEqual(self.convert(r'\section{软件设置}\ui{打开文件}'),
                         r'\section{軟體設定}\ui{開啟檔案}')

    def test_nested_literals_and_paths(self):
        text = (r'\file{结构/{输入}.json} \literalinput{$ 请解释计算}'
                r'\texttt{变量\{名称\}} \includegraphics[width={.8\linewidth}]{图片/结构.png}')
        self.assertEqual(self.convert(text), text)

    def test_references_and_urls_stay_valid(self):
        text = (r'\label{结构}\ref{结构}\url{https://example.com/软件}'
                r'\href{https://example.com/软件}{软件设置}')
        self.assertEqual(self.convert(text), text.replace('{软件设置}', '{軟體設定}'))

    def test_code_and_inline_verbatim_are_unchanged(self):
        for environment in ('lstlisting', 'verbatim', 'verbatim*', 'Verbatim', 'minted'):
            with self.subTest(environment=environment):
                text = ('\\begin{' + environment + '}[language=Matlab]\n'
                        "name = '计算'; % 软件\n\\end{" + environment + '}')
                self.assertEqual(self.convert(text), text)
        text = r'\verb|软件{变量}| \verb*+软件%输入+'
        self.assertEqual(self.convert(text), text)

    def test_comments_do_not_hide_following_prose(self):
        text = '% \\begin{verbatim} 软件\n软件\\%设置'
        self.assertEqual(self.convert(text), '% \\begin{verbatim} 软件\n軟體\\%設定')

    def test_screenshot_path_caption_and_label(self):
        self.assertEqual(
            self.convert(r'\screenshot{图片/结构.png}{软件\ui{设置}}{结构}'),
            r'\screenshot{图片/结构.png}{軟體\ui{設定}}{结构}')

    def test_macro_definition_and_index(self):
        self.assertEqual(self.convert(r'\newcommand{\screenshot}[3]{#1 软件 #2}'
                                     r'\index{Ruanjian@软件设置}'),
                         r'\newcommand{\screenshot}[3]{#1 軟體 #2}'
                         r'\index{Ruanjian@軟體設定}')

    def test_generation_preserves_figure_and_example_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'source'
            source.mkdir()
            fixtures = {
                'main.tex': b'\\usepackage{manual-style}\n',
                'chapters/test.tex': '软件设置'.encode(),
                'figures/diagram.tex': '图中软件设置'.encode(),
                'publication-assets/screenshot.png': b'\x89PNG\r\n\x1a\n',
                'examples/data.gz': b'\x1f\x8b\x00\xff',
                'build/main.aux': b'ignored',
                '__pycache__/build.pyc': b'ignored',
            }
            for name, data in fixtures.items():
                path = source / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
            with patch.object(translation, 'SOURCE', source):
                files = translation.expected_files(self.converter)
            self.assertEqual(files['chapters/test.tex'].decode(), '軟體設定')
            self.assertIn('appendixname=附錄', files['main.tex'].decode())
            for name in ('figures/diagram.tex', 'publication-assets/screenshot.png', 'examples/data.gz'):
                self.assertEqual(files[name], fixtures[name])
            self.assertNotIn('build/main.aux', files)
            self.assertNotIn('__pycache__/build.pyc', files)

    def test_sync_check_and_stale_file_removal(self):
        with tempfile.TemporaryDirectory() as directory, redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            target = Path(directory)
            with patch.object(translation, 'TARGET', target):
                first = {'old.tex': b'old', translation.MANIFEST: b'{"files": ["old.tex"]}'}
                self.assertTrue(translation.synchronize(first))
                (target / 'build').mkdir()
                (target / 'build/main.pdf').write_bytes(b'local build')
                second = {'new.tex': b'new', translation.MANIFEST: b'{"files": ["new.tex"]}'}
                self.assertFalse(translation.synchronize(second, check=True))
                self.assertTrue((target / 'old.tex').exists())
                translation.synchronize(second)
                self.assertFalse((target / 'old.tex').exists())
                self.assertEqual((target / 'build/main.pdf').read_bytes(), b'local build')
                self.assertTrue(translation.synchronize(second, check=True))
                (target / 'new.tex').write_bytes(b'changed')
                self.assertFalse(translation.synchronize(second, check=True))

    def test_missing_source_cannot_erase_generated_edition(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(translation, 'SOURCE', Path(directory) / 'missing'):
                with self.assertRaises(FileNotFoundError):
                    translation.expected_files(self.converter)


if __name__ == '__main__':
    unittest.main()
