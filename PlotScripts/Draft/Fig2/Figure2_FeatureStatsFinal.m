function Figure2_FeatureStatsFinal()
    clear; close all; clc;

    disp('Loading Clustering Data...');
    res_dir = '../../Data/MachineLearningData/rf_global_clustering/results';
    opts_cam = detectImportOptions(fullfile(res_dir, 'clustered_data_Neg_CAM22.csv'));
    cam = readtable(fullfile(res_dir, 'clustered_data_Neg_CAM22.csv'), opts_cam);
    opts_wint = detectImportOptions(fullfile(res_dir, 'clustered_data_Neg_WINT.csv'));
    wint = readtable(fullfile(res_dir, 'clustered_data_Neg_WINT.csv'), opts_wint);
    
    cam.TectonicType(cam.TectonicType == 6) = 5;
    wint.TectonicType(wint.TectonicType == 6) = 5;
    
    PAPER_TO_ML = [2, 3, 0, 1]; 
    PAPER_COLORS = {[0.8, 0.1, 0.1], [0.1, 0.3, 0.8], [0.1, 0.6, 0.3], [0.0, 0.0, 0.0]};
    
    % Font settings for easy tweaking
    FONTS.axis_label = 20;
    FONTS.tick_label = 15;
    FONTS.legend_main = 24;
    FONTS.legend_tsne = 22;
    FONTS.panel_label = 25;
    
    % Canvas: 1400x1100 (Option B)
    f = figure('Name', 'Figure 2: Feature Stats Final', 'Position', [100, 100, 1400, 1100], 'Color', 'w');
    
    %% Right Panel: Boxplots
    % 38% width allocation. Tightly stacked.
    w_box = 0.16; h_box = 0.35;
    
    % Bottom Row (keeps x-tick labels)
    bx3 = axes('Position', [0.62, 0.10, w_box, h_box]);
    bx4 = axes('Position', [0.81, 0.10, w_box, h_box]);
    % Top Row (no x-tick labels, tightly stacked)
    bx1 = axes('Position', [0.62, 0.49, w_box, h_box]);
    bx2 = axes('Position', [0.81, 0.49, w_box, h_box]);
    
    draw_box_panel(bx1, cam, wint, PAPER_TO_ML, PAPER_COLORS, 'Depth (km)', 'Neg_Depth', 'Neg_Depth', 'e', false, FONTS);
    draw_box_panel(bx2, cam, wint, PAPER_TO_ML, PAPER_COLORS, 'Attenuation ln(Q^{-1})', 'logS_AttenuationRF_Neg', 'logS_AttenuationRF_Neg', 'f', false, FONTS);
    draw_box_panel(bx3, cam, wint, PAPER_TO_ML, PAPER_COLORS, 'Temperature (\circC)', 'Temperature_N_CAM22', 'Temperature_N_WINT', 'g', true, FONTS);
    draw_box_panel(bx4, cam, wint, PAPER_TO_ML, PAPER_COLORS, 'Velocity perturbation (dV_s %)', 'dVsCAM22RF_Neg', 'dVsWINTRF_Neg', 'h', true, FONTS);
    
    lg_ax = axes('Position', [0.62, 0.88, 0.35, 0.05], 'Visible', 'off');
    h_cam = patch(lg_ax, nan, nan, [0.5 0.5 0.5], 'FaceAlpha', 0.85, 'EdgeColor', 'none');
    h_wint = patch(lg_ax, nan, nan, [0.5 0.5 0.5], 'FaceAlpha', 0.30, 'EdgeColor', 'none');
    legend(lg_ax, [h_cam, h_wint], {'CAM22', 'WINTERC-G'}, 'Location', 'north', 'Orientation', 'horizontal', 'FontSize', FONTS.legend_main, 'Box', 'off');

    %% Left Panel Bottom: t-SNE Scatter
    % 1:1 Aspect ratio, vertically expanded to close the gap.
    % 50% Height (0.50). In 1100px canvas = 550px.
    % 550px / 1400px width = 0.392 width.
    ax_tsne = axes('Position', [0.104, 0.10, 0.392, 0.50]); hold(ax_tsne, 'on');
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
    xlabel(ax_tsne, 'Projection dimension 1', 'FontSize', FONTS.axis_label, 'FontWeight', 'bold');
    ylabel(ax_tsne, 'Projection dimension 2', 'FontSize', FONTS.axis_label, 'FontWeight', 'bold');
    grid(ax_tsne, 'on'); box(ax_tsne, 'on'); axis(ax_tsne, 'square');
    set(ax_tsne, 'XTickLabel', []); set(ax_tsne, 'YTickLabel', []);
    set(ax_tsne, 'FontSize', FONTS.tick_label);
    ax_pos = get(ax_tsne, 'Position');
    annotation(ax_tsne.Parent, 'textbox', [ax_pos(1), ax_pos(2), 0.05, 0.05], ...
        'String', '(d)', 'FontSize', FONTS.panel_label, ...
        'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'bottom', 'LineStyle', 'none', 'Margin', 5);
    leg1 = legend(ax_tsne, h_clusters, {'C1 (Melt)', 'C2 (Rheological)', 'C3 (Metasomatic)', 'C4 (Structural)'}, 'Location', 'northwest', 'FontSize', FONTS.legend_tsne, 'Box', 'off');

    %% Left Panel Top: Joint KDE Scatters
    % Pulled down to Y=0.66 to close vertical gap with t-SNE.
    w_kde = 0.15; h_kde = 0.20; y_kde = 0.66; 
    
    xA = 0.05;
    ax_mA = axes('Position', [xA, y_kde, w_kde, h_kde]); ax_tA = axes('Position', [xA, y_kde + h_kde + 0.01, w_kde, 0.05]);
    plotjointkde(ax_mA, ax_tA, [], cam.logS_AttenuationRF_Neg, cam.Neg_Depth, cam.GMM_k4, PAPER_TO_ML, PAPER_COLORS, 'Attenuation ln(Q^{-1})', 'Depth (km)', 'a', FONTS);
        
    xB = xA + w_kde + 0.02; ax_mB = axes('Position', [xB, y_kde, w_kde, h_kde]); ax_tB = axes('Position', [xB, y_kde + h_kde + 0.01, w_kde, 0.05]);
    plotjointkde(ax_mB, ax_tB, [], cam.Temperature_N_CAM22, cam.Neg_Depth, cam.GMM_k4, PAPER_TO_ML, PAPER_COLORS, 'Temperature (\circC)', '', 'b', FONTS);
        
    xC = xB + w_kde + 0.02; ax_mC = axes('Position', [xC, y_kde, w_kde, h_kde]); ax_tC = axes('Position', [xC, y_kde + h_kde + 0.01, w_kde, 0.05]);
    ax_rC = axes('Position', [xC + w_kde + 0.005, y_kde, 0.025, h_kde]);
    plotjointkde(ax_mC, ax_tC, ax_rC, cam.dVsCAM22RF_Neg, cam.Neg_Depth, cam.GMM_k4, PAPER_TO_ML, PAPER_COLORS, 'Velocity perturbation (dV_s %)', '', 'c', FONTS);
    
    linkaxes([ax_mA, ax_mB, ax_mC], 'y');
    
    %% Save
    out_dir = '../../Figures/Global_Study'; if ~isfolder(out_dir), mkdir(out_dir); end
    out_file = fullfile(out_dir, 'Figure2_FeatureStatsFinal.png'); exportgraphics(f, out_file, 'Resolution', 300);
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

function draw_box_panel(ax, cam, wint, PAPER_TO_ML, PAPER_COLORS, ylabel_str, col_cam, col_wint, letter, keep_xlabels, FONTS)
    hold(ax, 'on');
    for p = 1:4
        ml_id = PAPER_TO_ML(p);
        vals_cam = cam.(col_cam)(cam.GMM_k4 == ml_id); vals_cam = vals_cam(~isnan(vals_cam));
        if ~isempty(vals_cam), bc1 = boxchart(ax, p*ones(size(vals_cam)) - 0.2, vals_cam); bc1.BoxFaceColor = PAPER_COLORS{p}; bc1.MarkerColor = PAPER_COLORS{p}; bc1.BoxFaceAlpha = 0.85; bc1.BoxWidth = 0.35; bc1.WhiskerLineColor = [0.2 0.2 0.2]; end
        vals_wint = wint.(col_wint)(wint.GMM_k4 == ml_id); vals_wint = vals_wint(~isnan(vals_wint));
        if ~isempty(vals_wint), bc2 = boxchart(ax, p*ones(size(vals_wint)) + 0.2, vals_wint); bc2.BoxFaceColor = PAPER_COLORS{p}; bc2.MarkerColor = PAPER_COLORS{p}; bc2.BoxFaceAlpha = 0.30; bc2.BoxWidth = 0.35; bc2.WhiskerLineColor = [0.2 0.2 0.2]; end
    end
    xticks(ax, 1:4); xlim(ax, [0.4 4.6]);
    if keep_xlabels
        xticklabels(ax, {'C1', 'C2', 'C3', 'C4'});
    else
        xticklabels(ax, {});
    end
    ylabel(ax, ylabel_str, 'FontSize', FONTS.axis_label, 'FontWeight', 'bold'); grid(ax, 'on'); box(ax, 'off');
    set(ax, 'FontSize', FONTS.tick_label);
    if ~isempty(letter)
        ax_pos = get(ax, 'Position');
        annotation(ax.Parent, 'textbox', [ax_pos(1) + ax_pos(3) - 0.05, ax_pos(2), 0.05, 0.05], ...
            'String', ['(' letter ')'], 'FontSize', FONTS.panel_label, ...
            'FontWeight', 'bold', 'HorizontalAlignment', 'right', ...
            'VerticalAlignment', 'bottom', 'LineStyle', 'none', 'Margin', 5);
    end
end

function plotjointkde(main_ax, top_ax, right_ax, x_all, y_all, gmm_k4, PAPER_TO_ML, PAPER_COLORS, xlabel_str, ylabel_str, letter, FONTS)
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
    box(main_ax, 'on'); grid(main_ax, 'on'); set(main_ax, 'YDir', 'reverse'); xlabel(main_ax, xlabel_str, 'FontSize', FONTS.axis_label, 'FontWeight', 'bold');
    if ~isempty(ylabel_str), ylabel(main_ax, ylabel_str, 'FontSize', FONTS.axis_label, 'FontWeight', 'bold'); else, set(main_ax, 'YTickLabel', []); end
    set(main_ax, 'linewidth', 1.5, 'fontsize', FONTS.tick_label);
    
    if ~isempty(letter)
        ax_pos = get(main_ax, 'Position');
        annotation(main_ax.Parent, 'textbox', [ax_pos(1), ax_pos(2), 0.05, 0.05], ...
            'String', ['(' letter ')'], 'FontSize', FONTS.panel_label, ...
            'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'bottom', 'LineStyle', 'none', 'Margin', 5);
    end
    if ~isempty(top_ax)
        if max_dens_x > 0, ylim(top_ax, [0 max_dens_x * 1.1]); end; xlim(top_ax, [min(x_all)-0.1*std(x_all,'omitnan'), max(x_all)+0.1*std(x_all,'omitnan')]); xlim(main_ax, top_ax.XLim); axis(top_ax, 'off');
    end
    if ~isempty(right_ax)
        if max_dens_y > 0, xlim(right_ax, [0 max_dens_y * 1.1]); end; ylim(right_ax, [min(y_all)-10, max(y_all)+10]); ylim(main_ax, right_ax.YLim); set(right_ax, 'YDir', 'reverse'); axis(right_ax, 'off');
    end
end
