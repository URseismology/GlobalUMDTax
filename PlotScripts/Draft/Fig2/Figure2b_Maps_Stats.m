function Figure2b_Maps_Stats()
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
    cam22_opts = detectImportOptions(fullfile(stats_dir, 'clustered_data_Neg_CAM22.csv'));
    cam22_data = readtable(fullfile(stats_dir, 'clustered_data_Neg_CAM22.csv'), cam22_opts);
    
    wint_opts = detectImportOptions(fullfile(stats_dir, 'clustered_data_Neg_WINT.csv'));
    wint_data = readtable(fullfile(stats_dir, 'clustered_data_Neg_WINT.csv'), wint_opts);
    
    %% 5. Setup Figure and Layout (4x1 grid)
    f = figure('Name', 'Figure 2b: Mantle Physical Properties at 100km', 'Position', [100, 50, 1000, 1600], 'Color', 'w', 'Visible', 'off');
    
    w_panel = 0.50;
    h_panel = 0.162; % Robinson aspect ratio vertically within 1000x1600 figure
    px_left = 0.25;
    
    % Contiguous layout positions with zero vertical gap between actual maps
    py = [0.05 + 3*h_panel, 0.05 + 2*h_panel, 0.05 + h_panel, 0.05];
    
    % Colors for inset plots
    c_cam = [0 0.4470 0.7410]; % Blue
    c_wint = [0.8500 0.3250 0.0980]; % Orange/Red
    
    % Helper function to plot boxplots in inset
    function plot_inset_box(ax_pos, y_label_str, val_cam, g_cam_raw, val_wint, g_wint_raw)
        % Subtract 1 to retrieve raw 0-3 values
        g_cam_val = g_cam_raw - 1;
        g_wint_val = g_wint_raw - 1;
        
        % Map GMM_k4 values (0->3, 1->4, 2->1, 3->2)
        g_cam = zeros(size(g_cam_val));
        g_cam(g_cam_val == 0) = 3;
        g_cam(g_cam_val == 1) = 4;
        g_cam(g_cam_val == 2) = 1;
        g_cam(g_cam_val == 3) = 2;
        
        g_wint = zeros(size(g_wint_val));
        g_wint(g_wint_val == 0) = 3;
        g_wint(g_wint_val == 1) = 4;
        g_wint(g_wint_val == 2) = 1;
        g_wint(g_wint_val == 3) = 2;
        
        % Filter out NaNs and keep mapped clusters 1-4
        valid_cam = ~isnan(val_cam) & ~isnan(g_cam_val) & g_cam_val >= 0 & g_cam_val <= 3;
        vc_val = val_cam(valid_cam);
        vc_grp = g_cam(valid_cam);
        
        valid_wint = ~isnan(val_wint) & ~isnan(g_wint_val) & g_wint_val >= 0 & g_wint_val <= 3;
        vw_val = val_wint(valid_wint);
        vw_grp = g_wint(valid_wint);
        
        % Combine into a single vector with model and cluster group identifiers
        X = [vc_val; vw_val];
        G_clus = [vc_grp; vw_grp];
        G_model = [ones(length(vc_val), 1); 2*ones(length(vw_val), 1)];
        
        % Position: Shifted 5 degrees to the right (+0.007) and down by 50 degrees (-0.045)
        inset_w = 0.08;
        inset_h = 0.0715; % Increased height by 30% from 0.055
        in_ax = axes('Position', [ax_pos(1)+0.027, ax_pos(2)-0.0025, inset_w, inset_h]);
        
        % Call boxplot
        boxplot(in_ax, X, {G_clus, G_model}, 'positions', [0.8 1.2 1.8 2.2 2.8 3.2 3.8 4.2], ...
                'colors', [c_cam; c_wint], 'width', 0.25, 'symbol', '');
        
        % Fill boxes with color
        hold(in_ax, 'on');
        boxes = findobj(in_ax, 'Tag', 'Box');
        for k = 1:length(boxes)
            x_data = get(boxes(k), 'XData');
            y_data = get(boxes(k), 'YData');
            mean_x = mean(x_data);
            frac = mean_x - floor(mean_x);
            if abs(frac - 0.8) < 0.15 || abs(frac - 0.7) < 0.15
                face_color = c_cam;
            else
                face_color = c_wint;
            end
            patch(x_data, y_data, face_color, 'FaceAlpha', 0.4, 'EdgeColor', face_color, 'LineWidth', 1.5, 'Parent', in_ax);
        end
        
        % Bring medians and whiskers to the front
        uistack(findobj(in_ax, 'Tag', 'Median'), 'top');
        uistack(findobj(in_ax, 'Tag', 'Upper Whisker'), 'top');
        uistack(findobj(in_ax, 'Tag', 'Lower Whisker'), 'top');
        uistack(findobj(in_ax, 'Tag', 'Upper Adjacent Value'), 'top');
        uistack(findobj(in_ax, 'Tag', 'Lower Adjacent Value'), 'top');

        % Style the axes
        set(in_ax, 'XTick', [1 2 3 4], 'XTickLabel', {'C1','C2','C3','C4'}, 'Color', 'w', 'Box', 'on', 'FontSize', 9, 'YAxisLocation', 'right');
        xlim(in_ax, [0.4 4.6]);
        xlabel(in_ax, 'Cluster', 'FontSize', 9, 'FontWeight', 'bold');
        ylabel(in_ax, y_label_str, 'FontSize', 9, 'FontWeight', 'bold');
        grid(in_ax, 'on');
    end
    
    %% Panel 1: Temperature (Top)
    disp('Plotting Panel 1: Temperature...');
    ax1 = axes('Position', [px_left, py(1), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]);
    hold on;
    m_pcolor(xq, yq, Temp_Grid);
    shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax1, slanCM('thermal'));
    caxis(ax1, [300 1500]);
    c1 = colorbar('eastoutside');
    c1.Label.String = 'Temperature (CAM22) at 100 km (°C)';
    c1.Label.FontWeight = 'bold';
    c1.Label.FontSize = 12;
    
    % Plot Temp boxplot inset
    plot_inset_box([px_left, py(1), w_panel, h_panel], '°C', ...
                   cam22_data.Temperature_N_CAM22, cam22_data.GMM_k4 + 1, ...
                   wint_data.Temperature_N_WINT, wint_data.GMM_k4 + 1);
    
    %% Panel 2: Vote Map
    disp('Plotting Panel 2: Vote Map...');
    ax2 = axes('Position', [px_left, py(2), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]);
    hold on;
    m_pcolor(xq, yq, totvotpos1);
    shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax2, slanCM('bilbao'));
    caxis(ax2, [0 9]);
    c2 = colorbar('eastoutside');
    c2.Label.String = 'Craton Vote Map at 100 km (Votes)';
    c2.Label.FontWeight = 'bold';
    c2.Label.FontSize = 12;
    
    % Plot Depth boxplot inset beside vote map
    plot_inset_box([px_left, py(2), w_panel, h_panel], 'Depth (km)', ...
                   cam22_data.Neg_Depth, cam22_data.GMM_k4 + 1, ...
                   wint_data.Neg_Depth, wint_data.GMM_k4 + 1);
    
    %% Panel 3: Attenuation
    disp('Plotting Panel 3: Attenuation...');
    ax3 = axes('Position', [px_left, py(3), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]);
    hold on;
    m_pcolor(xq, yq, ln_Q_inv);
    shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax3, slanCM('vik'));
    % caxis(ax3, [-7 -4]); 
    c3 = colorbar('eastoutside');
    c3.Label.String = 'Attenuation ln(Q^{-1}) at 100 km';
    c3.Label.FontWeight = 'bold';
    c3.Label.FontSize = 12;
    
    % Plot Attenuation boxplot inset (WINT attenuation loaded from wint_data table)
    plot_inset_box([px_left, py(3), w_panel, h_panel], 'ln(Q^{-1})', ...
                   cam22_data.logS_AttenuationRF_Neg, cam22_data.GMM_k4 + 1, ...
                   wint_data.logS_AttenuationRF_Neg, wint_data.GMM_k4 + 1);
    
    %% Panel 4: Shear-Velocity (Bottom)
    disp('Plotting Panel 4: Shear Velocity...');
    ax4 = axes('Position', [px_left, py(4), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]);
    hold on;
    m_pcolor(xq, yq, dvs_Grid);
    shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax4, flipud(slanCM('vik')));
    caxis(ax4, [-5 5]); 
    c4 = colorbar('eastoutside');
    c4.Label.String = 'Shear-Velocity Perturbation (dVs/Vs) at 100 km (%)';
    c4.Label.FontWeight = 'bold';
    c4.Label.FontSize = 12;
    
    % Plot Vs boxplot inset
    plot_inset_box([px_left, py(4), w_panel, h_panel], 'dVs (%)', ...
                   cam22_data.dVsCAM22RF_Neg, cam22_data.GMM_k4 + 1, ...
                   wint_data.dVsWINTRF_Neg, wint_data.GMM_k4 + 1);
                   
    %% Global Legend
    % Place the legend in the empty space at the top of the figure
    leg_ax = axes('Position', [0.45, 0.75, 0.1, 0.05], 'Visible', 'off');
    hold(leg_ax, 'on');
    h1 = patch(NaN, NaN, c_cam, 'FaceAlpha', 0.4, 'EdgeColor', c_cam, 'LineWidth', 1.5);
    h2 = patch(NaN, NaN, c_wint, 'FaceAlpha', 0.4, 'EdgeColor', c_wint, 'LineWidth', 1.5);
    legend(leg_ax, [h1, h2], {'CAM22 Model', 'WINTERC-G Model'}, 'Location', 'north', 'Orientation', 'vertical', 'FontSize', 14, 'Box', 'off');
    
    %% Save Figure
    exportgraphics(f, '../../Figures/Global_Study/Figure2b_Maps_Stats.png', 'Resolution', 300);
    disp('Figure saved as Figures/Global_Study/Figure2b_Maps_Stats.png');
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
