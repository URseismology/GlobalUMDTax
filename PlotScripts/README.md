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
├── Draft/                # Exploratory and working scripts
├── Final/                # Refined figures
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

All scripts are written in **MATLAB (R2022b or newer recommended)** and rely on the local `Data/` folder. They use relative paths, so they must be executed from the directory they reside in (e.g., `Draft/Fig2/`).

### Final Figures
The primary scripts for the manuscript figures are located in the `Final/` directory:

- **Figure 1:** Tectonic Context and Data Overview
  - `Final/Figure1_Rev2.m`
  - `Final/Figure1B_Scatter_Waveforms.m`
- **Figure 2:** Feature Statistics and Lithospheric Distributions
  - `Final/Figure2_FeatureStatsFinal.m`
  - `Final/Revision1_Summary_Scatter_LAB.m`
- **Figure 3:** Tectonic Regionalization and Residual Statistics
  - `Final/Figure3_ClustersTectonics.m` (Original script with the full geological categorization)
  - `Draft/Fig3/Figure3_ClustersTectonics_Reduced.m` (Revised script: reduces categories to 4 by merging Oceanic into Craton Margins and Old Oceanic into Young Continents, with an optimized layout featuring a colorized horizontal symbol legend nested below the maps)
  - `Draft/Fig3/Figure3_ClustersTectonicsCratons_Reduced.m` (Final polished script: incorporates the Bedle Craton boundaries from KML files, plotting them as bold green outlines above the scatter symbols and inside the global inset map).
- **Supplemental Figures:**
  - `Final/FigSup1_SeisVsThermal_Full.m`

**To run a script:**
1. Open MATLAB.
2. Navigate your Current Folder to the script's directory (e.g., `cd PlotScripts/Draft/Fig2`).
3. Run the script (e.g., type `Figure2c_MapsLocs` in the command window).
4. The generated figures will be saved to the `Figures/` directory.

## Contributing

When modifying or adding new scripts:
- **Always use relative paths** pointing to the `Data/` directory (`../../Data/...`).
- **Never commit massive files** (>50MB). Add them to `.gitignore` and host them externally.
- **Dependencies:** If your script requires a new toolbox or library, place it in `Data/` and update this README.
