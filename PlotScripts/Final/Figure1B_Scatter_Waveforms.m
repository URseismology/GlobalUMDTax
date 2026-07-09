function Figure1B_Scatter_Waveforms()
    clear; close all; clc;
    
    % Add paths
    addpath('../Data/m_map');
    addpath('../Data/landmask');
    addpath('../Data/slanCM');
    
    %% 1. Load Seismic Data
    disp('Loading Seismic Data...');
    Data_Global_RF_Meta = readtable('../Data/MachineLearningData/rf_global_clustering/data/Data_Global_R1Meta.csv');
    Data_Global_RF_ML = readtable('../Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv');
    
    % Merge data
    Data_Global_RF = Data_Global_RF_Meta;
    Data_Global_RF.Neg_Depth = Data_Global_RF_ML.Neg_Depth;
    Data_Global_RF.GMM_k4 = Data_Global_RF_ML.GMM_k4;
    
    valid_idx = ~isnan(Data_Global_RF.Neg_Depth);
    Data_Valid = Data_Global_RF(valid_idx, :);
    
    seismic_depth = Data_Valid.Neg_Depth;
    gmm_k4 = Data_Valid.GMM_k4;
    st_lon = Data_Valid.Longitude;
    st_lat = Data_Valid.Latitude;
    
    %% 2. Load CAM-22 LAB Data
    disp('Loading CAM-22 LAB Data...');
    CAM22_LAB_FILE = '../Data/Velocity_Models/CAM2022-lithosphere.r0.0.nc';
    
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
    
    %% 3. Generate Visualizations
    % Set figure to exactly 2:1 aspect ratio
    f = figure('Name', 'Figure 1B: Waveforms & Scatter', 'Position', [100, 100, 1400, 700], 'Color', 'w', 'Visible', 'off');
    
    % Dimensions for layout
    h_main = 0.33;
    w_main = 0.1285;
    h_marg = 0.05;
    w_marg = 0.02;
    
    % Positions
    py_top = 0.52;
    py_bot = 0.15;
    
    % A. Top Row (C2/C3 waveforms and scatter on the right)
    disp('Plotting Top Row Waveforms and Scatter...');
    
    % Waveforms (C2 and C3): show y-tick labels, hide y-label for both C2 and C3
    ax_c2 = subplot('Position', [0.08, py_top, 0.33, h_main]);
    plotwaveforms(ax_c2, '../Data/MachineLearningData/RFs/sequenced_cluster3.mat', c_blue, 'C2 (Rheological)', true, true, false);
    
    ax_c3 = subplot('Position', [0.43, py_top, 0.33, h_main]);
    plotwaveforms(ax_c3, '../Data/MachineLearningData/RFs/sequenced_cluster0.mat', c_green, 'C3 (Metasomatic)', false, true, false);
    
    % Scatter on the right (C2/C3) - histogram on top, reduced horizontal space (px = 0.77), show x-tick labels
    px_top_s = 0.77;
    main_ax_top = axes('Position', [px_top_s, py_top, w_main, h_main]);
    top_ax_top  = axes('Position', [px_top_s, py_top + h_main + 0.01, w_main, h_marg]);
    right_ax_top = axes('Position', [px_top_s + w_main + 0.005, py_top, w_marg, h_main]);
    
    plotjointkde(main_ax_top, top_ax_top, right_ax_top, st_cam_lab, seismic_depth, c_indices, c_colors, [2, 3], true, true, true);
    
    % B. Bottom Row (C1/C4 waveforms and scatter on the right)
    disp('Plotting Bottom Row Waveforms and Scatter...');
    
    % Waveforms (C1 and C4): show y-tick labels and y-label for both C1 and C4
    ax_c1 = subplot('Position', [0.08, py_bot, 0.33, h_main]);
    plotwaveforms(ax_c1, '../Data/MachineLearningData/RFs/sequenced_cluster2.mat', c_red, 'C1 (Melt)', true, true, true);
    
    ax_c4 = subplot('Position', [0.43, py_bot, 0.33, h_main]);
    plotwaveforms(ax_c4, '../Data/MachineLearningData/RFs/sequenced_cluster1.mat', c_black, 'C4 (Deep Structural)', false, true, true);
    
    % Scatter on the right (C1/C4) - histogram on bottom, remove x-label, reduced horizontal space (px = 0.77), remove x-tick labels
    px_bot_s = 0.77;
    main_ax_bot = axes('Position', [px_bot_s, py_bot, w_main, h_main]);
    top_ax_bot  = axes('Position', [px_bot_s, py_bot - h_marg - 0.01, w_main, h_marg]);
    right_ax_bot = axes('Position', [px_bot_s + w_main + 0.005, py_bot, w_marg, h_main]);
    
    plotjointkde(main_ax_bot, top_ax_bot, right_ax_bot, st_cam_lab, seismic_depth, c_indices, c_colors, [1, 4], false, false, false);
    
    % Save Figure
    exportgraphics(f, '../Figures/Global_Study/Figure1B_Scatter_Waveforms.png', 'Resolution', 300);
    disp('Figure saved as Figures/Global_Study/Figure1B_Scatter_Waveforms.png');
end

function plotjointkde(main_ax, top_ax, right_ax, x_all, y_all, c_indices, c_colors, cluster_ids, show_xlabel, hist_on_top, show_xticklabels)
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
        xlabel(main_ax, 'CAM-22 LAB Depth (km)', 'FontSize', 8, 'FontWeight', 'bold');
    else
        xlabel(main_ax, '');
    end
    ylabel(main_ax, ''); % Omit Y-label
    
    % Flip Y-axis so depth increases downward (matching the waveforms)
    set(main_ax, 'YDir', 'reverse');
    
    % Hide Y-tick labels on the rightmost panels (scatter plots)
    set(main_ax, 'YTickLabel', []);
    
    if ~show_xticklabels
        set(main_ax, 'XTickLabel', []);
    end
    
    set(main_ax, 'linewidth', 1.5, 'fontsize', 8);
    
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

function plotwaveforms(ax_handle, RF_file_path, color_theme, title_str, show_depth_labels, show_yticklabels, show_ylabel)
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
        ylabel('Station Index', 'FontSize', 8, 'FontWeight', 'bold');
    else
        ylabel('');
    end
    
    if show_yticklabels
        % Keep tick labels visible
    else
        set(ax_handle, 'YTickLabel', []);
    end
    
    if show_depth_labels
        xlabel('Depth (km)', 'FontSize', 8, 'FontWeight', 'bold');
    else
        xlabel('');
        set(ax_handle, 'XTickLabel', []);
    end
    
    title(title_str, 'FontSize', 10, 'FontWeight', 'bold');
    box on;
    
    set(gca, 'linewidth', 2, 'fontsize', 8, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YAxisLocation', 'right', 'XColor', color_theme, 'YColor', color_theme);
    
    ax = gca;
    ax.XAxis.TickLabelColor = [0 0 0]; 
    ax.YAxis.TickLabelColor = [0 0 0];
    ax.XAxis.Label.Color = [0 0 0];
    ax.YAxis.Label.Color = [0 0 0];
    
    camroll(270);
end
