# Finalized Plotting Scripts

This directory contains the canonical, verified MATLAB scripts used to generate the main-text
figures for the manuscript, one subfolder per **current** figure number (post-reorder — see
the numbering note below if you ever touch `Draft/` or `Archive/`).

## How to run any script here

Each script expects its own containing folder (e.g. `Final/Fig3/`) as the MATLAB working
directory — not the `PlotScripts/` root. That's because their relative paths (`../../Data/...`,
`../../Figures/...`) are written for a script sitting two levels below `PlotScripts/`. Run as:

```
cd PlotScripts/Final/Fig3
matlab -nodisplay -nosplash -batch "Figure3_Map"
```

All outputs are written to `PlotScripts/Figures/Global_Study/`.

## Figure 1 — CRISP-RF denoising validation (`Fig1/`)

* **`Figure1_CRISP_Denoising.m`** — builds all four panels (raw Ps-RF, denoised Ps-RF, Sp-RF
  benchmark, denoised Ps-RF on the Hua-matched subset). Depends on the four `.mat` files sitting
  alongside it in this folder (`Data_S1a_raw_RF.mat`, `Data_S1b_sortedRF.mat`,
  `Hua_SpRF_Data.mat`, `Hua_subset_PsRF_data.mat`) and `jbfill.m`.
  Output: `Figure1_CRISP_Denoising.png`

## Figure 2 — GMM clustering / physical feature space (`Fig2/`)

* **`Figure2_FeatureStatsFinal.m`** — t-SNE embedding, GMM covariance ellipses, and the
  8-panel box/joint-KDE statistics grid. Self-contained.
  Output: `Figure2_FeatureStatsFinal.png`

## Figure 3 — Reclassifying continental layering (`Fig3/`)

Three scripts, run in order, because the final figure is a **manual composite of two
independently-generated pieces** (this is not documented anywhere else — it cost real time to
rediscover this session):

1. **`Figure3_Map.m`** — panel (a): the world map, legend, and the C4 depth inset.
   Depends on `jbfill.m` (copy kept in this folder) and reaches into
   `../../Draft/PearsonCratons/digitization` for the Pearson craton KML files (that data is not
   duplicated here). Output: `Figure3_Map.png` (+ `Figure3_Map_USInset.png`, currently unused).
2. **`Figure3_WaveformsKDE.m`** — panels (b)-(g): the 2x3 grid of waveform record-sections and
   joint-KDE depth scatter plots. Output: `Figure3_WaveformsKDE.png`.
3. **`Figure3_Composite.m`** — stacks the two PNGs above into the final figure, shifting the
   panel grid up to overlap the map's blank south-pole region (detected automatically, never
   clips real content). Run this last. Output: `Figure3_Composite.png` — **this is the file to
   embed in the manuscript.**

## Figure 4 — Tectonic validation (`Fig4/`)

* **`Figure4_TectonicValidation.m`** — three regional maps + Bedle/Pearson craton overlays +
  the below-map C1-C4 legend + the 2x2 count/box-plot grid on the right.
  Reaches into `../../Draft/PearsonCratons/digitization` the same way `Figure3_Map.m` does.
  Output: `Figure4_TectonicValidation.png`

## Figure 5 — Mosaic Model

No script — illustrator-produced (Nicoletta Barolini / Lauren Waszek). Final artwork lives at
`Revisions/tracked_revision/Figures/Revision3_Final_Figure5.png` (outside `PlotScripts/`).

## Figure-numbering note

The manuscript was restructured mid-review (current Figure 3 was the old Figure 1, current
Figure 4 was the old Figure 3). Everything in this `Final/` folder is named for the **current**
numbering. Older scripts still using the old numbers, and superseded/duplicate/broken variants
discovered during the 2026-09-24 cleanup, were moved to `../Archive/` (via `git mv`, so their
history is intact) rather than deleted — see filenames there for why each one was retired
(e.g. `_STALE`, `_BROKEN`, `_WrongContent`, `_no_cratons`).

## SI and other figures

Scripts for Supporting Information figures and figures not covered above (`Figure4_SlabProximityAnalysis.m`,
`Figure5A_PaleoCoastlines.m`, `Figure5B_ModernCoastlines.m`, `Revision1_Summary_Scatter_LAB.m`,
`FigSup1_SeisVsThermal_Full.m`, `Figure4_DeepStructureCratonLAB.m`) were **not** touched by the
2026-09-24 cleanup and still live in their previous locations — they weren't in scope and weren't
re-verified.
