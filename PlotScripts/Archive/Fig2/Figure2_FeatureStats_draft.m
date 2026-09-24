function Figure2_FeatureStats_draft()
    clear; close all; clc;

    %% 1. Configuration & Data Loading
    disp('Loading Clustering Data...');
    res_dir = '../../Data/MachineLearningData/rf_global_clustering/results';
    
    opts_cam = detectImportOptions(fullfile(res_dir, 'clustered_data_Neg_CAM22.csv'));
    cam = readtable(fullfile(res_dir, 'clustered_data_Neg_CAM22.csv'), opts_cam);
    
    opts_wint = detectImportOptions(fullfile(res_dir, 'clustered_data_Neg_WINT.csv'));
    wint = readtable(fullfile(res_dir, 'clustered_data_Neg_WINT.csv'), opts_wint);
    
    % Merge oceanic tectonic types
    cam.TectonicType(cam.TectonicType == 6) = 5;
    wint.TectonicType(wint.TectonicType == 6) = 5;
    
    % Mapping: Paper Cluster -> ML Cluster
    % C1(1)->2, C2(2)->3, C3(3)->0, C4(4)->1
    PAPER_TO_ML = [2, 3, 0, 1]; 
    
    % Colors for C1, C2, C3, C4
    PAPER_COLORS = {
        [0.8, 0.1, 0.1], ... % C1 (Red)
        [0.1, 0.3, 0.8], ... % C2 (Blue)
        [0.1, 0.6, 0.3], ... % C3 (Green)
        [0.0, 0.0, 0.0]  ... % C4 (Black)
    };
    
    % Tectonic Markers
    TEC_MARKERS = {'s', 'd', 'o', '^', 'v'};
    TEC_LABELS = {'Craton', 'Mod. Crat.', 'Phanerozoic', 'Rift/Backarc', 'Oceanic'};
    
    %% 2. Setup Figure Layout
    f = figure('Name', 'Figure 2: Feature Stats', 'Position', [100, 100, 1600, 800], 'Color', 'w');
    t = tiledlayout(2, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    %% 3. Panel A: t-SNE Scatter
    ax_tsne = nexttile(t, 1, [2, 1]); hold(ax_tsne, 'on');
    
    h_clusters = gobjects(4, 1);
    for p = 1:4
        ml_id = PAPER_TO_ML(p);
        idx_clust = (cam.GMM_k4 == ml_id);
        
        for tec = 1:5
            idx_tec = (cam.TectonicType == tec);
            idx_plot = idx_clust & idx_tec;
            
            if any(idx_plot)
                scatter(ax_tsne, cam.tsne_1(idx_plot), cam.tsne_2(idx_plot), 50, ...
                    TEC_MARKERS{tec}, 'MarkerFaceColor', PAPER_COLORS{p}, ...
                    'MarkerEdgeColor', 'w', 'LineWidth', 0.5, 'MarkerFaceAlpha', 0.85);
            end
        end
        % Dummy handle for cluster legend
        h_clusters(p) = plot(ax_tsne, nan, nan, 'o', 'MarkerFaceColor', PAPER_COLORS{p}, ...
            'MarkerEdgeColor', 'w', 'MarkerSize', 8, 'LineStyle', 'none');
    end
    xlabel(ax_tsne, 'tsne_1', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel(ax_tsne, 'tsne_2', 'FontSize', 12, 'FontWeight', 'bold');
    grid(ax_tsne, 'on'); box(ax_tsne, 'off');
    
    % Tectonic Legend
    h_tec = gobjects(5, 1);
    for tec = 1:5
        h_tec(tec) = plot(ax_tsne, nan, nan, TEC_MARKERS{tec}, 'MarkerFaceColor', [0.4 0.4 0.4], ...
            'MarkerEdgeColor', 'w', 'MarkerSize', 8, 'LineStyle', 'none');
    end
    leg1 = legend(ax_tsne, h_clusters, {'C1', 'C2', 'C3', 'C4'}, 'Location', 'northwest', 'FontSize', 10);
    title(leg1, 'Cluster');
    
    % Create a second axes for the second legend so they don't overwrite
    ax_dummy = axes('Position', ax_tsne.Position, 'Visible', 'off');
    leg2 = legend(ax_dummy, h_tec, TEC_LABELS, 'Location', 'southwest', 'FontSize', 10);
    title(leg2, 'Tectonic Setting');
    
    title(ax_tsne, '(a)', 'Units', 'normalized', 'Position', [-0.15 1.05], 'HorizontalAlignment', 'left', 'FontSize', 16, 'FontWeight', 'bold');
    
    %% 4. Panels B-E: Boxplots
    function draw_box_panel(tile_idx, ylabel_str, col_cam, col_wint, letter)
        ax = nexttile(t, tile_idx); hold(ax, 'on');
        
        for p = 1:4
            ml_id = PAPER_TO_ML(p);
            
            % CAM22
            vals_cam = cam.(col_cam)(cam.GMM_k4 == ml_id);
            vals_cam = vals_cam(~isnan(vals_cam));
            if ~isempty(vals_cam)
                bc1 = boxchart(ax, p*ones(size(vals_cam)) - 0.2, vals_cam);
                bc1.BoxFaceColor = PAPER_COLORS{p};
                bc1.MarkerColor = PAPER_COLORS{p};
                bc1.BoxFaceAlpha = 0.85;
                bc1.BoxWidth = 0.35;
                bc1.WhiskerLineColor = [0.2 0.2 0.2];
            end
            
            % WINT
            vals_wint = wint.(col_wint)(wint.GMM_k4 == ml_id);
            vals_wint = vals_wint(~isnan(vals_wint));
            if ~isempty(vals_wint)
                bc2 = boxchart(ax, p*ones(size(vals_wint)) + 0.2, vals_wint);
                bc2.BoxFaceColor = PAPER_COLORS{p};
                bc2.MarkerColor = PAPER_COLORS{p};
                bc2.BoxFaceAlpha = 0.30; % Transparency distinguishes WINT
                bc2.BoxWidth = 0.35;
                bc2.WhiskerLineColor = [0.2 0.2 0.2];
            end
        end
        
        xticks(ax, 1:4);
        xticklabels(ax, {'C1', 'C2', 'C3', 'C4'});
        xlim(ax, [0.4 4.6]);
        ylabel(ax, ylabel_str, 'FontSize', 11, 'FontWeight', 'bold');
        grid(ax, 'on'); box(ax, 'off');
        title(ax, ['(' letter ')'], 'Units', 'normalized', 'Position', [-0.15 1.05], 'HorizontalAlignment', 'left', 'FontSize', 16, 'FontWeight', 'bold');
    end

    draw_box_panel(2, 'Depth (km)', 'Neg_Depth', 'Neg_Depth', 'b');
    draw_box_panel(3, 'Attenuation ln(Q^{-1})', 'logS_AttenuationRF_Neg', 'logS_AttenuationRF_Neg', 'c');
    draw_box_panel(6, 'Temperature (\circC)', 'Temperature_N_CAM22', 'Temperature_N_WINT', 'd');
    draw_box_panel(7, 'Velocity perturbation (dV_s %)', 'dVsCAM22RF_Neg', 'dVsWINTRF_Neg', 'e');

    % Legend for Boxplots
    lg_ax = axes('Position', [0,0,1,1], 'Visible', 'off');
    h_cam = patch(lg_ax, nan, nan, [0.5 0.5 0.5], 'FaceAlpha', 0.85, 'EdgeColor', 'none');
    h_wint = patch(lg_ax, nan, nan, [0.5 0.5 0.5], 'FaceAlpha', 0.30, 'EdgeColor', 'none');
    legend(lg_ax, [h_cam, h_wint], {'CAM22', 'WINTERC-G'}, 'Location', 'north', 'Orientation', 'horizontal', 'FontSize', 12, 'Box', 'off');

    %% 5. Panel F: Contingency Heatmap
    ax_cont = nexttile(t, 4, [2, 1]);
    
    % Inner join on StationName
    [~, idxA, idxB] = intersect(cam.StationName, wint.StationName);
    df_cam22 = cam.GMM_k4(idxA);
    df_wint = wint.GMM_k4(idxB);
    
    % Raw cross-tabulation (ML labels: 0,1,2,3)
    raw_cont = zeros(4, 4);
    for i = 0:3
        for j = 0:3
            raw_cont(i+1, j+1) = sum(df_cam22 == i & df_wint == j);
        end
    end
    
    % Best match linear assignment
    cost = -raw_cont;
    M = matchpairs(cost, 1e6);
    mapping = containers.Map('KeyType', 'double', 'ValueType', 'double');
    for k = 1:size(M,1)
        % M(k,2) is WINT, M(k,1) is CAM
        mapping(M(k,2)-1) = M(k,1)-1; % -1 because matrix indices are 1-based, ML clusters are 0-based
    end
    
    % Apply mapping to WINT
    df_wint_mapped = zeros(size(df_wint));
    for k = 1:length(df_wint)
        if isKey(mapping, df_wint(k))
            df_wint_mapped(k) = mapping(df_wint(k));
        end
    end
    
    % Re-order by Paper Clusters: C1(2), C2(3), C3(0), C4(1)
    cont = zeros(4,4);
    for r = 1:4
        for c = 1:4
            c_ml_cam = PAPER_TO_ML(r);
            c_ml_win = PAPER_TO_ML(c);
            cont(r, c) = sum(df_cam22 == c_ml_cam & df_wint_mapped == c_ml_win);
        end
    end
    
    % Draw Heatmap manually with imagesc
    cmap = [linspace(1, 0.12, 256)', linspace(1, 0.31, 256)', linspace(1, 0.75, 256)']; % Blues
    imagesc(ax_cont, cont);
    colormap(ax_cont, cmap);
    caxis(ax_cont, [0, max(cont(:))]);
    
    xticks(ax_cont, 1:4); yticks(ax_cont, 1:4);
    xticklabels(ax_cont, {'C1', 'C2', 'C3', 'C4'});
    yticklabels(ax_cont, {'C1', 'C2', 'C3', 'C4'});
    xlabel(ax_cont, 'WINTERC-G cluster', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel(ax_cont, 'CAM22 cluster', 'FontSize', 12, 'FontWeight', 'bold');
    ax_cont.XAxisLocation = 'top';
    
    % Add text overlay
    row_totals = sum(cont, 2);
    for r = 1:4
        for c = 1:4
            v = cont(r,c);
            pct = 100 * v / row_totals(r);
            txt_color = 'k';
            if v / max(cont(:)) > 0.55, txt_color = 'w'; end
            
            text(ax_cont, c, r - 0.15, num2str(v), 'HorizontalAlignment', 'center', ...
                'FontSize', 14, 'FontWeight', 'bold', 'Color', txt_color);
            text(ax_cont, c, r + 0.15, sprintf('%.0f%%', pct), 'HorizontalAlignment', 'center', ...
                'FontSize', 10, 'Color', txt_color);
        end
    end
    
    cb = colorbar(ax_cont, 'southoutside');
    cb.Label.String = 'Stations';
    cb.Label.FontSize = 11;
    
    title(ax_cont, '(f)', 'Units', 'normalized', 'Position', [-0.10 1.05], 'HorizontalAlignment', 'left', 'FontSize', 16, 'FontWeight', 'bold');
    
    %% Save
    out_dir = '../../Figures/Global_Study';
    if ~isfolder(out_dir), mkdir(out_dir); end
    out_file = fullfile(out_dir, 'Figure2_FeatureStats_draft.png');
    exportgraphics(f, out_file, 'Resolution', 300);
    disp(['Figure saved as ', out_file]);
end
