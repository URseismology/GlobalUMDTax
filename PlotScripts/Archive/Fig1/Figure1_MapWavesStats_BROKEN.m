function Figure1_MapWavesStats()
    clear; close all; clc;

    %% 0. Global Parameters for Easy Tweaking

    % Font Sizes
    FONT_SIZE_LEGEND = 25;
    FONT_SIZE_CBAR = 20;
    FONT_SIZE_INSET_CBAR = 10;
    CFG.font_tick = 20;
    CFG.font_label = 30;
    CFG.font_title = 20;
    
    % Symbol Sizes
    SYM_SIZE_MAIN = 40;
    SYM_SIZE_US = 40;
    SYM_SIZE_LEGEND = 70;
    SYM_SIZE_LEGEND_US = 80;
    NA_SYMBOL_SCALE = 0.5;
    
    % Craton Line Properties
    CRATON_COLOR = [0.4 0.2 0.0];
    BEDLE_LINEWIDTH = 1.0;
    PEARSON_LINEWIDTH = 1.5;
    BEDLE_LINEWIDTH_INSET = 0.5;
    PEARSON_LINEWIDTH_INSET = 1.25;
    
    % Waveform Labels
    LABEL_C1 = '\color{red}C1';
    LABEL_C2 = '\color{blue}C2';
    LABEL_C3 = '\color{green}C3';
    LABEL_C4 = '\color{black}C4';
    LABEL_X_SCATTER = '';
    LABEL_X_WAVE = 'Depth (km)';
    LABEL_Y_WAVE = 'Station Index';
    
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
    
    
    % Alias variables for Waveforms/Scatter section
    seismic_depth = st_depth;
    gmm_k4 = st_c;

%% 2. Load CAM-22 LAB Data
    disp('Loading CAM-22 LAB Data...');
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
        st_cam_lab = F_LAB_CAM(st_lon, st_lat);
    else
        cam_lon(cam_lon > 180) = cam_lon(cam_lon > 180) - 360;
        F_LAB_CAM = scatteredInterpolant(double(cam_lon(:)), double(cam_lat(:)), double(cam_lab_grid(:)), 'linear', 'none');
        st_cam_lab = F_LAB_CAM(st_lon, st_lat);
    end
    
    % Setup Clusters
    idx_c1 = find(gmm_k4 == 2);
    idx_c2 = find(gmm_k4 == 3);
    idx_c3 = find(gmm_k4 == 0);
    idx_c4 = find(gmm_k4 == 1);
    
    c_indices = {idx_c1, idx_c2, idx_c3, idx_c4};
    c_colors = {[0.8, 0.1, 0.1], [0.1, 0.3, 0.8], [0.1, 0.6, 0.3], [0.0, 0.0, 0.0]}; % C1, C2, C3, C4
    
    c_red   = c_colors{1};
    c_blue  = c_colors{2};
    c_green = c_colors{3};
    c_black = c_colors{4};
    
    
    %% Setup Combined Figure
    % Total size = 1400 x 1600 (900 for Map + 700 for Waveforms)
    f = figure('Name', 'Figure 1: Map and Waveforms', 'Position', [100, 100, 1400, 1600], 'Color', 'w', 'Visible', 'off');


    function plot_locs_c123(psz, bbox, apply_na_scale)
        if nargin < 1, psz = 15; end
        if nargin < 2, bbox = [-180 180 -90 90]; end
        if nargin < 3, apply_na_scale = false; end
        
        function plot_c(indices, marker, edge_color)
            lons = st_lon(indices);
            lats = st_lat(indices);
            in_box = lons >= bbox(1) & lons <= bbox(2) & lats >= bbox(3) & lats <= bbox(4);
            if any(in_box)
                sz = repmat(psz, size(lons));
                if apply_na_scale
                    in_NA = lons >= -170 & lons <= -50 & lats >= 15 & lats <= 85;
                    sz(in_NA) = psz * NA_SYMBOL_SCALE;
                end
                m_scatter(lons(in_box), lats(in_box), sz(in_box), marker, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', edge_color, 'LineWidth', 1.0);
            end
        end
        
        % C1: Red circle
        plot_c(idx_c1, 'o', [0.8 0.1 0.1]);
        % C2: Blue triangle
        plot_c(idx_c2, '^', [0.1 0.3 0.8]);
        % C3: Green square
        plot_c(idx_c3, 's', [0.1 0.6 0.3]);
    end

    function plot_locs_c4(psz, bbox, apply_na_scale)
        if nargin < 1, psz = 15; end
        if nargin < 2, bbox = [-180 180 -90 90]; end
        if nargin < 3, apply_na_scale = false; end
        
        lons = st_lon(idx_c4);
        lats = st_lat(idx_c4);
        in_box = lons >= bbox(1) & lons <= bbox(2) & lats >= bbox(3) & lats <= bbox(4);
        if any(in_box)
            sz = repmat(psz, size(lons));
            if apply_na_scale
                in_NA = lons >= -170 & lons <= -50 & lats >= 15 & lats <= 85;
                sz(in_NA) = psz * NA_SYMBOL_SCALE;
            end
            m_scatter(lons(in_box), lats(in_box), sz(in_box), 'd', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 1.0);
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

    function plot_bedle_cratons(lw)
        if nargin < 1, lw = BEDLE_LINEWIDTH; end
        kml_dir = '../../Data/GeologicalData/BedleCratons';
        kml_files = dir(fullfile(kml_dir, '*.kml'));
        for i = 1:length(kml_files)
            filename = fullfile(kml_dir, kml_files(i).name);
            str = fileread(filename);
            idx1 = strfind(str, '<coordinates>');
            idx2 = strfind(str, '</coordinates>');
            if ~isempty(idx1) && ~isempty(idx2)
                coord_str = str(idx1(1)+13:idx2(1)-1);
                C = textscan(coord_str, '%f,%f,%f');
                lon = C{1}; lat = C{2};
                if length(lon) > 1
                    m_line(lon, lat, 'color', CRATON_COLOR, 'linewidth', lw);
                end
            end
        end
    end

    function plot_pearson_cratons(lw)
        if nargin < 1, lw = PEARSON_LINEWIDTH; end
        kml_dir = '../PearsonCratons/digitization';
        kml_files = dir(fullfile(kml_dir, '*.kml'));
        for i = 1:length(kml_files)
            filename = fullfile(kml_dir, kml_files(i).name);
            str = fileread(filename);
            idx1 = strfind(str, '<coordinates>');
            idx2 = strfind(str, '</coordinates>');
            if ~isempty(idx1) && ~isempty(idx2)
                coord_str = str(idx1(1)+13:idx2(1)-1);
                C = textscan(coord_str, '%f,%f,%f');
                lon = C{1}; lat = C{2};
                if length(lon) > 1
                    m_line(lon, lat, 'color', CRATON_COLOR, 'linewidth', lw);
                end
            end
        end
    end

    %% Main Panel (100km Temp)
    disp('Plotting Main Panel...');
    axMain = axes('Position', [0.05, 0.49375, 0.9, 0.45]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    
    hMain = m_pcolor(xq, yq, Temp_100_Grid); shading flat;
    set(hMain, 'FaceAlpha', 0.85); % Slightly transparent
    
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    plot_bedle_cratons();
    plot_pearson_cratons();
    
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
    plot_locs_c123(SYM_SIZE_MAIN, [-180 180 -90 90], true);
    
    % Add dummy points for legend (outside visible area)
    hC1 = scatter(axMain, NaN, NaN, SYM_SIZE_LEGEND, 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.8 0.1 0.1], 'LineWidth', 1.0);
    hC2 = scatter(axMain, NaN, NaN, SYM_SIZE_LEGEND, '^', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.1 0.3 0.8], 'LineWidth', 1.0);
    hC3 = scatter(axMain, NaN, NaN, SYM_SIZE_LEGEND, 's', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.1 0.6 0.3], 'LineWidth', 1.0);
    hC4 = scatter(axMain, NaN, NaN, SYM_SIZE_LEGEND, 'd', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 1.0);
    
    % Move legend to be centered on Hawaii
    lgd = legend(axMain, [hC1, hC2, hC3, hC4], {'\color{red}C1 (Melt)', '\color{blue}C2 (Rheological)', '\color{green}C3 (Metasomatic)', '\color{black}C4 (Deep)'}, 'FontSize', FONT_SIZE_LEGEND, 'FontWeight', 'bold');
    set(lgd, 'Position', [0.12, 0.52, 0.06, 0.12]); % Centered on Hawaii
    
    % Move colorbar to the right of Japan (in the NW Pacific Ocean)
    c = colorbar(axMain, 'Position', [0.86, 0.55, 0.015, 0.3]);
    c.Label.String = 'Temperature (°C)';
    c.Label.FontWeight = 'bold'; 
    c.Label.FontSize = FONT_SIZE_CBAR;

    %% Inset Panel (200km Temp)
    disp('Plotting Inset Panel...');
    % Move the inset ~20% higher
    axInset = axes('Position', [0.03, 0.566875, 0.28, 0.1575]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, Temp_200_Grid); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 0.5);
    m_grid('linestyle', 'none', 'box', 'on', 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    plot_bedle_cratons(BEDLE_LINEWIDTH_INSET);
    plot_pearson_cratons(PEARSON_LINEWIDTH_INSET);
    
    % Accentuate details between 1200 and 1400 deg C using the consistent colormap
    % Extract the slice of the main colormap that corresponds to 1200-1400 C
    idx_1200 = max(1, round(256 * ((1200 - 300) / 1200)));
    idx_1400 = min(256, round(256 * ((1400 - 300) / 1200)));
    cmap_inset = custom_cmap_main(idx_1200:idx_1400, :);
    
    colormap(axInset, cmap_inset); 
    caxis(axInset, [1200 1400]);
    plot_locs_c4(SYM_SIZE_MAIN, [-180 180 -90 90], true);
    
    % Add colorbar for inset (small, vertical, placed in the Pacific region)
    % Shifted slightly to the right to sit squarely in the Pacific.
    c_in = colorbar(axInset, 'Position', [0.075, 0.595, 0.008, 0.084375]);
    c_in.Label.String = 'Temp (°C)';
    c_in.Label.FontWeight = 'bold';
    c_in.Label.FontSize = FONT_SIZE_INSET_CBAR;

    
    % Panel (a) Label
    annotation(f, 'textbox', [0.04, 0.94, 0.05, 0.05], 'String', '(a)', 'EdgeColor', 'none', 'FontSize', 30, 'FontWeight', 'bold');


    h_main = 0.144375;
    w_main = 0.1285;
    h_marg = 0.021875000000000002;
    w_marg = 0.02;
    
    % Positions
    py_top = 0.240625;
    py_bot = 0.0525;
    
    % A. Top Row (C2/C3 waveforms and scatter on the right)
    disp('Plotting Top Row Waveforms and Scatter...');
    
    % Waveforms (C2 and C3): show x-tick labels for C2
    ax_c2 = subplot('Position', [0.08, py_top, 0.33, h_main]);
    plotwaveforms(ax_c2, '../../Data/MachineLearningData/RFs/sequenced_cluster3.mat', c_blue, LABEL_C2, true, true, false, CFG, LABEL_X_WAVE, LABEL_Y_WAVE);
    annotation(f, 'textbox', [0.08, py_top+0.0044, 0.05, 0.05], 'String', '(b)', 'EdgeColor', 'none', 'FontSize', CFG.font_title, 'FontWeight', 'bold');
    
    ax_c3 = subplot('Position', [0.43, py_top, 0.33, h_main]);
    plotwaveforms(ax_c3, '../../Data/MachineLearningData/RFs/sequenced_cluster0.mat', c_green, LABEL_C3, false, true, false, CFG, LABEL_X_WAVE, LABEL_Y_WAVE);
    annotation(f, 'textbox', [0.43, py_top+0.0044, 0.05, 0.05], 'String', '(c)', 'EdgeColor', 'none', 'FontSize', CFG.font_title, 'FontWeight', 'bold');
    
    % Scatter on the right (C2/C3) - histogram on top, reduced horizontal space (px = 0.77), show x-tick labels
    px_top_s = 0.77;
    main_ax_top = axes('Position', [px_top_s, py_top, w_main, h_main]);
    top_ax_top  = axes('Position', [px_top_s, py_top + h_main + 0.0044, w_main, h_marg]);
    right_ax_top = axes('Position', [px_top_s + w_main + 0.005, py_top, w_marg, h_main]);
    
    plotjointkde(main_ax_top, top_ax_top, right_ax_top, st_cam_lab, seismic_depth, c_indices, c_colors, [2, 3], true, true, true, CFG, LABEL_X_SCATTER);
    annotation(f, 'textbox', [px_top_s, py_top+0.0044, 0.05, 0.05], 'String', '(f)', 'EdgeColor', 'none', 'FontSize', CFG.font_title, 'FontWeight', 'bold');
    
    % B. Bottom Row (C1/C4 waveforms and scatter on the right)
    disp('Plotting Bottom Row Waveforms and Scatter...');
    
    % Waveforms (C1 and C4): show y-tick labels and y-label for both C1 and C4
    ax_c1 = subplot('Position', [0.08, py_bot, 0.33, h_main]);
    plotwaveforms(ax_c1, '../../Data/MachineLearningData/RFs/sequenced_cluster2.mat', c_red, LABEL_C1, true, true, true, CFG, LABEL_X_WAVE, LABEL_Y_WAVE);
    annotation(f, 'textbox', [0.08, py_bot+0.0044, 0.05, 0.05], 'String', '(d)', 'EdgeColor', 'none', 'FontSize', CFG.font_title, 'FontWeight', 'bold');
    
    ax_c4 = subplot('Position', [0.43, py_bot, 0.33, h_main]);
    plotwaveforms(ax_c4, '../../Data/MachineLearningData/RFs/sequenced_cluster1.mat', c_black, LABEL_C4, false, true, true, CFG, LABEL_X_WAVE, LABEL_Y_WAVE);
    annotation(f, 'textbox', [0.43, py_bot+0.0044, 0.05, 0.05], 'String', '(e)', 'EdgeColor', 'none', 'FontSize', CFG.font_title, 'FontWeight', 'bold');
    
    % Scatter on the right (C1/C4) - histogram on bottom, remove x-label, reduced horizontal space (px = 0.77), remove x-tick labels
    px_bot_s = 0.77;
    main_ax_bot = axes('Position', [px_bot_s, py_bot, w_main, h_main]);
    top_ax_bot  = axes('Position', [px_bot_s, py_bot - h_marg - 0.0044, w_main, h_marg]);
    right_ax_bot = axes('Position', [px_bot_s + w_main + 0.005, py_bot, w_marg, h_main]);
    
    plotjointkde(main_ax_bot, top_ax_bot, right_ax_bot, st_cam_lab, seismic_depth, c_indices, c_colors, [1, 4], false, false, false, CFG, LABEL_X_SCATTER);
    annotation(f, 'textbox', [px_bot_s, py_bot+0.0044, 0.05, 0.05], 'String', '(g)', 'EdgeColor', 'none', 'FontSize', CFG.font_title, 'FontWeight', 'bold');
    
    title(main_ax_bot, 'Thermal LAB (km)', 'FontSize', CFG.font_title, 'FontWeight', 'bold');
    
    
    %% Save Combined Figure
    out_dir = '../../Figures/Global_Study';
    if ~isfolder(out_dir), mkdir(out_dir); end
    out_file = fullfile(out_dir, 'Figure1_MapWavesStats.png');
    exportgraphics(f, out_file, 'Resolution', 300);
    disp(['Figure saved as ', out_file]);
end

function plotjointkde(main_ax, top_ax, right_ax, x_all, y_all, c_indices, c_colors, cluster_ids, show_xlabel, hist_on_top, show_xticklabels, CFG, LABEL_X_SCATTER)
    % Plot 1:1 reference line on main axis
    hold(main_ax, 'on');
    plot(main_ax, [10 300], [10 300], 'r--', 'LineWidth', 1.5);
    
    hold(top_ax, 'on');
    hold(right_ax, 'on');
    
    max_density_x = 0;
    max_density_y = 0;
    
    for cluster_id = cluster_ids
        x_data = x_all(c_indices{cluster_id});
        y_data = y_all(c_indices{cluster_id});
        
        valid = ~isnan(x_data) & ~isnan(y_data);
        x_data = x_data(valid);
        y_data = y_data(valid);
        
        if length(x_data) < 5, continue; end
        
        % 1. Plot Scatter on main axis with 2D KDE density
        try
            f_density = ksdensity([x_data, y_data], [x_data, y_data]);
            f_norm = (f_density - min(f_density)) / (max(f_density) - min(f_density) + eps);
            f_norm = 0.2 + 0.8 * f_norm; 
            C_rgb = (1 - f_norm) * [0.9 0.9 0.9] + f_norm * c_colors{cluster_id};
            scatter(main_ax, x_data, y_data, 15, C_rgb, 'filled', 'MarkerFaceAlpha', 0.7, 'MarkerEdgeColor', 'none');
        catch
            scatter(main_ax, x_data, y_data, 15, c_colors{cluster_id}, 'filled', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none');
        end
        
        % 2. Plot 1D Marginals on top/bottom axis
        [f_x, xi_x] = ksdensity(x_data, 'Support', [0, 400]);
        fill(top_ax, xi_x, f_x, c_colors{cluster_id}, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
        plot(top_ax, xi_x, f_x, '-', 'Color', c_colors{cluster_id}, 'LineWidth', 1.5);
        max_density_x = max(max_density_x, max(f_x));
        
        % 3. Plot 1D Marginals on right axis
        [f_y, xi_y] = ksdensity(y_data, 'Support', [0, 400]);
        fill(right_ax, f_y, xi_y, c_colors{cluster_id}, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
        plot(right_ax, f_y, xi_y, '-', 'Color', c_colors{cluster_id}, 'LineWidth', 1.5);
        max_density_y = max(max_density_y, max(f_y));
    end
    
    % Style main axis
    xlim(main_ax, [10 300]);
    ylim(main_ax, [10 300]);
    box(main_ax, 'on');
    grid(main_ax, 'on');
    
    if show_xlabel
        xlabel(main_ax, LABEL_X_SCATTER, 'FontSize', CFG.font_label, 'FontWeight', 'bold');
    else
        xlabel(main_ax, '');
    end
    ylabel(main_ax, ''); % Omit Y-label
    
    % Flip Y-axis so depth increases downward (matching the waveforms)
    set(main_ax, 'YDir', 'reverse');
    
    % Force X-axis to the bottom explicitly
    set(main_ax, 'XAxisLocation', 'bottom');
    
    % Hide Y-tick labels on the rightmost panels (scatter plots)
    set(main_ax, 'YTickLabel', []);
    
    if ~show_xticklabels
        set(main_ax, 'XTickLabel', []);
    end
    
    set(main_ax, 'linewidth', 1.5, 'fontsize', CFG.font_tick);
    
    % Style top/bottom marginal axis
    xlim(top_ax, [10 300]);
    if max_density_x > 0
        ylim(top_ax, [0 max_density_x * 1.1]);
    end
    
    % If histogram is on bottom, we can invert its Y-axis so it plots downwards
    if ~hist_on_top
        set(top_ax, 'YDir', 'reverse');
    end
    axis(top_ax, 'off');
    
    % Style right marginal axis
    ylim(right_ax, [10 300]);
    if max_density_y > 0
        xlim(right_ax, [0 max_density_y * 1.1]);
    end
    set(right_ax, 'YDir', 'reverse');
    axis(right_ax, 'off');
end

function plotwaveforms(ax_handle, RF_file_path, color_theme, title_str, show_depth_labels, show_yticklabels, show_ylabel, CFG, LABEL_X_WAVE, LABEL_Y_WAVE)
    axes(ax_handle);
    hold on;
    
    data = load(RF_file_path);
    RFs = data.rf_matrix_sorted;
    t = data.time_vector;
    
    for ii = 1:size(RFs,1)
        trace = RFs(ii, :) - mean(RFs(ii, :));
        trace_norm = trace / max(abs(trace));
        zeroLine = ii * ones(size(t));
        yvals = trace_norm + ii;
        
        negatives = trace_norm < 0;
        positives = trace_norm > 0;

        jbfill(t(positives), yvals(positives), zeroLine(positives), [0 0 1], 'none', 1, 1.0);
        jbfill(t(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], 'none', 1, 1.0);
    end
    
    ylim([0 size(RFs,1)]);
    xlim([6 max(t)]);
    xticks([6, 10:5:30]); 
    xticklabels([60, 100:50:300]);
    
    if show_ylabel
        ylabel(LABEL_Y_WAVE, 'FontSize', CFG.font_label, 'FontWeight', 'bold');
    else
        ylabel('');
    end
    
    if show_yticklabels
        % Keep tick labels visible
    else
        set(ax_handle, 'YTickLabel', []);
    end
    
    if show_depth_labels
        xlabel(LABEL_X_WAVE, 'FontSize', CFG.font_label, 'FontWeight', 'bold');
    else
        xlabel('');
        set(ax_handle, 'XTickLabel', []);
    end
    
    title(title_str, 'FontSize', CFG.font_title, 'FontWeight', 'bold', 'Interpreter', 'tex');
    box on;
    
    set(gca, 'linewidth', 2, 'fontsize', CFG.font_tick, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YAxisLocation', 'right', 'XColor', color_theme, 'YColor', color_theme);
    
    ax = gca;
    ax.XAxis.TickLabelColor = [0 0 0]; 
    ax.YAxis.TickLabelColor = [0 0 0];
    ax.XAxis.Label.Color = [0 0 0];
    ax.YAxis.Label.Color = [0 0 0];
    
    camroll(270);
end
