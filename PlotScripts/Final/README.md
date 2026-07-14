# Finalized Plotting Scripts

This directory contains the final, polished MATLAB scripts used to generate the figures for the manuscript. 

As scripts are completed, reviewed, and finalized, they should be moved into this folder.

## Current Scripts

* **`Revision1_Summary_Scatter_LAB.m`**
  * **Purpose**: Generates the massive 2x2 grid of custom Joint-Distribution KDE scatter plots.
  * **Key Features**: Colors individual scatter points based on their 2D Kernel Density Estimate, ensuring high-probability cores are visible. Displays marginal 1D distributions on the top and right axes to explicitly correlate the point cloud with the Thermal LAB. 
  * **Output**: `Figures/Global_Study/Revision1_Summary_Scatter_LAB.png`

* **`FigSup1_SeisVsThermal_Full.m`**
  * **Purpose**: Generates the supplemental tectonic breakdowns and GMM mode statistics for the LAB depth residuals.
  * **Key Features**: Fits optimal Gaussian Mixture Models to depth residuals (Seismic - Thermal) to automatically identify probability modes. Groups clusters by tectonic type and compares CAM-22 and WINTERC-G side-by-side using grouped boxcharts.
  * **Outputs**: `Figures/Global_Study/FigSup1_GMM_Distributions.png` and `Figures/Global_Study/FigSup1_Tectonic_BoxPlots.png`

* **`Figure2_FeatureStatsFinal.m`**
  * **Purpose**: Generates the comprehensive Feature Statistics matrix, combining a 1:1 t-SNE embedding plot, clustered model boxcharts, and dense 2D Joint KDE distributions.
  * **Key Features**: Employs an absolute layout geometry (1400x1100 px) to tightly pack axes. Features 2D Gaussian Kernel Density estimates dynamically shading the t-SNE scatter points and uses empirical 2-sigma GMM covariance boundary ellipses to delimit cluster cores.
  * **Output**: `Figures/Global_Study/Figure2_FeatureStatsFinal.png`

> **Note on Execution**: These scripts use relative paths (e.g., `./Data/` and `./Figures/`). To run them successfully, ensure your MATLAB current working directory is set to the main `PlotScripts` parent folder, or adjust the paths accordingly if running directly from within this `Final` folder.
