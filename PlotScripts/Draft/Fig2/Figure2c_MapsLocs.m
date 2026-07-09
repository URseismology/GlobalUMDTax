function Figure2c_MapsLocs()
    clear; close all; clc;
    
    % Add paths
    addpath('../../Data/m_map');
    addpath('../../Data/landmask');
    addpath('../../Data/slanCM');
    
    %% 1. Load Data Grids
    disp('Loading CAM22 Model (for Temperature & Vs)...');
    CAM22_FILE = '../../Data/Velocity_Models/CAM2022-vs-tmp.r0.0.nc';
    lon_cam = double(ncread(CAM22_FILE, 'longitude'));
    lat_cam = double(ncread(CAM22_FILE, 'latitude'));
    depth_cam = double(ncread(CAM22_FILE, 'depth'));
    
    d_idx_cam = find(depth_cam == 100);
    if isempty(d_idx_cam)
        [~, d_idx_cam] = min(abs(depth_cam - 100));
    end
    temp_raw = ncread(CAM22_FILE, 'tmp', [1, 1, d_idx_cam], [inf, inf, 1]);
    vs_raw = ncread(CAM22_FILE, 'vs', [1, 1, d_idx_cam], [inf, inf, 1]);
    v_ref = 4.50; % Reference velocity in km/s
    dvs_raw = (vs_raw - v_ref) ./ v_ref * 100;
    
    disp('Loading DBRD-NATURE2020 Tomography Model...');
    DBRD_FILE = '../../Data/MeltContent/DBRD-NATURE2020-depth.r0.1.nc';
    lon_dbrd = double(ncread(DBRD_FILE, 'longitude'));
    lat_dbrd = double(ncread(DBRD_FILE, 'latitude'));
    depth_dbrd = double(ncread(DBRD_FILE, 'depth'));
    
    d_idx_dbrd = find(depth_dbrd == 100);
    if isempty(d_idx_dbrd)
        [~, d_idx_dbrd] = min(abs(depth_dbrd - 100));
    end
    lQ_raw = ncread(DBRD_FILE, 'lQ', [1, 1, d_idx_dbrd], [inf, inf, 1]);
    
    % Load Votemap
    disp('Loading Votemap model...');
    votmap1 = load('../../Data/GlobalVs_Models/votemap_100_km.mat');
    xq = double(votmap1.xq);
    yq = double(votmap1.yq);
    totvotpos1 = double(votmap1.totvotespos);
    
    % Load ocean mask
    maskocean = load('../../Data/maskocean.mat').maskocean;
    
    %% 2. Interpolate Tomography Data onto Consistent Votemap Grid
    [LON_CAM, LAT_CAM] = ndgrid(lon_cam, lat_cam);
    LON_CAM(LON_CAM > 180) = LON_CAM(LON_CAM > 180) - 360;
    
    [LON_DBRD, LAT_DBRD] = ndgrid(lon_dbrd, lat_dbrd);
    LON_DBRD(LON_DBRD > 180) = LON_DBRD(LON_DBRD > 180) - 360;
    
    disp('Interpolating Tomography grids...');
    F_Temp = scatteredInterpolant(double(LON_CAM(:)), double(LAT_CAM(:)), double(temp_raw(:)), 'linear', 'none');
    Temp_Grid = F_Temp(xq, yq);
    
    F_lQ = scatteredInterpolant(double(LON_DBRD(:)), double(LAT_DBRD(:)), double(lQ_raw(:)), 'linear', 'none');
    lQ_Grid = F_lQ(xq, yq);
    
    F_dvs = scatteredInterpolant(double(LON_CAM(:)), double(LAT_CAM(:)), double(dvs_raw(:)), 'linear', 'none');
    dvs_Grid = F_dvs(xq, yq);
    
    % Convert lQ to ln(Q^-1) = -lQ * ln(10)
    ln_Q_inv = -lQ_Grid * log(10);
    
    %% 3. Mask out oceans on all grids
    Temp_Grid(maskocean) = NaN;
    ln_Q_inv(maskocean) = NaN;
    dvs_Grid(maskocean) = NaN;
    totvotpos1(maskocean) = NaN;
    
    %% 4. Load Clustering Statistics
    disp('Loading Clustering Statistics...');
    stats_dir = '../../Data/MachineLearningData/rf_global_clustering/results/';
    meta_dir = '../../Data/MachineLearningData/rf_global_clustering/data/';
    
    cam22_opts = detectImportOptions(fullfile(stats_dir, 'clustered_data_Neg_CAM22.csv'));
    cam22_data = readtable(fullfile(stats_dir, 'clustered_data_Neg_CAM22.csv'), cam22_opts);
    
    meta_opts = detectImportOptions(fullfile(meta_dir, 'Data_Global_R1Meta.csv'));
    meta_data = readtable(fullfile(meta_dir, 'Data_Global_R1Meta.csv'), meta_opts);
    
    st_lon = meta_data.Longitude;
    st_lat = meta_data.Latitude;
    st_depth = cam22_data.Neg_Depth;
    st_c = cam22_data.GMM_k4;
    
    valid_idx = ~isnan(st_depth);
    st_lon = st_lon(valid_idx);
    st_lat = st_lat(valid_idx);
    st_c = st_c(valid_idx);
    
    % Indices for each cluster based on raw GMM_k4
    % raw 2 = C1, raw 3 = C2, raw 0 = C3, raw 1 = C4
    idx_c1 = find(st_c == 2);
    idx_c2 = find(st_c == 3);
    idx_c3 = find(st_c == 0);
    idx_c4 = find(st_c == 1);
    
    %% 5. Setup Figure and Layout (4x2 grid)
    f = figure('Name', 'Figure 2c: Maps and Locations', 'Position', [100, 50, 1200, 1600], 'Color', 'w', 'Visible', 'off');
    
    w_panel = 0.41;
    h_panel = 0.162; 
    px_left1 = 0.05;
    px_left2 = 0.50;
    
    % Contiguous layout positions with zero vertical gap between actual maps
    py = [0.05 + 3*h_panel, 0.05 + 2*h_panel, 0.05 + h_panel, 0.05];
    
    % Helper to plot locations
    function plot_locs_left()
        psz = 10; % Reduced by 50% for better spatial clarity
        % C1: Red circle
        m_scatter(st_lon(idx_c1), st_lat(idx_c1), psz, 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.8 0.1 0.1], 'LineWidth', 1.0);
        % C2: Blue triangle
        m_scatter(st_lon(idx_c2), st_lat(idx_c2), psz, '^', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.1 0.3 0.8], 'LineWidth', 1.0);
        % C3: Green square
        m_scatter(st_lon(idx_c3), st_lat(idx_c3), psz, 's', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.1 0.6 0.3], 'LineWidth', 1.0);
    end

    function plot_locs_right()
        psz = 10;
        % C4: Black diamond
        m_scatter(st_lon(idx_c4), st_lat(idx_c4), psz, 'd', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 1.0);
    end

    %% Panel 1: Temperature (Top)
    disp('Plotting Panel 1: Temperature...');
    % Left
    ax1L = axes('Position', [px_left1, py(1), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, Temp_Grid); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax1L, slanCM('thermal')); caxis(ax1L, [300 1500]);
    plot_locs_left();
    title(ax1L, 'Temperature (CAM22) - Clusters C1, C2, C3', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Right
    ax1R = axes('Position', [px_left2, py(1), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, Temp_Grid); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax1R, slanCM('thermal')); caxis(ax1R, [300 1500]);
    plot_locs_right();
    title(ax1R, 'Temperature (CAM22) - Cluster C4', 'FontSize', 12, 'FontWeight', 'bold');
    
    c1 = colorbar(ax1R, 'eastoutside');
    c1.Label.String = 'Temperature (°C)';
    c1.Label.FontWeight = 'bold'; c1.Label.FontSize = 12;

    %% Panel 2: Vote Map
    disp('Plotting Panel 2: Vote Map...');
    % Left
    ax2L = axes('Position', [px_left1, py(2), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, totvotpos1); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax2L, slanCM('bilbao')); caxis(ax2L, [0 9]);
    plot_locs_left();
    
    % Right
    ax2R = axes('Position', [px_left2, py(2), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, totvotpos1); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax2R, slanCM('bilbao')); caxis(ax2R, [0 9]);
    plot_locs_right();
    
    c2 = colorbar(ax2R, 'eastoutside');
    c2.Label.String = 'Craton Vote Map (Votes)';
    c2.Label.FontWeight = 'bold'; c2.Label.FontSize = 12;

    %% Panel 3: Attenuation
    disp('Plotting Panel 3: Attenuation...');
    % Left
    ax3L = axes('Position', [px_left1, py(3), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, ln_Q_inv); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax3L, slanCM('vik'));
    plot_locs_left();
    
    % Right
    ax3R = axes('Position', [px_left2, py(3), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, ln_Q_inv); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax3R, slanCM('vik'));
    plot_locs_right();
    
    c3 = colorbar(ax3R, 'eastoutside');
    c3.Label.String = 'Attenuation ln(Q^{-1})';
    c3.Label.FontWeight = 'bold'; c3.Label.FontSize = 12;

    %% Panel 4: Shear-Velocity (Bottom)
    disp('Plotting Panel 4: Shear Velocity...');
    % Left
    ax4L = axes('Position', [px_left1, py(4), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, dvs_Grid); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax4L, flipud(slanCM('vik'))); caxis(ax4L, [-5 5]); 
    plot_locs_left();
    
    % Right
    ax4R = axes('Position', [px_left2, py(4), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, dvs_Grid); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax4R, flipud(slanCM('vik'))); caxis(ax4R, [-5 5]); 
    plot_locs_right();
    
    c4 = colorbar(ax4R, 'eastoutside');
    c4.Label.String = 'dVs/Vs (%)';
    c4.Label.FontWeight = 'bold'; c4.Label.FontSize = 12;

    %% Save Figure
    exportgraphics(f, '../../Figures/Global_Study/Figure2c_MapsLocs.png', 'Resolution', 300);
    disp('Figure saved as Figures/Global_Study/Figure2c_MapsLocs.png');
end

function plot_plate_boundaries()
    S_plates = shaperead('../../Data/global_tectonics/plates&provinces/shp/plate_boundaries.shp');
    for i = 1:length(S_plates)
        ptype = S_plates(i).type;
        x = S_plates(i).X;
        y = S_plates(i).Y;
        
        if strcmp(ptype, 'subduction zone') || strcmp(ptype, 'collision zone')
            if strcmp(ptype, 'subduction zone')
                pc = [0.1 0.3 0.6]; % Muted Blue
            else
                pc = 'k';
            end
            m_line(x, y, 'color', pc, 'linewidth', 1.0);
            
            if strcmp(ptype, 'subduction zone')
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
                m_line(mx, my, 'color', pc, 'linestyle', 'none', 'marker', '^', 'markersize', 1.8, 'markerfacecolor', pc);
            end
        else
            m_line(x, y, 'color', [0.7 0.7 0.7], 'linewidth', 0.6);
        end
    end
end
