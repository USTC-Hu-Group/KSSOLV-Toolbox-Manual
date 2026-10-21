#!/usr/bin/env python3
"""Build the manual from the standalone repository root."""

from pathlib import Path
import runpy


if __name__ == '__main__':
    runpy.run_path(
        str(Path(__file__).resolve().parent / 'docs' / 'manual-zh' / 'build.py'),
        run_name='__main__',
    )
