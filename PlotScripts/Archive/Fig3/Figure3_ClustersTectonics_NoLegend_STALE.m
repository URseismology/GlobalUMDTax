function Figure3_ClustersTectonics_Draft()
    clear; close all; clc;

    addpath('../../Data/m_map');
    
    %% 1. Data Loading
    disp('Loading Data...');
    S1 = shaperead('../../Data/ContinentCoastlines/ne_110m_coastline/ne_110m_coastline.shp');
    res_dir = '../../Data/MachineLearningData/rf_global_clustering/results';
    meta_dir = '../../Data/MachineLearningData/rf_global_clustering/data';
    
    Data_Global_RF_Meta = readtable(fullfile(meta_dir, 'Data_Global_R1Meta.csv'));
    Data_Global_RF_ML = readtable(fullfile(res_dir, 'clustered_data_Neg_CAM22.csv'));
    
    Data_Global_RF = Data_Global_RF_Meta;
    Data_Global_RF.GMM_k4 = Data_Global_RF_ML.GMM_k4;
    Data_Global_RF.Category = Data_Global_RF_ML.Category;
    Data_Global_RF.Checkname  = Data_Global_RF_ML.StationName;
    Data_Global_RF.TectonicType  = Data_Global_RF_ML.TectonicType;
    Data_Global_RF.Neg_Depth = Data_Global_RF_ML.Neg_Depth;

    %% 2. Tectonic Map Loading & Ocean Masking
    disp('Loading Tectonic Map...');
    TecRegnfile = "../../Data/TectonicRegionalization/SL2013sv_TectRegn_2d/SL2013sv_Cluster_2d";
    TecRegn = load(TecRegnfile); 
    F_TecReg = scatteredInterpolant(TecRegn(:,1),TecRegn(:,2),TecRegn(:,3),'nearest', 'none');
    
    % Use Votemap grid to perfectly align with maskocean
    votmap1 = load('../../Data/GlobalVs_Models/votemap_100_km.mat');
    xq = double(votmap1.xq);
    yq = double(votmap1.yq);
    
    TecRegMap = F_TecReg(xq,yq); 
    
    % Apply Ocean Mask
    maskocean = load('../../Data/maskocean.mat').maskocean;
    TecRegMap(maskocean) = NaN;
    
    %% 3. CAM-22 LAB Loading for Residuals
    disp('Loading CAM-22 LAB...');
    CAM22_LAB_FILE = '../../Data/Velocity_Models/CAM2022-lithosphere.r0.0.nc';
    cam_info = ncinfo(CAM22_LAB_FILE); cam_vars = {cam_info.Variables.Name};
    cam_lon_var = cam_vars{contains(cam_vars, 'lon', 'IgnoreCase', true)};
    cam_lat_var = cam_vars{contains(cam_vars, 'lat', 'IgnoreCase', true)};
    cam_lon = ncread(CAM22_LAB_FILE, cam_lon_var);
    cam_lat = ncread(CAM22_LAB_FILE, cam_lat_var);
    cam_lab_grid = ncread(CAM22_LAB_FILE, 'thickness');
    
    [CAM_LON, CAM_LAT] = ndgrid(cam_lon, cam_lat);
    CAM_LON(CAM_LON > 180) = CAM_LON(CAM_LON > 180) - 360;
    F_LAB_CAM = scatteredInterpolant(double(CAM_LON(:)), double(CAM_LAT(:)), double(cam_lab_grid(:)), 'linear', 'none');
    
    Data_Global_RF.CAM22_LAB = F_LAB_CAM(Data_Global_RF.Longitude, Data_Global_RF.Latitude);
    Data_Global_RF.Residual = Data_Global_RF.Neg_Depth - Data_Global_RF.CAM22_LAB;

    %% 4. Settings
    PAPER_TO_ML = [2, 3, 0, 1]; 
    PAPER_COLORS = {[0.8, 0.1, 0.1], [0.1, 0.3, 0.8], [0.1, 0.6, 0.3], [0.0, 0.0, 0.0]};
    PAPER_SHAPES = {'o', '^', 's', 'd'}; % Match Fig1a shapes explicitly
    C_NAMES = {'C1 (Melt)', 'C2 (Rheological)', 'C3 (Metasomatic)', 'C4 (Structural)'};
    
    % Original Tectonic Map Colors (ensuring index 1 aligns with Cratons)
    cmapTec = zeros(7, 3);
    cmapTec(1,:) = [0 0 0]; 
    cmapTec(2,:) = [0.5020    0.5020    0.5020];
    cmapTec(3,:) = [1.0000    0.8500    0.3000]; % P (Yellowish)
    cmapTec(4,:) = [1.0000    0.5500    0.0500]; % R&B (Orange)
    cmapTec(5,:) = [0.8000    0.8000    0.8000];
    cmapTec(6,:) = [1.0       1.0       1.0];
    cmapTec(7,:) = [0.95      0.95      0.95];
    
    TEC_NAMES = {'C', 'PB&MC', 'P', 'R&B', 'O', 'Old O'};
    
    psz = 80;

    %% 5. Plotting Figure (Left-Right Layout)
    f = figure('Position', [50, 50, 2000, 1200], 'Color', 'w');
    
    % --- LEFT 60%: MAPS (Tiled Horizontally) ---
    y_map = 0.12; h_map = 0.80;
    
    % Map 1: Americas
    ax_map1 = axes('Position', [0.02, y_map, 0.212, h_map]);
    m_proj('miller','lat',[-60 80],'lon',[-135 -20]); 
    draw_map_panel(ax_map1, xq, yq, TecRegMap, cmapTec, S1, Data_Global_RF, PAPER_TO_ML, PAPER_COLORS, PAPER_SHAPES, psz, [-135, -20]);
    
    % C4 Inset Map (Global) embedded inside Americas Map
    ax_inset = axes('Position', [0.063, 0.548, 0.169, 0.372]); % Flush top-right, size increased 30%
    m_proj('robinson', 'long', [-180 180]); hold(ax_inset, 'on');
    m_pcolor(xq, yq, TecRegMap); shading flat;
    for ic = 1:length(S1), m_line(S1(ic).X, S1(ic).Y, 'color', 'k', 'linewidth', 0.5); end
    plot_plate_boundaries();
    df_c4 = Data_Global_RF(Data_Global_RF.GMM_k4 == 1, :);
    if height(df_c4) > 0
        m_scatter(df_c4.Longitude, df_c4.Latitude, psz*0.2, 'd', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 1.0); % Reduced symbol size
    end
    colormap(ax_inset, cmapTec); caxis(ax_inset, [1 7]);
    m_grid('linestyle', 'none', 'ytick', [], 'xtick', [], 'box', 'on', 'backcolor', 'w');
    
    % Map 2: Africa & Europe
    ax_map2 = axes('Position', [0.232, y_map, 0.148, h_map]);
    m_proj('miller','lat',[-60 80],'lon',[-20 60]); 
    draw_map_panel(ax_map2, xq, yq, TecRegMap, cmapTec, S1, Data_Global_RF, PAPER_TO_ML, PAPER_COLORS, PAPER_SHAPES, psz, [-20, 60]);
    
    % Map 3: Asia & Oceania
    ax_map3 = axes('Position', [0.380, y_map, 0.220, h_map]);
    m_proj('miller','lat',[-60 80],'lon',[60 179]); 
    draw_map_panel(ax_map3, xq, yq, TecRegMap, cmapTec, S1, Data_Global_RF, PAPER_TO_ML, PAPER_COLORS, PAPER_SHAPES, psz, [60, 179]);
    
    % Colorbar for Maps
    cb_ax = axes('Position', [0.02, 0.07, 0.58, 0.04]);
    colormap(cb_ax, cmapTec); caxis(cb_ax, [1 7]);
    h_cb = colorbar(cb_ax, 'south', 'FontSize', 12);
    axis(cb_ax, 'off');
    h_cb.Ticks = 1.5:1:6.5; h_cb.TickLabels = TEC_NAMES;
    ylabel(h_cb, 'Tectonic Regionalization Model (SL2013sv)', 'FontWeight', 'bold', 'FontSize', 14);
    
    % Add Tectonic Code Legend Annotation underneath colorbar
    annotation('textbox', [0.02, 0.025, 0.58, 0.035], 'String', ...
        'Tectonic Codes: C = Cratons, PB&MC = Precambrian Belts & Modified Cratons, P = Phanerozoic, R&B = Ridges & Backarcs, O = Oceanic, Old O = Old Oceanic', ...
        'FontSize', 12, 'LineStyle', 'none', 'BackgroundColor', 'none', 'HorizontalAlignment', 'center');

    % --- RIGHT 40%: STATS (2x2 Grid) ---
    w_col = 0.16; 
    
    % Row Y-positions
    y_boxes = [0.52, 0.10];
    y_bars  = [0.78, 0.36];
    h_box = 0.25; h_bar = 0.11;
    
    c_order = [2, 1, 3, 4]; % Col 1 (C2, C1), Col 2 (C3, C4)
    
    for i = 1:4
        c = c_order(i);
        ml_id = PAPER_TO_ML(c);
        idx_c = find(Data_Global_RF.GMM_k4 == ml_id);
        df_c = Data_Global_RF(idx_c, :);
        
        if i <= 2
            x_col = 0.63;
        else
            x_col = 0.82;
        end
        
        if mod(i, 2) == 1
            row = 1;
        else
            row = 2;
        end
        
        % Bar Plot
        ax_bar = axes('Position', [x_col, y_bars(row), w_col, h_bar]); hold(ax_bar, 'on');
        counts = histcounts(df_c.TectonicType, 0.5:1:6.5);
        pcts = counts / sum(counts) * 100;
        for t = 1:6
            b = bar(ax_bar, t, counts(t), 'FaceColor', cmapTec(t, :), 'EdgeColor', 'k', 'LineWidth', 1.5);
            if counts(t) > 0
                text(ax_bar, t, counts(t) + max(counts)*0.05, sprintf('%.0f%%', pcts(t)), 'HorizontalAlignment', 'center', 'FontSize', 10);
            end
        end
        xlim(ax_bar, [0.5 6.5]); ylim(ax_bar, [0, max(max(counts)*1.25, 1)]);
        set(ax_bar, 'XTick', [], 'FontSize', 12, 'LineWidth', 1.5);
        if i <= 2, ylabel(ax_bar, 'Count', 'FontWeight', 'bold'); end
        title(ax_bar, C_NAMES{c}, 'FontSize', 16, 'Color', PAPER_COLORS{c});
        box(ax_bar, 'on');
        
        % Box Plot
        ax_box = axes('Position', [x_col, y_boxes(row), w_col, h_box]); hold(ax_box, 'on');
        valid = ~isnan(df_c.Residual) & ~isnan(df_c.TectonicType) & (df_c.TectonicType >= 1 & df_c.TectonicType <= 6);
        res_valid = df_c.Residual(valid);
        tec_valid = df_c.TectonicType(valid);
        
        if ~isempty(res_valid)
            cat_tec = categorical(tec_valid, 1:6, TEC_NAMES);
            bc = boxchart(ax_box, cat_tec, res_valid, 'GroupByColor', cat_tec, 'MarkerStyle', 'o', 'BoxWidth', 0.7);
            for t = 1:length(bc)
                if t <= 6
                    bc(t).BoxFaceColor = cmapTec(t, :);
                    bc(t).BoxFaceAlpha = 1.0;
                    bc(t).BoxEdgeColor = 'k';
                    bc(t).BoxMedianLineColor = 'k';
                    bc(t).WhiskerLineColor = 'k';
                    bc(t).MarkerColor = cmapTec(t, :);
                    bc(t).MarkerStyle = 'o';
                    bc(t).MarkerSize = 4;
                    bc(t).LineWidth = 1.5;
                end
            end
        end
        
        yline(ax_box, 0, 'r--', 'LineWidth', 2);
        for yl = -200:100:200, yline(ax_box, yl, 'k:', 'LineWidth', 1); end
        
        ylim(ax_box, [-200 200]);
        set(ax_box, 'FontSize', 12, 'LineWidth', 1.5);
        if row == 2
            xtickangle(ax_box, 45);
        else
            set(ax_box, 'XTickLabel', []);
        end
        if i <= 2, ylabel(ax_box, 'Residual: Seismic - Thermal LAB (km)', 'FontWeight', 'bold'); end
        box(ax_box, 'on');
    end
    
    out_dir = '../../Figures/Global_Study'; if ~isfolder(out_dir), mkdir(out_dir); end
    exportgraphics(f, fullfile(out_dir, 'Figure3_ClustersTectonics_Draft.png'), 'Resolution', 300);
end

function draw_map_panel(ax, xq, yq, TecRegMap, cmapTec, S1, df, PAPER_TO_ML, PAPER_COLORS, PAPER_SHAPES, psz, lon_bounds)
    hold(ax, 'on');
    m_pcolor(xq, yq, TecRegMap);
    shading flat;
    
    for ic = 1:length(S1)      
        m_line(S1(ic).X, S1(ic).Y, 'color', 'k', 'linewidth', 1.5);  
    end
    plot_plate_boundaries();
    
    % Filter df to strictly inside lon_bounds to prevent edge clipping
    in_lon = df.Longitude >= lon_bounds(1) & df.Longitude <= lon_bounds(2);
    df_map = df(in_lon, :);
    
    for p = 1:3
        ml_id = PAPER_TO_ML(p);
        idx = (df_map.GMM_k4 == ml_id);
        df_sub = df_map(idx, :);
        
        if height(df_sub) > 0
            % Find symbols inside the US box to reduce their size
            in_us = df_sub.Longitude >= -125 & df_sub.Longitude <= -65 & df_sub.Latitude >= 25 & df_sub.Latitude <= 50;
            s = repmat(psz, height(df_sub), 1);
            s(in_us) = psz * 0.5;
            
            % White face, colored edge, mapped strictly to Cluster ID (PAPER_SHAPES)
            m_scatter(df_sub.Longitude, df_sub.Latitude, s, PAPER_SHAPES{p}, ...
                'MarkerFaceColor', 'w', 'MarkerEdgeColor', PAPER_COLORS{p}, 'LineWidth', 1.5); 
        end
    end
    
    colormap(ax, cmapTec);
    caxis(ax, [1 7]);
    m_grid('linestyle', '-', 'ytick', [], 'xtick', [], 'tickdir', 'out', 'linewi', 1.5, 'gridcolor', 'k', 'backcolor', 'w');
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
