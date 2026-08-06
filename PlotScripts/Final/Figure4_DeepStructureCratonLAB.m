% Figure5A_PaleoCoastlines.m
clear; clc; close all;

addpath('../../Data/m_map');
out_dir = '../../Figures/Global_Study';
if ~isfolder(out_dir), mkdir(out_dir); end

%% 1. Load Data
stats_dir = '../../Data/MachineLearningData/rf_global_clustering/results/';
meta_dir = '../../Data/MachineLearningData/rf_global_clustering/data/';
cam22_opts = detectImportOptions(fullfile(stats_dir, 'clustered_data_Neg_CAM22.csv'));
cam22_data = readtable(fullfile(stats_dir, 'clustered_data_Neg_CAM22.csv'), cam22_opts);
meta_opts = detectImportOptions(fullfile(meta_dir, 'Data_Global_R1Meta.csv'));
meta_data = readtable(fullfile(meta_dir, 'Data_Global_R1Meta.csv'), meta_opts);

all_lats = meta_data.Latitude;
all_lons = meta_data.Longitude;
all_labels = cam22_data.GMM_k4;
all_conts = lower(meta_data.Continent);
num_all = length(all_lats);

% C4 is raw label 1.
idx_c4 = find(all_labels == 1);
num_c4 = length(idx_c4);

mat_file = '../VedSlabContours/Reconstructed_Subduction_Zones_Youngeta2018.mat';
load(mat_file); % sz struct array

% Group slabs
g1_lats = []; g1_lons = []; % Phase 3: 50-120
g2_lats = []; g2_lons = []; % Phase 2: 120-175
g3_lats = []; g3_lons = []; % Phase 1: 175-260

for j = 1:length(sz)
    age = sz(j).age;
    if age >= 50 && age <= 120
        g1_lats = [g1_lats; sz(j).lat(:)]; g1_lons = [g1_lons; sz(j).lon(:)];
    elseif age > 120 && age <= 175
        g2_lats = [g2_lats; sz(j).lat(:)]; g2_lons = [g2_lons; sz(j).lon(:)];
    elseif age > 175 && age <= 260
        g3_lats = [g3_lats; sz(j).lat(:)]; g3_lons = [g3_lons; sz(j).lon(:)];
    end
end

%% 2. Calculate Distances for ALL stations
min_dist_all_stations = zeros(num_all, 1);
closest_group_all = zeros(num_all, 1);

fprintf('Calculating distances for all %d stations...\n', num_all);
for i = 1:num_all
    st_lat = all_lats(i);
    st_lon = all_lons(i);
    d1 = inf; d2 = inf; d3 = inf;
    if ~isempty(g1_lats), d1 = min(distance(st_lat, st_lon, g1_lats, g1_lons)); end
    if ~isempty(g2_lats), d2 = min(distance(st_lat, st_lon, g2_lats, g2_lons)); end
    if ~isempty(g3_lats), d3 = min(distance(st_lat, st_lon, g3_lats, g3_lons)); end
    [min_dist_all_stations(i), closest_group_all(i)] = min([d1, d2, d3]);
end

PLOT_THRESH = 1; % Reduced threshold as requested to see if distributions align closer 

% C4 specific metrics
c4_min_dist = min_dist_all_stations(idx_c4);
proximal_c4_idx = c4_min_dist <= PLOT_THRESH;

%% 3. Continent-by-Continent Statistical Test (Excluding C1)
% C1 is label 2, C2 is 3, C3 is 0, C4 is 1.
valid_idx = (all_labels ~= 2); % Exclude C1

valid_labels = all_labels(valid_idx);
valid_prox = (min_dist_all_stations(valid_idx) <= PLOT_THRESH);
valid_conts = all_conts(valid_idx);

is_c4 = (valid_labels == 1);

unique_conts = unique(valid_conts);
unique_conts(strcmp(unique_conts, 'continent')) = []; % Remove header artifact if present
unique_conts(strcmp(unique_conts, '')) = [];

n_conts = length(unique_conts);
slab_prev = zeros(1, n_conts);
c4_prev = zeros(1, n_conts);
cont_labels = cell(1, n_conts);

for i = 1:n_conts
    c_name = unique_conts{i};
    idx_c = strcmp(valid_conts, c_name);
    n_c = sum(idx_c);
    
    slab_prev(i) = sum(valid_prox(idx_c)) / n_c * 100;
    c4_prev(i) = sum(is_c4(idx_c)) / n_c * 100;
    
    % Capitalize for plot
    words = split(c_name, ' ');
    for w = 1:length(words)
        words{w}(1) = upper(words{w}(1));
    end
    cont_labels{i} = strjoin(words, ' ');
    if strcmp(cont_labels{i}, 'North America'), cont_labels{i} = 'N. America'; end
    if strcmp(cont_labels{i}, 'South America'), cont_labels{i} = 'S. America'; end
end

% Sort by slab prevalence
[slab_prev, sort_idx] = sort(slab_prev);
c4_prev = c4_prev(sort_idx);
cont_labels = cont_labels(sort_idx);

%% 4. Multi-panel Plot (Manual Layout for Overlap)
f = figure('Position', [100, 100, 1800, 550], 'Color', 'w');

c_g1 = [0.2 0.4 0.8]; % Blue (Phase 3)
c_g2 = [0.9 0.6 0.1]; % Orange (Phase 2)
c_g3 = [0.8 0.1 0.2]; % Red (Phase 1)

% We draw in reverse order (Map 3, Map 2, Map 1) so that Left overlaps Middle, Middle overlaps Right.

% Map 3: Phase 3 (50-120 Ma) - Youngest (Right) (shifted left to overlap Pacific)
ax3 = axes('Position', [0.64, 0.05, 0.34, 0.9]);
m_proj('robinson', 'long', [-180 180], 'lat', [-90 90]);
fprintf('Fetching 90 Ma coastlines from GPlates Web Service...\n');
data_90 = webread('http://gws.gplates.org/reconstruct/coastlines/?time=90&model=SETON2012');
hold on;
for i = 1:length(data_90.features)
    plot_geojson_coords(data_90.features(i).geometry.coordinates);
end
for j = 1:length(sz)
    if sz(j).age >= 50 && sz(j).age <= 110
        m_plot(sz(j).lon, sz(j).lat, '-', 'color', c_g1, 'linewidth', 2);
    end
end
m_line(all_lons(idx_c4(~proximal_c4_idx)), all_lats(idx_c4(~proximal_c4_idx)), 'marker', 'd', 'color', 'k', 'linest', 'none', 'markersize', 5, 'markerfacecolor', 'w', 'linewidth', 0.5);
m_line(all_lons(idx_c4(proximal_c4_idx)), all_lats(idx_c4(proximal_c4_idx)), 'marker', 'd', 'color', 'k', 'linest', 'none', 'markersize', 6, 'markerfacecolor', 'k');
m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
m_text(170, 80, '110-50 Ma', 'FontSize', 16, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'BackgroundColor', 'w');

% Map 2: Phase 2 (120-175 Ma) - Middle (shifted left to overlap Pacific)
ax2 = axes('Position', [0.33, 0.05, 0.34, 0.9]);
m_proj('robinson', 'long', [-180 180], 'lat', [-90 90]);
fprintf('Fetching 150 Ma coastlines from GPlates Web Service...\n');
data_150 = webread('http://gws.gplates.org/reconstruct/coastlines/?time=150&model=SETON2012');
hold on;
for i = 1:length(data_150.features)
    plot_geojson_coords(data_150.features(i).geometry.coordinates);
end
for j = 1:length(sz)
    if sz(j).age >= 120 && sz(j).age <= 160
        m_plot(sz(j).lon, sz(j).lat, '-', 'color', c_g2, 'linewidth', 2);
    end
end
m_line(all_lons(idx_c4(~proximal_c4_idx)), all_lats(idx_c4(~proximal_c4_idx)), 'marker', 'd', 'color', 'k', 'linest', 'none', 'markersize', 5, 'markerfacecolor', 'w', 'linewidth', 0.5);
m_line(all_lons(idx_c4(proximal_c4_idx)), all_lats(idx_c4(proximal_c4_idx)), 'marker', 'd', 'color', 'k', 'linest', 'none', 'markersize', 6, 'markerfacecolor', 'k');
m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
m_text(170, 80, '160-120 Ma', 'FontSize', 16, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'BackgroundColor', 'w');

% Map 1: Phase 1 (175-260 Ma) - Oldest (Left)
ax1 = axes('Position', [0.02, 0.05, 0.34, 0.9]);
m_proj('robinson', 'long', [-180 180], 'lat', [-90 90]);
fprintf('Fetching 200 Ma coastlines from GPlates Web Service...\n');
data_200 = webread('http://gws.gplates.org/reconstruct/coastlines/?time=200&model=SETON2012');
hold on;
for i = 1:length(data_200.features)
    plot_geojson_coords(data_200.features(i).geometry.coordinates);
end
for j = 1:length(sz)
    if sz(j).age >= 170 && sz(j).age <= 260
        m_plot(sz(j).lon, sz(j).lat, '-', 'color', c_g3, 'linewidth', 2);
    end
end
m_line(all_lons(idx_c4(~proximal_c4_idx)), all_lats(idx_c4(~proximal_c4_idx)), 'marker', 'd', 'color', 'k', 'linest', 'none', 'markersize', 5, 'markerfacecolor', 'w', 'linewidth', 0.5);
m_line(all_lons(idx_c4(proximal_c4_idx)), all_lats(idx_c4(proximal_c4_idx)), 'marker', 'd', 'color', 'k', 'linest', 'none', 'markersize', 6, 'markerfacecolor', 'k');
m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
m_text(170, 80, '260-170 Ma', 'FontSize', 16, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'BackgroundColor', 'w');

% Top-left legend for diamonds (Aleutians location)
h4 = plot(NaN,NaN,'d','color','k','markerfacecolor','k');
h5 = plot(NaN,NaN,'d','color','k','markerfacecolor','w');
lgd = legend(ax1, [h4,h5], {sprintf('C4 Proximal (\\leq %d\\circ)', PLOT_THRESH), sprintf('C4 Distal (> %d\\circ)', PLOT_THRESH)}, 'Location', 'northwest');
lgd.FontSize = 14;
lgd.Box = 'on';
lgd.Color = 'w';
lgd.EdgeColor = 'w';
lgd.Position(1) = ax1.Position(1) + 0.05;
lgd.Position(2) = ax1.Position(2) + ax1.Position(4) - 0.25;

% 5. INSET STATISTICS (Bottom Left of Map 1)
% Use normalized figure coordinates for the inset axes
ax_inset = axes('Position', [0.03, 0.25, 0.08, 0.25]);
b = bar([slab_prev', c4_prev'], 'grouped', 'FaceColor', 'flat');
b(1).CData = repmat([0.4 0.4 0.4], n_conts, 1); % Dark Grey for Slab Prevalence
b(2).CData = repmat([0.2 0.6 0.2], n_conts, 1); % Green for C4 Prevalence
set(gca, 'XTick', 1:n_conts, 'XTickLabel', cont_labels, 'XTickLabelRotation', 45, 'FontSize', 12);
ylabel('Prevalence (%)', 'FontSize', 10);
title(ax_inset, 'Explaining C4', 'FontSize', 16, 'FontWeight', 'bold');
grid on;
ylim([0 100]);
% Inset Legend
lgd_inset = legend({'Model', 'Observation'}, 'Location', 'northwest', 'FontSize', 12);
lgd_inset.Box = 'off';

out_file = fullfile(out_dir, 'Figure4_DeepStructureCratonLAB.png');
fprintf('Saved %s\n', out_file);
exportgraphics(f, out_file, 'Resolution', 300);
disp(['Saved ', out_file]);
