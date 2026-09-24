# Figure 1 Draft Scripts Directory — historical name, contents have moved

**2026-09-24 update:** the scripts this README used to describe (`Figure1a_MapLocs.m`,
`Figure1_Amap_revised.m`/`_NA.m`, `Figure1B_Scatter_Waveforms.m`) were either archived as
superseded or promoted to their canonical home. See `PlotScripts/Final/README.md` for where the
actual current Figure 1 and Figure 3 scripts live now (this folder's name is a leftover from the
pre-reorder figure numbering — nothing canonical for the *current* Figure 1 is in here).

## What's actually still in this folder

Not re-verified as part of the 2026-09-24 cleanup — treat descriptions below as best-effort,
not confirmed accurate:

- `Figure1_Amap_revised.m`, `Figure1_Amap_revised_NA.m` — exploratory Age-Craton map variants
  (global and US-zoom). Not the canonical Figure 3 map (that's `Final/Fig3/Figure3_Map.m`).
- `Figure4_SlabProximityAnalysis.m`, `Figure5A_PaleoCoastlines.m`, `Figure5B_ModernCoastlines.m` —
  appear related to Supporting Information content (Mesozoic subduction correlation, moved to SI
  per the manuscript's restructuring). Not touched by today's main-figure cleanup.
- `Revision1_Figure1.m`, `Revision1_Summary_Scatter_LAB.m`, `PlotCratonsTestPub.m` — older
  exploratory scripts. Note there's *also* a same-named `Revision1_Summary_Scatter_LAB.m` in
  `Final/` — that duplicate-naming problem hasn't been investigated or resolved (out of scope
  for the four-figure cleanup); don't assume either copy is authoritative without checking.
- `Supporting/` — `FigureS1a/b/c_*.m` scripts, apparently SI map/statistics variants.
- `build_fig1.py`, `fix_layout.py`, `generate_combined_fig.py`, `plot_geojson_coords.m`,
  `test_geojson.m` — utility/exploration scripts, purpose not re-verified.

If you need to work with any of these, verify what they actually produce against the current
manuscript/SI before trusting old descriptions (including this one) — that's the lesson of the
2026-09-24 cleanup.
