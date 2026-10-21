"""Plot saved, verified IDPP images; never run MATLAB or generate new coordinates.

Optional redraw requires matplotlib and numpy; the main manual build does not.
Run this file with Python from any cwd. The figure is 122 x 60 mm, with vector
PDF, 400-dpi PNG and provenance output under output/figures/neb-idpp.
The published assets are never overwritten.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


MANUAL = Path(__file__).resolve().parents[1]
REPOSITORY = MANUAL.parents[1]
EXAMPLES = MANUAL / "examples"
OUTPUT_DIRECTORY = REPOSITORY / "output" / "figures" / "neb-idpp"
SOURCE = EXAMPLES / "neb-exchange"
REPORT = EXAMPLES / "polymer-neb-examples-results.json"
PROVENANCE = OUTPUT_DIRECTORY / "results-neb-idpp-provenance.json"


def checksum(path: Path) -> dict:
    return {
        "file": str(path.relative_to(REPOSITORY)),
        "bytes": path.stat().st_size,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def main() -> None:
    paths = [SOURCE / f"image-{index:02d}.json" for index in range(7)]
    objects = [json.loads(path.read_text()) for path in paths]
    coordinates = np.asarray(
        [[site["xyz"] for site in obj["sites"]] for obj in objects], dtype=float
    )
    assert coordinates.shape == (7, 2, 3)
    assert np.all(coordinates[:, :, 1] == 5.0)
    for obj in objects:
        assert [site["label"] for site in obj["sites"]] == ["H_A", "H_B"]
        assert obj["lattice"]["pbc"] == [False, False, False]

    fractions = np.arange(7, dtype=float) / 6
    linear = (
        (1 - fractions[:, None, None]) * coordinates[0]
        + fractions[:, None, None] * coordinates[-1]
    )
    distances = np.linalg.norm(coordinates[:, 0] - coordinates[:, 1], axis=1)
    linear_distances = np.linalg.norm(linear[:, 0] - linear[:, 1], axis=1)
    report = json.loads(REPORT.read_text())["neb"]
    assert np.allclose(coordinates, report["coordinates"], rtol=0, atol=1e-12)
    assert np.allclose(distances, report["minimumPairDistances"], rtol=0, atol=1e-12)
    assert np.allclose(linear_distances, report["linearMinimumPairDistances"], rtol=0, atol=1e-12)
    assert np.array_equal(coordinates[0], [[2, 5, 5], [8, 5, 5]])
    assert np.array_equal(coordinates[-1], [[8, 5, 5], [2, 5, 5]])
    assert linear_distances[3] == 0

    plt.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "font.size": 8,
            "axes.labelsize": 8,
            "xtick.labelsize": 7.2,
            "ytick.labelsize": 7.2,
            "legend.fontsize": 7,
            "axes.linewidth": 0.55,
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.edgecolor": "#586674",
            "axes.labelcolor": "#242C33",
            "text.color": "#242C33",
            "xtick.color": "#586674",
            "ytick.color": "#586674",
            "xtick.major.width": 0.5,
            "ytick.major.width": 0.5,
            "xtick.major.size": 2.5,
            "ytick.major.size": 2.5,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
            "savefig.facecolor": "white",
        }
    )
    blue = "#07548D"
    teal = "#4A9FA3"
    grey = "#87929A"
    pale = "#E5EDF1"
    figure = plt.figure(figsize=(122 / 25.4, 60 / 25.4))
    gridspec = figure.add_gridspec(
        1, 2, left=0.105, right=0.98, bottom=0.235, top=0.79, wspace=0.52
    )
    tracks = figure.add_subplot(gridspec[0])
    separation = figure.add_subplot(gridspec[1])
    figure.text(0.105, 0.94, "(a) Atom tracks", fontsize=8, fontweight="bold")
    figure.text(0.63, 0.94, "(b) Pair distance", fontsize=8, fontweight="bold")

    tracks.plot(
        coordinates[:, 0, 0], coordinates[:, 0, 2], "o-", color=teal,
        linewidth=1.4, markersize=3, markeredgewidth=0.5, label="A",
    )
    tracks.plot(
        coordinates[:, 1, 0], coordinates[:, 1, 2], "s-", color=blue,
        linewidth=1.4, markersize=2.9, markeredgewidth=0.5, label="B",
    )
    tracks.plot(
        linear[:, 0, 0], linear[:, 0, 2], "--", color=grey,
        linewidth=0.9, zorder=0, label="Linear",
    )
    tracks.annotate(
        "A00 / B06", (2, 5), xytext=(2, 7.3), textcoords="data",
        ha="left", va="bottom", fontsize=6.8,
    )
    tracks.annotate(
        "A06 / B00", (8, 5), xytext=(8, 7.3), textcoords="data",
        ha="right", va="bottom", fontsize=6.8,
    )
    tracks.annotate(
        "A03", coordinates[3, 0, [0, 2]], xytext=(0, 5),
        textcoords="offset points", ha="center", va="bottom", color=teal, fontsize=7,
    )
    tracks.annotate(
        "B03", coordinates[3, 1, [0, 2]], xytext=(0, -5),
        textcoords="offset points", ha="center", va="top", color=blue, fontsize=7,
    )
    tracks.set(xlabel="x (Å)", ylabel="z (Å)", xlim=(1.5, 8.5), ylim=(2.35, 7.65))
    tracks.set_xticks([2, 4, 6, 8])
    tracks.set_yticks([3, 5, 7])
    tracks.set_aspect("equal", adjustable="box")
    tracks.legend(
        loc="lower center", bbox_to_anchor=(0.5, 1.04), ncol=3,
        frameon=False, handlelength=1.2, handletextpad=0.35, columnspacing=0.8,
        borderaxespad=0,
    )

    separation.plot(
        range(7), distances, "o-", color=blue, linewidth=1.4,
        markersize=3.2, markeredgewidth=0.5, label="IDPP",
    )
    separation.plot(
        range(7), linear_distances, "s--", color=grey, linewidth=0.9,
        markersize=2.8, markeredgewidth=0.5, label="Linear",
    )
    separation.set(xlabel="Image", ylabel="d(A, B) (Å)", xlim=(-0.25, 6.25), ylim=(-0.35, 6.55))
    separation.set_xticks(range(7), [f"{index:02d}" for index in range(7)])
    separation.set_yticks([0, 2, 4, 6])
    separation.grid(axis="y", color=pale, linewidth=0.55)
    separation.set_axisbelow(True)
    separation.legend(
        loc="lower center", bbox_to_anchor=(0.5, 1.04), ncol=2,
        frameon=False, handlelength=1.5, handletextpad=0.4, columnspacing=1.2,
        borderaxespad=0,
    )
    figure.text(
        0.54, 0.045, "Saved IDPP images; y = 5 Å. Lines join computed images.",
        ha="center", fontsize=6.7, color="#586674",
    )
    figure.canvas.draw()
    renderer = figure.canvas.get_renderer()
    figure_bounds = figure.bbox
    text_bounds = []
    for text in figure.findobj(matplotlib.text.Text):
        if not text.get_text() or not text.get_visible():
            continue
        bounds = text.get_window_extent(renderer)
        assert bounds.x0 >= figure_bounds.x0 - 0.5, text.get_text()
        assert bounds.x1 <= figure_bounds.x1 + 0.5, text.get_text()
        assert bounds.y0 >= figure_bounds.y0 - 0.5, text.get_text()
        assert bounds.y1 <= figure_bounds.y1 + 0.5, text.get_text()
        text_bounds.append({"text": text.get_text(), "boundsPx": list(bounds.bounds)})

    OUTPUT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    pdf = OUTPUT_DIRECTORY / "results-neb-idpp.pdf"
    png = OUTPUT_DIRECTORY / "results-neb-idpp.png"
    figure.savefig(
        pdf, metadata={"Title": "IDPP geometry from saved images", "Creator": "matplotlib",
                       "CreationDate": None, "ModDate": None}
    )
    figure.savefig(png, dpi=400)
    plt.close(figure)
    provenance = {
        "plotKind": "Scientific teaching figure; not a GUI screenshot",
        "matplotlib": matplotlib.__version__,
        "numpy": np.__version__,
        "figureSizeMm": [122, 60],
        "fontFamily": "DejaVu Sans",
        "axesLabelSizePt": 8,
        "pngDpi": 400,
        "coordinateUnit": "angstrom",
        "sources": [checksum(path) for path in paths] + [checksum(REPORT)],
        "script": checksum(Path(__file__).resolve()),
        "outputs": [checksum(pdf), checksum(png)],
        "coordinatesByImageAndAtom": coordinates.tolist(),
        "idppDistances": distances.tolist(),
        "linearDistances": linear_distances.tolist(),
        "maxDifferenceFromVerifiedReport": float(
            np.max(np.abs(distances - np.asarray(report["minimumPairDistances"])))
        ),
        "MATLABRerun": False,
        "GUIOperated": False,
        "textWithinFigureBounds": True,
        "textBounds": text_bounds,
    }
    PROVENANCE.write_text(json.dumps(provenance, ensure_ascii=False, indent=2) + "\n")
    print(f"Saved {pdf} and {png}; distances match verified report.")


if __name__ == "__main__":
    main()
