#!/usr/bin/env python3
"""Check English chapter coverage, unchanged code, and screenshot provenance."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import struct


ROOT = Path(__file__).resolve().parents[1]
CN = ROOT / 'docs' / 'manual-zh-CN'
EN = ROOT / 'docs' / 'manual-en'
MANIFEST = ROOT / 'docs' / 'provenance' / 'english-edition-assets.json'
LISTING = re.compile(r'\\begin\{lstlisting\}.*?\\end\{lstlisting\}', re.S)
LABEL = re.compile(r'\\label\{([^{}]+)\}')
ASSET = re.compile(r'publication-assets/([^{}\s]+)')


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify(require_captures=True, check_raw_captures=False):
    failures = []
    chapters = sorted((CN / 'chapters').glob('*.tex'))
    for source in chapters:
        target = EN / 'chapters' / source.name
        if not target.is_file():
            failures.append(f'Missing English chapter: {source.name}')
            continue
        original, translated = source.read_text(), target.read_text()
        if LABEL.findall(original) != LABEL.findall(translated):
            failures.append(f'Labels changed: {source.name}')
        if LISTING.findall(original) != LISTING.findall(translated):
            failures.append(f'Executable code listing changed: {source.name}')
    code = [*(CN / 'examples').rglob('*.m'), *(CN / 'figures').glob('*.py')]
    for source in code:
        target = EN / source.relative_to(CN)
        if not target.is_file() or source.read_bytes() != target.read_bytes():
            failures.append(f'Example/generator code changed: {source.relative_to(CN)}')
    assets = set()
    for edition in (CN, EN):
        sources = [edition / 'main.tex', edition / 'manual-style.sty',
                   *(edition / 'chapters').rglob('*.tex'),
                   *(edition / 'figures').rglob('*.tex')]
        for source in sources:
            if not source.is_file():
                failures.append(f'Missing manual source: {source.relative_to(ROOT)}')
                continue
            assets.update(ASSET.findall(source.read_text()))
    records = {}
    if MANIFEST.is_file():
        records = {entry['asset']: entry for entry in json.loads(MANIFEST.read_text())['assets']}
    pending = []
    for name in sorted(assets):
        path = EN / 'publication-assets' / name
        record = records.get(name)
        if check_raw_captures and record and record['status'] == 'captured-en':
            raw = ROOT / record.get('rawCapture', '')
            if not raw.is_file():
                failures.append(f'Raw capture missing: {name}')
            elif sha256(raw) != record.get('rawSHA256'):
                failures.append(f'Raw capture checksum mismatch: {name}')
        if not path.is_file() or not record or record['status'] not in {
                'captured-en', 'reused-language-neutral'}:
            pending.append(name)
            continue
        if sha256(path) != record['sha256']:
            failures.append(f'English asset checksum mismatch: {name}')
        if record['status'] == 'captured-en' and not all(record.get(key) for key in (
                'rawCapture', 'rawSHA256', 'softwareVersion', 'locale', 'scene')):
            failures.append(f'Incomplete capture provenance: {name}')
        if record['status'] == 'captured-en':
            pixels, box = record.get('nativePixels', []), record.get('cropBoxXYXY', [])
            valid = (len(pixels) == 2 and len(box) == 4
                     and 0 <= box[0] < box[2] <= pixels[0]
                     and 0 <= box[1] < box[3] <= pixels[1])
            if not valid:
                failures.append(f'Capture crop outside native image: {name}')
            elif path.suffix.lower() == '.png':
                size = struct.unpack('>II', path.read_bytes()[16:24])
                if size != (box[2] - box[0], box[3] - box[1]):
                    failures.append(f'Capture crop dimensions mismatch: {name}')
    if require_captures:
        failures.extend(f'English screenshot not ready: {name}' for name in pending)
    return {'chapters': len(chapters), 'codeFiles': len(code),
            'referencedAssets': len(assets), 'pendingAssets': pending, 'failures': failures}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--allow-pending-captures', action='store_true',
                        help='Check an unpublished draft while reporting missing captures.')
    parser.add_argument('--check-raw-captures', action='store_true',
                        help='Also require local raw screenshots and verify their checksums.')
    args = parser.parse_args()
    report = verify(require_captures=not args.allow_pending_captures,
                    check_raw_captures=args.check_raw_captures)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return bool(report['failures'])


if __name__ == '__main__':
    raise SystemExit(main())
