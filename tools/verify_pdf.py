#!/usr/bin/env python3
"""Compare a rebuilt manual with its approved PDF, ignoring PDF metadata."""

import argparse
import hashlib
import json
from pathlib import Path

from pypdf import PdfReader


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def font_streams(reader):
    seen, streams = set(), set()

    def walk(resources):
        for reference in resources.get('/Font', {}).values():
            font = reference.get_object()
            descendant = (font['/DescendantFonts'][0].get_object()
                          if '/DescendantFonts' in font else font)
            descriptor = descendant.get('/FontDescriptor', {})
            if hasattr(descriptor, 'get_object'):
                descriptor = descriptor.get_object()
            data = next((descriptor[key].get_object().get_data()
                         for key in ('/FontFile', '/FontFile2', '/FontFile3')
                         if key in descriptor), None)
            if data is None or '/ToUnicode' not in font:
                raise ValueError('Missing embedded font or Unicode map')
            streams.add((sha256(data), sha256(font['/ToUnicode'].get_object().get_data())))
        for reference in resources.get('/XObject', {}).values():
            key = getattr(reference, 'idnum', id(reference))
            if key in seen:
                continue
            seen.add(key)
            obj = reference.get_object()
            if obj.get('/Subtype') == '/Form':
                walk(obj.get('/Resources', {}))

    for page in reader.pages:
        walk(page['/Resources'])
    return streams


def compare(approved, rebuilt):
    first, second = PdfReader(approved), PdfReader(rebuilt)
    if len(first.pages) != len(second.pages):
        raise ValueError('Page count differs')
    for number, (a, b) in enumerate(zip(first.pages, second.pages), 1):
        if a.extract_text() != b.extract_text():
            raise ValueError(f'Page {number}: extracted text differs')
        if (list(a.mediabox), list(a.cropbox), a.get('/Rotate', 0)) != (
                list(b.mediabox), list(b.cropbox), b.get('/Rotate', 0)):
            raise ValueError(f'Page {number}: page geometry differs')
        if a.get_contents().get_data() != b.get_contents().get_data():
            raise ValueError(f'Page {number}: decoded layout stream differs')
    fonts = font_streams(first)
    if fonts != font_streams(second):
        raise ValueError('Embedded fonts or Unicode maps differ')
    return {
        'pages': len(first.pages),
        'pageTextEqual': True,
        'pageGeometryEqual': True,
        'decodedPageContentEqual': True,
        'embeddedFontAndUnicodeStreamsEqual': True,
        'fontStreamPairs': len(fonts),
        'approvedSHA256': sha256(approved.read_bytes()),
        'rebuiltSHA256': sha256(rebuilt.read_bytes()),
    }


def main():
    root = Path(__file__).resolve().parents[1]
    filename = 'KSSOLV_Toolbox_User_Manual_zh-CN.pdf'
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--approved', type=Path, default=root / 'dist' / filename)
    parser.add_argument('--rebuilt', type=Path, default=root / 'output' / 'pdf' / filename)
    args = parser.parse_args()
    print(json.dumps(compare(args.approved, args.rebuilt), ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
