#!/usr/bin/env python3
"""Build a Chinese manual with a JVM-free XeLaTeX toolchain."""

from pathlib import Path
import shutil
import subprocess
import sys
import re

from pypdf import PdfReader, PdfWriter
from pypdf.generic import DecodedStreamObject, NameObject


def executable(name):
    found = shutil.which(name)
    if found:
        return found
    mac_tex = Path('/Library/TeX/texbin') / name
    if mac_tex.is_file():
        return str(mac_tex)
    raise RuntimeError(f'{name} is required. Install TeX Live or MacTeX first.')


def export_portable_pdf(source, destination):
    """Embed CID-to-Unicode maps that some CJK viewers otherwise load externally."""
    writer = PdfWriter(clone_from=source)
    maps = {}
    for page in writer.pages:
        for reference in page['/Resources'].get('/Font', {}).values():
            font = reference.get_object()
            if ('/ToUnicode' not in font and font.get('/Subtype') == '/Type1'
                    and str(font.get('/BaseFont', '')).split('+')[-1] == 'CMEX10'):
                name = 'CMEX10-Unicode'
                if name not in maps:
                    stream = DecodedStreamObject()
                    stream.set_data(cmex_unicode_map(font))
                    maps[name] = writer._add_object(stream.flate_encode())
                font[NameObject('/ToUnicode')] = maps[name]
                continue
            if font.get('/Subtype') != '/Type0' or '/ToUnicode' in font:
                continue
            descendant = font['/DescendantFonts'][0].get_object()
            info = descendant['/CIDSystemInfo']
            if info.get('/Registry') != 'Adobe' or info.get('/Ordering') != 'GB1':
                raise RuntimeError(f'Missing Unicode map for {font.get("/BaseFont")}')
            name = 'Adobe-GB1-UCS2'
            if name not in maps:
                result = subprocess.run([executable('kpsewhich'), '-format=cmap', name],
                                        capture_output=True, text=True, check=True)
                cmap = Path(result.stdout.strip())
                stream = DecodedStreamObject()
                stream.set_data(cmap.read_bytes())
                maps[name] = writer._add_object(stream.flate_encode())
            font[NameObject('/ToUnicode')] = maps[name]
    writer.write(destination)
    reader = PdfReader(destination)
    text = ''.join(page.extract_text() for page in reader.pages)
    if sum('\u4e00' <= char <= '\u9fff' for char in text) < 20000:
        raise RuntimeError('Chinese text extraction failed; do not distribute this PDF.')


def cmex_unicode_map(font):
    """Map the standard CMEX10 encoding used by this book's large math symbols."""
    result = subprocess.run([executable('kpsewhich'), 'cmex10.afm'],
                            capture_output=True, text=True, check=True)
    afm = Path(result.stdout.strip()).read_text(encoding='ascii')
    symbols = {
        'parenleftbig': '0028', 'parenrightbig': '0029',
        'parenleftbigg': '0028', 'parenrightbigg': '0029',
        'bracketleftbig': '005B', 'bracketrightbig': '005D',
        'vextendsingle': '007C',
        'bracketlefttp': '23A1', 'bracketleftbt': '23A3',
        'bracketleftex': '23A2', 'bracketrighttp': '23A4',
        'bracketrightbt': '23A6', 'bracketrightex': '23A5',
        'bracelefttp': '23A7', 'braceleftmid': '23A8',
        'braceleftbt': '23A9', 'braceex': '23AA',
        'summationdisplay': '2211', 'integraldisplay': '222B',
        'hatwide': '0302',
    }
    used = set(str(font['/FontDescriptor']['/CharSet']).strip('/').split('/'))
    if used - symbols.keys():
        raise RuntimeError(f'Unmapped CMEX10 glyphs: {sorted(used - symbols.keys())}')
    pairs = [(int(code), symbols[glyph]) for code, glyph in
             re.findall(r'^C (\d+) ;.*? N (\S+) ;', afm, re.M)
             if glyph in symbols and int(code) < 256]
    lines = ['<%02X> <%s>' % pair for pair in pairs]
    cmap = ('/CIDInit /ProcSet findresource begin\n12 dict begin\nbegincmap\n'
            '/CIDSystemInfo << /Registry (KSSOLV) /Ordering (Math) /Supplement 0 >> def\n'
            '/CMapName /CMEX10-Unicode def\n/CMapType 2 def\n'
            '1 begincodespacerange\n<00> <FF>\nendcodespacerange\n'
            f'{len(lines)} beginbfchar\n' + '\n'.join(lines) +
            '\nendbfchar\nendcmap\nCMapName currentdict /CMap defineresource pop\n'
            'end\nend\n')
    return cmap.encode('ascii')


def main():
    root = Path(__file__).resolve().parent
    language = root.name.removeprefix('manual-')
    if language == 'zh-TW':
        fonts = root.parents[1] / 'output' / 'fonts' / 'noto-cjk'
        required = [f'Noto{family}CJKtc-{weight}.otf'
                    for family in ('Serif', 'Sans') for weight in ('Regular', 'Bold')]
        if any(not (fonts / name).is_file() for name in required):
            print('Install the Traditional Chinese fonts first: '
                  'python tools/download_tw_fonts.py (from the repository root)', file=sys.stderr)
            return 1
    output = root.parents[1] / 'output' / 'pdf'
    build = root / 'build'
    build.mkdir(exist_ok=True)
    xelatex = executable('xelatex')
    latexmk = executable('latexmk')
    command = [latexmk, '-xelatex', f'-xelatex={xelatex} %O %S',
               '-interaction=nonstopmode', '-halt-on-error', '-outdir=build', 'main.tex']
    with (build / 'build.log').open('w', encoding='utf-8') as log:
        process = subprocess.run(command, cwd=root, stdout=log, stderr=subprocess.STDOUT)
    if process.returncode:
        print((build / 'build.log').read_text(encoding='utf-8')[-6000:], file=sys.stderr)
        return process.returncode
    log = (build / 'main.log').read_text(encoding='utf-8', errors='replace')
    failures = [line for line in log.splitlines()
                if 'Missing character:' in line or 'Overfull \\hbox' in line
                or 'undefined references' in line or 'undefined on input line' in line]
    if failures:
        print('\n'.join(failures), file=sys.stderr)
        print('Resolve document diagnostics before exporting.', file=sys.stderr)
        return 2
    output.mkdir(parents=True, exist_ok=True)
    destination = output / f'KSSOLV_Toolbox_User_Manual_{language}.pdf'
    export_portable_pdf(build / 'main.pdf', destination)
    print(destination)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
