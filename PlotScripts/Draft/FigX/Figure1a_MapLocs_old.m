function Figure1a_MapLocs()
    clear; close all; clc;
    
    % Add paths
    addpath('../../Data/m_map');
    addpath('../../Data/landmask');
    addpath('../../Data/slanCM');
    
    %% 1. Load Data Grids
    disp('Loading CAM22 Model (Temperature at 100km & 200km)...');
    CAM22_FILE = '../../Data/Velocity_Models/CAM2022-vs-tmp.r0.0.nc';
    lon_cam = double(ncread(CAM22_FILE, 'longitude'));
    lat_cam = double(ncread(CAM22_FILE, 'latitude'));
    depth_cam = double(ncread(CAM22_FILE, 'depth'));
    
    % 100 km slice
    d_idx_100 = find(depth_cam == 100);
    if isempty(d_idx_100)
        [~, d_idx_100] = min(abs(depth_cam - 100));
    end
    temp_100_raw = ncread(CAM22_FILE, 'tmp', [1, 1, d_idx_100], [inf, inf, 1]);
    
    % 200 km slice
    d_idx_200 = find(depth_cam == 200);
    if isempty(d_idx_200)
        [~, d_idx_200] = min(abs(depth_cam - 200));
    end
    temp_200_raw = ncread(CAM22_FILE, 'tmp', [1, 1, d_idx_200], [inf, inf, 1]);
    
    % Load Votemap (for standard grid)
    disp('Loading Votemap model for grid...');
    votmap1 = load('../../Data/GlobalVs_Models/votemap_100_km.mat');
    xq = double(votmap1.xq);
    yq = double(votmap1.yq);
    
    % Load ocean mask
    maskocean = load('../../Data/maskocean.mat').maskocean;
    
    %% 2. Interpolate Tomography Data onto Consistent Votemap Grid
    [LON_CAM, LAT_CAM] = ndgrid(lon_cam, lat_cam);
    LON_CAM(LON_CAM > 180) = LON_CAM(LON_CAM > 180) - 360;
    
    disp('Interpolating Tomography grids...');
    F_Temp_100 = scatteredInterpolant(double(LON_CAM(:)), double(LAT_CAM(:)), double(temp_100_raw(:)), 'linear', 'none');
    Temp_100_Grid = F_Temp_100(xq, yq);
    Temp_100_Grid(maskocean) = NaN;
    
    F_Temp_200 = scatteredInterpolant(double(LON_CAM(:)), double(LAT_CAM(:)), double(temp_200_raw(:)), 'linear', 'none');
    Temp_200_Grid = F_Temp_200(xq, yq);
    Temp_200_Grid(maskocean) = NaN;
    
    %% 3. Load Clustering Statistics
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
    
    %% 4. Setup Figure and Layout
    f = figure('Name', 'Figure 1a: Map Locations', 'Position', [100, 100, 1400, 900], 'Color', 'w', 'Visible', 'off');
    
    % Helpers
    function plot_locs_c123()
        psz = 15; 
        % C1: Red circle
        m_scatter(st_lon(idx_c1), st_lat(idx_c1), psz, 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.8 0.1 0.1], 'LineWidth', 1.0);
        % C2: Blue triangle
        m_scatter(st_lon(idx_c2), st_lat(idx_c2), psz, '^', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.1 0.3 0.8], 'LineWidth', 1.0);
        % C3: Green square
        m_scatter(st_lon(idx_c3), st_lat(idx_c3), psz, 's', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.1 0.6 0.3], 'LineWidth', 1.0);
    end

    function plot_locs_c4()
        psz = 15;
        % C4: Black diamond
        m_scatter(st_lon(idx_c4), st_lat(idx_c4), psz, 'd', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 1.0);
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

    %% Main Panel (100km Temp)
    disp('Plotting Main Panel...');
    axMain = axes('Position', [0.05, 0.1, 0.9, 0.8]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, Temp_100_Grid); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1);
    plot_plate_boundaries();
    colormap(axMain, slanCM('thermal')); 
    caxis(axMain, [300 1500]);
    plot_locs_c123();
    title(axMain, 'CAM22 Temperature at 100 km (Clusters C1-C3)', 'FontSize', 16, 'FontWeight', 'bold');
    
    c = colorbar(axMain, 'eastoutside');
    c.Label.String = 'Temperature (°C)';
    c.Label.FontWeight = 'bold'; 
    c.Label.FontSize = 14;

    %% Inset Panel (200km Temp)
    disp('Plotting Inset Panel...');
    % Place inset in the lower-left corner
    axInset = axes('Position', [0.12, 0.15, 0.3, 0.3]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, Temp_200_Grid); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 0.5);
    % Turn off grid lines and labels for cleaner inset
    m_grid('linestyle', 'none', 'box', 'on', 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(axInset, slanCM('thermal')); 
    caxis(axInset, [300 1500]);
    plot_locs_c4();
    title(axInset, 'CAM22 at 200 km (C4)', 'FontSize', 12, 'FontWeight', 'bold');

    %% Save Figure
    out_dir = '../../Figures/Global_Study';
    if ~isfolder(out_dir), mkdir(out_dir); end
    out_file = fullfile(out_dir, 'Figure1a_MapLocs.png');
    exportgraphics(f, out_file, 'Resolution', 300);
    disp(['Figure saved as ', out_file]);
end
