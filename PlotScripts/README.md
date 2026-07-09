# GlobalUMDTax: Plotting Scripts & Data

**Global Taxonomy Addresses the Paradox of Strength and History of Ancient Continents**

*Tolulope Olugboji¹²\**, *Jean-Joel Legre¹†*, *Steve Carr¹†*, *Zachary Sudholz³⁴*

¹ Department of Earth and Environmental Sciences, University of Rochester, USA  
² Department of Electrical and Computer Engineering, University of Rochester, USA  
³ Bullard Laboratories, Department of Earth Sciences, University of Cambridge, Cambridge, UK  
⁴ Research School of Earth Sciences, The Australian National University, Canberra ACT, Australia  
*\* Corresponding author: tolulope.olugboji@rochester.edu*  
*† These authors contributed equally to this work.*

**Keywords:** Continents | Mantle Discontinuity | Metasomatism | Craton Stability

---

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
The primary scripts for the manuscript figures are:

- **Figure 1:** Age-Craton Map and Scatter Plots
  - `Draft/Fig1/Figure1_Amap_revised.m`
  - `Draft/Fig1/Figure1_Rev2.m`
- **Figure 2:** Mantle Physical Properties and Statistics
  - `Draft/Fig2/Figure2b_Maps_Stats.m`: Generates 4x1 map panels with inset boxplots.
  - `Draft/Fig2/Figure2c_MapsLocs.m`: Generates 4x2 map panels overlaying cluster locations.
- **Figure 3:** Continent-Scale Comparisons
  - `Draft/Fig3/Revision1_Figure3_Continent_CAM22.m`

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
