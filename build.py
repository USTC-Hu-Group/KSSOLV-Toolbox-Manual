#!/usr/bin/env python3
"""Build the manual from the standalone repository root."""

import argparse
from pathlib import Path
import runpy
import sys


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--language', choices=('zh-CN', 'zh-TW', 'en'), default='zh-CN',
                        help='Manual to build (default: zh-CN).')
    parser.add_argument('--draft', action='store_true',
                        help='Build an unpublished English draft with pending screenshot markers.')
    args = parser.parse_args()
    if args.draft and args.language != 'en':
        parser.error('--draft is only available for the English edition')
    entry = Path(__file__).resolve().parent / 'docs' / f'manual-{args.language}' / 'build.py'
    sys.argv = [str(entry)] + (['--draft'] if args.draft else [])
    runpy.run_path(
        str(entry),
        run_name='__main__',
    )
