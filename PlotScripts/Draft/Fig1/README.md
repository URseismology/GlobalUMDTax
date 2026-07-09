# Figure 1 Draft Scripts Directory

This directory contains the prototype, production, and legacy scripts targeted for the development of **Figure 1** (Global/Regional Discontinuity and Age-Craton Taxonomy Maps).

---

## Script Index

### 1. `Figure1_Amap_revised.m`
*   **Purpose**: Renders the revised 2-panel global Age-Craton map.
*   **Description**: Discretizes Artemieva's global crustal age grid into three zones (Phanerozoic, Proterozoic, Archean). 
    *   **Panel A**: Overlays C1 (Melt: red circle), C2 (Rheological: blue circle+dot), and C3 (Metasomatic: green circle+cross) stations with transparent marker faces.
    *   **Panel B**: Overlays C4 (Deep Structural: black circle+star) stations.
*   **Inputs**:
    *   `Data/MachineLearningData/IrinaThermal/global-ages-0705-1x1.nc` (Artemieva Global Crustal Age grid)
    *   `Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv` (Station cluster classifications and negative depth values)
    *   `Data/MachineLearningData/rf_global_clustering/data/Data_Global_R1Meta.csv` (Station geographical metadata/coordinates)
    *   `Data/global_tectonics/plates&provinces/shp/plate_boundaries.shp` (Plate boundary shapefile)
*   **Outputs**:
    *   `Figures/Global_Study/Figure1_Amap_revised_v1.png` (Standard version plotting all stations)
    *   `Figures/Global_Study/Figure1_Amap_revised_v2.png` (Thinned version merging stations within 1° to their centroid)

### 2. `Figure1_Amap_revised_NA.m`
*   **Purpose**: Renders a zoomed-in, regional version of the 2-panel Age-Craton map for the United States lower-48 states.
*   **Description**: Focuses the coordinates and projection bounds on the US Lower 48 (Lat: 24–50°N, Lon: 125–70°W). 
*   **Inputs**:
    *   Same inputs as `Figure1_Amap_revised.m`
*   **Outputs**:
    *   `Figures/Global_Study/Figure1_Amap_revised_NA_v1.png` (All NA stations)
    *   `Figures/Global_Study/Figure1_Amap_revised_NA_v2.png` (Decluttered NA stations thinned within 1°)

### 3. `Revision1_Summary_Scatter_LAB.m`
*   **Purpose**: Compares seismic discontinuity depths from receiver functions against thermal and shear-velocity LAB depth profiles.
*   **Description**: Plots statistical correlations, density histograms, and linear fits for stations to analyze lithospheric decoupling boundaries.
*   **Inputs**:
    *   `Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv`
*   **Outputs**:
    *   `Figures/Global_Study/Revision1_Summary_Scatter_LAB.png`

### 4. `Figure1_Rev2.m`
*   **Purpose**: Production figure script under development.
*   **Description**: Aims to construct a 3-panel regional subplot layout (Americas, Europe/Africa, Asia/Australia) zoom to minimize distortion and make sparse stations visible.
*   **Inputs**:
    *   `Data/Velocity_Models/CAM2022-lithosphere.r0.0.nc` (CAM22 LAB model grid)
    *   `Data/global_tectonics/plates&provinces/shp/plate_boundaries.shp`
    *   `Data/GlobalVs_Models/votemap_100_km.mat` (Craton boundaries)
    *   `Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv`
*   **Outputs**:
    *   TBD (under development)

### 5. `Revision1_Figure1.m`
*   **Purpose**: Legacy Figure 1 script.
*   **Description**: Represents the original figure script displaying regional subplots mapping CAM22 LAB depths and station locations.
*   **Inputs**:
    *   `Data/Velocity_Models/CAM2022-lithosphere.r0.0.nc`
    *   `Data/global_tectonics/plates&provinces/shp/plate_boundaries.shp`
*   **Outputs**:
    *   Legacy figure files

### 6. `Figure1B_Scatter_Waveforms.m`
*   **Purpose**: Renders the complete, multi-component waveforms and scatter comparison layout for Figure 1B.
*   **Description**: Combines the 4 GMM-cluster stacked receiver function waveform panels and the 2D Joint KDE scatter comparison plots (vs. CAM-22 LAB) in a compact 2-row layout (Top Row: C2/C3; Bottom Row: C1/C4).
*   **Inputs**:
    *   `Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv`
    *   `Data/MachineLearningData/rf_global_clustering/data/Data_Global_R1Meta.csv`
    *   `Data/Velocity_Models/CAM2022-lithosphere.r0.0.nc`
    *   `Data/MachineLearningData/RFs/sequenced_cluster0.mat` to `3.mat` (Sorted cluster waveforms)
*   **Outputs**:
    *   `Figures/Global_Study/Figure1B_Scatter_Waveforms.png` (Tall 2:1 composite figure)

