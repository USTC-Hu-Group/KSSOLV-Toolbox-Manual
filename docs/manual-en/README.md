# English user manual

This is the English edition of the KSSOLV Toolbox V0.5.0 user manual, covering the standalone application, MATLAB® toolbox, and KSSOLV Toolbox Online.

[Download the English PDF](../../dist/KSSOLV_Toolbox_User_Manual_en.pdf).

All 28 chapter and supplement files have been translated and cross-reviewed. Equations, numerical examples, labels, and executable code are preserved. Interface terminology follows the application's native `en_US` resources. The 83 image assets include 76 screenshots captured from the native English interface and 7 language-neutral resources.

## Build and check

From the repository root, with the dependencies described in the root README:

```sh
# Coverage, unchanged-code, and capture-provenance checks
python tools/verify_english_manual.py

# Build the release PDF
python build.py --language en
```

Release builds write `output/pdf/KSSOLV_Toolbox_User_Manual_en.pdf` and use the same JVM-free XeLaTeX toolchain as the Chinese editions. The published copy is in `dist/`, linked above.

The build rejects missing glyphs, horizontal overflow, undefined references, changes to executable listings or example scripts, and incomplete screenshot provenance.

For an optional unpublished layout proof, run `python build.py --language en --draft`. It writes `output/pdf/KSSOLV_Toolbox_User_Manual_en_DRAFT.pdf` with a DRAFT watermark. Keep layout proofs in `output/`.

## Figures and examples

The [English asset manifest](../provenance/english-edition-assets.json) records each image's capture status and provenance. English screenshots show the same structures, parameters, results, and interface states as their Chinese counterparts. Native text lengths may change layout. Capture pixels are cropped; labels are not repainted or substituted. Language-neutral plots and branding are reused unchanged. Operating-system dialogs retain the system language, as noted in their captions and provenance.

All 23 executable files—21 MATLAB example scripts and 2 Python figure generators—are byte-identical to the Simplified Chinese edition. Executable listings also retain their original paths, including references to `docs/manual-zh-CN/examples/`; those paths remain valid in this repository. Example data and projects are included unchanged. The supplied Chinese example notes remain available alongside them.
