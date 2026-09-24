function Figure1_CRISP_Denoising()
    % Figure 1: CRISP-RF denoising validation.
    % (a) raw, unsorted Ps-RFs, ~700 stations
    % (b) denoised + sorted Ps-RFs, ~700 stations, coherent mantle conversions emerge
    % (c) Sp-RF benchmark, Hua et al. (2023), same 122-station subset as (d)
    % (d) this study's denoised Ps-RFs, restricted to the same station subset as (c)
    %
    % Both (c) and (d) are sorted by ONE shared key: this study's own
    % Ps-RF NVG pick (Neg_Depth, from the clustering pipeline's CAM22
    % table), ascending. Row i is therefore the same station in both
    % panels. This study's pick was chosen over Hua's own NVG pick as
    % the sort key because it has full 122/122 coverage (Hua's has 24
    % NaN picks) and spans the full 60-265 km range this study resolves,
    % rather than being capped at Hua's 69-140 km detection window.
    clear; close all; clc;

    addpath('../Fig1');  % jbfill.m

    %% 0. Config
    CFG.font_label = 35;
    CFG.font_tick  = 25;
    CFG.font_panel = 35;
    CFG.font_title = 35;

    c_neg = [0.80, 0.10, 0.10];  % red  = velocity decrease
    c_pos = [0.10, 0.10, 0.80];  % blue = velocity increase

    LABEL_DEPTH = 'Depth (km)';
    LABEL_STA   = 'Station Index';

    DEPTH_LIM = [60, 300];  % shared depth window across all four panels

    %% 1. Load data
    a   = load('Data_S1a_raw_RF.mat');        % panel (a)
    b   = load('Data_S1b_sortedRF.mat');      % panel (b)
    hsp = load('Hua_SpRF_Data.mat');          % panel (c)
    hps = load('Hua_subset_PsRF_data.mat');   % panel (d)

    % (c)/(d) are row-for-row aligned by station (verified: hsp row i ==
    % hps row i). Sort both by this study's own Ps-RF NVG pick so the
    % coherent structure this study resolves lines up in the same row
    % across both panels; unmatched/NaN picks sort to the end.
    this_study_depth = match_this_study_nvg(hps.station_names, ...
        '../../Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv');
    [~, ord] = sort(this_study_depth);
    RF_c = hsp.RF_matrix(ord, :);
    RF_d = hps.rf_matrix(ord, :);

    %% 2. Figure + fixed-size 2x2 axes grid, each panel 2:1 (W:H) physical aspect
    % Solve the geometry so the two columns exactly fill the figure width
    % (no leftover right-margin whitespace) while every panel is still a
    % strict 2:1 (width:height) rectangle on screen. No panel titles (the
    % caption covers that), so margins only need to fit axis labels/ticks.
    PANEL_ASPECT = 2.0;   % width:height
    FIG_W_PX = 1900;
    panel_h = 0.34;       % fraction of figure height, chosen for row spacing below
    left_margin = 0.10; right_margin = 0.02; col_gap = 0.015;
    bottom_margin = 0.11; row_gap = 0.17;  % row_gap fits row-above's xlabel/ticks + row-below's title

    panel_w = (1 - left_margin - right_margin - col_gap) / 2;  % fills width exactly
    panel_w_px = panel_w * FIG_W_PX;
    panel_h_px = panel_w_px / PANEL_ASPECT;
    FIG_H_PX = round(panel_h_px / panel_h);

    f = figure('Name', 'Figure 1: CRISP-RF Denoising', 'Position', [50, 50, FIG_W_PX, FIG_H_PX], ...
        'Color', 'w', 'Visible', 'off');

    px = [left_margin, left_margin + panel_w + col_gap];
    py = [bottom_margin + panel_h + row_gap, bottom_margin];

    % (a) raw Ps-RF, ~700 stations — leftmost column: keep depth axis
    ax_a = axes('Position', [px(1), py(1), panel_w, panel_h]);
    plot_wiggle_time(ax_a, a.giant_rf_matrix, a.time_vector, c_neg, c_pos, CFG, LABEL_DEPTH, LABEL_STA, true, true);
    title(ax_a, 'Ps-RF (Raw)', 'FontSize', CFG.font_title, 'FontWeight', 'bold');
    add_panel_letter(f, px(1), py(1), 'a', CFG);

    % (b) denoised + sorted Ps-RF, ~700 stations — depth axis same as (a), suppressed
    ax_b = axes('Position', [px(2), py(1), panel_w, panel_h]);
    plot_wiggle_time(ax_b, b.rf_matrix, b.time_vector, c_neg, c_pos, CFG, LABEL_DEPTH, LABEL_STA, false, true);
    title(ax_b, 'Ps-RF (Denoised)', 'FontSize', CFG.font_title, 'FontWeight', 'bold');
    add_panel_letter(f, px(2), py(1), 'b', CFG);

    % (c) Sp-RF benchmark, Hua et al. (2023) — leftmost column: keep depth axis
    ax_c = axes('Position', [px(1), py(2), panel_w, panel_h]);
    plot_wiggle_depth(ax_c, RF_c, hsp.depthRange(:)', c_neg, c_pos, CFG, LABEL_DEPTH, LABEL_STA, true, true, DEPTH_LIM);
    title(ax_c, 'Sp-RF (Benchmark)', 'FontSize', CFG.font_title, 'FontWeight', 'bold');
    add_panel_letter(f, px(1), py(2), 'c', CFG);

    % (d) this study's denoised Ps-RF, same station subset as (c) — depth axis suppressed
    ax_d = axes('Position', [px(2), py(2), panel_w, panel_h]);
    plot_wiggle_time(ax_d, RF_d, hps.time_vector, c_neg, c_pos, CFG, LABEL_DEPTH, LABEL_STA, false, true);
    title(ax_d, 'Ps-RF (This Study)', 'FontSize', CFG.font_title, 'FontWeight', 'bold');
    add_panel_letter(f, px(2), py(2), 'd', CFG);

    %% 3. Export
    drawnow;
    out_dir = '../../Figures/Global_Study';
    if ~exist(out_dir, 'dir'); mkdir(out_dir); end
    out_file = fullfile(out_dir, 'Figure1_CRISP_Denoising_Draft.png');
    exportgraphics(f, out_file, 'Resolution', 300);
    fprintf('Saved %s\n', out_file);
end

function plot_wiggle_time(ax, RF, t, c_neg, c_pos, CFG, depth_lab, sta_lab, show_depth_axis, show_sta_axis)
    % Wiggle plot on a Ps-RF time axis (s), relabeled to depth (km) via
    % the fixed 10x mapping used elsewhere in this codebase (6->60 ... 30->300).
    draw_wiggles(ax, RF, t, c_neg, c_pos);
    xlim(ax, [6, 30]);
    xticks(ax, [6, 10:5:30]);
    if show_depth_axis
        xticklabels(ax, [60, 100:50:300]);
        xlabel(ax, depth_lab, 'FontSize', CFG.font_label, 'FontWeight', 'bold');
    else
        xticklabels(ax, []);
    end
    finish_axes(ax, sta_lab, CFG, show_sta_axis);
end

function plot_wiggle_depth(ax, RF, depth, c_neg, c_pos, CFG, depth_lab, sta_lab, show_depth_axis, show_sta_axis, depth_lim)
    % Wiggle plot already on a real depth (km) axis (Hua Sp-RF data).
    draw_wiggles(ax, RF, depth, c_neg, c_pos);
    xlim(ax, depth_lim);
    if show_depth_axis
        xlabel(ax, depth_lab, 'FontSize', CFG.font_label, 'FontWeight', 'bold');
    else
        xticklabels(ax, []);
    end
    finish_axes(ax, sta_lab, CFG, show_sta_axis);
end

function draw_wiggles(ax, RF, x, c_neg, c_pos)
    axes(ax); hold(ax, 'on');
    n = size(RF, 1);
    for ii = 1:n
        trace = RF(ii, :) - mean(RF(ii, :), 'omitnan');
        m = max(abs(trace), [], 'omitnan');
        if m == 0 || isnan(m), continue; end
        trace_norm = trace / m;
        yvals = trace_norm + ii;
        zeroLine = ii * ones(size(x));
        neg = trace_norm < 0;
        pos = trace_norm > 0;
        jbfill(x(pos), yvals(pos), zeroLine(pos), c_pos, 'none', 1, 1.0);
        jbfill(x(neg), yvals(neg), zeroLine(neg), c_neg, 'none', 1, 1.0);
    end
    ylim(ax, [0, n + 1]);
end

function finish_axes(ax, sta_lab, CFG, show_sta_axis)
    if show_sta_axis
        ylabel(ax, sta_lab, 'FontSize', CFG.font_label, 'FontWeight', 'bold');
    else
        set(ax, 'YTickLabel', []);
    end
    box(ax, 'on');
    set(ax, 'LineWidth', 1.5, 'FontSize', CFG.font_tick, 'YAxisLocation', 'right');
    camroll(ax, 270);
end

function add_panel_letter(f, x, y_bottom, letter, CFG)
    % Inset inside the panel's bottom-left corner, tight box (no floating
    % annotation above the panel, minimal padding around the glyph).
    annotation(f, 'textbox', [x + 0.006, y_bottom + 0.006, 0.05, 0.05], 'String', sprintf('(%s)', letter), ...
        'EdgeColor', 'none', 'BackgroundColor', 'w', 'Margin', 1, ...
        'FontSize', CFG.font_panel, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
end

function neg_depth = match_this_study_nvg(station_names, csv_path)
    % Match a Ps-RF station list (network-station codes, e.g. "AU-ARMA")
    % to this study's own Neg_Depth (NVG pick) by bare station code.
    csv = readtable(csv_path);
    csv_codes = bare_code(string(csv.StationName));
    target_codes = bare_code(string(station_names));

    neg_depth = nan(numel(target_codes), 1);
    [tf, idx] = ismember(target_codes, csv_codes);
    neg_depth(tf) = csv.Neg_Depth(idx(tf));
end

function codes = bare_code(names)
    % Strip a network prefix separated by '-' or '_', keeping the last token.
    codes = strings(size(names));
    for i = 1:numel(names)
        parts = strsplit(names(i), {'-', '_'});
        codes(i) = parts{end};
    end
end
