# KSSOLV Toolbox Simplified Chinese manual

This is the editing source for the **V0.5.0** manual, covering the standalone application, MATLAB® toolbox, and KSSOLV Toolbox Online. The [repository README](../../README.md) lists all editions and their status. The Traditional Chinese edition is generated from this directory; English is planned.

## Build

Install Python dependencies and run from the repository root:

```sh
python3 -m pip install -r requirements.txt
python3 build.py --language zh-CN
```

Alternatively, run `python3 build.py` inside this directory. Temporary TeX files go into `build/`; the exported PDF goes into `output/pdf/KSSOLV_Toolbox_User_Manual_zh-CN.pdf` at the repository root.

Use Python 3.9 or later and TeX Live 2026 or a compatible distribution providing:

- XeLaTeX, latexmk, MakeIndex, and kpsewhich.
- ctex, fontspec, TikZ, tcolorbox, xurl, makeidx, and idxlayout.
- Fandol, TeX Gyre Pagella/Heros, Latin Modern Mono, and AMS Computer Modern fonts.
- The adobemapping package with Adobe-GB1-UCS2; see [third-party notices](THIRD-PARTY-NOTICES.md).

Keep `.latexmkrc` and `manual-index.ist` next to `main.tex`. The build checks missing glyphs, horizontal overflow, and undefined references, and embeds Unicode maps for CJK and extended mathematical symbols. No Java/JVM or native-code compilation is required. A LaTeX editor can preview `main.tex`; use the Python script for distributable PDFs.

## Edit text and figures

- `main.tex` assembles the book; `chapters/` contains body text; `manual-style.sty` defines page layout and fonts.
- Use `\ui{…}` for interface labels, `\file{…}` for filenames, `steps` for procedures, and `\literalinput{…}` for exact input.
- Index entries use `\index{pinyin sorting key@Chinese topic}`. Check steps, captions, labels, and index entries when updating a figure.
- Keep scientific plots as vector PDFs where possible. Keep screenshot crops at their original resolution and retain their provenance.
- `figures/` contains TikZ figures; `publication-assets/` contains the published screenshot crops and vector figures. Original full-screen screenshots and private review records are not distributed.

After editing, regenerate the Traditional Chinese sources from the repository root:

```sh
python3 tools/download_tw_fonts.py
python3 tools/translate_zh_tw.py --build
python3 tools/translate_zh_tw.py --check
```

The converter preserves figures, examples, code listings, paths, URLs, and exact input. Review converted terminology before publishing.

The font download step provides pinned, openly licensed Noto CJK TC fonts, since Fandol lacks some Taiwan characters. Downloads are verified and cached in `output/fonts/noto-cjk/`; no system font installation is needed. See the repository README for details.

## Examples and optional figure generation

The [example instructions](examples/README.zh-CN.md) describe structures, `.ks` projects, MATLAB® scripts, JSON results, and their intended use. MATLAB® scripts require a separately installed KSSOLV Toolbox; set `KSSOLV_TOOLBOX_ROOT` or make the toolbox discoverable by MATLAB®. Run applicable non-graphical scripts with `-nojvm`. Numerical references check units, trends, and convergence; random initial states can change final digits.

See [volume sources](examples/VOLUME-SOURCES.md) and the [pymatgen license](examples/PYMATGEN-MIT-LICENSE.txt) for example data provenance.

The cover uses the supplied diamond-cubic silicon structure, repeated along `[100]`, with first-neighbor bonds and one tetrahedral coordination highlighted. To regenerate its editable TikZ source, run from the repository root:

```sh
python3 docs/manual-zh-CN/figures/generate_cover_silicon.py
```

This script uses only the Python standard library and records coordination and bond-angle checks in `output/cover-design/geometry.json`.

To redraw the optional NEB/IDPP figures:

```sh
python3 -m pip install numpy matplotlib
python3 docs/manual-zh-CN/figures/plot_neb_idpp.py
```

Output goes into `output/figures/neb-idpp/`; the script reads the supplied reference data, does not run MATLAB®, and does not overwrite publication assets. PDF builds use the supplied figures and do not need these optional Python libraries.

Approved release PDFs and manifests are kept in `dist/`. A successful build does not replace editorial review or validation of the documented application workflows.
