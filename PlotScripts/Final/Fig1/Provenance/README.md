# Provenance material for Figure 1

This is Steve Carr's original delivery for the Figure 1 (CRISP-RF denoising) data pipeline —
kept for transparency/audit trail, not part of the runnable Figure 1 pipeline itself.
`Figure1_CRISP_Denoising.m` (one level up) only depends on the four `.mat` files sitting
alongside it there, not on anything in this folder.

**Status: reference only, not verified runnable.** These scripts were already known (per the
project's own earlier hand-off notes) to have `load()` calls referencing filenames that don't
match what's actually in this folder — e.g. `Code_S1_scatter.m` calls
`load('All_stations_nvg_sequenced.mat')`, which isn't present here. Nobody has gone back and
fixed that, because the analysis these scripts feed (an NVG-vs-PVG depth scatter/histogram) is
out of scope for the current manuscript's Figure 1. Treat these as historical record of how the
four consumable `.mat` files one level up were derived, not as scripts to run.

- `Code_S1_scatter.m`, `Code_S2_Residuals_matrix.m`, `Code_S3_Hua_Sp_Ps.m` — original processing
  scripts.
- `Data_Hua_neg_subset.mat`, `Data_Hua_pos_subset.mat`, `Data_Residuals_sequenced.mat`,
  `Data_Residuals_unsequenced.mat` — intermediate data these scripts consume/produce.
- `Extracted_Metadata.txt` — station metadata used by `Code_S3_Hua_Sp_Ps.m`.
