clear 
close all
clc

%% 1. Load Seismic Data
disp('Loading Seismic Data...');
Data_Global_RF_Meta = readtable('./Data/MachineLearningData/rf_global_clustering/data/Data_Global_R1Meta.csv');
Data_Global_RF_ML = readtable('./Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv');

% Merge data (assuming exact same row order as in previous scripts)
Data_Global_RF = Data_Global_RF_Meta;
Data_Global_RF.Neg_Depth = Data_Global_RF_ML.Neg_Depth;
Data_Global_RF.GMM_k4 = Data_Global_RF_ML.GMM_k4;
Data_Global_RF.TectonicType = Data_Global_RF_ML.TectonicType;

% Filter for specific categories (LVL, HVL) if needed
% For now we use all valid data where Neg_Depth is not NaN
valid_idx = ~isnan(Data_Global_RF.Neg_Depth);
Data_Valid = Data_Global_RF(valid_idx, :);

seismic_depth = Data_Valid.Neg_Depth;
gmm_k4 = Data_Valid.GMM_k4;
st_lon = Data_Valid.Longitude;
st_lat = Data_Valid.Latitude;
tectonic_type = Data_Valid.TectonicType;

%% 2. Load WINTERC-G LAB Data
disp('Loading WINTERC-G LAB Data...');
WINTERC_LAB_FILE = '../../Data/WINTERC_G/WINTERC-G_LAB.txt';
LAB_winter_data = load(WINTERC_LAB_FILE);
LAB_winter_data_long = LAB_winter_data(:,2);
LAB_winter_data_long(LAB_winter_data_long > 180) = LAB_winter_data_long(LAB_winter_data_long > 180) - 360;
LAB_winter_lat = LAB_winter_data(:,3);
LAB_winter_depths = LAB_winter_data(:,4);

F_LAB_WINT = scatteredInterpolant(LAB_winter_data_long, LAB_winter_lat, LAB_winter_depths, 'linear', 'none');
st_wint_lab = F_LAB_WINT(st_lon, st_lat);

%% 3. Load CAM-22 LAB Data
disp('Loading CAM-22 LAB Data...');
CAM22_LAB_FILE = '../../Data/Velocity_Models/CAM2022-lithosphere.r0.0.nc';

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

%% Cluster Assignments
% GMM_k4 == 2: C1 (Melt)
% GMM_k4 == 3: C2 (Rheological)
% GMM_k4 == 0: C3 (Metasomatism)
% GMM_k4 == 1: C4 (Structural)

idx_c1 = find(gmm_k4 == 2);
idx_c2 = find(gmm_k4 == 3);
idx_c3 = find(gmm_k4 == 0);
idx_c4 = find(gmm_k4 == 1);

c_indices = {idx_c1, idx_c2, idx_c3, idx_c4};
c_names = {'C1 (Melt)', 'C2 (Rheological)', 'C3 (Metasomatism)', 'C4 (Structural)'};
c_colors = {[0.3882, 0.3569, 0.5294], [0.6706, 0.3961, 0.6157], [0.4353, 0.6392, 0.4745], [0.8392, 0.5412, 0.0941]};

%% 4. Cluster-Specific Correlation Analysis
fprintf('\n--- Cluster-Specific Correlation (Seismic vs Thermal LAB) ---\n');
for i = 1:4
    idx = c_indices{i};
    valid_wint = ~isnan(st_wint_lab(idx)) & ~isnan(seismic_depth(idx));
    [R_w, p_w] = corr(seismic_depth(idx(valid_wint)), st_wint_lab(idx(valid_wint)), 'Type', 'Spearman');
    
    valid_cam = ~isnan(st_cam_lab(idx)) & ~isnan(seismic_depth(idx));
    [R_c, p_c] = corr(seismic_depth(idx(valid_cam)), st_cam_lab(idx(valid_cam)), 'Type', 'Spearman');
    
    fprintf('%s:\n', c_names{i});
    fprintf('  CAM-22 Correlation:    R = %6.2f (p = %.4f)\n', R_c, p_c);
    fprintf('  WINTERC-G Correlation: R = %6.2f (p = %.4f)\n', R_w, p_w);
end

%% 5. Tectonic Pattern Analysis for Melt (C1)
fprintf('\n--- Melt (C1) Residual Analysis by Tectonic Region ---\n');
res_wint = seismic_depth - st_wint_lab;
res_cam = seismic_depth - st_cam_lab;

% 1-Cratons, 2-Precambrian F&T, 3-Phanerozoic, 4-Ridges & Backarcs, 5-Oceanic, 6-Oldest Oceanic
tec_names = {'Cratons', 'Precambrian', 'Phanerozoic', 'Ridges/Backarcs', 'Oceanic', 'Old Oceanic'};

c1_tec = tectonic_type(idx_c1);
c1_res_cam = res_cam(idx_c1);
c1_res_wint = res_wint(idx_c1);

for t = 1:6
    idx_t = find(c1_tec == t);
    if isempty(idx_t), continue; end
    mean_cam = mean(c1_res_cam(idx_t), 'omitnan');
    mean_wint = mean(c1_res_wint(idx_t), 'omitnan');
    fprintf('%s (N=%d):\n', tec_names{t}, length(idx_t));
    fprintf('  Mean Residual (CAM-22):    %5.1f km\n', mean_cam);
    fprintf('  Mean Residual (WINTERC-G): %5.1f km\n', mean_wint);
end

%% 6. Visualizations
figure('Position', [100, 100, 1800, 600]);
fs = 14;

% Panel A: Density Plot of Residuals (CAM-22)
subplot(1, 3, 1);
hold on;
for i = 1:4
    valid = ~isnan(res_cam(c_indices{i}));
    [f, xi] = ksdensity(res_cam(c_indices{i}(valid)));
    plot(xi, f, 'LineWidth', 2.5, 'Color', c_colors{i});
end
plot([0 0], ylim, 'k--', 'LineWidth', 2); % 0 is the LAB
xlabel('Residual (Seismic - CAM-22 LAB) [km]', 'FontSize', fs, 'FontWeight', 'bold');
ylabel('Probability Density', 'FontSize', fs, 'FontWeight', 'bold');
title('Distribution of Depth Residuals (CAM-22)', 'FontSize', fs);
set(gca, 'FontSize', fs, 'LineWidth', 2);
legend([c_names, {'Thermal LAB'}], 'Location', 'best', 'FontSize', fs-2);
grid on; box on;

% Panel B: Density Plot of Residuals (WINTERC-G)
subplot(1, 3, 2);
hold on;
for i = 1:4
    valid = ~isnan(res_wint(c_indices{i}));
    [f, xi] = ksdensity(res_wint(c_indices{i}(valid)));
    plot(xi, f, 'LineWidth', 2.5, 'Color', c_colors{i});
end
plot([0 0], ylim, 'k--', 'LineWidth', 2); % 0 is the LAB
xlabel('Residual (Seismic - WINTERC-G LAB) [km]', 'FontSize', fs, 'FontWeight', 'bold');
ylabel('Probability Density', 'FontSize', fs, 'FontWeight', 'bold');
title('Distribution of Depth Residuals (WINTERC-G)', 'FontSize', fs);
set(gca, 'FontSize', fs, 'LineWidth', 2);
grid on; box on;

% Panel C: Box Plot of Melt (C1) Residuals by Tectonic Type
subplot(1, 3, 3);
% We will plot CAM-22 residuals for this boxplot as an example
% Create a categorical array for tectonic names
tec_labels = categorical(c1_tec, 1:6, tec_names);
boxplot(c1_res_cam, tec_labels, 'Colors', c_colors{1});
hold on;
plot(xlim, [0 0], 'k--', 'LineWidth', 2); % 0 is the LAB
xlabel('Tectonic Region', 'FontSize', fs, 'FontWeight', 'bold');
ylabel('Residual (Seismic - CAM-22 LAB) [km]', 'FontSize', fs, 'FontWeight', 'bold');
title('C1 (Melt) Depth vs Tectonic Setting', 'FontSize', fs);
set(gca, 'FontSize', fs-2, 'LineWidth', 2);
xtickangle(45);
grid on; box on;

% Save figure
if ~exist('./Figures/Global_Study', 'dir')
    mkdir('./Figures/Global_Study');
end
exportgraphics(gcf, './Figures/Global_Study/Revision1_FollowUp_LAB_Distributions.png', 'Resolution', 300);
fprintf('\nSaved visualizations to ./Figures/Global_Study/Revision1_FollowUp_LAB_Distributions.png\n');
