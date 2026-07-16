# Finalized Plotting Scripts

This directory contains the final, polished MATLAB scripts used to generate the figures for the manuscript. 

As scripts are completed, reviewed, and finalized, they should be moved into this folder.

## Current Scripts

* **`Figure1_Rev2.m`**
  * **Purpose**: Generates the main Figure 1 map, showing global cratons and plate boundaries over detailed coastlines.
  * **Key Features**: Overlays complex geographic shapefiles with customized colors and thicknesses.
  * **Output**: `Figures/Global_Study/Figure1_Rev2.png`

* **`Figure1B_Scatter_Waveforms.m`**
  * **Purpose**: Generates scatter plots and waveform comparisons for Figure 1.
  * **Output**: `Figures/Global_Study/Figure1B_Scatter_Waveforms.png`

* **`Figure2_FeatureStatsFinal.m`**
  * **Purpose**: Generates the comprehensive Feature Statistics matrix, combining a 1:1 t-SNE embedding plot, clustered model boxcharts, and dense 2D Joint KDE distributions.
  * **Key Features**: Employs an absolute layout geometry (1400x1100 px) to tightly pack axes. Features 2D Gaussian Kernel Density estimates dynamically shading the t-SNE scatter points and uses empirical 2-sigma GMM covariance boundary ellipses to delimit cluster cores.
  * **Output**: `Figures/Global_Study/Figure2_FeatureStatsFinal.png`

* **`Figure3_ClustersTectonics.m`**
  * **Purpose**: Generates continent-scale maps overlaying clustering results with tectonic regionalization, alongside residual statistics for each tectonic cluster.
  * **Key Features**: Dynamic horizontal panel layout, custom 2x2 box/bar plots, geometrically anchored global inset maps, and detailed subduction-zone boundary markers.
  * **Output**: `Figures/Global_Study/Figure3_ClustersTectonics_Draft.png`

* **`Figure3_ClustersTectonics_Reduced.m`** *(Located in `../Draft/Fig3/`)*
  * **Purpose**: Generates continent-scale maps overlaying clustering results with a simplified 4-category tectonic regionalization, merging Oceanic into Craton Margins, and Old Oceanic into Young Continents.
  * **Key Features**: Completely optimized layout that places statistics side-by-side with a shared, fixed Y-axis. Features geographically-anchored panel labels, and an elegant horizontally-stacked, colorized symbol legend perfectly aligned beneath the map.
  * **Output**: `Figures/Global_Study/Figure3_ClustersTectonics_Reduced.png`

* **`Figure3_ClustersTectonicsCratons_Reduced.m`** *(Located in `../Draft/Fig3/`)*
  * **Purpose**: Identical to `Figure3_ClustersTectonics_Reduced.m`, but specifically overlays custom Bedle (2021) Craton Boundaries dynamically parsed from individual KML files.
  * **Key Features**: Dynamically loads KML polygons and renders them as bold green outlines overlaid precisely on top of the tectonic map, data symbols, and the global inset map.
  * **Output**: `Figures/Global_Study/Figure3_ClustersTectonicsCratons_Reduced.png`

* **`Revision1_Summary_Scatter_LAB.m`**
  * **Purpose**: Generates the massive 2x2 grid of custom Joint-Distribution KDE scatter plots.
  * **Key Features**: Colors individual scatter points based on their 2D Kernel Density Estimate, ensuring high-probability cores are visible. Displays marginal 1D distributions on the top and right axes to explicitly correlate the point cloud with the Thermal LAB. 
  * **Output**: `Figures/Global_Study/Revision1_Summary_Scatter_LAB.png`

* **`FigSup1_SeisVsThermal_Full.m`**
  * **Purpose**: Generates the supplemental tectonic breakdowns and GMM mode statistics for the LAB depth residuals.
  * **Key Features**: Fits optimal Gaussian Mixture Models to depth residuals (Seismic - Thermal) to automatically identify probability modes. Groups clusters by tectonic type and compares CAM-22 and WINTERC-G side-by-side using grouped boxcharts.
  * **Outputs**: `Figures/Global_Study/FigSup1_GMM_Distributions.png` and `Figures/Global_Study/FigSup1_Tectonic_BoxPlots.png`

> **Note on Execution**: These scripts use relative paths (e.g., `./Data/` and `./Figures/`). To run them successfully, ensure your MATLAB current working directory is set to the main `PlotScripts` parent folder, or adjust the paths accordingly if running directly from within this `Final` folder.
