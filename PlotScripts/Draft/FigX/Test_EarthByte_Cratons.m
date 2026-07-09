clear; close all; clc;
addpath('./Data/m_map');
addpath('./Data/landmask');
addpath('./Data/slanCM');

f = figure('Name', 'EarthByte Craton Boundaries', 'Position', [100, 100, 1000, 600], 'Visible', 'off');
m_proj('robinson', 'long', [-180 180]);
hold on;

%% Load CAM22 LAB Grid
disp('Loading CAM-22 LAB Grid...');
CAM22_LAB_FILE = '../../Data/Velocity_Models/CAM2022-lithosphere.r0.0.nc';
cam_info = ncinfo(CAM22_LAB_FILE);
cam_vars = {cam_info.Variables.Name};
cam_lon_var = cam_vars{contains(cam_vars, 'lon', 'IgnoreCase', true)};
cam_lat_var = cam_vars{contains(cam_vars, 'lat', 'IgnoreCase', true)};
depth_candidates = {'depth', 'z', 'lab', 'lithosphere', 'thickness'};
cam_depth_var = '';
for i = 1:length(cam_vars)
    for j = 1:length(depth_candidates)
        if strcmpi(cam_vars{i}, depth_candidates{j})
            cam_depth_var = cam_vars{i};
            break;
        end
    end
end
if isempty(cam_depth_var)
    rem_vars = cam_vars(~ismember(cam_vars, {cam_lon_var, cam_lat_var}));
    cam_depth_var = rem_vars{1};
end
cam_lon = ncread(CAM22_LAB_FILE, cam_lon_var);
cam_lat = ncread(CAM22_LAB_FILE, cam_lat_var);
cam_lab_grid = ncread(CAM22_LAB_FILE, cam_depth_var);

if isvector(cam_lon) && isvector(cam_lat) && ismatrix(cam_lab_grid)
    [CAM_LON, CAM_LAT] = ndgrid(cam_lon, cam_lat);
    CAM_LON(CAM_LON > 180) = CAM_LON(CAM_LON > 180) - 360;
    F_LAB_CAM = scatteredInterpolant(double(CAM_LON(:)), double(CAM_LAT(:)), double(cam_lab_grid(:)), 'linear', 'none');
else
    cam_lon(cam_lon > 180) = cam_lon(cam_lon > 180) - 360;
    F_LAB_CAM = scatteredInterpolant(double(cam_lon(:)), double(cam_lat(:)), double(cam_lab_grid(:)), 'linear', 'none');
end

%% Create evaluation grid
longridinterp = -180:0.5:180;
latgridinterp = -90:0.5:90;
[yq, xq] = meshgrid(latgridinterp, longridinterp);
xq = double(xq); yq = double(yq);

LAB_Map = F_LAB_CAM(xq, yq);
ocean_mask = ~landmask(yq, xq);
LAB_Map(ocean_mask) = NaN;

%% Plot Thermal LAB as background
cmapDepth = flipud(slanCM('vik'));
depth_limits = [50 250];

m_pcolor(xq, yq, LAB_Map);
colormap(gca, cmapDepth); 
caxis(depth_limits); 
shading flat;

c = colorbar('southoutside');
c.Label.String = 'Depth to Seismic Boundary and Thermal LAB';

m_coast('color', 'k', 'linewidth', 1);
m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1);

%% Load and plot plate boundaries
S_plates = shaperead('Data/global_tectonics/plates&provinces/shp/plate_boundaries.shp');
for i = 1:length(S_plates)
    ptype = S_plates(i).type;
    x = S_plates(i).X;
    y = S_plates(i).Y;
    
    if strcmp(ptype, 'subduction zone') || strcmp(ptype, 'collision zone')
        if strcmp(ptype, 'subduction zone')
            pc = 'b';
        else
            pc = 'k';
        end
        m_line(x, y, 'color', pc, 'linewidth', 1.5);
        valid = find(~isnan(x) & ~isnan(y));
        if isempty(valid), continue; end
        
        mx = x(valid(1));
        my = y(valid(1));
        dist = 0;
        for k = 2:length(valid)
            idx = valid(k);
            prev = valid(k-1);
            if idx ~= prev + 1
                dist = 0;
                mx(end+1) = x(idx);
                my(end+1) = y(idx);
                continue;
            end
            d = sqrt((x(idx) - x(prev))^2 + (y(idx) - y(prev))^2);
            dist = dist + d;
            if dist >= 10
                mx(end+1) = x(idx);
                my(end+1) = y(idx);
                dist = 0;
            end
        end
        m_line(mx, my, 'color', pc, 'linestyle', 'none', 'marker', '^', 'markersize', 2.5, 'markerfacecolor', pc);
    else
        m_line(x, y, 'color', [0.6 0.6 0.6], 'linewidth', 1);
    end
end

%% Overlay Votemap Outlines (Threshold 8)
votmap1 = load("./Data/GlobalVs_Models/votemap_100_km.mat");
vmap = votmap1.totvotespos;
ocean_mask_v = ~landmask(votmap1.yq, votmap1.xq);
vmap(ocean_mask_v) = NaN;
[c_v, h_v] = m_contour(votmap1.xq, votmap1.yq, vmap, [8 8], 'color', 'k', 'linewidth', 1.5);

%% Overlay C1, C2, C3 symbols colorcoded by depth
Data_CAM22_ML = readtable('Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv');
Data_Global_RF_Meta = readtable('Data/MachineLearningData/rf_global_clustering/data/Data_Global_R1Meta.csv');

st_lon = Data_Global_RF_Meta.Longitude;
st_lat = Data_Global_RF_Meta.Latitude;
st_continent = Data_Global_RF_Meta.Continent;
st_depth = Data_CAM22_ML.Neg_Depth;
st_c = Data_CAM22_ML.GMM_k4;

valid_idx = ~isnan(st_depth);
st_lon = st_lon(valid_idx);
st_lat = st_lat(valid_idx);
st_depth = st_depth(valid_idx);
st_c = st_c(valid_idx);
st_continent = st_continent(valid_idx);

idx_c1 = find(st_c == 2); % Melt
idx_c2 = find(st_c == 3); % Rheological
idx_c3 = find(st_c == 0); % Metasomatism

psz_vec = 25 * ones(size(st_depth));
idx_na = strcmpi(st_continent, 'north america');
psz_vec(idx_na) = 12.5;

% Map seismic depth to colormap
nColors = size(cmapDepth, 1);
cIdx = round(((st_depth - depth_limits(1)) / (depth_limits(2) - depth_limits(1))) * (nColors-1)) + 1;
cIdx(cIdx < 1) = 1;
cIdx(cIdx > nColors) = nColors;

h_sc = zeros(1, 3);
h_sc(1) = m_scatter(st_lon(idx_c1), st_lat(idx_c1), psz_vec(idx_c1), 'Marker', '^', 'MarkerFaceColor', 'flat', 'CData', cmapDepth(cIdx(idx_c1),:), 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
h_sc(2) = m_scatter(st_lon(idx_c2), st_lat(idx_c2), psz_vec(idx_c2), 'Marker', 's', 'MarkerFaceColor', 'flat', 'CData', cmapDepth(cIdx(idx_c2),:), 'MarkerEdgeColor', 'w', 'LineWidth', 0.5);
h_sc(3) = m_scatter(st_lon(idx_c3), st_lat(idx_c3), psz_vec(idx_c3), 'Marker', 'o', 'MarkerFaceColor', 'flat', 'CData', cmapDepth(cIdx(idx_c3),:), 'MarkerEdgeColor', 'w', 'LineWidth', 0.5);

legend(h_sc, {'C1 (Melt)', 'C2 (Rheological)', 'C3 (Metasomatic)'}, 'Location', 'northeastoutside');

title('CAM22 LAB Depth & Craton Outlines (Votemap >= 8)');
exportgraphics(f, 'Figures/Global_Study/Test_EarthByte_Cratons.png', 'Resolution', 300);
