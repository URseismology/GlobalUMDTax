clear 
close all
clc

%% 1. Load Seismic Data
disp('Loading Seismic Data...');
Data_Global_RF_Meta = readtable('./Data/MachineLearningData/rf_global_clustering/data/Data_Global_R1Meta.csv');
Data_Global_RF_ML = readtable('./Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv');

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

%% Setup Clusters
idx_c1 = find(gmm_k4 == 2);
idx_c2 = find(gmm_k4 == 3);
idx_c3 = find(gmm_k4 == 0);
idx_c4 = find(gmm_k4 == 1);

c_indices = {idx_c1, idx_c2, idx_c3, idx_c4};
c_names = {'C1 (Melt)', 'C2 (Rheological)', 'C3 (Metasomatism)', 'C4 (Structural)'};
c_colors = {[0.3882, 0.3569, 0.5294], [0.6706, 0.3961, 0.6157], [0.4353, 0.6392, 0.4745], [0.8392, 0.5412, 0.0941]};

model_labs = {st_cam_lab, st_wint_lab};
model_names = {'CAM-22', 'WINTERC-G'};

%% Figure 1: 2x2 Joint-Distribution KDE Scatter Plots
disp('Generating Joint-Distribution KDE Scatter Plots...');
figure('Position', [50, 50, 1400, 1200], 'Color', 'w');
fs = 14;

% Layout setup
row_groups = {[2, 3], [1, 4]}; % Row 1: C2, C3. Row 2: C1, C4.

x0 = 0.08; y0 = 0.08;
w_main = 0.34; h_main = 0.34;
w_marg = 0.06; h_marg = 0.06;
dx = 0.46; dy = 0.46;

shared_limits = [10, 300];

for m = 1:2
    for r = 1:2
        % Calculate positions for this 2x2 grid panel
        px = x0 + (m-1)*dx;
        py = y0 + (2-r)*dy;
        
        main_ax = axes('Position', [px, py, w_main, h_main]);
        hold on;
        
        top_ax = axes('Position', [px, py+h_main+0.01, w_main, h_marg]);
        hold on;
        
        right_ax = axes('Position', [px+w_main+0.01, py, w_marg, h_main]);
        hold on;
        
        % Plot the 1:1 line on main axis
        plot(main_ax, [0 400], [0 400], 'r--', 'LineWidth', 2);
        
        max_density_x = 0;
        max_density_y = 0;
        
        for cluster_id = row_groups{r}
            x_data = model_labs{m}(c_indices{cluster_id});
            y_data = seismic_depth(c_indices{cluster_id});
            
            valid = ~isnan(x_data) & ~isnan(y_data);
            x_data = x_data(valid);
            y_data = y_data(valid);
            
            if length(x_data) < 5, continue; end
            
            % --- 1. Compute 2D KDE for Scatter ---
            % Evaluate density at the exact data points
            try
                f_density = ksdensity([x_data, y_data], [x_data, y_data]);
                
                % Normalize density to [0.1, 1] to keep all points somewhat visible
                f_norm = (f_density - min(f_density)) / (max(f_density) - min(f_density) + eps);
                f_norm = 0.2 + 0.8 * f_norm; 
                
                % Map to RGB color fading from white to cluster color
                C_rgb = (1 - f_norm) * [0.9 0.9 0.9] + f_norm * c_colors{cluster_id};
                
                % Plot Scatter
                scatter(main_ax, x_data, y_data, 30, C_rgb, 'filled', 'MarkerFaceAlpha', 0.7, 'MarkerEdgeColor', 'none');
            catch
                % Fallback if 2D KDE fails
                scatter(main_ax, x_data, y_data, 30, c_colors{cluster_id}, 'filled', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none');
            end
            
            % --- 2. Compute 1D Marginals ---
            [f_x, xi_x] = ksdensity(x_data, 'Support', [0, 400]);
            fill(top_ax, xi_x, f_x, c_colors{cluster_id}, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
            plot(top_ax, xi_x, f_x, '-', 'Color', c_colors{cluster_id}, 'LineWidth', 1.5);
            max_density_x = max(max_density_x, max(f_x));
            
            [f_y, xi_y] = ksdensity(y_data, 'Support', [0, 400]);
            fill(right_ax, f_y, xi_y, c_colors{cluster_id}, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
            plot(right_ax, f_y, xi_y, '-', 'Color', c_colors{cluster_id}, 'LineWidth', 1.5);
            max_density_y = max(max_density_y, max(f_y));
        end
        
        % --- Formatting ---
        % Main axis
        xlim(main_ax, shared_limits); ylim(main_ax, shared_limits);
        set(main_ax, 'FontSize', fs-2, 'LineWidth', 1.5, 'Box', 'on', 'GridColor', [0.8 0.8 0.8]);
        grid(main_ax, 'on');
        
        if r == 2
            xlabel(main_ax, sprintf('%s Thermal LAB Depth [km]', model_names{m}), 'FontSize', fs, 'FontWeight', 'bold');
        else
            set(main_ax, 'XTickLabel', []);
        end
        if m == 1
            ylabel(main_ax, 'Seismic Depth [km]', 'FontSize', fs, 'FontWeight', 'bold');
        else
            set(main_ax, 'YTickLabel', []);
        end
        
        % Add legend text
        xl = shared_limits;
        title_str = sprintf('%s vs %s', c_names{row_groups{r}(1)}, c_names{row_groups{r}(2)});
        
        if r == 1
            title(top_ax, sprintf('%s', model_names{m}), 'FontSize', fs+4, 'FontWeight', 'bold');
        end
        text(main_ax, xl(1)+10, xl(2)-20, c_names{row_groups{r}(1)}, 'FontSize', fs, 'FontWeight', 'bold', 'Color', c_colors{row_groups{r}(1)});
        text(main_ax, xl(1)+10, xl(2)-40, c_names{row_groups{r}(2)}, 'FontSize', fs, 'FontWeight', 'bold', 'Color', c_colors{row_groups{r}(2)});
        
        % Marginals
        xlim(top_ax, shared_limits);
        ylim(top_ax, [0, max_density_x * 1.1]);
        set(top_ax, 'XTickLabel', [], 'YTickLabel', [], 'XColor', 'none', 'YColor', 'none');
        
        ylim(right_ax, shared_limits);
        xlim(right_ax, [0, max_density_y * 1.1]);
        set(right_ax, 'XTickLabel', [], 'YTickLabel', [], 'XColor', 'none', 'YColor', 'none');
    end
end

if ~exist('./Figures/Global_Study', 'dir')
    mkdir('./Figures/Global_Study');
end
exportgraphics(gcf, './Figures/Global_Study/Revision1_Summary_Scatter_LAB.png', 'Resolution', 300);
fprintf('\nSaved visualization to ./Figures/Global_Study/Revision1_Summary_Scatter_LAB.png\n');
