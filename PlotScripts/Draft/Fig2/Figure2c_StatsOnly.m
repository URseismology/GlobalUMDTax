function Figure2c_StatsOnly()
    clear; close all; clc;
    
    %% 1. Load Clustering Statistics
    disp('Loading Clustering Statistics...');
    stats_dir = '../../Data/MachineLearningData/rf_global_clustering/results/';
    cam22_opts = detectImportOptions(fullfile(stats_dir, 'clustered_data_Neg_CAM22.csv'));
    cam22_data = readtable(fullfile(stats_dir, 'clustered_data_Neg_CAM22.csv'), cam22_opts);
    
    wint_opts = detectImportOptions(fullfile(stats_dir, 'clustered_data_Neg_WINT.csv'));
    wint_data = readtable(fullfile(stats_dir, 'clustered_data_Neg_WINT.csv'), wint_opts);
    
    %% 2. Setup Figure (2x2 grid, optimized aspect ratio)
    f = figure('Name', 'Figure 2c: Discontinuity Properties Statistics', 'Position', [100, 100, 1200, 900], 'Color', 'w', 'Visible', 'off');
    
    c_cam = [0 0.4470 0.7410];  % Premium Blue
    c_wint = [0.8500 0.3250 0.0980]; % Premium Orange/Red
    
    % Panel positions [left, bottom, width, height]
    positions = {
        [0.08, 0.55, 0.40, 0.38], ... % Top Left: Temperature
        [0.56, 0.55, 0.40, 0.38], ... % Top Right: Depth
        [0.08, 0.08, 0.40, 0.38], ... % Bottom Left: Attenuation
        [0.56, 0.08, 0.40, 0.38]      % Bottom Right: Shear Velocity
    };
    
    % Define the 4 subplots
    plot_info = {
        % Name, y-label, CAM22 Column, WINT Column
        'Lithospheric Temperature', 'Temperature (°C)', 'Temperature_N_CAM22', 'Temperature_N_WINT';
        'Discontinuity Depth', 'Depth (km)', 'Neg_Depth', 'Neg_Depth';
        'Lithospheric Attenuation', 'ln(Q^{-1})', 'logS_AttenuationRF_Neg', 'logS_AttenuationRF_Neg';
        'Shear Velocity Perturbation', 'dVs/Vs (%)', 'dVsCAM22RF_Neg', 'dVsWINTRF_Neg'
    };
    
    for i = 1:4
        info = plot_info(i, :);
        pos = positions{i};
        ax = axes('Position', pos);
        
        col_cam = info{3};
        col_wint = info{4};
        
        val_cam = cam22_data.(col_cam);
        val_wint = wint_data.(col_wint);
        
        % Map GMM_k4 values (0->3, 1->4, 2->1, 3->2)
        g_cam_raw = cam22_data.GMM_k4;
        g_cam = zeros(size(g_cam_raw));
        g_cam(g_cam_raw == 0) = 3;
        g_cam(g_cam_raw == 1) = 4;
        g_cam(g_cam_raw == 2) = 1;
        g_cam(g_cam_raw == 3) = 2;
        
        g_wint_raw = wint_data.GMM_k4;
        g_wint = zeros(size(g_wint_raw));
        g_wint(g_wint_raw == 0) = 3;
        g_wint(g_wint_raw == 1) = 4;
        g_wint(g_wint_raw == 2) = 1;
        g_wint(g_wint_raw == 3) = 2;
        
        % Filter out NaNs and validate clusters
        valid_cam = ~isnan(val_cam) & ~isnan(g_cam_raw) & g_cam_raw >= 0 & g_cam_raw <= 3;
        vc_val = val_cam(valid_cam);
        vc_grp = g_cam(valid_cam);
        
        valid_wint = ~isnan(val_wint) & ~isnan(g_wint_raw) & g_wint_raw >= 0 & g_wint_raw <= 3;
        vw_val = val_wint(valid_wint);
        vw_grp = g_wint(valid_wint);
        
        % Combine into a single vector
        X = [vc_val; vw_val];
        G_clus = [vc_grp; vw_grp];
        G_model = [ones(length(vc_val), 1); 2*ones(length(vw_val), 1)];
        
        % Plot Boxplot
        boxplot(ax, X, {G_clus, G_model}, 'positions', [0.8 1.2 1.8 2.2 2.8 3.2 3.8 4.2], ...
                'colors', [c_cam; c_wint], 'width', 0.22, 'symbol', '');
        
        % Fill boxes with color
        hold(ax, 'on');
        boxes = findobj(ax, 'Tag', 'Box');
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
            patch(x_data, y_data, face_color, 'FaceAlpha', 0.4, 'EdgeColor', face_color, 'LineWidth', 1.5, 'Parent', ax);
        end
        
        % Style the axes
        set(ax, 'XTick', [1 2 3 4], 'XTickLabel', {'Cluster 1','Cluster 2','Cluster 3','Cluster 4'}, ...
            'Color', 'w', 'Box', 'on', 'FontSize', 11, 'LineWidth', 1.2);
        xlim(ax, [0.4 4.6]);
        xlabel(ax, 'Tomographic Cluster Index', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel(ax, info{2}, 'FontSize', 12, 'FontWeight', 'bold');
        title(ax, info{1}, 'FontSize', 14, 'FontWeight', 'bold');
        grid(ax, 'on');
        
        % Bring medians and whiskers to the front
        uistack(findobj(ax, 'Tag', 'Median'), 'top');
        uistack(findobj(ax, 'Tag', 'Upper Whisker'), 'top');
        uistack(findobj(ax, 'Tag', 'Lower Whisker'), 'top');
        uistack(findobj(ax, 'Tag', 'Upper Adjacent Value'), 'top');
        uistack(findobj(ax, 'Tag', 'Lower Adjacent Value'), 'top');
        
        % Add Legend to the first subplot
        if i == 1
            h1 = patch(NaN, NaN, c_cam, 'FaceAlpha', 0.4, 'EdgeColor', c_cam, 'LineWidth', 1.5);
            h2 = patch(NaN, NaN, c_wint, 'FaceAlpha', 0.4, 'EdgeColor', c_wint, 'LineWidth', 1.5);
            legend(ax, [h1, h2], {'CAM22 Model', 'WINTERC-G Model'}, 'Location', 'Best', 'FontSize', 11);
        end
    end
    
    %% Save Figure
    exportgraphics(f, '../../Figures/Global_Study/Figure2c_StatsOnly.png', 'Resolution', 300);
    disp('Figure saved as Figures/Global_Study/Figure2c_StatsOnly.png');
end
