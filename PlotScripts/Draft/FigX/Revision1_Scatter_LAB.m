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

% Filter for specific categories (LVL, HVL) if needed
% For now we use all valid data where Neg_Depth is not NaN
valid_idx = ~isnan(Data_Global_RF.Neg_Depth);
Data_Valid = Data_Global_RF(valid_idx, :);

seismic_depth = Data_Valid.Neg_Depth;
gmm_k4 = Data_Valid.GMM_k4;
st_lon = Data_Valid.Longitude;
st_lat = Data_Valid.Latitude;

%% 2. Load WINTERC-G LAB Data
disp('Loading WINTERC-G LAB Data...');
WINTERC_LAB_FILE = '../../Data/WINTERC_G/WINTERC-G_LAB.txt';
LAB_winter_data = load(WINTERC_LAB_FILE);
LAB_winter_data_long = LAB_winter_data(:,2);
LAB_winter_data_long(LAB_winter_data_long > 180) = LAB_winter_data_long(LAB_winter_data_long > 180) - 360;
LAB_winter_lat = LAB_winter_data(:,3);
LAB_winter_depths = LAB_winter_data(:,4);

% Interpolate to station coordinates
F_LAB_WINT = scatteredInterpolant(LAB_winter_data_long, LAB_winter_lat, LAB_winter_depths, 'linear', 'none');
st_wint_lab = F_LAB_WINT(st_lon, st_lat);

%% 3. Load CAM-22 LAB Data
disp('Loading CAM-22 LAB Data...');
CAM22_LAB_FILE = '../../Data/Velocity_Models/CAM2022-lithosphere.r0.0.nc';

cam_info = ncinfo(CAM22_LAB_FILE);
cam_vars = {cam_info.Variables.Name};

% Find Longitude, Latitude, and Depth variables
cam_lon_var = cam_vars{contains(cam_vars, 'lon', 'IgnoreCase', true)};
cam_lat_var = cam_vars{contains(cam_vars, 'lat', 'IgnoreCase', true)};

% The LAB depth might be 'depth', 'z', or 'LAB'
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
    % Fallback if exactly one remaining variable
    rem_vars = cam_vars(~ismember(cam_vars, {cam_lon_var, cam_lat_var}));
    cam_depth_var = rem_vars{1};
end

cam_lon = ncread(CAM22_LAB_FILE, cam_lon_var);
cam_lat = ncread(CAM22_LAB_FILE, cam_lat_var);
cam_lab_grid = ncread(CAM22_LAB_FILE, cam_depth_var);

% Note: NetCDF grids are typically 2D or need meshgrid
if isvector(cam_lon) && isvector(cam_lat) && ismatrix(cam_lab_grid)
    [CAM_LON, CAM_LAT] = ndgrid(cam_lon, cam_lat);
    % Wrap longitude if needed
    CAM_LON(CAM_LON > 180) = CAM_LON(CAM_LON > 180) - 360;
    
    % Use scattered interpolant for ease
    F_LAB_CAM = scatteredInterpolant(double(CAM_LON(:)), double(CAM_LAT(:)), double(cam_lab_grid(:)), 'linear', 'none');
    st_cam_lab = F_LAB_CAM(st_lon, st_lat);
else
    % Fallback if it's already a scattered format
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

c1_color = [0.3882, 0.3569, 0.5294];
c2_color = [0.6706, 0.3961, 0.6157];
c3_color = [0.4353, 0.6392, 0.4745];
c4_color = [0.8392, 0.5412, 0.0941];

%% 4. Correlation Analysis
fprintf('\n--- Correlation between Seismic Depth and Thermal LAB Depth ---\n');

% Filter out NaNs for correlation
valid_wint = ~isnan(st_wint_lab) & ~isnan(seismic_depth);
[R_wint, p_wint] = corr(seismic_depth(valid_wint), st_wint_lab(valid_wint), 'Type', 'Spearman');
fprintf('WINTERC-G LAB vs Seismic Depth: Spearman R = %.2f (p = %.4f)\n', R_wint, p_wint);

valid_cam = ~isnan(st_cam_lab) & ~isnan(seismic_depth);
[R_cam, p_cam] = corr(seismic_depth(valid_cam), st_cam_lab(valid_cam), 'Type', 'Spearman');
fprintf('CAM-22 LAB vs Seismic Depth: Spearman R = %.2f (p = %.4f)\n', R_cam, p_cam);


%% 5. Cluster Analysis (C1 vs C3 Residuals)
% Residual = Seismic Depth - LAB Depth
% Negative residual -> Seismic boundary is shallower than LAB (Lithosphere)
% Positive residual -> Seismic boundary is deeper than LAB (Asthenosphere)

res_wint = seismic_depth - st_wint_lab;
res_cam = seismic_depth - st_cam_lab;

fprintf('\n--- Cluster Depth Relationships (Residuals) ---\n');
fprintf('Residual = Seismic Depth - Thermal LAB Depth\n');

fprintf('\nCluster 1 (Melt):\n');
fprintf('  Mean Residual (WINTERC-G): %.1f km\n', mean(res_wint(idx_c1), 'omitnan'));
fprintf('  Mean Residual (CAM-22): %.1f km\n', mean(res_cam(idx_c1), 'omitnan'));

fprintf('\nCluster 3 (Metasomatism):\n');
fprintf('  Mean Residual (WINTERC-G): %.1f km\n', mean(res_wint(idx_c3), 'omitnan'));
fprintf('  Mean Residual (CAM-22): %.1f km\n', mean(res_cam(idx_c3), 'omitnan'));


%% 6. Plotting: Scatter Plots (Figure 1 Extension)
fs = 18;
psz = 100;

figure(1);
set(gcf, 'Position', [100, 100, 1800, 800]);

% Subplot 1: Neg_Depth vs CAM-22 LAB Depth
subplot(1, 2, 1);
hold on;
% 1:1 Reference Line
max_depth = max([max(st_cam_lab), max(seismic_depth)]) + 50;
plot([0, max_depth], [0, max_depth], 'k--', 'LineWidth', 2);

scatter(st_cam_lab(idx_c4), seismic_depth(idx_c4), psz, 'MarkerFaceColor', c4_color, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
scatter(st_cam_lab(idx_c3), seismic_depth(idx_c3), psz, 'MarkerFaceColor', c3_color, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
scatter(st_cam_lab(idx_c2), seismic_depth(idx_c2), psz, 'MarkerFaceColor', c2_color, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
scatter(st_cam_lab(idx_c1), seismic_depth(idx_c1), psz, 'MarkerFaceColor', c1_color, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

set(gca, 'YDir', 'reverse', 'XDir', 'reverse'); % Depth increases downwards
xlim([0 max_depth]); ylim([0 max_depth]);
xlabel('CAM-22 Thermal LAB Depth (km)', 'FontSize', fs, 'FontWeight', 'bold');
ylabel('Seismic Boundary Depth (km)', 'FontSize', fs, 'FontWeight', 'bold');
title('Seismic Boundary vs CAM-22 Thermal LAB', 'FontSize', fs+2);
set(gca, 'FontSize', fs, 'LineWidth', 2);
grid on; box on;
legend('1:1 Reference', 'C4 (Structural)', 'C3 (Metasomatism)', 'C2 (Rheological)', 'C1 (Melt)', 'Location', 'southwest', 'FontSize', fs-4);

% Subplot 2: Neg_Depth vs WINTERC-G LAB Depth
subplot(1, 2, 2);
hold on;
% 1:1 Reference Line
max_depth = max([max(st_wint_lab), max(seismic_depth)]) + 50;
plot([0, max_depth], [0, max_depth], 'k--', 'LineWidth', 2);

scatter(st_wint_lab(idx_c4), seismic_depth(idx_c4), psz, 'MarkerFaceColor', c4_color, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
scatter(st_wint_lab(idx_c3), seismic_depth(idx_c3), psz, 'MarkerFaceColor', c3_color, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
scatter(st_wint_lab(idx_c2), seismic_depth(idx_c2), psz, 'MarkerFaceColor', c2_color, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
scatter(st_wint_lab(idx_c1), seismic_depth(idx_c1), psz, 'MarkerFaceColor', c1_color, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

set(gca, 'YDir', 'reverse', 'XDir', 'reverse');
xlim([0 max_depth]); ylim([0 max_depth]);
xlabel('WINTERC-G Thermal LAB Depth (km)', 'FontSize', fs, 'FontWeight', 'bold');
ylabel('Seismic Boundary Depth (km)', 'FontSize', fs, 'FontWeight', 'bold');
title('Seismic Boundary vs WINTERC-G Thermal LAB', 'FontSize', fs+2);
set(gca, 'FontSize', fs, 'LineWidth', 2);
grid on; box on;

% Save figure
if ~exist('./Figures/Global_Study', 'dir')
    mkdir('./Figures/Global_Study');
end
exportgraphics(gcf, './Figures/Global_Study/Revision1_LAB_Scatter.png', 'Resolution', 300);
fprintf('\nSaved scatter plot to ./Figures/Global_Study/Revision1_LAB_Scatter.png\n');
