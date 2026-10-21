#!/usr/bin/env python3
"""Build the manual from the standalone repository root."""

import argparse
from pathlib import Path
import runpy


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--language', choices=('zh-CN', 'zh-TW'), default='zh-CN',
                        help='Manual to build (default: zh-CN).')
    args = parser.parse_args()
    runpy.run_path(
        str(Path(__file__).resolve().parent / 'docs' / f'manual-{args.language}' / 'build.py'),
        run_name='__main__',
    )
