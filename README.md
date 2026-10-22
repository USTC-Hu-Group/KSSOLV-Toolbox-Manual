# KSSOLV Toolbox User Manuals

[![License: BSL 1.1](https://img.shields.io/badge/License-BSL%201.1-blue)](LICENSE)
[![Language: LaTeX](https://img.shields.io/badge/Language-LaTeX-008080?logo=latex)](#build-the-manuals)
[![Python >=3.9](https://img.shields.io/badge/Python-%3E%3D3.9-3776AB?logo=python&logoColor=white)](#build-the-manuals)
[![Latest release](https://img.shields.io/github/v/release/USTC-Hu-Group/KSSOLV-Toolbox-Manual)](https://github.com/USTC-Hu-Group/KSSOLV-Toolbox-Manual/releases/latest)

This repository provides the user manuals for [KSSOLV Toolbox](https://github.com/USTC-Hu-Group/KSSOLV-Toolbox), covering the standalone application, MATLAB toolbox, and online version.

Download PDFs from the [latest release](https://github.com/USTC-Hu-Group/KSSOLV-Toolbox-Manual/releases/latest):

| Language | Download |
| --- | --- |
| Simplified Chinese | [Download PDF](https://github.com/USTC-Hu-Group/KSSOLV-Toolbox-Manual/releases/latest/download/KSSOLV_Toolbox_User_Manual_zh-CN.pdf) |
| Traditional Chinese (Taiwan) | [Download PDF](https://github.com/USTC-Hu-Group/KSSOLV-Toolbox-Manual/releases/latest/download/KSSOLV_Toolbox_User_Manual_zh-TW.pdf) |
| English | [Download PDF](https://github.com/USTC-Hu-Group/KSSOLV-Toolbox-Manual/releases/latest/download/KSSOLV_Toolbox_User_Manual_en.pdf) |

## Contents

The manuals cover installation, the workspace, atomic structure modeling, calculation parameters and workflows, volumetric data, results analysis, remote computing, and troubleshooting, with worked examples for molecules and materials.

## Reading guide

New users can start with installation (or the Online instructions), explore the workspace, and follow the hydrogen molecule tutorial for a complete first calculation. Then use the modeling and workflow chapters for your own systems, and consult the parameter chapters, quick reference, and subject index as needed. Example inputs and scripts are included under each edition's `examples/` directory.

## Build the manuals

Install Python 3.9+ and TeX Live 2026 (or a compatible distribution with XeLaTeX and latexmk); see the [TeX requirements](docs/manual-zh-CN/README.md#build). Run from the repository root:

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt

python build.py --language en
python build.py --language zh-CN

# Traditional Chinese: download the required fonts once before building.
python tools/download_tw_fonts.py
python build.py --language zh-TW
```

PDFs are saved to `output/pdf/KSSOLV_Toolbox_User_Manual_<language>.pdf`, where `<language>` is `en`, `zh-CN`, or `zh-TW`.

## License

Original content is licensed under the [Business Source License 1.1](LICENSE). Production use outside its Additional Use Grant requires a [commercial license](COMMERCIAL-LICENSE.md). [Third-party materials](THIRD-PARTY-LICENSES.md) retain their respective licenses.
