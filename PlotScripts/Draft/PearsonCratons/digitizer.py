"""
Digitizer 
--------------------
Phase 1 — Align :
    detect_oval() uses OpenCV Canny edges + morphological closing + contour
    scoring to find the map oval.  Scoring ranks candidates by aspect-ratio
    match to the chosen projection and proximity to the image centre, so it
    works with or without graticule lines, color bars, or legends.
    The 4 mask extremities feed _calibrate() to set (cx, cy, sx, sy).
    Falls back to centred default placement if detection fails.
    • Coloured markers show the 4 extremity points.
    • 8 stretch handles + drag for manual fine-tuning.
    • Manual 4-click calibration as last-resort fallback.
Phase 2 — Digitize:
    • Left-click  → add point
    • Right-click → undo last point
    • Click near first point (orange) or End Digitization → close polygon
"""

import glob
import json
import os
import threading
from pathlib import Path

import numpy as np
import tkinter as tk
from tkinter import simpledialog, messagebox, ttk
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2Tk
from matplotlib.figure import Figure
from matplotlib.patches import Polygon as MplPolygon
import matplotlib.image as mpimg
import cartopy.crs as ccrs
import cartopy.io.shapereader as shpreader
from shapely.geometry import LineString, MultiLineString

_PC = ccrs.PlateCarree()

PROJ_OPTIONS: dict = {'Robinson': ccrs.Robinson(), 'Mollweide': ccrs.Mollweide()}
try:
    PROJ_OPTIONS['EqualEarth'] = ccrs.EqualEarth()
except AttributeError:
    pass

HANDLE_R_PX = 10   # screen-pixel radius for handle hit detection
CLOSE_R_PX  = 14   # screen-pixel radius for polygon snap-close


# ── Projection helpers ────────────────────────────────────────────────────────

def _to_proj(proj, lons, lats):
    pts = proj.transform_points(_PC, np.asarray(lons, float), np.asarray(lats, float))
    return pts[:, 0], pts[:, 1]

def _from_proj(proj, rx, ry):
    pts = _PC.transform_points(proj, np.array([float(rx)]), np.array([float(ry)]))
    return None if np.isnan(pts[0, 0]) else (float(pts[0, 0]), float(pts[0, 1]))

def _extents(proj):
    """Return (x_half, y_half) in projection metres for the full globe."""
    rx, _ = _to_proj(proj, [-180., 180.], [0., 0.])
    _, ry = _to_proj(proj, [0., 0.], [-90., 90.])
    return float(abs(rx[0])), float(abs(ry[1]))

def _oval_lonlat(n=300):
    lons = np.concatenate([np.linspace(-180, 180, n), np.full(n, 180.),
                           np.linspace(180, -180, n), np.full(n, -180.), [-180.]])
    lats = np.concatenate([np.full(n, -90.), np.linspace(-90, 90, n),
                           np.full(n, 90.), np.linspace(90, -90, n), [-90.]])
    return lons, lats

def _load_coast():
    shp = shpreader.natural_earth('110m', 'physical', 'coastline')
    segs = []
    for geom in shpreader.Reader(shp).geometries():
        parts = list(geom.geoms) if isinstance(geom, MultiLineString) else [geom]
        for p in parts:
            if isinstance(p, LineString):
                c = np.array(p.coords)
                segs.append((c[:, 0], c[:, 1]))
    return segs


# ── Auto-detect ───────────────────────────────────────────────────────────────

def detect_oval(img: np.ndarray, proj):
    """
    Find the 4 extremities of the map oval by scanning inward from each edge.

    Works with or without graticule lines.  Each tip is found independently:
      left  tip — scan columns left→right, restricted to middle 50 % of height
      right tip — scan columns right→left, same band
      top   tip — scan rows top→bottom,   restricted to middle 50 % of width
      bot   tip — scan rows bottom→top,   same band
    The centre-band restriction ignores colour bars, legends, axis labels, etc.
    A final aspect-ratio sanity check rejects wildly wrong results.

    Returns (px_l, py_l, px_r, py_r, px_t, py_t, px_b, py_b) or None.
    """
    import cv2

    if img.dtype != np.uint8:
        u8 = (np.clip(img, 0.0, 1.0) * 255).astype(np.uint8)
    else:
        u8 = img.copy()
    gray = cv2.cvtColor(u8, cv2.COLOR_RGB2GRAY) if u8.ndim == 3 else u8
    h, w = gray.shape

    otsu_val, _ = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    edges = cv2.Canny(gray, otsu_val * 0.5, otsu_val)

    # Centre bands — oval tips always fall here, non-map decorations don't
    vy0, vy1 = int(h * 0.25), int(h * 0.75)   # vertical band for left/right tips
    hx0, hx1 = int(w * 0.25), int(w * 0.75)   # horizontal band for top/bot tips

    def first_col(col_range):
        for col in col_range:
            rows = np.where(edges[vy0:vy1, col])[0]
            if len(rows):
                return float(col), float(rows.mean() + vy0)
        return None

    def first_row(row_range):
        for row in row_range:
            cols = np.where(edges[row, hx0:hx1])[0]
            if len(cols):
                return float(cols.mean() + hx0), float(row)
        return None

    left   = first_col(range(w // 2))
    right  = first_col(range(w - 1, w // 2, -1))
    top    = first_row(range(h // 2))
    bottom = first_row(range(h - 1, h // 2, -1))

    if not all([left, right, top, bottom]):
        return None

    # Sanity check: aspect ratio must be within 35 % of projection expectation
    xh, yh = _extents(proj)
    width_px, height_px = right[0] - left[0], bottom[1] - top[1]
    if height_px < 1 or abs(width_px / height_px / (xh / yh) - 1.0) > 0.35:
        return None

    return (left[0], left[1], right[0], right[1],
            top[0],  top[1],  bottom[0], bottom[1])


def _calibrate(px_l, py_l, px_r, py_r, px_t, py_t, px_b, py_b, proj):
    xh, yh = _extents(proj)
    cx = (px_l + px_r) / 2.0
    sx = (px_r - px_l) / (2.0 * xh)
    cy = (py_t + py_b) / 2.0
    sy = (py_b - py_t) / (2.0 * yh)
    return cx, cy, sx, sy


# ── KML writer ────────────────────────────────────────────────────────────────

def save_kml(name: str, lonlats: list) -> str:
    Path('digitization').mkdir(exist_ok=True)
    coords = ' '.join(f'{lo},{la},0' for lo, la in lonlats)
    xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<kml xmlns="http://www.opengis.net/kml/2.2">\n'
        '<Document>\n'
        f'\t<name>{name}.kml</name>\n'
        '\t<Placemark>\n'
        f'\t\t<name>{name}</name>\n'
        '\t\t<LineString>\n'
        '\t\t\t<tessellate>1</tessellate>\n'
        '\t\t\t<coordinates>\n'
        f'\t\t\t\t{coords}\n'
        '\t\t\t</coordinates>\n'
        '\t\t</LineString>\n'
        '\t</Placemark>\n'
        '</Document>\n'
        '</kml>\n'
    )
    path = f'digitization/{name}.kml'
    Path(path).write_text(xml, encoding='utf-8')
    return path


# ── App ───────────────────────────────────────────────────────────────────────

_CALIB_TARGETS = [
    ('Left tip',    '#e74c3c', 'lon=−180, lat=0'),
    ('Right tip',   '#2ecc71', 'lon=+180, lat=0'),
    ('Top centre',  '#f39c12', 'lon=0, lat=+90'),
    ('Bot centre',  '#3498db', 'lon=0, lat=−90'),
]


class DigitizerApp:

    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title('Craton Digitizer')
        self.root.geometry('1280x840')

        self.phase     = 'select'
        self.img_path  = None
        self.img_w     = 1
        self.img_h     = 1
        self._proj_name = 'Robinson'
        self._img_raw: np.ndarray | None = None

        # Affine transform  (img_x = rx*sx + cx,  img_y = -ry*sy + cy)
        self.ref_cx = 0.0
        self.ref_cy = 0.0
        self.ref_sx = 1.0
        self.ref_sy = 1.0

        # Coastline lon/lat data — loaded once
        self._coast_ll: list = []

        # Matplotlib overlay artists
        self._coast_art: list = []
        self._coast_rx:  list = []
        self._coast_ry:  list = []
        self._oval_art       = None
        self._oval_rx        = None
        self._oval_ry        = None
        self._handle_sc      = None
        self._det_markers:  list = []

        # Manual calibration
        self._man_clicks: list = []
        self._man_arts:   list = []

        # Overlay lock (middle-mouse toggles)
        self._locked: bool = False

        # Coastline async load guard
        self._coast_loading: bool = False

        # Drag (overlay move, only when unlocked)
        self._drag_mode   = None
        self._drag_m0     = (0., 0.)
        self._drag_cx0    = 0.
        self._drag_cy0    = 0.
        self._drag_sx0    = 1.
        self._drag_sy0    = 1.
        self._drag_fixed  = (0., 0.)

        # Digitise — points persist across lock/unlock cycles
        self.poly_px:  list = []
        self.poly_ll:  list = []
        self._preview: list = []

        self._build_ui()
        self._refresh_templates()

    # ── UI ────────────────────────────────────────────────────────────────────

    def _build_ui(self):
        top = tk.Frame(self.root, pady=5, padx=8)
        top.pack(side=tk.TOP, fill=tk.X)

        tk.Label(top, text='Template:').pack(side=tk.LEFT)
        self.tpl_var = tk.StringVar()
        self.tpl_cb  = ttk.Combobox(top, textvariable=self.tpl_var,
                                    width=28, state='readonly')
        self.tpl_cb.pack(side=tk.LEFT, padx=(3, 10))

        tk.Label(top, text='Projection:').pack(side=tk.LEFT)
        self.proj_var = tk.StringVar(value='Robinson')
        pcb = ttk.Combobox(top, textvariable=self.proj_var,
                           values=list(PROJ_OPTIONS), width=12, state='readonly')
        pcb.pack(side=tk.LEFT, padx=(3, 10))
        pcb.bind('<<ComboboxSelected>>', self._on_proj_change)

        tk.Button(top, text='Load', command=self._load).pack(side=tk.LEFT)

        # Right-side buttons (always shown once image is loaded)
        self.end_btn    = tk.Button(top, text='End Digitization',
                                    command=self._finish_polygon,
                                    bg='#c0392b', fg='white',
                                    font=('Arial', 10, 'bold'))
        self.manual_btn = tk.Button(top, text='Manual Calibrate',
                                    command=self._enter_manual,
                                    bg='#2980b9', fg='white')
        self.redet_btn  = tk.Button(top, text='Re-detect',
                                    command=self._run_detect,
                                    bg='#8e44ad', fg='white')
        self.view_btn   = tk.Button(top, text='Reset View',
                                    command=self._reset_view,
                                    bg='#555', fg='white')

        cf = tk.Frame(self.root)
        cf.pack(fill=tk.BOTH, expand=True)
        self.fig = Figure(facecolor='#1e1e1e')
        self.ax  = self.fig.add_subplot(111)
        self.ax.set_axis_off()
        self.fig.tight_layout(pad=0)
        self.canvas = FigureCanvasTkAgg(self.fig, master=cf)
        self.canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

        tf = tk.Frame(self.root)
        tf.pack(fill=tk.X)
        self.toolbar = NavigationToolbar2Tk(self.canvas, tf)
        self.toolbar.update()

        self.status_var = tk.StringVar(value='Select a template image and click Load.')
        tk.Label(self.root, textvariable=self.status_var, anchor='w',
                 relief=tk.SUNKEN, padx=6,
                 font=('Arial', 9)).pack(side=tk.BOTTOM, fill=tk.X)

        self.canvas.mpl_connect('button_press_event',   self._on_press)
        self.canvas.mpl_connect('motion_notify_event',  self._on_motion)
        self.canvas.mpl_connect('button_release_event', self._on_release)
        self.canvas.mpl_connect('scroll_event',         self._on_scroll)
        self.root.bind('<Key>', self._on_key)

    def _refresh_templates(self):
        exts = {'.png', '.jpg', '.jpeg', '.tif', '.tiff', '.bmp'}
        Path('template').mkdir(exist_ok=True)
        names = [os.path.basename(f) for f in sorted(glob.glob('template/*'))
                 if Path(f).suffix.lower() in exts]
        self.tpl_cb['values'] = names
        if names:
            self.tpl_cb.current(0)

    # ── Load ──────────────────────────────────────────────────────────────────

    def _load(self):
        name = self.tpl_var.get()
        if not name:
            messagebox.showwarning('No template', 'Select a template image first.')
            return
        path = f'template/{name}'
        if not os.path.exists(path):
            messagebox.showerror('Missing', f'File not found: {path}')
            return

        self.img_path   = path
        raw             = mpimg.imread(path)
        self._img_raw   = raw.astype(np.float32) / 255.0 if raw.dtype == np.uint8 else raw.astype(np.float32)
        self.img_h, self.img_w = self._img_raw.shape[:2]
        self._proj_name = self.proj_var.get()

        self.ax.clear()
        self.ax.set_axis_off()
        self.ax.imshow(self._img_raw, origin='upper',
                       extent=[0, self.img_w, self.img_h, 0],
                       zorder=0, aspect='auto')
        self.ax.set_xlim(0, self.img_w)
        self.ax.set_ylim(self.img_h, 0)
        self.fig.tight_layout(pad=0)
        self.canvas.draw()

        self._coast_art = []; self._coast_rx = []; self._coast_ry = []
        self._oval_art  = None; self._oval_rx = None; self._oval_ry = None
        self._handle_sc = None; self._det_markers = []

        for b in (self.end_btn, self.manual_btn, self.redet_btn):
            b.pack_forget()

        cal = self._calib_path()
        loaded = False
        if cal.exists():
            try:
                d = json.loads(cal.read_text())
                self.ref_cx = d['ref_cx']; self.ref_cy = d['ref_cy']
                self.ref_sx = d['ref_sx']; self.ref_sy = d['ref_sy']
                self._proj_name = d.get('proj_name', 'Robinson')
                self.proj_var.set(self._proj_name)
                self._rebuild_overlay()   # oval only (coasts load async below)
                self._enter_edit()
                loaded = True
            except (KeyError, ValueError, json.JSONDecodeError):
                cal.unlink(missing_ok=True)
        if not loaded:
            self._run_detect()
        self._ensure_coast()   # fire-and-forget; updates overlay when ready

    def _calib_path(self) -> Path:
        return Path(self.img_path).with_name(Path(self.img_path).stem + '_calib.json')

    def _on_proj_change(self, _=None):
        new = self.proj_var.get()
        if new == self._proj_name or not self.img_path:
            return
        self._proj_name = new
        if self.phase in ('edit', 'manual_calib'):
            self._run_detect()

    # ── Auto-detect ───────────────────────────────────────────────────────────

    def _run_detect(self):
        proj = PROJ_OPTIONS[self._proj_name]
        self._status('Detecting map oval…')
        self.root.update()

        result = detect_oval(self._img_raw, proj)

        if result is None:
            self._status('Detection failed — using default placement. '
                         'Use Manual Calibrate to set 4 oval tips.')
            xh, _ = _extents(proj)
            s = self.img_w / (xh * 2)
            self.ref_cx = self.img_w / 2.; self.ref_cy = self.img_h / 2.
            self.ref_sx = self.ref_sy = s
            self._rebuild_overlay()
            self._enter_edit()
            return

        px_l, py_l, px_r, py_r, px_t, py_t, px_b, py_b = result
        self.ref_cx, self.ref_cy, self.ref_sx, self.ref_sy = _calibrate(
            px_l, py_l, px_r, py_r, px_t, py_t, px_b, py_b, proj)
        self._rebuild_overlay()

        for m in self._det_markers:
            try: m.remove()
            except Exception: pass
        self._det_markers = []
        colours = ['#e74c3c', '#2ecc71', '#f39c12', '#3498db']
        for (px, py), col in zip(
                [(px_l,py_l),(px_r,py_r),(px_t,py_t),(px_b,py_b)], colours):
            dot, = self.ax.plot(px, py, 'o', color=col, ms=12,
                                markeredgecolor='white', markeredgewidth=1.5,
                                zorder=12)
            self._det_markers.append(dot)
        self.canvas.draw_idle()
        self._enter_edit()

    # ── Manual calibration ────────────────────────────────────────────────────

    def _enter_manual(self):
        self.phase = 'manual_calib'
        self._man_clicks = []
        for a in self._man_arts:
            try: a.remove()
            except Exception: pass
        self._man_arts = []
        self.canvas.draw_idle()
        self._status(f'Manual 1/4 — click {_CALIB_TARGETS[0][2]}')

    def _handle_manual_click(self, px, py):
        n = len(self._man_clicks)
        if n >= 4:
            return
        self._man_clicks.append((px, py))
        lbl, col, desc = _CALIB_TARGETS[n]
        dot, = self.ax.plot(px, py, 'o', color=col, ms=12,
                            markeredgecolor='white', markeredgewidth=1.5, zorder=12)
        self._man_arts.append(dot)
        self.canvas.draw_idle()

        if len(self._man_clicks) == 4:
            (x0,y0),(x1,y1),(x2,y2),(x3,y3) = self._man_clicks
            proj = PROJ_OPTIONS[self._proj_name]
            self.ref_cx, self.ref_cy, self.ref_sx, self.ref_sy = _calibrate(
                x0,y0, x1,y1, x2,y2, x3,y3, proj)
            for a in self._man_arts:
                try: a.remove()
                except Exception: pass
            self._man_arts = []
            self._rebuild_overlay()
            self._enter_edit()
        else:
            nxt = _CALIB_TARGETS[len(self._man_clicks)]
            self._status(f'Manual {len(self._man_clicks)+1}/4 — click {nxt[2]}')

    # ── Overlay ───────────────────────────────────────────────────────────────

    def _ensure_coast(self):
        """Start async coastline load (returns immediately; overlay updates when done)."""
        if self._coast_ll or self._coast_loading:
            return
        self._coast_loading = True
        self._status('Loading coastlines in background — oval shown now…')
        def _load():
            data = _load_coast()
            self.root.after(0, lambda: self._on_coast_done(data))
        threading.Thread(target=_load, daemon=True).start()

    def _on_coast_done(self, data):
        self._coast_loading = False
        self._coast_ll = data
        if self.phase in ('edit', 'manual_calib') and self._img_raw is not None:
            self._rebuild_overlay()
            self.canvas.draw_idle()
        self._update_status()

    def _clear_overlay(self):
        for a in self._coast_art:
            try: a.remove()
            except Exception: pass
        self._coast_art = []; self._coast_rx = []; self._coast_ry = []
        if self._oval_art:
            try: self._oval_art.remove()
            except Exception: pass
            self._oval_art = None
        if self._handle_sc:
            try: self._handle_sc.remove()
            except Exception: pass
            self._handle_sc = None

    def _rebuild_overlay(self):
        self._clear_overlay()
        proj = PROJ_OPTIONS[self._proj_name]

        for lons, lats in self._coast_ll:
            rx, ry = _to_proj(proj, lons, lats)
            ok = ~(np.isnan(rx) | np.isnan(ry))
            if ok.sum() < 2:
                continue
            rx_ok, ry_ok = rx[ok], ry[ok]
            px, py = self._r2i(rx_ok, ry_ok)
            ln, = self.ax.plot(px, py, '-', color='#3daee9',
                               lw=0.6, alpha=0.85, zorder=2)
            self._coast_art.append(ln)
            self._coast_rx.append(rx_ok)
            self._coast_ry.append(ry_ok)

        o_lons, o_lats = _oval_lonlat()
        orx, ory = _to_proj(proj, o_lons, o_lats)
        ok = ~(np.isnan(orx) | np.isnan(ory))
        self._oval_rx, self._oval_ry = orx[ok], ory[ok]
        opx, opy = self._r2i(self._oval_rx, self._oval_ry)
        self._oval_art, = self.ax.plot(opx, opy, '-', color='white',
                                       lw=1.8, alpha=0.95, zorder=3)

        hx, hy = self._handles()
        self._handle_sc = self.ax.scatter(
            hx, hy, s=80, c='white', marker='s',
            edgecolors='#f39c12', linewidths=1.8, zorder=10)

    def _move_overlay(self):
        """Fast pixel-only update — no Cartopy calls."""
        for ln, rx, ry in zip(self._coast_art, self._coast_rx, self._coast_ry):
            ln.set_data(*self._r2i(rx, ry))
        if self._oval_art is not None:
            self._oval_art.set_data(*self._r2i(self._oval_rx, self._oval_ry))
        hx, hy = self._handles()
        if self._handle_sc is not None:
            self._handle_sc.set_offsets(np.c_[hx, hy])
        self.canvas.draw_idle()

    # ── Transform ─────────────────────────────────────────────────────────────

    def _r2i(self, rx, ry):
        return rx * self.ref_sx + self.ref_cx, -ry * self.ref_sy + self.ref_cy

    def _i2ll(self, px, py):
        proj = PROJ_OPTIONS[self._proj_name]
        return _from_proj(proj,
                          (px - self.ref_cx) / self.ref_sx,
                          -(py - self.ref_cy) / self.ref_sy)

    def _handles(self):
        xh, yh = _extents(PROJ_OPTIONS[self._proj_name])
        cx, cy, sx, sy = self.ref_cx, self.ref_cy, self.ref_sx, self.ref_sy
        hx = [cx-xh*sx, cx+xh*sx, cx-xh*sx, cx+xh*sx,
              cx,        cx,        cx-xh*sx, cx+xh*sx]
        hy = [cy-yh*sy, cy-yh*sy, cy+yh*sy, cy+yh*sy,
              cy-yh*sy, cy+yh*sy, cy,        cy]
        return hx, hy

    def _hit_handle(self, event):
        if event.xdata is None:
            return None
        hx, hy = self._handles()
        for i, (hdx, hdy) in enumerate(zip(hx, hy)):
            sh = self.ax.transData.transform((hdx, hdy))
            if np.hypot(event.x - sh[0], event.y - sh[1]) <= HANDLE_R_PX:
                return i
        return None

    # ── Phase helpers ──────────────────────────────────────────────────────────

    def _enter_edit(self):
        self.phase = 'edit'
        self._locked = False
        self.end_btn.pack(side=tk.RIGHT, padx=8)
        self.manual_btn.pack(side=tk.RIGHT, padx=4)
        self.redet_btn.pack(side=tk.RIGHT, padx=4)
        self.view_btn.pack(side=tk.RIGHT, padx=4)
        if self._handle_sc:
            self._handle_sc.set_visible(True)
        for m in self._det_markers:
            try: m.set_visible(True)
            except Exception: pass
        self.canvas.draw_idle()
        self._update_status()

    def _toggle_lock(self):
        self._locked = not self._locked
        # Save calib whenever we lock (so Re-detect can restore it)
        if self._locked:
            self._calib_path().write_text(
                json.dumps(dict(ref_cx=self.ref_cx, ref_cy=self.ref_cy,
                                ref_sx=self.ref_sx, ref_sy=self.ref_sy,
                                proj_name=self._proj_name), indent=2))
            if self._handle_sc:
                self._handle_sc.set_visible(False)
            for m in self._det_markers:
                try: m.set_visible(False)
                except Exception: pass
        else:
            if self._handle_sc:
                self._handle_sc.set_visible(True)
        self.canvas.draw_idle()
        self._update_status()

    def _update_status(self):
        if self.phase != 'edit':
            return
        if self._locked:
            n = len(self.poly_px)
            self._status(f'LOCKED — Left-click: add point ({n} so far).  '
                         'Right-click: undo.  Middle-mouse: unlock to reposition overlay.')
        else:
            self._status('UNLOCKED — Drag overlay to align.  Scroll: scale.  '
                         'WASD / scroll to navigate.  Middle-mouse: lock and digitize.')

    def _reset_view(self):
        if self.img_path:
            self.ax.set_xlim(0, self.img_w)
            self.ax.set_ylim(self.img_h, 0)
            self.canvas.draw_idle()

    # ── Digitise ──────────────────────────────────────────────────────────────

    def _add_point(self, px, py):
        if len(self.poly_px) >= 3:
            s0 = self.ax.transData.transform(self.poly_px[0])
            sc = self.ax.transData.transform((px, py))
            if np.hypot(sc[0]-s0[0], sc[1]-s0[1]) <= CLOSE_R_PX:
                self._finish_polygon()
                return
        ll = self._i2ll(px, py)
        if ll is None:
            self._status('Outside map extent — try again.')
            return
        self.poly_px.append((px, py))
        self.poly_ll.append(ll)
        self._draw_preview()
        self._update_status()

    def _undo_point(self):
        if not self.poly_px:
            return
        self.poly_px.pop()
        self.poly_ll.pop()
        self._draw_preview()
        self._status(f'{len(self.poly_px)} point(s). Right-click to undo more.')

    def _draw_preview(self, cursor=None):
        for a in self._preview:
            try: a.remove()
            except Exception: pass
        self._preview = []
        if not self.poly_px:
            self.canvas.draw_idle()
            return
        xs = [p[0] for p in self.poly_px]
        ys = [p[1] for p in self.poly_px]
        ln,  = self.ax.plot(xs, ys, '-',  color='#e74c3c', lw=1.4, zorder=6)
        pts, = self.ax.plot(xs, ys, 'o',  color='#e74c3c', ms=4,   zorder=7)
        fp,  = self.ax.plot(xs[0], ys[0], 'o', color='#f39c12', ms=9, zorder=8)
        self._preview = [ln, pts, fp]
        if cursor and cursor[0] is not None:
            rb, = self.ax.plot([xs[-1], cursor[0]], [ys[-1], cursor[1]],
                               '--', color='#e74c3c', lw=0.8, alpha=0.5, zorder=6)
            self._preview.append(rb)
        self.canvas.draw_idle()

    def _finish_polygon(self):
        if len(self.poly_ll) < 3:
            self._status('Need at least 3 points.')
            return
        pts_ll = self.poly_ll[:]
        if pts_ll[0] != pts_ll[-1]:
            pts_ll.append(pts_ll[0])
        name = simpledialog.askstring('Name polygon',
                                     'Enter a name for this craton KML:',
                                     parent=self.root)
        if not name or not name.strip():
            self._status('Cancelled.')
            return
        name = name.strip().replace(' ', '_')
        path = save_kml(name, pts_ll)
        self.ax.add_patch(MplPolygon(self.poly_px, closed=True,
                                     facecolor='#f4a0a0', edgecolor='#c0392b',
                                     alpha=0.45, lw=1.0, zorder=5))
        for a in self._preview:
            try: a.remove()
            except Exception: pass
        self._preview = []
        self.poly_px = []
        self.poly_ll = []
        self.canvas.draw()
        self._status(f'Saved → {path}  ({len(pts_ll)-1} points). Ready for next polygon.')

    # ── Events ────────────────────────────────────────────────────────────────

    def _on_press(self, event):
        if self.toolbar.mode != '':
            return

        if self.phase == 'manual_calib':
            if event.button == 1 and event.inaxes == self.ax and event.xdata is not None:
                self._handle_manual_click(event.xdata, event.ydata)
            return

        if self.phase != 'edit':
            return

        # Middle-mouse → toggle overlay lock
        if event.button == 2:
            self._toggle_lock()
            return

        if not self._locked:
            # ── Overlay move mode ──────────────────────────────────────────────
            if event.button == 1 and event.inaxes == self.ax:
                h = self._hit_handle(event)
                if h is not None:
                    self._drag_mode = h
                    self._drag_cx0 = self.ref_cx; self._drag_cy0 = self.ref_cy
                    hx, hy = self._handles()
                    opp = {0:3,1:2,2:1,3:0,4:5,5:4,6:7,7:6}
                    self._drag_fixed = (hx[opp[h]], hy[opp[h]])
                elif event.xdata is not None:
                    self._drag_mode = 'translate'
                    self._drag_m0   = (event.xdata, event.ydata)
                    self._drag_cx0  = self.ref_cx
                    self._drag_cy0  = self.ref_cy
        else:
            # ── Digitize mode ─────────────────────────────────────────────────
            if event.inaxes == self.ax:
                if event.button == 1 and event.xdata is not None:
                    self._add_point(event.xdata, event.ydata)
                elif event.button == 3:
                    self._undo_point()

    def _on_motion(self, event):
        if self.toolbar.mode != '':
            return

        if self.phase == 'edit' and not self._locked and self._drag_mode is not None:
            if event.xdata is not None:
                mx, my = event.xdata, event.ydata
            else:
                try:
                    mx, my = self.ax.transData.inverted().transform((event.x, event.y))
                except Exception:
                    return
            if self._drag_mode == 'translate':
                self.ref_cx = self._drag_cx0 + (mx - self._drag_m0[0])
                self.ref_cy = self._drag_cy0 + (my - self._drag_m0[1])
            else:
                self._move_handle(self._drag_mode, mx, my)
            self._move_overlay()
            return

        if self.phase == 'edit' and self._locked and self.poly_px and event.inaxes == self.ax:
            self._draw_preview(cursor=(event.xdata, event.ydata))

    def _move_handle(self, h: int, mx: float, my: float):
        fx, fy = self._drag_fixed
        xh, yh = _extents(PROJ_OPTIONS[self._proj_name])
        MIN = 1e-6
        if h in (0, 1, 2, 3):
            rsx = +1 if h in (1, 3) else -1
            rsy = +1 if h in (0, 1) else -1
            nsx = (mx - fx) / (2 * rsx * xh)
            nsy = (fy - my) / (2 * rsy * yh)
            if nsx > MIN and nsy > MIN:
                self.ref_cx = (mx+fx)/2; self.ref_cy = (my+fy)/2
                self.ref_sx = nsx;        self.ref_sy = nsy
        elif h in (4, 5):
            rsy = +1 if h == 4 else -1
            nsy = (fy - my) / (2 * rsy * yh)
            if nsy > MIN:
                self.ref_cy = (my+fy)/2; self.ref_sy = nsy
        elif h in (6, 7):
            rsx = -1 if h == 6 else +1
            nsx = (mx - fx) / (2 * rsx * xh)
            if nsx > MIN:
                self.ref_cx = (mx+fx)/2; self.ref_sx = nsx

    def _on_release(self, event):
        if event.button == 1:
            self._drag_mode = None

    def _on_key(self, event):
        if not self.img_path:
            return
        key = event.keysym.lower()
        if key not in ('w', 'a', 's', 'd'):
            return
        xl = self.ax.get_xlim()
        yl = self.ax.get_ylim()                   # yl[0] > yl[1] (y-axis flipped)
        sx = (xl[1] - xl[0]) * 0.15
        sy = (yl[0] - yl[1]) * 0.15              # positive
        if   key == 'a': self.ax.set_xlim(xl[0] - sx, xl[1] - sx)
        elif key == 'd': self.ax.set_xlim(xl[0] + sx, xl[1] + sx)
        elif key == 'w': self.ax.set_ylim(yl[0] - sy, yl[1] - sy)
        elif key == 's': self.ax.set_ylim(yl[0] + sy, yl[1] + sy)
        self.canvas.draw_idle()

    def _on_scroll(self, event):
        if event.inaxes != self.ax:
            return

        if self.phase == 'edit' and not self._locked:
            # Scale the overlay around the cursor
            f  = 1.1 if event.button == 'up' else (1. / 1.1)
            cx = event.xdata if event.xdata is not None else self.ref_cx
            cy = event.ydata if event.ydata is not None else self.ref_cy
            self.ref_cx = cx + (self.ref_cx - cx) * f
            self.ref_cy = cy + (self.ref_cy - cy) * f
            self.ref_sx *= f; self.ref_sy *= f
            self._move_overlay()
        else:
            # Zoom the viewport around the cursor
            if event.xdata is None:
                return
            f   = 1. / 1.25 if event.button == 'up' else 1.25
            x, y = event.xdata, event.ydata
            xl  = self.ax.get_xlim()
            yl  = self.ax.get_ylim()
            self.ax.set_xlim(x + (xl[0] - x) * f, x + (xl[1] - x) * f)
            self.ax.set_ylim(y + (yl[0] - y) * f, y + (yl[1] - y) * f)
            self.canvas.draw_idle()

    def _status(self, msg: str):
        self.status_var.set(msg)


if __name__ == '__main__':
    root = tk.Tk()
    DigitizerApp(root)
    root.mainloop()
