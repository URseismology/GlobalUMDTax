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
Data_Global_RF.TectonicType = Data_Global_RF_ML.TectonicType;

valid_idx = ~isnan(Data_Global_RF.Neg_Depth);
Data_Valid = Data_Global_RF(valid_idx, :);

seismic_depth = Data_Valid.Neg_Depth;
gmm_k4 = Data_Valid.GMM_k4;
st_lon = Data_Valid.Longitude;
st_lat = Data_Valid.Latitude;
tectonic_type = Data_Valid.TectonicType;

%% 2. Load WINTERC-G LAB Data
disp('Loading WINTERC-G LAB Data...');
WINTERC_LAB_FILE = '../Data/WINTERC_G/WINTERC-G_LAB.txt';
LAB_winter_data = load(WINTERC_LAB_FILE);
LAB_winter_data_long = LAB_winter_data(:,2);
LAB_winter_data_long(LAB_winter_data_long > 180) = LAB_winter_data_long(LAB_winter_data_long > 180) - 360;
LAB_winter_lat = LAB_winter_data(:,3);
LAB_winter_depths = LAB_winter_data(:,4);

F_LAB_WINT = scatteredInterpolant(LAB_winter_data_long, LAB_winter_lat, LAB_winter_depths, 'linear', 'none');
st_wint_lab = F_LAB_WINT(st_lon, st_lat);

%% 3. Load CAM-22 LAB Data
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

%% Setup Clusters
idx_c1 = find(gmm_k4 == 2);
idx_c2 = find(gmm_k4 == 3);
idx_c3 = find(gmm_k4 == 0);
idx_c4 = find(gmm_k4 == 1);

c_indices = {idx_c1, idx_c2, idx_c3, idx_c4};
c_names = {'C1 (Melt)', 'C2 (Rheological)', 'C3 (Metasomatism)', 'C4 (Structural)'};
c_colors = {[0.3882, 0.3569, 0.5294], [0.6706, 0.3961, 0.6157], [0.4353, 0.6392, 0.4745], [0.8392, 0.5412, 0.0941]};

res_cam = seismic_depth - st_cam_lab;
res_wint = seismic_depth - st_wint_lab;

%% Figure 1: GMM Modeling of Distributions
disp('Generating Figure 1: GMM Mode Fitting...');
figure('Position', [50, 50, 1400, 1000]);
fs = 12;

model_residuals = {res_cam, res_wint};
model_names = {'CAM-22', 'WINTERC-G'};

options = statset('MaxIter', 500);
global_min = min([res_cam(:); res_wint(:)]);
global_max = max([res_cam(:); res_wint(:)]);
shared_xlim = [global_min - 20, global_max + 20];

for m = 1:2
    for c = 1:4
        subplot(4, 2, (c-1)*2 + m);
        hold on;
        
        X = model_residuals{m}(c_indices{c});
        X = X(~isnan(X));
        X = X(:);
        
        if length(X) > 5
            % Plot Histogram
            histogram(X, 'Normalization', 'pdf', 'FaceColor', c_colors{c}, 'EdgeColor', 'w');
            
            % Fit GMM
            best_bic = inf;
            best_gmm = [];
            max_k = min(3, floor(length(X)/5));
            for k = 1:max_k
                try
                    gm = fitgmdist(X, k, 'Options', options, 'Replicates', 5, 'RegularizationValue', 0.1);
                    if gm.BIC < best_bic
                        best_bic = gm.BIC;
                        best_gmm = gm;
                    end
                catch
                    % Ignore fitting errors for poorly conditioned k
                end
            end
            
            if ~isempty(best_gmm)
                % Plot GMM PDF
                x_grid = linspace(shared_xlim(1), shared_xlim(2), 1000)';
                y_grid = pdf(best_gmm, x_grid);
                plot(x_grid, y_grid, 'k-', 'LineWidth', 2);
                
                % Display Modes and plot vertical lines
                modes = sort(best_gmm.mu);
                mode_str = 'Modes: ';
                yl = ylim;
                for i = 1:length(modes)
                    mode_str = [mode_str, sprintf('%.1f km ', modes(i))];
                    plot([modes(i) modes(i)], yl, 'k:', 'LineWidth', 1.5);
                end
                
                % Add text box
                xl = shared_xlim;
                text(xl(1) + 0.05*diff(xl), yl(2) - 0.1*diff(yl), mode_str, 'FontSize', fs-2, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k');
            end
        end
        
        plot([0 0], ylim, 'r--', 'LineWidth', 2); % LAB line
        xlim(shared_xlim);
        
        if c == 4
            xlabel(sprintf('Residual (Seismic - %s) [km]', model_names{m}), 'FontSize', fs, 'FontWeight', 'bold');
        end
        if m == 1
            ylabel(c_names{c}, 'FontSize', fs, 'FontWeight', 'bold');
        end
        if c == 1
            title(sprintf('%s LAB', model_names{m}), 'FontSize', fs+2);
        end
        
        set(gca, 'FontSize', fs, 'LineWidth', 1.5);
        grid on; box on;
    end
end

if ~exist('./Figures/Global_Study', 'dir')
    mkdir('./Figures/Global_Study');
end
exportgraphics(gcf, './Figures/Global_Study/FigSup1_GMM_Distributions.png', 'Resolution', 300);


%% Figure 2: Tectonic Breakdown (Box Plots)
disp('Generating Figure 2: Tectonic Breakdowns...');
figure('Position', [50, 50, 1800, 500]);
tec_names = {'Cratons', 'Precambrian', 'Phanerozoic', 'Ridges/Backarcs', 'Oceanic', 'Old Oceanic'};

for c = 1:4
    subplot(1, 4, c);
    hold on;
    
    c_tec = tectonic_type(c_indices{c});
    c_res_cam = res_cam(c_indices{c});
    c_res_wint = res_wint(c_indices{c});
    
    valid_cam = ~isnan(c_res_cam) & ~isnan(c_tec) & (c_tec >= 1 & c_tec <= 6);
    valid_wint = ~isnan(c_res_wint) & ~isnan(c_tec) & (c_tec >= 1 & c_tec <= 6);
    
    tec_combined = [c_tec(valid_cam); c_tec(valid_wint)];
    res_combined = [c_res_cam(valid_cam); c_res_wint(valid_wint)];
    model_group = [ones(sum(valid_cam), 1); 2*ones(sum(valid_wint), 1)]; % 1=CAM, 2=WINT
    
    if ~isempty(res_combined)
        % Space each tectonic type by 2 units for visual clarity
        tec_numeric = tec_combined * 2; 
        model_cat = categorical(model_group, 1:2, {'CAM-22', 'WINTERC-G'});
        
        bc = boxchart(tec_numeric, res_combined, 'GroupByColor', model_cat);
    end
    
    % Draw horizontal lines every 100 km
    for y_line = -200:100:200
        if y_line == 0
            plot([1 13], [0 0], 'r--', 'LineWidth', 2, 'HandleVisibility', 'off'); % LAB line
        else
            plot([1 13], [y_line y_line], 'k:', 'LineWidth', 1, 'HandleVisibility', 'off');
        end
    end
    
    % Draw vertical lines at each tectonic type separation (between groups)
    for x_line = 3:2:11
        plot([x_line x_line], [-200 200], '-', 'Color', [0.8 0.8 0.8], 'LineWidth', 1, 'HandleVisibility', 'off');
    end
    
    ylim([-200 200]);
    xlim([1 13]);
    set(gca, 'XTick', 2:2:12, 'XTickLabel', tec_names);
    
    xlabel('Tectonic Region', 'FontSize', fs, 'FontWeight', 'bold');
    if c == 1
        ylabel('Residual (Seismic - LAB) [km]', 'FontSize', fs, 'FontWeight', 'bold');
    end
    title(c_names{c}, 'FontSize', fs+2);
    
    set(gca, 'FontSize', fs-2, 'LineWidth', 1.5);
    xtickangle(45);
    grid off; box on;
    
    if c == 4
        legend('Location', 'best');
    end
end

exportgraphics(gcf, './Figures/Global_Study/FigSup1_Tectonic_BoxPlots.png', 'Resolution', 300);
fprintf('\nSaved visualizations to ./Figures/Global_Study/FigSup1_GMM_Distributions.png and FigSup1_Tectonic_BoxPlots.png\n');
