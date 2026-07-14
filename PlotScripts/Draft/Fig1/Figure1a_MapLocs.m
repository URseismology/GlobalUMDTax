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
    
    % Ensure longitudes are in [-180, 180] for regional plotting bounds
    st_lon(st_lon > 180) = st_lon(st_lon > 180) - 360;
    
    % Indices for each cluster based on raw GMM_k4
    % raw 2 = C1, raw 3 = C2, raw 0 = C3, raw 1 = C4
    idx_c1 = find(st_c == 2);
    idx_c2 = find(st_c == 3);
    idx_c3 = find(st_c == 0);
    idx_c4 = find(st_c == 1);
    
    %% 4. Setup Figure and Layout
    f = figure('Name', 'Figure 1ax: Map Locations Experimental', 'Position', [100, 100, 1400, 900], 'Color', 'w', 'Visible', 'off');
    
    % Helpers
    function plot_locs_c123(psz, bbox)
        if nargin < 1, psz = 15; end
        if nargin < 2, bbox = [-180 180 -90 90]; end
        
        function plot_c(indices, marker, edge_color)
            lons = st_lon(indices);
            lats = st_lat(indices);
            in_box = lons >= bbox(1) & lons <= bbox(2) & lats >= bbox(3) & lats <= bbox(4);
            if any(in_box)
                m_scatter(lons(in_box), lats(in_box), psz, marker, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', edge_color, 'LineWidth', 1.0);
            end
        end
        
        % C1: Red circle
        plot_c(idx_c1, 'o', [0.8 0.1 0.1]);
        % C2: Blue triangle
        plot_c(idx_c2, '^', [0.1 0.3 0.8]);
        % C3: Green square
        plot_c(idx_c3, 's', [0.1 0.6 0.3]);
    end

    function plot_locs_c4(psz, bbox)
        if nargin < 1, psz = 15; end
        if nargin < 2, bbox = [-180 180 -90 90]; end
        
        lons = st_lon(idx_c4);
        lats = st_lat(idx_c4);
        in_box = lons >= bbox(1) & lons <= bbox(2) & lats >= bbox(3) & lats <= bbox(4);
        if any(in_box)
            % C4: Black diamond
            m_scatter(lons(in_box), lats(in_box), psz, 'd', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 1.0);
        end
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
    
    hMain = m_pcolor(xq, yq, Temp_100_Grid); shading flat;
    set(hMain, 'FaceAlpha', 0.85); % Slightly transparent
    
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    
    % Create custom colormap with sharp transition at 1315 C
    % Range: [300, 1500]. Total = 1200.
    % 300 to 1315 (1015 span) -> Cold
    % 1315 to 1500 (185 span) -> Hot
    n_cold = round(256 * (1015/1200));
    n_hot = 256 - n_cold;
    
    % Cold: Grayscale (avoids clashing with C2 Blue and C3 Green)
    gray_vals = linspace(0.3, 0.9, n_cold)';
    cmap_cold = [gray_vals, gray_vals, gray_vals];
    
    % Hot: Muted Yellow to Orange (avoids clashing with C1 Red and C3 Green)
    r_hot = linspace(1.0, 0.9, n_hot)';
    g_hot = linspace(0.9, 0.5, n_hot)';
    b_hot = linspace(0.5, 0.1, n_hot)';
    cmap_hot = [r_hot, g_hot, b_hot];
    
    custom_cmap_main = [cmap_cold; cmap_hot];
    
    colormap(axMain, custom_cmap_main); 
    caxis(axMain, [300 1500]);
    plot_locs_c123();
    title(axMain, 'CAM22 Temperature at 100 km (Clusters C1-C3)', 'FontSize', 16, 'FontWeight', 'bold');
    
    c = colorbar(axMain, 'eastoutside');
    c.Label.String = 'Temperature (°C)';
    c.Label.FontWeight = 'bold'; 
    c.Label.FontSize = 14;

    %% Inset Panel (200km Temp)
    disp('Plotting Inset Panel...');
    % Move the inset ~20% higher
    axInset = axes('Position', [0.03, 0.23, 0.28, 0.28]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, Temp_200_Grid); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 0.5);
    m_grid('linestyle', 'none', 'box', 'on', 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    
    % Accentuate details between 1200 and 1400 deg C using the consistent colormap
    % Extract the slice of the main colormap that corresponds to 1200-1400 C
    idx_1200 = max(1, round(256 * ((1200 - 300) / 1200)));
    idx_1400 = min(256, round(256 * ((1400 - 300) / 1200)));
    cmap_inset = custom_cmap_main(idx_1200:idx_1400, :);
    
    colormap(axInset, cmap_inset); 
    caxis(axInset, [1200 1400]);
    plot_locs_c4();
    title(axInset, 'CAM22 at 200 km (C4)', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Add colorbar for inset (small, vertical, placed in the Pacific region)
    % Shifted slightly to the right to sit squarely in the Pacific.
    c_in = colorbar(axInset, 'Position', [0.075, 0.28, 0.008, 0.15]);
    c_in.Label.String = 'Temp (°C)';
    c_in.Label.FontWeight = 'bold';
    c_in.Label.FontSize = 10;

    %% Save Figure 1
    out_dir = '../../Figures/Global_Study';
    if ~isfolder(out_dir), mkdir(out_dir); end
    out_file = fullfile(out_dir, 'Figure1a_MapLocs.png');
    exportgraphics(f, out_file, 'Resolution', 300);
    disp(['Figure saved as ', out_file]);
    
    %% 5. Setup US Zoom Figure
    disp('Plotting US Zoom Figure...');
    f2 = figure('Name', 'Figure 1ax: US Zoom', 'Position', [100, 100, 1200, 700], 'Color', 'w', 'Visible', 'off');
    
    axUS = axes('Position', [0.05, 0.1, 0.8, 0.8]);
    m_proj('mercator', 'long', [-130 -65], 'lat', [22 52]); hold on;
    
    hUS = m_pcolor(xq, yq, Temp_100_Grid); shading flat;
    set(hUS, 'FaceAlpha', 0.85); 
    
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1);
    plot_plate_boundaries();
    
    colormap(axUS, custom_cmap_main); 
    caxis(axUS, [300 1500]);
    plot_locs_c123(40, [-130, -65, 22, 52]); % Explicitly clip points to US bounds to prevent wrap artifacts
    
    title(axUS, 'CAM22 Temperature at 100 km (US Zoom - Clusters C1-C3)', 'FontSize', 16, 'FontWeight', 'bold');
    
    c_us = colorbar(axUS, 'eastoutside');
    c_us.Label.String = 'Temperature (°C)';
    c_us.Label.FontWeight = 'bold'; 
    c_us.Label.FontSize = 14;

    out_file_us = fullfile(out_dir, 'Figure1a_US_MapLocs.png');
    exportgraphics(f2, out_file_us, 'Resolution', 300);
    disp(['Figure saved as ', out_file_us]);
end
