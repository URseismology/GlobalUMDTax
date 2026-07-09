%% Read Data
%Refernece Stations in Africa
load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/oceania/parameter_set_1/filtered_neg_sequenced_full.mat']);

%Load Station Details
station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/global_station_catalog_df.csv');
station_details = station_details(strcmp(station_details.continent,'Oceania'),:);
station_details.net_sta = strcat(station_details.network_code, '-' ,station_details.station_code);
station_filtered = station_details(ismember(station_details.net_sta, sequencedData.station),:);

%Read the Oceania Geographic Details Table
oce_geo = readgeotable(['/scratch/tolugboj_lab/Sayan_Swar_WS/' ...
    'PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/' ...
    'geological_data/oceania/Geological_Regions_of_Australia.geojson']);
T=geotable2table(oce_geo,["lat","lon"]);
T=T(T.feature~="GR_VOID",:);

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

ageRanges = [
    4000;   % Archaean
    2500;   % Archaean to Proterozoic
    66;     % Cainozoic
    251;    % Mesozoic
    145;    % Mesozoic to Cainozoic
    541;    % Palaeozoic
    230;    % Palaeozoic to Cainozoic
    320;    % Palaeozoic to Mesozoic
    2500;   % Proterozoic
    260;    % Proterozoic to Mesozoic
    750;    % Proterozoic to Palaeozoic
];

area_per_age = groupsummary(T,"age_class","sum","aprox_area");
area_per_age.age = ageRanges;
area_per_age = sortrows(area_per_age,"age","descend");
area_range = [min(area_per_age.sum_aprox_area),max(area_per_age.sum_aprox_area)];
all_areas = area_per_age.sum_aprox_area;
all_area_norm = round(((all_areas-min(all_areas))/(max(all_areas)-min(all_areas)))*255+1);

%% Count the Number of Stations in Each Clusters For Each Age Class
num_age_class = length(area_per_age.age_class);
total_clusters = length(unique(all_clusters));
cluster_cnt = zeros(num_age_class,total_clusters);

for i=1:num_age_class
    age_class = area_per_age.age_class(i);
    T_age = T(T.age_class==age_class,:);
    nrows = size(T_age,1);
    is_inside = zeros(length(all_stations),1);
    for irow=1:nrows
        %lat_lon_bndry = polyshape(T_age{irow,'lon'}{:},T_age{irow,'lat'}{:});
        %is_inside_temp = isinterior(lat_lon_bndry,station_coord(:,1),station_coord(:,2));
        is_inside_temp = inpolygon(station_coord(:,2),station_coord(:,1),T_age{irow,'lon'}{:},T_age{irow,'lat'}{:});
        is_inside = is_inside_temp + is_inside;
    end
    matching_clusters_idx = find(is_inside>=1);
    matching_clusters = all_clusters(matching_clusters_idx);
    [clus_cnt,clus] = groupcounts(matching_clusters);
    cluster_cnt(i,clus) = clus_cnt;
end
clear age_class T_age nrows is_inside matching_clusters_idx matching_clusters clus_cnt clus i irow lat_lon_bndry is_inside_temp
clc

%%
figure;
bh = barh(cluster_cnt,'BarWidth',0.9);
%bh(1).BarWidth=1;bh(2).BarWidth=1;bh(3).BarWidth=1;bh(4).BarWidth=1;
bh(1).FaceColor='r';bh(2).FaceColor='m';bh(3).FaceColor='y';bh(4).FaceColor='b';
xlim([0 10])

set(gca,'YTick',1:size(cluster_cnt,1), 'YTickLabel',area_per_age.age_class, 'YTickLabelRotation',45);
legend({'N1','N2','N3','N4'}, 'Location','best');
set(gca,'XTick',[],'XTickLabel',[]);





 





