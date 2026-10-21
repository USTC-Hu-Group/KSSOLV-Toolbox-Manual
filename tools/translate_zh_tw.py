#!/usr/bin/env python3
"""Generate the Taiwan Traditional Chinese manual; optionally build its PDF.

Only main.tex, manual-style.sty and chapters/*.tex are converted. Figures
(including TikZ), examples, licenses and build support are copied byte for byte.
The converter handles this repository's TeX conventions, not arbitrary TeX macros.
"""

import argparse
from importlib.metadata import version
import json
from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs' / 'manual-zh-CN'
TARGET = ROOT / 'docs' / 'manual-zh-TW'
MANIFEST = '.translation-manifest.json'
SKIP_DIRS = {'build', '__pycache__', '.cache'}
SKIP_SUFFIXES = {'.aux', '.log', '.toc', '.out', '.idx', '.ind', '.ilg',
                 '.fls', '.fdb_latexmk', '.xdv', '.pyc', '.synctex', '.gz'}
# .gz files in examples are reference data and must be kept.
LITERAL_COMMANDS = {
    'file', 'literalinput', 'texttt', 'verb', 'url', 'nolinkurl', 'path',
    'input', 'include', 'includeonly', 'includegraphics', 'graphicspath',
    'label', 'ref', 'eqref', 'pageref', 'autoref', 'nameref', 'vref',
    'cref', 'Cref', 'cite', 'citep', 'citet', 'bibliography',
    'bibliographystyle', 'lstinputlisting', 'detokenize', 'href', 'hyperref',
}
TOKEN = re.compile(
    r'(?P<comment>%[^\n]*)'
    r'|(?P<environment>\\begin\{(?P<env>lstlisting|verbatim\*?|Verbatim|minted)\}'
    r'.*?\\end\{(?P=env)\})'
    r'|(?P<verb>\\verb\*?(?P<delimiter>[^A-Za-z\s]).*?(?P=delimiter))'
    r'|\\(?P<command>[A-Za-z]+)\*?|\\.', re.DOTALL)


def group_end(text, start, opening='{', closing='}'):
    """Find a balanced TeX argument, respecting escapes and comments."""
    depth, pos = 0, start
    while pos < len(text):
        char = text[pos]
        if char == '\\':
            pos += 2
            continue
        if char == '%':
            end = text.find('\n', pos)
            pos = len(text) if end < 0 else end + 1
            continue
        if char == opening:
            depth += 1
        elif char == closing:
            depth -= 1
            if depth == 0:
                return pos + 1
        pos += 1
    raise ValueError(f'Unclosed TeX argument at character {start}')


def argument_end(text, pos):
    """Skip optional arguments, then protect one mandatory argument."""
    while True:
        while pos < len(text) and text[pos].isspace():
            pos += 1
        if pos < len(text) and text[pos] == '[':
            pos = group_end(text, pos, '[', ']')
        else:
            break
    if pos < len(text) and text[pos] == '{':
        return group_end(text, pos)
    return pos


def convert_tex(text, converter):
    """Convert prose while leaving executable/literal TeX content intact."""
    result, pos = [], 0
    while match := TOKEN.search(text, pos):
        result.append(converter.convert(text[pos:match.start()]))
        end = match.end()
        command = match.group('command')
        if command in LITERAL_COMMANDS or command == 'screenshot':
            end = argument_end(text, end)
        if command == 'screenshot' and end > match.end() and text[end - 1] == '}':
            # Its first argument is an asset path, second a caption, third a label.
            result.append(text[match.start():end])
            caption_start = end
            while caption_start < len(text) and text[caption_start].isspace():
                caption_start += 1
            if caption_start >= len(text) or text[caption_start] != '{':
                raise ValueError('Expected a screenshot caption')
            caption_end = group_end(text, caption_start)
            result.append(text[end:caption_start + 1])
            result.append(convert_tex(text[caption_start + 1:caption_end - 1], converter))
            result.append('}')
            end = argument_end(text, caption_end)
            result.append(text[caption_end:end])
        else:
            result.append(text[match.start():end])
        pos = end
    result.append(converter.convert(text[pos:]))
    return ''.join(result)


def source_files():
    for path in sorted(SOURCE.rglob('*')):
        relative = path.relative_to(SOURCE)
        if not path.is_file() or any(part in SKIP_DIRS for part in relative.parts):
            continue
        if path.name == '.DS_Store' or path.name.startswith('._'):
            continue
        if relative.parts[0] != 'examples' and (
                path.suffix in SKIP_SUFFIXES or path.name in {'main.pdf', 'main.dvi', 'main.ps'}):
            continue
        yield path, relative


def expected_files(converter):
    if not (SOURCE / 'main.tex').is_file():
        raise FileNotFoundError(f'Missing Simplified Chinese entry point: {SOURCE / "main.tex"}')
    files = {}
    for source, relative in source_files():
        data = source.read_bytes()
        if relative.as_posix() in {'main.tex', 'manual-style.sty'} or (
                relative.parts[0] == 'chapters' and relative.suffix == '.tex'):
            text = convert_tex(data.decode('utf-8'), converter)
            if relative.as_posix() == 'main.tex':
                text = text.replace('fontset=fandol', 'fontset=none')
                # ctex defaults to Simplified Chinese for automatic appendix names.
                text = text.replace('\\usepackage{manual-style}',
                                    '\\usepackage{manual-fonts-tw}\n\\usepackage{manual-style}\n'
                                    '\\ctexset{appendixname=附錄,listfigurename=插圖,'
                                    'bibname=參考文獻,proofname=證明}')
            files[relative.as_posix()] = text.encode('utf-8')
        elif relative.as_posix() == 'README.md':
            files['README.md'] = (
                '# KSSOLV Toolbox Traditional Chinese manual\n\n'
                'This generated edition uses `zh-TW` (Taiwan Traditional Chinese). '
                'Edit [the Simplified Chinese sources](../manual-zh-CN/README.md), '
                'then run the following commands from the repository root:\n\n'
                '```sh\npython tools/translate_zh_tw.py\n'
                'python tools/download_tw_fonts.py\n'
                'python build.py --language zh-TW\n```\n\n'
                'Use `python tools/translate_zh_tw.py --check` to check synchronization '
                'or `--build` to regenerate and compile in one command. '
                'Regeneration overwrites generated files. All figures, screenshots, '
                'examples, code listings and literal inputs remain unchanged. '
                'The index retains the original pinyin sorting.\n\n'
                'See the [repository README](../../README.md) for dependencies, '
                'output paths and the language roadmap. '
                'You can also run `python build.py` inside this directory.\n'
            ).encode('utf-8')
        else:
            files[relative.as_posix()] = data
    files['manual-fonts-tw.sty'] = (ROOT / 'tools' / 'manual-fonts-tw.sty').read_bytes()
    manifest = {
        'source': '../manual-zh-CN', 'language': 'zh-TW', 'conversion': 's2twp',
        'package': f'opencc-python-reimplemented=={version("opencc-python-reimplemented")}',
        'files': sorted(files),
    }
    files[MANIFEST] = (json.dumps(manifest, ensure_ascii=False, indent=2) + '\n').encode('utf-8')
    return files


def synchronize(files, check=False):
    old_manifest = TARGET / MANIFEST
    previous = json.loads(old_manifest.read_text())['files'] if old_manifest.exists() else []
    stale = set(previous) - files.keys()
    # Only remove files recorded by an earlier generation, never build output.
    for name in stale:
        path = (TARGET / name).resolve()
        if not path.is_relative_to(TARGET.resolve()):
            raise ValueError(f'Invalid generated path: {name}')
    changed = [name for name, data in files.items()
               if not (TARGET / name).is_file() or (TARGET / name).read_bytes() != data]
    if check:
        for name in changed:
            print(f'Out of date: {name}', file=sys.stderr)
        for name in sorted(stale):
            print(f'Stale: {name}', file=sys.stderr)
        return not changed and not stale
    for name in changed:
        destination = TARGET / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(files[name])
    for name in stale:
        (TARGET / name).unlink(missing_ok=True)
    print(f'Generated {TARGET} ({len(changed)} updated, {len(stale)} removed).')
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group()
    action.add_argument('--check', action='store_true', help='Check generated files without writing.')
    action.add_argument('--build', action='store_true', help='Generate sources, then compile the PDF.')
    args = parser.parse_args()
    try:
        from opencc import OpenCC
    except ImportError:
        parser.exit(1, 'Install the pure-Python converter: python -m pip install -r requirements.txt\n')
    if not synchronize(expected_files(OpenCC('s2twp')), check=args.check):
        return 1
    if args.check:
        print('Traditional Chinese sources are up to date.')
    if args.build:
        return subprocess.run([sys.executable, str(ROOT / 'build.py'), '--language', 'zh-TW'],
                              cwd=ROOT).returncode
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
