function Figure2_OptionC()
    clear; close all; clc;

    disp('Loading Clustering Data...');
    res_dir = '../../Data/MachineLearningData/rf_global_clustering/results';
    opts_cam = detectImportOptions(fullfile(res_dir, 'clustered_data_Neg_CAM22.csv'));
    cam = readtable(fullfile(res_dir, 'clustered_data_Neg_CAM22.csv'), opts_cam);
    opts_wint = detectImportOptions(fullfile(res_dir, 'clustered_data_Neg_WINT.csv'));
    wint = readtable(fullfile(res_dir, 'clustered_data_Neg_WINT.csv'), opts_wint);
    
    cam.TectonicType(cam.TectonicType == 6) = 5; wint.TectonicType(wint.TectonicType == 6) = 5;
    PAPER_TO_ML = [2, 3, 0, 1]; 
    PAPER_COLORS = {[0.8, 0.1, 0.1], [0.1, 0.3, 0.8], [0.1, 0.6, 0.3], [0.0, 0.0, 0.0]};
    
    f = figure('Name', 'Figure 2: Option C', 'Position', [100, 100, 1800, 900], 'Color', 'w');
    
    %% Col 1: t-SNE Scatter (1:1 Aspect)
    % 0.25 * 1800 = 450px. 0.50 * 900 = 450px.
    ax_tsne = axes('Position', [0.05, 0.20, 0.25, 0.50]); hold(ax_tsne, 'on');
    h_clusters = gobjects(4, 1);
    for p = 1:4
        ml_id = PAPER_TO_ML(p); idx_clust = (cam.GMM_k4 == ml_id);
        x_data = cam.tsne_1(idx_clust); y_data = cam.tsne_2(idx_clust);
        
        if length(x_data) > 5
            try
                f_density = ksdensity([x_data, y_data], [x_data, y_data]);
                f_norm = (f_density - min(f_density)) / (max(f_density) - min(f_density) + eps);
                f_norm = 0.2 + 0.8 * f_norm; C_rgb = (1 - f_norm) * [0.9 0.9 0.9] + f_norm * PAPER_COLORS{p};
                scatter(ax_tsne, x_data, y_data, 50, C_rgb, 'filled', 'MarkerFaceAlpha', 0.85, 'MarkerEdgeColor', 'w', 'LineWidth', 0.5);
            catch
                scatter(ax_tsne, x_data, y_data, 50, 'o', 'MarkerFaceColor', PAPER_COLORS{p}, 'MarkerEdgeColor', 'w', 'LineWidth', 0.5, 'MarkerFaceAlpha', 0.85);
            end
            plot_gmm_ellipse(ax_tsne, x_data, y_data, PAPER_COLORS{p});
        end
        h_clusters(p) = plot(ax_tsne, nan, nan, 'o', 'MarkerFaceColor', PAPER_COLORS{p}, 'MarkerEdgeColor', 'w', 'MarkerSize', 10, 'LineStyle', 'none');
    end
    xlabel(ax_tsne, 'Projection dimension 1', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel(ax_tsne, 'Projection dimension 2', 'FontSize', 12, 'FontWeight', 'bold');
    grid(ax_tsne, 'on'); box(ax_tsne, 'on'); axis(ax_tsne, 'square');
    leg1 = legend(ax_tsne, h_clusters, {'C1 (Melt)', 'C2 (Rheological)', 'C3 (Metasomatic)', 'C4 (Structural)'}, 'Location', 'northwest', 'FontSize', 11, 'Box', 'off');
    title(ax_tsne, '(a)', 'Units', 'normalized', 'Position', [-0.05 1.05], 'HorizontalAlignment', 'left', 'FontSize', 16, 'FontWeight', 'bold');

    %% Col 2: 3x1 Stacked Joint KDEs sharing X-axis (Temperature)
    w_kde = 0.22; h_kde = 0.22; xK = 0.38;
    
    % Panel A: Temp vs Attenuation (Top)
    ax_m1 = axes('Position', [xK, 0.68, w_kde, h_kde]); 
    ax_t1 = axes('Position', [xK, 0.68 + h_kde + 0.01, w_kde, 0.05]); 
    ax_r1 = axes('Position', [xK + w_kde + 0.005, 0.68, 0.03, h_kde]);
    plotjointkde(ax_m1, ax_t1, ax_r1, cam.Temperature_N_CAM22, cam.logS_AttenuationRF_Neg, cam.GMM_k4, PAPER_TO_ML, PAPER_COLORS, '', 'Attenuation ln(Q^{-1})', 'b', false);
        
    % Panel B: Temp vs Depth (Middle)
    ax_m2 = axes('Position', [xK, 0.38, w_kde, h_kde]); 
    ax_r2 = axes('Position', [xK + w_kde + 0.005, 0.38, 0.03, h_kde]);
    plotjointkde(ax_m2, [], ax_r2, cam.Temperature_N_CAM22, cam.Neg_Depth, cam.GMM_k4, PAPER_TO_ML, PAPER_COLORS, '', 'Depth (km)', 'c', true);
        
    % Panel C: Temp vs Velocity (Bottom)
    ax_m3 = axes('Position', [xK, 0.08, w_kde, h_kde]); 
    ax_r3 = axes('Position', [xK + w_kde + 0.005, 0.08, 0.03, h_kde]);
    plotjointkde(ax_m3, [], ax_r3, cam.Temperature_N_CAM22, cam.dVsCAM22RF_Neg, cam.GMM_k4, PAPER_TO_ML, PAPER_COLORS, 'Temperature (\circC)', 'Velocity (dV_s %)', 'd', false);
    
    linkaxes([ax_m1, ax_m2, ax_m3], 'x');

    %% Col 3: 4x1 Stacked Boxplots
    w_box = 0.20; h_box = 0.18; xB = 0.76;
    bx1 = axes('Position', [xB, 0.76, w_box, h_box]);
    bx2 = axes('Position', [xB, 0.53, w_box, h_box]);
    bx3 = axes('Position', [xB, 0.30, w_box, h_box]);
    bx4 = axes('Position', [xB, 0.07, w_box, h_box]);
    
    draw_box_panel(bx1, cam, wint, PAPER_TO_ML, PAPER_COLORS, 'Depth (km)', 'Neg_Depth', 'Neg_Depth', 'e');
    draw_box_panel(bx2, cam, wint, PAPER_TO_ML, PAPER_COLORS, 'Attenuation', 'logS_AttenuationRF_Neg', 'logS_AttenuationRF_Neg', 'f');
    draw_box_panel(bx3, cam, wint, PAPER_TO_ML, PAPER_COLORS, 'Temp (\circC)', 'Temperature_N_CAM22', 'Temperature_N_WINT', 'g');
    draw_box_panel(bx4, cam, wint, PAPER_TO_ML, PAPER_COLORS, 'dV_s %', 'dVsCAM22RF_Neg', 'dVsWINTRF_Neg', 'h');
    
    lg_ax = axes('Position', [0.72, 0.95, 0.25, 0.05], 'Visible', 'off');
    h_cam = patch(lg_ax, nan, nan, [0.5 0.5 0.5], 'FaceAlpha', 0.85, 'EdgeColor', 'none');
    h_wint = patch(lg_ax, nan, nan, [0.5 0.5 0.5], 'FaceAlpha', 0.30, 'EdgeColor', 'none');
    legend(lg_ax, [h_cam, h_wint], {'CAM22', 'WINTERC-G'}, 'Location', 'north', 'Orientation', 'horizontal', 'FontSize', 12, 'Box', 'off');
    
    out_dir = '../../Figures/Global_Study'; if ~isfolder(out_dir), mkdir(out_dir); end
    out_file = fullfile(out_dir, 'Figure2_OptionC.png'); exportgraphics(f, out_file, 'Resolution', 300);
end

% Include helpers...
function plot_gmm_ellipse(ax, x, y, color)
    idx = ~isnan(x) & ~isnan(y); if sum(idx) < 3, return; end
    mu = [mean(x(idx)), mean(y(idx))]; Sigma = cov(x(idx), y(idx)); [V, D] = eig(Sigma);
    scale = 2; t = linspace(0, 2*pi, 100); a = scale * sqrt(max(0, D(1,1))); b = scale * sqrt(max(0, D(2,2)));
    ellipse_x_r = a * cos(t); ellipse_y_r = b * sin(t); rotated = V * [ellipse_x_r; ellipse_y_r];
    ex = rotated(1, :) + mu(1); ey = rotated(2, :) + mu(2);
    patch(ax, ex, ey, color, 'FaceAlpha', 0.15, 'EdgeColor', color, 'LineWidth', 2);
end

function draw_box_panel(ax, cam, wint, PAPER_TO_ML, PAPER_COLORS, ylabel_str, col_cam, col_wint, letter)
    hold(ax, 'on');
    for p = 1:4
        ml_id = PAPER_TO_ML(p);
        vals_cam = cam.(col_cam)(cam.GMM_k4 == ml_id); vals_cam = vals_cam(~isnan(vals_cam));
        if ~isempty(vals_cam), bc1 = boxchart(ax, p*ones(size(vals_cam)) - 0.2, vals_cam); bc1.BoxFaceColor = PAPER_COLORS{p}; bc1.MarkerColor = PAPER_COLORS{p}; bc1.BoxFaceAlpha = 0.85; bc1.BoxWidth = 0.35; bc1.WhiskerLineColor = [0.2 0.2 0.2]; end
        vals_wint = wint.(col_wint)(wint.GMM_k4 == ml_id); vals_wint = vals_wint(~isnan(vals_wint));
        if ~isempty(vals_wint), bc2 = boxchart(ax, p*ones(size(vals_wint)) + 0.2, vals_wint); bc2.BoxFaceColor = PAPER_COLORS{p}; bc2.MarkerColor = PAPER_COLORS{p}; bc2.BoxFaceAlpha = 0.30; bc2.BoxWidth = 0.35; bc2.WhiskerLineColor = [0.2 0.2 0.2]; end
    end
    xticks(ax, 1:4); xticklabels(ax, {'C1', 'C2', 'C3', 'C4'}); xlim(ax, [0.4 4.6]);
    ylabel(ax, ylabel_str, 'FontSize', 11, 'FontWeight', 'bold'); grid(ax, 'on'); box(ax, 'off');
    title(ax, ['(' letter ')'], 'Units', 'normalized', 'Position', [-0.15 1.05], 'HorizontalAlignment', 'left', 'FontSize', 16, 'FontWeight', 'bold');
end

function plotjointkde(main_ax, top_ax, right_ax, x_all, y_all, gmm_k4, PAPER_TO_ML, PAPER_COLORS, xlabel_str, ylabel_str, letter, reverse_y)
    hold(main_ax, 'on'); if ~isempty(top_ax), hold(top_ax, 'on'); end; if ~isempty(right_ax), hold(right_ax, 'on'); end
    max_dens_x = 0; max_dens_y = 0;
    for p = 1:4
        ml_id = PAPER_TO_ML(p); idx = (gmm_k4 == ml_id); x_data = x_all(idx); y_data = y_all(idx);
        valid = ~isnan(x_data) & ~isnan(y_data); x_data = x_data(valid); y_data = y_data(valid);
        if length(x_data) < 5, continue; end
        try
            f_density = ksdensity([x_data, y_data], [x_data, y_data]); f_norm = (f_density - min(f_density)) / (max(f_density) - min(f_density) + eps); f_norm = 0.2 + 0.8 * f_norm; C_rgb = (1 - f_norm) * [0.9 0.9 0.9] + f_norm * PAPER_COLORS{p};
            scatter(main_ax, x_data, y_data, 25, C_rgb, 'filled', 'MarkerFaceAlpha', 0.8, 'MarkerEdgeColor', 'none');
        catch, scatter(main_ax, x_data, y_data, 25, PAPER_COLORS{p}, 'filled', 'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'none'); end
        if ~isempty(top_ax)
            [f_x, xi_x] = ksdensity(x_data); fill(top_ax, xi_x, f_x, PAPER_COLORS{p}, 'EdgeColor', 'none', 'FaceAlpha', 0.5); plot(top_ax, xi_x, f_x, '-', 'Color', PAPER_COLORS{p}, 'LineWidth', 1.5); max_dens_x = max(max_dens_x, max(f_x));
        end
        if ~isempty(right_ax)
            [f_y, xi_y] = ksdensity(y_data); fill(right_ax, f_y, xi_y, PAPER_COLORS{p}, 'EdgeColor', 'none', 'FaceAlpha', 0.5); plot(right_ax, f_y, xi_y, '-', 'Color', PAPER_COLORS{p}, 'LineWidth', 1.5); max_dens_y = max(max_dens_y, max(f_y));
        end
    end
    box(main_ax, 'on'); grid(main_ax, 'on'); 
    if reverse_y, set(main_ax, 'YDir', 'reverse'); end
    if ~isempty(xlabel_str), xlabel(main_ax, xlabel_str, 'FontSize', 11, 'FontWeight', 'bold'); else, set(main_ax, 'XTickLabel', []); end
    if ~isempty(ylabel_str), ylabel(main_ax, ylabel_str, 'FontSize', 11, 'FontWeight', 'bold'); else, set(main_ax, 'YTickLabel', []); end
    set(main_ax, 'linewidth', 1.5, 'fontsize', 10); title(main_ax, ['(' letter ')'], 'Units', 'normalized', 'Position', [-0.05 1.15], 'HorizontalAlignment', 'left', 'FontSize', 16, 'FontWeight', 'bold');
    if ~isempty(top_ax)
        if max_dens_x > 0, ylim(top_ax, [0 max_dens_x * 1.1]); end; xlim(top_ax, [min(x_all)-0.1*std(x_all,'omitnan'), max(x_all)+0.1*std(x_all,'omitnan')]); xlim(main_ax, top_ax.XLim); axis(top_ax, 'off');
    end
    if ~isempty(right_ax)
        if max_dens_y > 0, xlim(right_ax, [0 max_dens_y * 1.1]); end; ylim(right_ax, [min(y_all)-0.1*std(y_all,'omitnan'), max(y_all)+0.1*std(y_all,'omitnan')]); ylim(main_ax, right_ax.YLim); if reverse_y, set(right_ax, 'YDir', 'reverse'); end; axis(right_ax, 'off');
    end
end
