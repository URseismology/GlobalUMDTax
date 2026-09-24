mntDir = '/gpfs/fs2/scratch/tolugboj_lab/';
%mntDir = '/Users/stevecarr/Documents/bluehive';
addpath ([mntDir '/Prj7_RadonT/Prj7_US_Earthscope/figures_4pub/m_map/']);
addpath([mntDir '/Prj7_RadonT/Prj7_US_Earthscope/ccp_codes']);
addpath ([mntDir '/Prj7_RadonT/RFImager_EvansVersion/1_Functions']);
addpath ([mntDir '/Prj7_RadonT/Prj7_US_Earthscope/figs_codes']);

station_data = readtable('./Reordered_Global_paired_complete.csv');

pws = 0;
counter = 0;
isImageRFsInitialized = false;
sorted_filtered_stations_data = table2cell(station_data);

figure(1);clf
for i = 1:height(station_data)

    data = station_data(i,:);

    continent = char(data.Continent);

    if strcmp(continent, 'north america')
        RFDIR  = [localBaseDir 'Prj7_RadonT/2_Data/Parallel_Download/MTCRF/'];
    else
        RFDIR = [localBaseDir 'Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/rf_prep_slurm_step_7/rf_output/' continent '/'];
    end

    addpath(RFDIR);

    netname = char(data.Network); %'CCP'; %for Global mid_mantle
    staname = char(data.Station);

    MTC_ccp = fullfile(RFDIR, [netname '_' staname '_residual_nocrust.mat']);

    if exist(MTC_ccp, 'file') ~= 2
        fprintf('Skipping station %s_%s (MTC_cpp file not found)\n', netname, num2str(staname));
        continue;
    end

    RFmat = load(MTC_ccp);
    filteredRF_struct = RFmat.residuals_Struct; %filtered
    R = filteredRF_struct.residualsRF;
    t = filteredRF_struct.taus ;
    rayP = filteredRF_struct.rayP ;

    % cut data
    tBegin = find(t > 0, 1); %find(t > 0, 1);
    tEnd   = find(t > 25, 1);%find(t > 25, 1);
    t = t(tBegin:tEnd);
    R = R(:, tBegin:tEnd);

    %t= t+6 ; %Accounting for time-shift

    %% Only necessary when plotting filtered data. temp fix
    if length(R) ~= length(t)
        % original time vector
        original_t = linspace(min(t), max(t), size(R,2));

        % Interpolate t to match the length of R
        t_resampled = interp1(t, t, original_t, 'linear', 'extrap');

        % Now, t_resampled should have the same length as the number of columns in R
        t = t_resampled;
    end
    %%
    %Stack RF traces
    sumR = getsum(R,rayP,pws);
    sumR = sumR / max(abs(sumR));

    sizeT = length(t);
    yLev = 0.6*(size(sorted_filtered_stations_data,1) - i);
    yVec = repmat(yLev, 1, sizeT);
    
    %Plot stations as transects
    ax1=gca;
    jbfill(t, max(sumR+yLev, yLev), yVec, [0 0 1],'k', 1, 1.0);
    jbfill(t, min(sumR+yLev, yLev), yVec, [1 0 0],'k', 1, 1.0);
    xlim([4 25]);%xlim([6 30]);
    xlabel(ax1, 'Time(s)','FontSize',15)
    yticklabels(" ")
    %%
    % Store the normalized receiver functions in the matrix to plot as an
    % image
 % In the loop, check whether imageRFs has been initialized
    if ~isImageRFsInitialized
        % If not, initialize it with the current size of sumR
        imageRFs = zeros(size(sorted_filtered_stations_data, 1), 1001);
        % Update the flag to avoid re-initialization
        isImageRFsInitialized = true;
    end    

    if length(sumR) ~= size(imageRFs, 2)
        sumR = interp1(1:length(sumR), sumR, linspace(1, length(sumR), size(imageRFs,2)));
    end

    if any(isnan(sumR))
        disp(['Skipping station due to NaNs in sumR for gridnumber: ', num2str(staname)]);
        continue;
    end

    counter = counter + 1;  % Increment the counter for a successful entry

    imageRFs(counter,:) = sumR;

    % Store the station data in the structure
    RFStruct(counter).Data = sumR;
    RFStruct(counter).Lat = sorted_filtered_stations_data{i, 6}; %sorted_filtered_stations_data{i, 4};
    RFStruct(counter).Lon = sorted_filtered_stations_data{i, 5}; %sorted_filtered_stations_data{i, 3};
    RFStruct(counter).GridNumber = staname; % Add this line

end
hold on

% Save the data
%save('RFDataWithCoords_residuals.mat', 'RFStruct', 'imageRFs', 't');
%%
ylim([-3 370])
camroll(270)


% stackedRFs = sum(imageRFs, 1);
% stackedRFs = stackedRFs / max(abs(stackedRFs));
% 
% % Define the new vector of time values
% t_new = linspace(min(t), max(t), length(stackedRFs));
% 
% % Interpolate the 't' data to these new time points
% t_interpolated = interp1(t, t, t_new, 'linear', 'extrap');
% yVec = repmat(yLev, 1, length(t_interpolated));
