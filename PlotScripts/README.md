# GlobalUMDTax: Plotting Scripts & Data

This directory (`PlotScripts`) contains the MATLAB scripts and data necessary to reproduce the figures for the GlobalUMDTax manuscript.

## Project Structure

```text
PlotScripts/
├── Data/                 # All data files and dependencies needed to run the scripts
│   ├── m_map/            # Mapping library (dependency)
│   ├── slanCM/           # Custom colormap library (dependency)
│   ├── Velocity_Models/  # Tomography models (CAM22, etc.)
│   ├── MachineLearningData/  # Clustering results and metadata
│   └── ...               # (Other shapefiles and models)
├── Draft/                # Exploratory and working scripts (not guaranteed current)
├── Final/                # Canonical scripts, one location per main-text figure -- see Final/README.md
├── Archive/              # Confirmed-superseded scripts, kept for history (see Final/README.md)
└── README.md             # This guide
```

## Geological Datasets

The `PlotCratons.m` script (located in `Draft/FigX/`) explores various geological datasets that define craton boundaries and tectonic plates globally and regionally. The current available data includes:

1. **Global Tectonics:**
   - **Cratons:** `Data/global_tectonics/plates&provinces/shp/cratons.shp` (Currently active in plot)
   - **Plate Boundaries:** `Data/global_tectonics/plates&provinces/shp/plate_boundaries.shp` (Currently active in plot)
   - *Reference: Hasterok, D., et al. (2022). New maps of global geologic provinces and tectonic plates. Earth-Science Reviews, 231, 104069. [DOI: 10.1016/j.earscirev.2022.104069](https://doi.org/10.1016/j.earscirev.2022.104069)*
2. **EarthByte Craton Boundaries:** `Data/EarthByte_Craton_Boundaries/Craton_Data/Craton_Boundaries.shp` (Commented out)
   - *Reference: Craton boundary detection from full-waveform tomography model reveals links to critical metal deposits. [DOI: 10.1016/j.gsf.2025.102176](https://doi.org/10.1016/j.gsf.2025.102176)*
3. **North America Physiographic Regions:** `Data/GeologicalData/north america/physio_shp/physio.shp` (Commented out)
4. **Oceania Geological Regions:** `Data/GeologicalData/oceania/Geological_Regions_of_Australia.shp` (Commented out)
5. **Africa Archean Blocks (CSV):** `Data/GeologicalData/Africa/Archean_Blocks/*.csv` (Multiple Archean blocks, commented out)
6. **Africa Lekic Cratons (MAT):** `Data/GeologicalData/Africa/geoData/AfricaCratons_Lekic.mat` (Commented out)
   - *Reference: French, S. W., & Romanowicz, B. A. (or Lekic, V.) - Outlines based on global/regional tomography models.*

7. **Bedle Craton Boundaries (KML):** `Data/GeologicalData/BedleCratons/*.kml`
   - *Reference: Bedle, H. (2021). [DOI: 10.1029/2021TC006714](https://doi.org/10.1029/2021TC006714)*

## Important Note on Large Data Files

> [!WARNING]
> Due to GitHub's file size limits, the `votemap_100_km.mat` file (~397MB) is **not included in this repository**.
> **To run `Figure2b` and `Figure2c`, you must download this file separately.**
> 
> **Download location:**
> It is hosted on our internal NAS (`repovibranium`) and can be downloaded via this shareable link:
> **[Download Large Files (including votemap_100_km.mat)](https://repovibranium.quickconnect.to/sharing/phF28aHED)**
> 
> **Installation:**
> Place the downloaded `votemap_100_km.mat` file into the following directory relative to the scripts:
> `Data/GlobalVs_Models/votemap_100_km.mat`

## Running the Scripts

All scripts are written in **MATLAB (R2022b or newer recommended)** and rely on the local `Data/`
folder. They use relative paths written for a script sitting **two levels below `PlotScripts/`**
(e.g. `../../Data/...`), so run each one with its own containing folder as MATLAB's current
directory — not the `PlotScripts/` root.

### Final Figures — one canonical script (or small set) per figure, in `Final/FigN/`

As of the 2026-09-24 cleanup, every main-text figure has exactly one canonical location — see
**`Final/README.md`** for the authoritative, detailed list (dependencies, output filenames, and
for Figure 3 specifically, the composite pipeline order — it's built from two pieces plus a
compositing step, which isn't obvious from the file names alone). Summary:

- **Figure 1:** `Final/Fig1/Figure1_CRISP_Denoising.m`
- **Figure 2:** `Final/Fig2/Figure2_FeatureStatsFinal.m`
- **Figure 3:** `Final/Fig3/Figure3_Map.m` + `Figure3_WaveformsKDE.m` + `Figure3_Composite.m` (run in that order)
- **Figure 4:** `Final/Fig4/Figure4_TectonicValidation.m`
- **Figure 5:** No script — illustrator-produced, see `Revisions/tracked_revision/Figures/Revision3_Final_Figure5.png`

**To run a script:**
1. Open MATLAB.
2. Navigate your Current Folder to the script's own directory (e.g., `cd PlotScripts/Final/Fig3`).
3. Run it by name (e.g., type `Figure3_Map` in the command window).
4. The generated figure is saved to `Figures/Global_Study/`.

### `Draft/` and `Archive/`

`Draft/` holds exploratory/working scripts for figures beyond the main four above (SI figures,
in-progress work) — nothing in here is guaranteed current. `Archive/` holds scripts and files
confirmed superseded during the 2026-09-24 cleanup (moved via `git mv`, not deleted, so history
is intact) — filenames there are suffixed with why each was retired (`_STALE`, `_BROKEN`,
`_WrongContent`, `_no_cratons`, etc.).

## Figure-numbering trap

The manuscript was restructured mid-review (current Figure 3 was the old Figure 1; current
Figure 4 was the old Figure 3). Some filenames still in `Draft/` reflect the *old* numbering —
if you're ever tempted to treat a `Draft/` script named `Figure1*` as feeding current Figure 1,
check `Final/README.md`'s figure-numbering note first.

## Contributing

When modifying or adding new scripts:
- **Always use relative paths** pointing to the `Data/` directory (`../../Data/...`).
- **Never commit massive files** (>50MB). Add them to `.gitignore` and host them externally.
- **Dependencies:** If your script requires a new toolbox or library, place it in `Data/` and update this README.
- **If you promote a `Draft/` script to canonical status**, move it into `Final/FigN/` (not just
  copy it — use `git mv` so history follows), archive whatever it superseded, and update
  `Final/README.md`. The 2026-09-24 cleanup exists specifically because this wasn't done
  consistently before, and it cost real time to untangle.
