%% Add the current directory and subdirectories to the path
addpath(genpath(pwd));

%% Load datasets
% Load data for positive and negative values
sequencedData_negs = load('All_stations_nvg_sequenced.mat');
sequencedData_pos = load('ss_noAfrica_pos_reordered.mat');

% Define variables for negative and positive datasets
t = sequencedData_negs.time_vector;
imageRFs_negs = sequencedData_negs.dataset_imageRFs_reordered;

imageRFs_pos = sequencedData_pos.dataset_imageRFs_reordered;
continents_pos = cellstr(sequencedData_pos.continents_reordered);
stations_pos = cellstr(sequencedData_pos.station_names_reordered);
latitudes_pos = sequencedData_pos.coordinates_reordered(:,1);
longitudes_pos = sequencedData_pos.coordinates_reordered(:,2);


% Assign colors to continents
continent_colors = containers.Map({'oceania', 'south america', 'europe', 'asia', 'north america'}, ...
    {[0, 0, 1], [0, 1, 0], [1, 1, 0], [0, 1, 1], [1, 0, 0]}); %SA,US,Austr ...

% Output dataset initialization
global outputData;
outputData = {};  % Initialize as an empty cell array

%% Process and Plot NVG (Negative Wiggle Plots)
[modifiedRFs_negs, ~] = process_rf_data(imageRFs_negs, t, 'NVG', continent_colors);

%% Process and Plot PVG (Positive Wiggle Plots)
%[~, modifiedRFs_pos] = process_rf_data(imageRFs_pos, t, 'PVG', continent_colors);

%%
window_size = 10; % window size for semblance computation
step = 1; % step size for semblance computation

% Semblance-weighted stacking for the current cluster
semblance = compute_semblance(modifiedRFs_negs, window_size, step); % Compute semblance
weightedRFs = modifiedRFs_negs .* repmat(semblance, size(modifiedRFs_negs, 1), 1);
meanTrace_negs = nanmean(weightedRFs, 1);
meanTrace_negs(isnan(meanTrace_negs)) = 0;

% Semblance-weighted stacking for the current cluster
% semblance = compute_semblance(modifiedRFs_pos, window_size, step); % Compute semblance
% weightedRFs = modifiedRFs_pos .* repmat(semblance, size(modifiedRFs_pos, 1), 1);
% meanTrace_pos = nanmean(weightedRFs, 1);
% meanTrace_pos(isnan(meanTrace_pos)) = 0;

%%
% Read the CSV file into a table
data = readtable('Reordered_Global_paired_complete.csv');

% Extract the necessary columns
Neg_Depth = data.Neg_Depth;
Pos_Depth = data.Pos_Depth;
categories = data.Category;

% Clean the data by removing rows with NaNs or invalid values
valid_idx = ~isnan(Neg_Depth) & ~isnan(Pos_Depth) & ~strcmp(categories, '');
Neg_Depth_clean = Neg_Depth(valid_idx);
Pos_Depth_clean = Pos_Depth(valid_idx);
categories_clean = categories(valid_idx);

% Define min and max depths for plotting
min_depth = min([Neg_Depth_clean; Pos_Depth_clean]) - 10; % Subtract 10 for padding
max_depth = max([Neg_Depth_clean; Pos_Depth_clean]) + 10; % Add 10 for padding

% Initialize the figure
figure(3); clf;
subplot(4,4,[6:4:14,8:4:16]);

face_alpha = 0.7;  % Transparency value
hold on;

% Plot the one-to-one line (y = x)
plot([min_depth, max_depth], [min_depth, max_depth], '-b', 'LineWidth', 1.3);

% Plot the depth windows as dashed lines (20 km, 40 km, 60 km, 80 km)
depth_offsets = [20, 40, 60, 80];  % Define the offset distances

for offset = depth_offsets
    % Plot the upper dashed line (y = x + offset)
    plot([min_depth, max_depth], [min_depth + offset, max_depth + offset], '--b', 'LineWidth', 0.6);
    
    % Plot the lower dashed line (y = x - offset)
    plot([min_depth, max_depth], [min_depth - offset, max_depth - offset], '--b', 'LineWidth', 0.6);
end

% Plot the average Moho depth (35 km) with a thick magenta line
moho_depth = 35;
plot([0, 350], [moho_depth, moho_depth], '--m', 'LineWidth', 2, 'DisplayName', 'Avg Moho Depth (Horizontal)'); % Horizontal line

% Define custom colors for each category using specified RGB values
category_colors = containers.Map();
category_colors('LVD') = [0, 1, 0];       % Green for LVD
category_colors('LVL') = [1, 0.5, 0];     % Orange for LVL
category_colors('HVL') = [0.5, 0, 0.5];   % Purple for HVL

% Get the unique categories
category_list = unique(categories_clean);

% Loop through categories and plot each group with custom colors
for i = 1:length(category_list)
    cat = category_list{i};
    idx = strcmp(categories_clean, cat);
    
    % Check if the category has a defined color
    if isKey(category_colors, cat)
        marker_color = category_colors(cat);
    else
        marker_color = [0, 0, 0]; % Default to black if color not defined
    end
    
    scatter(Neg_Depth_clean(idx), Pos_Depth_clean(idx), 100, ...
            'MarkerFaceColor', marker_color, ...
            'MarkerEdgeColor', 'k', ...
            'MarkerFaceAlpha', face_alpha, ...
            'DisplayName', cat);
end

xlabel('NVG Depth (km)','FontSize',15);
ylabel('PVG Depth (km)','FontSize',15);
title('Categorization of NVG vs PVG Depths by Stratification Type','FontSize',15);
%legend('Location', 'best');
xlim([30 330])
ylim([30 330])
grid on;

meanVp = 8.1; meanVs = 4.55;
depth_axis = t./ ((1/meanVs) - (1/meanVp));

subplot(4,4,2:4)
%create a stack wiggle plot n depths 
fillpart = meanTrace_negs < 0;                  %Change here
jbfill(depth_axis(fillpart), meanTrace_negs(fillpart), zeros(size(meanTrace_negs(fillpart))), 'red', 'none', 0, 1);   %Change here
hold on
plot(depth_axis, meanTrace_negs, 'k', 'LineWidth', 1);
title('NVG Depth (km)','FontSize',20);
%ylabel('Amplitude');
ylim([-0.16, 0.05]);
xlim([30, 330]);
hold off;
%camroll(270);
grid on

subplot(4,4,5:4:13)
% %create a stack wiggle plot stack of p depths
% fillpart = meanTrace_pos > 0;                  %Change here
% jbfill(depth_axis(fillpart), meanTrace_pos(fillpart), zeros(size(meanTrace_pos(fillpart))), 'blue', 'none', 0, 1);   %Change here
% hold on
% plot(depth_axis, meanTrace_pos, 'k', 'LineWidth', 1);
% xlabel('PVG Depth (km)','FontSize',20);
% %ylabel('Amplitude');
% ylim([-0.05, 0.15]);
% xlim([30, 330]);
% set(gca,"XDir","reverse")
% hold off;
% camroll(270);
% grid on
% set(gca,"XDir","reverse")
%print(figure(3),'./Figures/Figure3_scatter','-vector','-dpdf','-r0')
%%
% Load the data
data = readtable('Reordered_Global_paired_update_Africa.csv');

% Extract the necessary columns
Neg_Depth = data.Neg_Depth;
Pos_Depth = data.Pos_Depth;
categories = data.Category;

% Initialize logical masks for each condition
SDa_mask = strcmp(categories, 'LVD') & Neg_Depth <= 130;
SDb_mask = strcmp(categories, 'LVD') & Neg_Depth > 130 & Neg_Depth < 250;
DDa_mask = (strcmp(categories, 'LVL') | strcmp(categories, 'HVL')) & Neg_Depth <= 130 & Pos_Depth < 250;
DDb_mask = (strcmp(categories, 'LVL') | strcmp(categories, 'HVL')) & Neg_Depth > 130 & Pos_Depth < 250;

% Count data points for each group
SDa_count = sum(SDa_mask);
SDb_count = sum(SDb_mask);
DDa_count = sum(DDa_mask);
DDb_count = sum(DDb_mask);

% Calculate total counts
total_count = height(data);
total_SD_count = SDa_count + SDb_count;
total_DD_count = DDa_count + DDb_count;

% Calculate percentages
SDa_percentage_total = (SDa_count / total_count) * 100;
SDb_percentage_total = (SDb_count / total_count) * 100;
DDa_percentage_total = (DDa_count / total_count) * 100;
DDb_percentage_total = (DDb_count / total_count) * 100;

SDa_percentage_SD = (SDa_count / total_SD_count) * 100;
SDb_percentage_SD = (SDb_count / total_SD_count) * 100;

DDa_percentage_DD = (DDa_count / total_DD_count) * 100;
DDb_percentage_DD = (DDb_count / total_DD_count) * 100;

% Display the results
fprintf('Percentage out of total data:\n');
fprintf('SDa: %.2f%%\n', SDa_percentage_total);
fprintf('SDb: %.2f%%\n', SDb_percentage_total);
fprintf('DDa: %.2f%%\n', DDa_percentage_total);
fprintf('DDb: %.2f%%\n', DDb_percentage_total);

fprintf('\nPercentage among SDs:\n');
fprintf('SDa: %.2f%%\n', SDa_percentage_SD);
fprintf('SDb: %.2f%%\n', SDb_percentage_SD);

fprintf('\nPercentage among DDs:\n');
fprintf('DDa: %.2f%%\n', DDa_percentage_DD);
fprintf('DDb: %.2f%%\n', DDb_percentage_DD);

% Create the stacked histogram
group_counts = [SDa_count, SDb_count; DDa_count, DDb_count];
group_labels = {'SDa', 'SDb'; 'DDa', 'DDb'};

% Define bar positions and labels
x_positions = [1, 2];
group_names = {'Single Discontinuity (SD)', 'Double Discontinuity (DD)'};

% Plot the stacked histogram
figure;
bar(x_positions, group_counts, 'stacked');

% Customize the plot
xticks(x_positions);
xticklabels(group_names);
ylabel('Count');
legend(group_labels(:), 'Location', 'NorthEast');
title('Stacked Histogram of Discontinuities');
grid on;


% Save the figure (optional)
%print(figure(1),'./Figures/Figure1_hist','-vector','-dpdf','-r0')

%% Function to process receiver function data and plot
function [modifiedRFs_negs, modifiedRFs_pos] = process_rf_data(imageRFs, t, type, continent_colors)

modifiedRFs_negs = zeros(size(imageRFs,1), size(imageRFs,2));
modifiedRFs_pos = zeros(size(imageRFs,1), size(imageRFs,2));

figure('Name', ['Wiggle Plot: ', type], 'NumberTitle', 'off');
clf;

% Subplot for continent colored bars
subplot(1, 10, 1);
% hold on;
% for ii = 1:size(imageRFs, 1)
%     continent_color = continent_colors(continents{ii});
%     plot([0, 1], [ii, ii], 'Color', continent_color, 'LineWidth', 4);
% end
% xlim([0, 1]); ylim([0, size(imageRFs, 1)]); axis off;

% Main plot for wiggle traces
subplot(1, 10, 2:10);
hold on;

% Loop through each station to process data
for ii = 1:size(imageRFs, 1)
    trace = imageRFs(ii, :) - mean(imageRFs(ii, :));
    trace_norm = trace / max(abs(trace));
    trace_norm = -trace_norm;

    % Separate positive and negative traces for coloring
    if strcmp(type, 'NVG')
        trace_norm(trace_norm > 0) = 0;  % Keep only negative values
        modifiedRFs_negs(ii, :) = trace_norm;
    else
        trace_norm(trace_norm < 0) = 0;  % Keep only positive values
        modifiedRFs_pos(ii, :) = trace_norm;
    end

    yvals = trace_norm + ii;
    zeroLine = ii * ones(size(t));
    negatives = trace_norm < 0;
    positives = trace_norm > 0;

    % Plot wiggle trace
    jbfill(t(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], 'none', 0);
    jbfill(t(positives), yvals(positives), zeroLine(positives), [0 0 1], 'none', 0);
    %plot(t, yvals, 'k','LineWidth', 0.05);

    % Get station's max time from arrival data
    %maxTime = get_station_arrival_time(stations{ii}, arrival_times);

    % Plot max time as a vertical line
    %plot([maxTime, maxTime], [ii - 0.5, ii + 0.5], '-k', 'LineWidth', 1);
end

xlim([6 30]); ylim([1, size(imageRFs, 1) + 1]);
xlabel('Time (s)');
ylabel('Station Index');
title([type, ' Wiggle Plot']);
end

%% Helper function to get closest Vp/Vs from tomography data
function [Vp, Vs] = get_closest_velocity(tomoData, lat, lon)
[~, idx] = min(sqrt((tomoData.Latitude - lat).^2 + (tomoData.Longitude - lon).^2));
Vp = tomoData.Vp_km_s_(idx);
Vs = tomoData.Vs_km_s_(idx);
end


