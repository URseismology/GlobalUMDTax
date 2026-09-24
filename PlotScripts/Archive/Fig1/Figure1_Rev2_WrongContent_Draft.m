clear 
close all
clc

addpath('./Data/m_map');
addpath('./Data/slanCM');
addpath('./Data/landmask');

%% 1. Load Coastlines and Tectonic Boundaries
S1 = shaperead('./Data/ContinentCoastlines/ne_110m_coastline/ne_110m_coastline.shp');
% Load Plate Boundaries and Provinces
S_plates = shaperead('Data/global_tectonics/plates&provinces/shp/plate_boundaries.shp');
S_cratons = shaperead('Data/global_tectonics/plates&provinces/shp/supercratons.shp');

%% 2. Load Data for Both Models
disp('Loading Data...');
Data_Global_RF_Meta = readtable('./Data/MachineLearningData/rf_global_clustering/data/Data_Global_R1Meta.csv');

% CAM-22 Data
Data_CAM22_ML = readtable('./Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv');
Data_CAM22 = Data_Global_RF_Meta;
Data_CAM22.GMM_k4 = Data_CAM22_ML.GMM_k4;
Data_CAM22.Neg_Depth = Data_CAM22_ML.Neg_Depth;

% WINTERC-G Data (uses CAM22 clustering definition, as done previously)
Data_WINT = Data_Global_RF_Meta;
Data_WINT.GMM_k4 = Data_CAM22_ML.GMM_k4;
Data_WINT.Neg_Depth = Data_CAM22_ML.Neg_Depth;

%% 3. Load Thermal LAB Grids
disp('Loading WINTERC-G LAB Grid...');
WINTERC_LAB_FILE = '../../Data/WINTERC_G/WINTERC-G_LAB.txt';
LAB_winter_data = load(WINTERC_LAB_FILE);
LAB_winter_data_long = LAB_winter_data(:,2);
LAB_winter_data_long(LAB_winter_data_long > 180) = LAB_winter_data_long(LAB_winter_data_long > 180) - 360;
LAB_winter_lat = LAB_winter_data(:,3);
LAB_winter_depths = LAB_winter_data(:,4);
F_LAB_WINT = scatteredInterpolant(LAB_winter_data_long, LAB_winter_lat, LAB_winter_depths, 'linear', 'none');

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

%% Create evaluation grid for map backgrounds
longridinterp = -180:0.5:180;
latgridinterp = -90:0.5:90;
[yq, xq] = meshgrid(latgridinterp, longridinterp);
xq = double(xq); yq = double(yq);

%% 4. Plotting
model_names = {'CAM-22', 'WINTERC-G'};
datasets = {Data_CAM22, Data_WINT};
interpolants = {F_LAB_CAM, F_LAB_WINT};

% Colormap for Absolute Depth (40 to 200 km keeps white at 120 km)
cmapDepth = flipud(slanCM('vik')); % Diverging Red-White-Blue
depth_limits = [40 200];
fs = 18; % Font size

for m = 1:2
    fprintf('Generating Figure for %s...\n', model_names{m});
    
    current_data = datasets{m};
    current_F_LAB = interpolants{m};
    
    LAB_Map = current_F_LAB(xq, yq);
    
    % Mask out oceans
    ocean_mask = ~landmask(yq, xq);
    LAB_Map(ocean_mask) = NaN;
    
    st_depth = current_data.Neg_Depth;
    st_lon = current_data.Longitude;
    st_lat = current_data.Latitude;
    st_c = current_data.GMM_k4;
    
    valid_idx = ~isnan(st_depth);
    st_lon = st_lon(valid_idx);
    st_lat = st_lat(valid_idx);
    st_depth = st_depth(valid_idx);
    st_c = st_c(valid_idx);
    
    f = figure('Position', [100, 100, 2400, 800], 'Color', 'w', 'Visible', 'off');
    
    projections = {
        {'miller', 'lat', [-60 55], 'lon', [-135 -20]}, ... % Americas
        {'miller', 'lat', [-40 60], 'lon', [-20 60]}, ...   % Europe/Africa
        {'miller', 'lat', [-50 60], 'lon', [60 180]}        % Asia/Australia
    };
    
    for p = 1:3
        % Use standard subplot to preserve natural map aspect ratio
        ax = subplot(1, 3, p);
        m_proj(projections{p}{:});
        hold on;
        
        % 1. Plot Thermal LAB as background
        m_pcolor(xq, yq, LAB_Map);
        colormap(ax, cmapDepth); 
        caxis(depth_limits); 
        shading flat;
        
        % Coastlines
        for ic = 1:length(S1)      
            m_line(S1(ic).X, S1(ic).Y, 'color', [0.2 0.2 0.2], 'linewidth', 1.0);  
        end
        
        % Plate Boundaries (color-coded by type)
        for ip = 1:length(S_plates)
            btype = S_plates(ip).type;
            if contains(btype, 'spreading center')
                c = [1 0 0]; % Red
                lw = 1.5;
            elseif contains(btype, 'subduction')
                c = [0 0 1]; % Blue
                lw = 2.0;
            elseif contains(btype, 'transform')
                c = [0 0.5 0]; % Green
                lw = 1.5;
            elseif contains(btype, 'collision')
                c = [0 0 0]; % Black
                lw = 1.5;
            else
                c = [0.4 0.4 0.4]; % Gray for extension/inferred
                lw = 1.0;
            end
            m_line(S_plates(ip).X, S_plates(ip).Y, 'color', c, 'linewidth', lw);
        end
        
        % Cratons (blue)
        for icr = 1:length(S_cratons)      
            m_line(S_cratons(icr).X, S_cratons(icr).Y, 'color', [0 0 1], 'linewidth', 2.0, 'linestyle', '-');  
        end
        
        % Marker size smaller for Americas (panel 1)
        if p == 1
            psz = 50;
        else
            psz = 120;
        end
        
        % Map seismic depth to colormap
        nColors = size(cmapDepth, 1);
        cIdx = round(((st_depth - depth_limits(1)) / (depth_limits(2) - depth_limits(1))) * (nColors-1)) + 1;
        cIdx(cIdx < 1) = 1;
        cIdx(cIdx > nColors) = nColors;
        
        % Plot C1, C2, C3 with different shapes, omitted C4
        idx_c1 = find(st_c == 2); % Melt
        idx_c2 = find(st_c == 3); % Rheological
        idx_c3 = find(st_c == 0); % Metasomatism
        
        h = zeros(1,3);
        % C1 = Triangle
        for i = 1:length(idx_c1)
            idx = idx_c1(i);
            sc = m_scatter(st_lon(idx), st_lat(idx), psz, ...
                'Marker', '^', 'MarkerFaceColor', cmapDepth(cIdx(idx),:), ...
                'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
            if i == 1, h(1) = sc; end
        end
        % C2 = Square
        for i = 1:length(idx_c2)
            idx = idx_c2(i);
            sc = m_scatter(st_lon(idx), st_lat(idx), psz, ...
                'Marker', 's', 'MarkerFaceColor', cmapDepth(cIdx(idx),:), ...
                'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
            if i == 1, h(2) = sc; end
        end
        % C3 = Circle
        for i = 1:length(idx_c3)
            idx = idx_c3(i);
            sc = m_scatter(st_lon(idx), st_lat(idx), psz, ...
                'Marker', 'o', 'MarkerFaceColor', cmapDepth(cIdx(idx),:), ...
                'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
            if i == 1, h(3) = sc; end
        end
        
        m_grid('linestyle', '-', 'ytick', [], 'xtick', [], 'tickdir', 'out', ...
               'linewi', 1, 'gridcolor', [0.8 0.8 0.8], 'backcolor', [0.85 0.85 0.85], 'fontsize', fs);
           
        % Add legend only to the first panel
        if p == 1
            valid_h = h(h~=0);
            leg_labels = {'C1 (Melt)', 'C2 (Rheological)', 'C3 (Metasomatic)'};
            
            % Add dummy lines for cratons and plates to legend
            hp = plot(NaN, NaN, 'color', [0 0 0], 'linewidth', 2.0);
            hc = plot(NaN, NaN, 'color', [0 0 1], 'linewidth', 2.0, 'linestyle', '-');
            
            valid_h = [valid_h, hp, hc];
            leg_labels = [leg_labels(h~=0), {'Plate Boundaries', 'Cratons'}];
            
            legend(valid_h, leg_labels, 'Location', 'southwest', 'FontSize', fs-4);
        end
        
        % Add colorbar to the rightmost panel
        if p == 3
            cb = colorbar;
            cb.Label.String = 'Absolute Depth (Seismic and Thermal LAB) [km]';
            cb.Label.FontSize = fs;
            cb.Position = [0.93 0.1 0.015 0.8];
        end
    end
    
    % Save the figure
    out_name = sprintf('Figure1_%s_DecouplingMap.png', model_names{m});
    exportgraphics(f, out_name, 'Resolution', 300);
    close(f);
    fprintf('Saved %s\n', out_name);
end
disp('Done!');
