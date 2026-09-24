localBaseDir = '/scratch/tolugboj_lab/';
%localBaseDir = '/Users/stevecarr/Documents/bluehive/';
FUNCDIR = [localBaseDir 'Prj7_RadonT/RFImager_EvansVersion/2_Functions/'];

maindir = [localBaseDir 'Prj7_RadonT/RFImager_EvansVersion/3_Workflw/Global_codes_Figs/'];
addpath(FUNCDIR); addpath(maindir);
addpath([localBaseDir 'Prj7_RadonT/RFImager_EvansVersion/3_Workflw/Global_codes_Figs/2_Data/Hua_Sp_RFs/Dataset/']);

%%
% pairedData = readtable([maindir 'Reordered_Global_paired_complete.csv']);
% 
% % Set directory path for Hua et al data
% dataFolder = [maindir '2_Data/Hua_Sp_RFs/Dataset/RF/'];
% destinationFolder = [maindir '2_Data/Hua_Sp_RFs/Dataset/Global_stations/'];
% %%
% % Copy matching Hua data to chosen directory 
% % Get the list of files in the RF folder
% fileList = dir(fullfile(dataFolder, '*.txt'));
% 
% for i = 1:length(fileList)
%     % Extract Network and Station codes from file name
%     filename = fileList(i).name;
%     splitName = split(filename, '_');
%     networkCode = splitName{1};
%     stationCode = splitName{2}(1:end-4); % Remove '.txt' extension
% 
%     % Check if this Network-Station pair exists in pairedData
%     isMatch = any(strcmp(pairedData.Network, networkCode) & strcmp(pairedData.Station, stationCode));
%     if isMatch
%         % Copy the file to the destination folder
%         sourceFile = fullfile(dataFolder, filename);
%         destinationFile = fullfile(destinationFolder, filename);
%         copyfile(sourceFile, destinationFile);
%         fprintf('Copied %s to %s\n', filename, destinationFolder);
%     end
% end
% 
% disp('File copying complete for all matching stations.');
% %%
% %Build Sp matrix of matching Hua Stations
% 
% dataFolder = [maindir '2_Data/Hua_Sp_RFs/Dataset/Global_stations/']; 
% 
% % Initialize fields for the .mat file
% depthRange = (0:300)';  % Depth range from 0 to 300 km
% numDepths = length(depthRange);
% fileList = dir(fullfile(dataFolder, '*.txt'));
% numStations = length(fileList);
% 
% % Initialize matrices to store data
% RF_matrix = NaN(numStations, numDepths); % Each row will hold RF amplitudes for a station
% NVG_depth = NaN(numStations, 1);
% NVG_probability = NaN(numStations, 1);
% PVG_depth = NaN(numStations, 1);
% PVG_probability = NaN(numStations, 1);
% stationNames = cell(numStations, 1);  % To store station names
% networkNames = cell(numStations, 1);  % To store network names
% 
% for i = 1:numStations
%     % Extract file name and parse network/station codes
%     filename = fileList(i).name;
%     splitName = split(filename, '_');
%     networkCode = splitName{1};
%     stationCode = splitName{2}(1:end-4); % Remove '.txt' extension
%     filePath = fullfile(dataFolder, filename);
% 
%     % Open and read the file
%     fid = fopen(filePath, 'r');
% 
%     % Skip the header line
%     fgetl(fid);
% 
%     % Read metadata line (second line)
%     metaLine = fgetl(fid);
%     metaData = textscan(metaLine, '%s %s %f %f %f %f %f %f %f %f');
%     PVG_prob = metaData{5}; % Probability of PVG-150
%     PVG_depthVal = metaData{6}; % Depth of PVG-150
%     NVG_prob = metaData{7}; % Probability of NVG
%     NVG_depthVal = metaData{8}; % Depth of NVG
% 
%     % Handle cases where metadata values are empty
%     if isempty(PVG_prob); PVG_prob = NaN; end
%     if isempty(PVG_depthVal); PVG_depthVal = NaN; end
%     if isempty(NVG_prob); NVG_prob = NaN; end
%     if isempty(NVG_depthVal); NVG_depthVal = NaN; end
% 
%     % Read receiver function data from line 3 onward
%     rfData = textscan(fid, '%f %f %f %f', 'HeaderLines', 2);
%     fclose(fid);
% 
%     % Extract relevant data up to 300 km depth
%     depth = rfData{1};
%     rfAmplitude = rfData{2};
%     validIdx = depth <= 300;  % Only keep depths 0-300 km
% 
%     % Store data into matrices
%     RF_matrix(i, validIdx) = rfAmplitude(validIdx)';
%     NVG_depth(i) = NVG_depthVal;
%     NVG_probability(i) = NVG_prob;
%     PVG_depth(i) = PVG_depthVal;
%     PVG_probability(i) = PVG_prob;
%     stationNames{i} = stationCode;
%     networkNames{i} = networkCode;
% end
% 
% % Save data to a .mat file
% save('Global_SpRF_Data.mat', 'depthRange', 'RF_matrix', 'NVG_depth', 'NVG_probability', 'PVG_depth', 'PVG_probability', 'stationNames', 'networkNames');
% 
% disp('Global_SpRF_Data.mat file created successfully.');
%%
%Plot Ps receiver functions
% Data = load('Hua_pos_subset.mat');
% imageRFs = Data.Hua_pos_subset.dataset_imageRF;
% t = Data.Hua_pos_subset.time_vector;
% staion_names = Data.Hua_pos_subset.station_name;
% 
% % Define figure and subplots
% figure(2); clf;
% 
% for ii = 1:size(imageRFs, 1)
%     trace = imageRFs(ii, :)- mean(imageRFs(ii, :));
%     trace_norm = trace / max(abs(trace));
%     trace_norm = -trace_norm;
% 
%     %trace_norm(trace_norm > 0) = 0;   
% 
%     yvals = trace_norm + ii;
%     zeroLine = ii * ones(size(t));
%     negatives = trace_norm < 0;
%     positives = trace_norm > 0;
% 
%     jbfill(t(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], [0 0 0], 1,0.8);
%     jbfill(t(positives), yvals(positives), zeroLine(positives), [0 0 1], [0 0 0], 1,0.8);
% end
% 
% xlim([6 30]);
% ylim([-1, size(imageRFs, 1) + 2]);  % Adjusted for spacing
% xlabel('Time (s)');
% ylabel('Ordered Station Index');
% 
% % Ensure the plot is fully rendered
% drawnow;
% camroll(270)
% %print(figure(2),'./Figures/Hua_Sp_RFs','-vector','-dpdf','-r0')
%%
% %Plot Hua Sp receiver functions
% Metadata = readtable('Extracted_Metadata.txt');
% 
% Data = load('Hua_SpRF_Data.mat');
% station_names = Data.stationNames;
% imageRFs = Data.RF_matrix;
% t = Data.depthRange;
% t=t';
% 
% % Process station names to get the PVG probabilities
% metadataStations = Metadata.Station;
% metadataNetworks = Metadata.Network;
% metadataPVGProb = Metadata.PVG_Probability;
% 
% % Initialize an array to store probabilities for each station in Data
% PVG_probabilities = NaN(size(station_names));
% 
% % Match station names to Metadata and retrieve PVG probabilities
% for i = 1:length(station_names)
%     % Extract station name by splitting on hyphen or underscore if needed
%     parts = split(station_names{i}, {'-', '_'});
%     station = parts{end};  % Assume last part is station name
%     % Find matching station in Metadata
%     match_idx = find(strcmp(metadataStations, station));
% 
%     if ~isempty(match_idx)
%         % Store the PVG probability from Metadata
%         PVG_probabilities(i) = metadataPVGProb(match_idx);
%     end
% end
% 
% % Separate non-NaN and NaN PVG probabilities
% nonNaN_indices = find(~isnan(PVG_probabilities));
% NaN_indices = find(isnan(PVG_probabilities));
% 
% % Sort non-NaN indices by PVG probability in descending order
% [~, nonNaN_sorted_indices] = sort(PVG_probabilities(nonNaN_indices), 'descend');
% sorted_indices = [nonNaN_indices(nonNaN_sorted_indices); NaN_indices];  % Append NaN indices at the end
% 
% % Define figure and subplots
% figure(2); clf;
% 
% for ii = 1:length(sorted_indices)
%     idx = sorted_indices(ii);
%     trace = imageRFs(idx, :);
%     trace_norm = trace / max(abs(trace));
% 
%     yvals = trace_norm + ii;
%     zeroLine = ii * ones(size(t));
%     negatives = trace_norm < 0;
%     positives = trace_norm > 0;
% 
%     jbfill(t(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], [0.3 0.3 0.3], 1, 0.8);
%     jbfill(t(positives), yvals(positives), zeroLine(positives), [0 0 1], [0.3 0.3 0.3], 1, 0.8);
% 
%     % Output station name and PVG probability
%     disp(['Station Name: ', station_names{idx}, ', PVG Probability: ', num2str(PVG_probabilities(idx))]);
% end
% 
% % Set plot limits and labels
% xlim([0 300]);
% ylim([-1, length(sorted_indices) + 2]);
% xlabel('Time (s)');
% ylabel('Ordered Station Index');
% 
% % Ensure the plot is fully rendered and rotate
% drawnow;
% camroll(270);
% %print(figure(2),'./Figures/Hua_Sp_RFs','-vector','-dpdf','-r0')


%%
% Load data from Hua_pos_subset
Data = load('Hua_neg_subset.mat');
imageRFs_subset = Data.Hua_neg_subset.dataset_imageRF;
t = Data.Hua_neg_subset.time_vector;
station_names_subset = string(Data.Hua_neg_subset.station_name);

%Load Ps-RFs for this study
GiantData = load('paired_filtered_giant_rf_matrix.mat');
imageRFs_giant = GiantData.giant_rf_matrix;
station_names_giant = string(GiantData.giant_station_names);
time_vector_giant = GiantData.time_vector;

% GiantData =  load('merged_categories_data.mat');
% imageRFs_giant = GiantData.rf_matrix;
% station_names_giant = string(GiantData.station_names);
% time_vector_giant = GiantData.time_vector;

% Process station names to isolate only station codes (last part of the name)
station_codes_subset = arrayfun(@(name) strtrim(split(name, {'-', '_'})), station_names_subset, 'UniformOutput', false);
station_codes_subset = cellfun(@(code) code{end}, station_codes_subset, 'UniformOutput', false); % Get last part

station_codes_giant = arrayfun(@(name) strtrim(split(name, {'-', '_'})), station_names_giant, 'UniformOutput', false);
station_codes_giant = cellfun(@(code) code{end}, station_codes_giant, 'UniformOutput', false); % Get last part

% Find indices in giant_rf_matrix that match station_codes in Hua_pos_subset
matching_indices = [];
for i = 1:length(station_codes_subset)
    % Locate the index of each station in the giant station codes
    idx = find(strcmp(station_codes_giant, station_codes_subset{i}));
    if ~isempty(idx)
        matching_indices = [matching_indices; idx(1)];  % Store first match if duplicates exist
    else
        disp(['No match found for station: ', station_names_subset(i)]);
    end
end

% Reorder giant_rf_matrix based on matching indices and subset order
ordered_imageRFs = imageRFs_giant(matching_indices, :);

% Define figure and plot the reordered receiver functions
figure(1); clf;

for ii = 1:size(ordered_imageRFs, 1)
    trace = ordered_imageRFs(ii, :); %- mean(ordered_imageRFs(ii, :));
    trace_norm = trace / max(abs(trace));
    %trace_norm = -trace_norm;

    % Prepare y-values for the plot
    yvals = trace_norm + ii;
    zeroLine = ii * ones(size(time_vector_giant));
    negatives = trace_norm < 0;
    positives = trace_norm > 0;
    
    jbfill(time_vector_giant(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], [0 0 0], 1, 0.8);
    jbfill(time_vector_giant(positives), yvals(positives), zeroLine(positives), [0 0 1], [0 0 0], 1, 0.8);hold on;
end

% Set plot limits and labels
xlim([6 30]);
ylim([-1, size(ordered_imageRFs, 1) + 2]);  % Adjusted for spacing
xlabel('Time (s)');
ylabel('Ordered Station Index');

% Ensure the plot is fully rendered
drawnow;
camroll(270);
hold off;
%print(figure(2),'./Figures/Hua_Ps_RFs','-vector','-dpdf','-r0')
%%
% Plot Hua Sp receiver functions
Metadata = readtable('Extracted_Metadata.txt');

Data = load('Hua_SpRF_Data.mat'); % Hua RFs
station_names = string(Data.stationNames); % Convert to string for easier comparison
imageRFs = Data.RF_matrix;
t = Data.depthRange;
t = t';

% Load Ps-RFs for this study
GiantData = load('paired_filtered_giant_rf_matrix.mat');
imageRFs_giant = GiantData.giant_rf_matrix;
station_names_giant = string(GiantData.giant_station_names); % Convert to string
time_vector_giant = GiantData.time_vector;

% Preprocess station names in station_names_giant to handle hyphens or underscores
processed_station_names_giant = station_names_giant;
for i = 1:length(station_names_giant)
    if contains(station_names_giant(i), {'-', '_'})
        parts = split(station_names_giant(i), {'-', '_'});
        processed_station_names_giant(i) = parts(end); % Use the part after the separator
    end
end

% Match processed station names to Hua station names
[~, sorted_indices] = ismember(processed_station_names_giant, station_names);

% Remove unmatched stations (if any)
valid_indices = sorted_indices(sorted_indices > 0);
sorted_imageRFs = imageRFs(valid_indices, :); % Sort RFs to match giant station order
sorted_station_names = station_names(valid_indices); % Corresponding sorted station names

% Define figure and subplots
figure(2); clf;

for ii = 1:length(valid_indices)
    idx = valid_indices(ii);
    trace = sorted_imageRFs(ii, :);
    trace_norm = trace / max(abs(trace));

    yvals = trace_norm + ii;
    zeroLine = ii * ones(size(t));
    negatives = trace_norm < 0;
    positives = trace_norm > 0;

    jbfill(t(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], [0.3 0.3 0.3], 1, 0.8);
    jbfill(t(positives), yvals(positives), zeroLine(positives), [0 0 1], [0.3 0.3 0.3], 1, 0.8);

    % Output station name
    disp(['Station Name: ', sorted_station_names(ii)]);
end

% Set plot limits and labels
xlim([0 300]);
ylim([-1, length(valid_indices) + 2]);
xlabel('Time (s)');
ylabel('Ordered Station Index');

% Ensure the plot is fully rendered and rotate
drawnow;
camroll(270);

%print(figure(2),'./Figures/Hua_Sp_RFs','-vector','-dpdf','-r0')

