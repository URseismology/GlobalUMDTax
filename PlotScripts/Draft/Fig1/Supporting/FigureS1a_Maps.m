function FigureS1a_Maps() clear;
close all;
clc;

% Add paths addpath('../../../Data/m_map');
addpath('../../../Data/landmask');
addpath('../../../Data/slanCM');

% % 1. Load Data Grids disp('Loading CAM22 Model (for Temperature)...');
CAM22_FILE = '../../../Data/Velocity_Models/CAM2022-vs-tmp.r0.0.nc';
lon_cam = double(ncread(CAM22_FILE, 'longitude'));
lat_cam = double(ncread(CAM22_FILE, 'latitude'));
depth_cam = double(ncread(CAM22_FILE, 'depth'));

d_idx_cam = find(depth_cam == 100);
if isempty (d_idx_cam)
  [ ~, d_idx_cam ] = min(abs(depth_cam - 100));
end temp_raw = ncread(CAM22_FILE, 'tmp', [ 1, 1, d_idx_cam ], [ inf, inf, 1 ]);

disp('Loading DBRD-NATURE2020 Tomography Model...');
DBRD_FILE = '../../../Data/MeltContent/DBRD-NATURE2020-depth.r0.1.nc';
lon_dbrd = double(ncread(DBRD_FILE, 'longitude'));
lat_dbrd = double(ncread(DBRD_FILE, 'latitude'));
depth_dbrd = double(ncread(DBRD_FILE, 'depth'));

d_idx_dbrd = find(depth_dbrd == 100);
if isempty (d_idx_dbrd)
  [ ~, d_idx_dbrd ] = min(abs(depth_dbrd - 100));
end lQ_raw = ncread(DBRD_FILE, 'lQ', [ 1, 1, d_idx_dbrd ], [ inf, inf, 1 ]);

% Load CAM22 absolute Vs and calculate perturbation % vs_raw =
    ncread(CAM22_FILE, 'vs', [ 1, 1, d_idx_cam ], [ inf, inf, 1 ]);
v_ref = 4.50;
% Reference velocity in km / s dvs_raw = (vs_raw - v_ref)./ v_ref * 100;

% Load Votemap disp('Loading Votemap model...');
votmap1 = load('../../../Data/GlobalVs_Models/votemap_100_km.mat');
xq = double(votmap1.xq);
yq = double(votmap1.yq);
totvotpos1 = double(votmap1.totvotespos);

% Load ocean mask maskocean = load('../../../Data/maskocean.mat').maskocean;

% %
    2. Interpolate Tomography Data onto Consistent Votemap
        Grid[LON_CAM, LAT_CAM] = ndgrid(lon_cam, lat_cam);
LON_CAM(LON_CAM > 180) = LON_CAM(LON_CAM > 180) - 360;

[ LON_DBRD, LAT_DBRD ] = ndgrid(lon_dbrd, lat_dbrd);
LON_DBRD(LON_DBRD > 180) = LON_DBRD(LON_DBRD > 180) - 360;

disp('Interpolating Tomography grids...');
F_Temp = scatteredInterpolant(double(LON_CAM( :)), double(LAT_CAM( :)),
                              double(temp_raw( :)), 'linear', 'none');
Temp_Grid = F_Temp(xq, yq);

F_lQ = scatteredInterpolant(double(LON_DBRD( :)), double(LAT_DBRD( :)),
                            double(lQ_raw( :)), 'linear', 'none');
lQ_Grid = F_lQ(xq, yq);

F_dvs = scatteredInterpolant(double(LON_CAM( :)), double(LAT_CAM( :)),
                             double(dvs_raw( :)), 'linear', 'none');
dvs_Grid = F_dvs(xq, yq);

% Convert lQ to ln(Q ^ -1) = -lQ * ln(10) ln_Q_inv = -lQ_Grid * log(10);

% % 3. Mask out oceans on all grids Temp_Grid(maskocean) = NaN;
ln_Q_inv(maskocean) = NaN;
dvs_Grid(maskocean) = NaN;
totvotpos1(maskocean) = NaN;

% % 4. Setup Figure and Layout(2x2 grid) f =
    figure('Name', 'Figure 2a: Mantle Physical Properties at 100km', 'Position',
           [ 100, 100, 1400, 950 ], 'Color', 'w', 'Visible', 'off');

w_panel = 0.43;
h_panel = 0.38;

py_top = 0.54;
py_bot = 0.08;

px_left = 0.04;
px_right = 0.52;

% % Panel 1 : Temperature(Top Left) disp('Plotting Panel 1: Temperature...');
ax1 = axes('Position', [ px_left, py_top, w_panel, h_panel ]);
m_proj('robinson', 'long', [-180 180]);
hold on;
m_pcolor(xq, yq, Temp_Grid);
shading flat;
m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1);
plot_plate_boundaries();
colormap(ax1, slanCM('thermal'));
caxis(ax1, [300 1500]);
c1 = colorbar('southoutside');
c1.Label.String = 'Temperature (°C)';
c1.Label.FontWeight = 'bold';
title('Temperature (CAM22) at 100 km', 'FontSize', 12, 'FontWeight', 'bold');

% % Panel 2 : Vote Map(Top Right) disp('Plotting Panel 2: Vote Map...');
ax2 = axes('Position', [ px_right, py_top, w_panel, h_panel ]);
m_proj('robinson', 'long', [-180 180]);
hold on;
m_pcolor(xq, yq, totvotpos1);
shading flat;
m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1);
plot_plate_boundaries();
colormap(ax2, slanCM('bilbao'));
caxis(ax2, [0 9]);
c2 = colorbar('southoutside');
c2.Label.String = 'Model Agreement (Votes)';
c2.Label.FontWeight = 'bold';
title('Craton Vote Map at 100 km', 'FontSize', 12, 'FontWeight', 'bold');

% % Panel 3 : Attenuation(Bottom Left) disp('Plotting Panel 3: Attenuation...');
ax3 = axes('Position', [ px_left, py_bot, w_panel, h_panel ]);
m_proj('robinson', 'long', [-180 180]);
hold on;
m_pcolor(xq, yq, ln_Q_inv);
shading flat;
m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1);
plot_plate_boundaries();
colormap(ax3, slanCM('vik'));
% caxis(ax3, [-7 - 4]);
% Re - applied colormap limits c3 = colorbar('southoutside');
c3.Label.String = 'ln(Q^{-1})';
c3.Label.FontWeight = 'bold';
title('Attenuation ln(Q^{-1}) at 100 km', 'FontSize', 12, 'FontWeight', 'bold');

% % Panel 4 : Shear - Velocity(Bottom Right)
                          disp('Plotting Panel 4: Shear Velocity...');
ax4 = axes('Position', [ px_right, py_bot, w_panel, h_panel ]);
m_proj('robinson', 'long', [-180 180]);
hold on;
m_pcolor(xq, yq, dvs_Grid);
shading flat;
m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1);
plot_plate_boundaries();
colormap(ax4, flipud(slanCM('vik')));
caxis(ax4, [-5 5]);
% Re - applied colormap limits c4 = colorbar('southoutside');
c4.Label.String = 'dVs/Vs (%)';
c4.Label.FontWeight = 'bold';
title('Shear-Velocity Perturbation (dVs/Vs) at 100 km', 'FontSize', 12,
      'FontWeight', 'bold');

% %
    Save Figure exportgraphics(f,
                               '../../../Figures/Global_Study/FigureS1a_Maps.png',
                               'Resolution', 300);
disp('Figure saved as Figures/Global_Study/FigureS1a_Maps.png');
end

    function
    plot_plate_boundaries() S_plates = shaperead(
        '../../../Data/global_tectonics/plates&provinces/shp/plate_boundaries.shp');
    for
      i = 1 : length(S_plates) ptype = S_plates(i).type;
    x = S_plates(i).X;
    y = S_plates(i).Y;

    if strcmp (ptype, 'subduction zone')
      || strcmp(ptype, 'collision zone') if strcmp (
             ptype, 'subduction zone') pc = [0.1 0.3 0.6];
    % Muted Blue else pc = 'k';
    end m_line(x, y, 'color', pc, 'linewidth', 1.0);

    if strcmp (ptype, 'subduction zone')
      valid = find(~isnan(x) & ~isnan(y));
    if isempty (valid)
      , continue;
    end mx = x(valid(1));
    my = y(valid(1));
    dist = 0;
                for
                  k = 2 : length(valid) idx = valid(k);
                prev = valid(k - 1);
                if idx
                  ~= prev + 1 dist = 0;
                mx(end + 1) = x(idx);
                my(end + 1) = y(idx);
                continue;
                end d = sqrt((x(idx) - x(prev)) ^ 2 + (y(idx) - y(prev)) ^ 2);
                dist = dist + d;
                if dist
                  >= 10 mx(end + 1) = x(idx);
                my(end + 1) = y(idx);
                dist = 0;
                end end m_line(mx, my, 'color', pc, 'linestyle', 'none',
                               'marker', '^', 'markersize', 1.8,
                               'markerfacecolor', pc);
                end else m_line(x, y, 'color', [0.7 0.7 0.7], 'linewidth', 0.6);
                end end end
