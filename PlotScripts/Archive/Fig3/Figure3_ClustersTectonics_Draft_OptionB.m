function Figure3_ClustersTectonics_Draft_OptionB()
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
    
    Data_Global_RF.TectonicType(Data_Global_RF.TectonicType == 6) = 5;

    %% 2. Tectonic Map Loading
    disp('Loading Tectonic Map...');
    TecRegnfile = "../../Data/TectonicRegionalization/SL2013sv_TectRegn_2d/SL2013sv_Cluster_2d";
    TecRegn = load(TecRegnfile); 
    F_TecReg = scatteredInterpolant(TecRegn(:,1),TecRegn(:,2),TecRegn(:,3),'nearest', 'none');
    
    longridinterp = -180:0.5:180; latgridinterp = -90:0.5:90;
    [yq,xq] = meshgrid(latgridinterp,longridinterp);
    TecRegMap = F_TecReg(xq,yq); 
    
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
    C_NAMES = {'C1 (Melt)', 'C2 (Rheological)', 'C3 (Metasomatic)', 'C4 (Structural)'};
    
    % Pastel Colors for Tectonic Map
    cmapTec = zeros(7, 3);
    cmapTec(1,:) = [0 0 0]; 
    cmapTec(2,:) = [0.85, 0.75, 0.60]; 
    cmapTec(3,:) = [0.85, 0.85, 0.85]; 
    cmapTec(4,:) = [0.95, 0.90, 0.70]; 
    cmapTec(5,:) = [0.70, 0.90, 0.90]; 
    cmapTec(6,:) = [0.75, 0.80, 0.90]; 
    cmapTec(7,:) = [0.95, 0.95, 0.95]; 
    
    TEC_NAMES = {'Cratons', 'Precambrian', 'Phanerozoic', 'Ridges/Backarcs', 'Oceanic', 'Old Oceanic'};
    
    psz = 80;

    %% 5. Plotting (Option B Layout: 1x4 stacked vertical)
    f = figure('Position', [50, 50, 1800, 1200], 'Color', 'w');
    
    % --- TOP HALF: Maps ---
    w_map = 0.28; h_map = 0.40; y_map = 0.55;
    
    ax_map1 = axes('Position', [0.04, y_map, w_map, h_map]);
    m_proj('miller','lat',[-60 55],'lon',[-135 -20]); 
    draw_map_panel(ax_map1, xq, yq, TecRegMap, cmapTec, S1, Data_Global_RF, PAPER_TO_ML, PAPER_COLORS, psz);
    
    ax_map2 = axes('Position', [0.34, y_map, w_map, h_map]);
    m_proj('miller','lat',[-38 75],'lon',[-20 60]); 
    draw_map_panel(ax_map2, xq, yq, TecRegMap, cmapTec, S1, Data_Global_RF, PAPER_TO_ML, PAPER_COLORS, psz);
    
    ax_map3 = axes('Position', [0.64, y_map, w_map, h_map]);
    m_proj('miller','lat',[-50 80],'lon',[60 179]); 
    draw_map_panel(ax_map3, xq, yq, TecRegMap, cmapTec, S1, Data_Global_RF, PAPER_TO_ML, PAPER_COLORS, psz);
    
    % Colorbar
    cb_ax = axes('Position', [0.34, 0.51, 0.28, 0.015]);
    colormap(cb_ax, cmapTec);
    caxis(cb_ax, [1 7]);
    h_cb = colorbar(cb_ax, 'south', 'FontSize', 12);
    axis(cb_ax, 'off');
    h_cb.Ticks = 1.5:1:6.5;
    h_cb.TickLabels = {'C', 'PB&MC', 'P', 'R&B', 'O', 'Old O'};
    ylabel(h_cb, 'Tectonic Regionalization', 'FontWeight', 'bold', 'FontSize', 14);

    % --- BOTTOM HALF: Bar & Box Plots (Stacked) ---
    w_col = 0.20; x_cols = [0.05, 0.28, 0.51, 0.74];
    h_bar = 0.12; y_bar = 0.30;
    h_box = 0.23; y_box = 0.05;
    
    for c = 1:4
        ml_id = PAPER_TO_ML(c);
        idx_c = find(Data_Global_RF.GMM_k4 == ml_id);
        df_c = Data_Global_RF(idx_c, :);
        
        % Bar Plot
        ax_bar = axes('Position', [x_cols(c), y_bar, w_col, h_bar]); hold(ax_bar, 'on');
        counts = histcounts(df_c.TectonicType, 0.5:1:6.5);
        pcts = counts / sum(counts) * 100;
        for t = 1:6
            b = bar(ax_bar, t, counts(t), 'FaceColor', cmapTec(t+1, :), 'EdgeColor', 'k', 'LineWidth', 1.5);
            if counts(t) > 0
                text(ax_bar, t, counts(t) + max(counts)*0.05, sprintf('%.0f%%', pcts(t)), 'HorizontalAlignment', 'center', 'FontSize', 10);
            end
        end
        xlim(ax_bar, [0.5 6.5]); ylim(ax_bar, [0, max(max(counts)*1.25, 1)]);
        set(ax_bar, 'XTick', [], 'FontSize', 12, 'LineWidth', 1.5);
        if c == 1, ylabel(ax_bar, 'Station Count', 'FontWeight', 'bold'); end
        title(ax_bar, C_NAMES{c}, 'FontSize', 16, 'Color', PAPER_COLORS{c});
        box(ax_bar, 'on');
        
        % Box Plot
        ax_box = axes('Position', [x_cols(c), y_box, w_col, h_box]); hold(ax_box, 'on');
        valid = ~isnan(df_c.Residual) & ~isnan(df_c.TectonicType) & (df_c.TectonicType >= 1 & df_c.TectonicType <= 6);
        res_valid = df_c.Residual(valid);
        tec_valid = df_c.TectonicType(valid);
        
        if ~isempty(res_valid)
            cat_tec = categorical(tec_valid, 1:6, TEC_NAMES);
            bc = boxchart(ax_box, cat_tec, res_valid, 'GroupByColor', cat_tec);
            for t = 1:length(bc)
                if t <= 6
                    bc(t).BoxFaceColor = cmapTec(t+1, :);
                    bc(t).MarkerColor = cmapTec(t+1, :);
                end
            end
        end
        
        yline(ax_box, 0, 'r--', 'LineWidth', 2);
        for yl = -200:100:200, yline(ax_box, yl, 'k:', 'LineWidth', 1); end
        
        ylim(ax_box, [-200 200]);
        set(ax_box, 'FontSize', 12, 'LineWidth', 1.5);
        xtickangle(ax_box, 45);
        if c == 1, ylabel(ax_box, 'Depth Residual (km)', 'FontWeight', 'bold'); end
        box(ax_box, 'on');
    end
    
    out_dir = '../../Figures/Global_Study'; if ~isfolder(out_dir), mkdir(out_dir); end
    exportgraphics(f, fullfile(out_dir, 'Figure3_ClustersTectonics_Draft_OptionB.png'), 'Resolution', 300);
end

function draw_map_panel(ax, xq, yq, TecRegMap, cmapTec, S1, df, PAPER_TO_ML, PAPER_COLORS, psz)
    hold(ax, 'on');
    m_pcolor(xq, yq, TecRegMap);
    shading flat;
    
    for ic = 1:length(S1)      
        m_line(S1(ic).X, S1(ic).Y, 'color', 'k', 'linewidth', 2);  
    end
    
    for p = 1:4
        ml_id = PAPER_TO_ML(p);
        idx = (df.GMM_k4 == ml_id);
        df_sub = df(idx, :);
        
        cat_LVD = df_sub(string(df_sub.Category) == "LVD", :);
        cat_LVL = df_sub(string(df_sub.Category) == "LVL", :);
        cat_HVL = df_sub(string(df_sub.Category) == "HVL", :);
        
        if height(cat_LVD) > 0, m_scatter(cat_LVD.Longitude, cat_LVD.Latitude, psz, 'o', 'MarkerFaceColor', PAPER_COLORS{p}, 'MarkerEdgeColor', 'k', 'LineWidth', 1.0); end
        if height(cat_LVL) > 0, m_scatter(cat_LVL.Longitude, cat_LVL.Latitude, psz, 's', 'MarkerFaceColor', PAPER_COLORS{p}, 'MarkerEdgeColor', 'k', 'LineWidth', 1.0); end
        if height(cat_HVL) > 0, m_scatter(cat_HVL.Longitude, cat_HVL.Latitude, psz, 'v', 'MarkerFaceColor', PAPER_COLORS{p}, 'MarkerEdgeColor', 'k', 'LineWidth', 1.0); end
    end
    
    colormap(ax, cmapTec);
    caxis(ax, [1 7]);
    m_grid('linestyle', '-', 'ytick', [], 'xtick', [], 'tickdir', 'out', 'linewi', 2, 'gridcolor', 'w', 'backcolor', 'w');
end
