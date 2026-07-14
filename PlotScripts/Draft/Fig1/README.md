# Figure 1 Draft Scripts Directory

This directory contains the prototype, production, and legacy scripts targeted for the development of **Figure 1** (Global/Regional Discontinuity and Age-Craton Taxonomy Maps).

---

## Script Index

### 1. `Figure1a_MapLocs.m` (Final Master Script)
*   **Purpose**: Renders the finalized, polished global map and US-focused regional zoom map of thermal fields and station clusters.
*   **Description**: Plots the 100km CAM22 absolute temperature field with a custom thermal LAB transition colormap, transparent map faces, and properly sized cluster symbols (C1-C3). Outputs two figures: a global overview with an inset (Pacific centered), and a zoomed-in detail map of the US lower-48 with explicit point bounding.
*   **Inputs**:
    *   `Data/Velocity_Models/CAM2022-vs-tmp.r0.0.nc` (CAM22 Temperature)
    *   `Data/GlobalVs_Models/votemap_100_km.mat` (Tomography Voting Map)
    *   `Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv`
    *   `Data/global_tectonics/plates&provinces/shp/plate_boundaries.shp`
*   **Outputs**:
    *   `Figures/Global_Study/Figure1a_MapLocs.png` (Global view)
    *   `Figures/Global_Study/Figure1a_US_MapLocs.png` (US Zoom view)

### 2. `Figure1_Amap_revised.m`
*   **Purpose**: Renders the revised 2-panel global Age-Craton map.
*   **Description**: Discretizes Artemieva's global crustal age grid into three zones (Phanerozoic, Proterozoic, Archean). 
    *   **Panel A**: Overlays C1 (Melt: red circle), C2 (Rheological: blue circle+dot), and C3 (Metasomatic: green circle+cross) stations with transparent marker faces.
    *   **Panel B**: Overlays C4 (Deep Structural: black circle+star) stations.
*   **Inputs**:
    *   `Data/MachineLearningData/IrinaThermal/global-ages-0705-1x1.nc`
    *   `Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv`
    *   `Data/MachineLearningData/rf_global_clustering/data/Data_Global_R1Meta.csv`
    *   `Data/global_tectonics/plates&provinces/shp/plate_boundaries.shp`
*   **Outputs**:
    *   `Figures/Global_Study/Figure1_Amap_revised_v1.png` and `v2.png`

### 3. `Figure1_Amap_revised_NA.m`
*   **Purpose**: Renders a zoomed-in, regional version of the 2-panel Age-Craton map for the United States lower-48 states.

### 4. `Figure1B_Scatter_Waveforms.m`
*   **Purpose**: Renders the complete, multi-component waveforms and scatter comparison layout for Figure 1B.
*   **Outputs**:
    *   `Figures/Global_Study/Figure1B_Scatter_Waveforms.png`

---

## Supporting Maps (`Supporting/` Directory)

The `Supporting/` directory contains a collection of scripts moved from previous draft phases (`Fig2`). These scripts generate supplementary global maps and statistical comparisons that complement the main Figure 1 outputs.

### `FigureS1a_Maps.m`
*   **Purpose**: Plots CAM22 Temperature, DBRD-NATURE2020 Melt Content, and Tomography Consensus side-by-side.
*   **Output**: `Figures/Global_Study/FigureS1a_Maps.png`

### `FigureS1b_Maps_Stats.m`
*   **Purpose**: Combines global maps (Temperature, Melt, Votemap) with multi-model empirical cumulative distribution function (eCDF) statistical plots.
*   **Output**: `Figures/Global_Study/FigureS1b_Maps_Stats.png`

### `FigureS1c_MapsLocs.m`
*   **Purpose**: Combines global maps with explicitly overlaid cluster station locations (C1-C4) and correlation scatter plots. Generated automatically via `generate_figS1c.py`.
*   **Output**: `Figures/Global_Study/FigureS1c_MapsLocs.png`

### `FigureS1c_StatsOnly.m`
*   **Purpose**: Generates solely the statistical correlation scatter plots without the heavy map renders.
*   **Output**: `Figures/Global_Study/FigureS1c_StatsOnly.png`
