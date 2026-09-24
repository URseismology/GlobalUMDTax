# Craton Digitizer — Tutorial

## Setup

```bash
pip install -r requirements.txt
```

Place the template map image (PNG, JPG, or TIFF) in the `template/` folder.

---

## Digitizing cratons

### 1. Launch the tool

```bash
python digitizer.py
```

### 2. Load a template

- Select your image from the **Template** dropdown.
- Select the projection (**Robinson** or **Mollweide**) — match whatever the paper uses.
- Click **Load**.

The tool will auto-detect the map oval using edge detection and place the coastline overlay on top. The four coloured dots show the detected oval tips.

### 3. Position the overlay

The overlay starts **unlocked** — you can move it freely.

| Action | Effect |
|---|---|
| Left-click drag (body) | Translate overlay |
| Left-click drag (square handles) | Stretch overlay |
| Scroll wheel | Scale overlay |
| WASD | Pan the view |
| Scroll wheel (zoomed in) | Zoom view |
| **Reset View** button | Fit full image |
| **Re-detect** button | Re-run auto-detection |
| **Manual Calibrate** button | Click 4 known points manually |

Move the overlay until the coastlines line up with the map.

### 4. Lock and digitize

Press **middle mouse button** to lock the overlay in place.

The status bar shows **LOCKED**. Now:

| Action | Effect |
|---|---|
| Left-click | Add a point |
| Right-click | Undo last point |
| Middle mouse | Unlock overlay to reposition |

Click points around one craton outline. You can **unlock → reposition → lock** as many times as you need — points accumulate across all lock/unlock cycles.

When the polygon is complete, click **End Digitization** (or click near the first orange point to snap-close). Enter a name when prompted.
