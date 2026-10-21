#!/usr/bin/env python3
"""Download pinned, OFL-licensed Noto CJK TC fonts for the Traditional manual.

Only font binaries and their licenses are fetched; no code is built or executed.
Existing matching files are reused. Downloads stay in the ignored output tree.
"""

import hashlib
from pathlib import Path
import sys
from urllib.error import URLError
from urllib.request import urlopen


REVISION = 'f8d157532fbfaeda587e826d4cd5b21a49186f7c'
BASE = f'https://raw.githubusercontent.com/notofonts/noto-cjk/{REVISION}/'
DESTINATION = Path(__file__).resolve().parents[1] / 'output' / 'fonts' / 'noto-cjk'
FILES = {
    'Serif/OTF/TraditionalChinese/NotoSerifCJKtc-Regular.otf':
        '234301038e76e7c35c43113785024700c4e4fe7bdce1d1fbbc42fca7e6683798',
    'Serif/OTF/TraditionalChinese/NotoSerifCJKtc-Bold.otf':
        'a4441a76dbf56719600c5dcbd5b5e5a068a20944cc41c959487a657133576ee6',
    'Sans/OTF/TraditionalChinese/NotoSansCJKtc-Regular.otf':
        'dce08bd4fd91aa8aa76ed8fea4b694c2dfb8550f67871e326843212ddbeb88b4',
    'Sans/OTF/TraditionalChinese/NotoSansCJKtc-Bold.otf':
        '3ee160e5015106e3ec1a394301df54fa9bbbf8a251519984aec5c0abc50840c0',
    'Sans/LICENSE': '6a73f9541c2de74158c0e7cf6b0a58ef774f5a780bf191f2d7ec9cc53efe2bf2',
    'Serif/LICENSE': '6a73f9541c2de74158c0e7cf6b0a58ef774f5a780bf191f2d7ec9cc53efe2bf2',
}


def main():
    DESTINATION.mkdir(parents=True, exist_ok=True)
    for source, checksum in FILES.items():
        name = Path(source).name if source.endswith('.otf') else source.replace('/', '-')
        destination = DESTINATION / name
        if destination.exists() and hashlib.sha256(destination.read_bytes()).hexdigest() == checksum:
            print(f'Verified {name}')
            continue
        print(f'Downloading {name}', flush=True)
        with urlopen(BASE + source, timeout=60) as response:
            data = response.read()
        if hashlib.sha256(data).hexdigest() != checksum:
            raise ValueError(f'SHA256 mismatch for {name}; download not saved')
        temporary = destination.with_suffix(destination.suffix + '.tmp')
        temporary.write_bytes(data)
        temporary.replace(destination)
    print(f'Fonts ready: {DESTINATION}')
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (OSError, URLError, ValueError) as error:
        print(f'Font download failed: {error}', file=sys.stderr)
        raise SystemExit(1)
