%% Read Data
%Refernece Stations in Africa
clear;
load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/oceania/parameter_set_1/filtered_neg_sequenced_full.mat']);

filt_idx=true(length(sequencedData.station),1);
filt_idx(find(ismember(sequencedData.station,{'AU-PSAA2','AU-PSAA1','AU-PSAA3','AU-BW1H','AU-MANU','AU-RABL','IU-PMG','GE-PMG','IU-SNZO'})))=0;
sequencedData.station=sequencedData.station(filt_idx,:);
sequencedData.clusters=sequencedData.clusters(filt_idx,:);
sequencedData.dataset_imageRFs_pos_reordered=sequencedData.dataset_imageRFs_pos_reordered(filt_idx,:);
%%
station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/global_station_catalog_df.csv');
station_details = station_details(strcmp(station_details.continent,'Oceania'),:);
station_details.net_sta = strcat(station_details.network_code, '-' ,station_details.station_code);
station_filtered = station_details(ismember(station_details.net_sta, sequencedData.station),:);

%% Prepare Station Data With Coordinates
all_stations = sequencedData.station;
all_clusters = sequencedData.clusters;
station_coord = zeros(length(all_stations),2);

for iSta = 1 : length(all_stations)
    sta = strtrim(all_stations(iSta,:));
    sta_row = station_filtered(ismember(station_filtered.net_sta, sta),:);
    sta_row = sta_row(1,:);
    station_coord(iSta,1) = sta_row.station_lat;
    station_coord(iSta,2) = sta_row.station_lon;
end
clear sta_row sta;

%%
figure(103);
geoscatter(station_coord(:,1),station_coord(:,2),50,"blue","^","filled");
text(station_coord(:,1)+0.1,station_coord(:,2)+0.2,all_stations,'FontSize',6);
set(gcf,"Position",[93 98 1646 1037]);
set(gca,"MapCenter",[-28.8730 133.9144],"ZoomLevel",5);