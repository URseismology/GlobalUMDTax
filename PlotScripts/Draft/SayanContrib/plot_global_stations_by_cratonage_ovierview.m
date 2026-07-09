%% Plotting of Global Ages - Stp1 Data Load Stations

seq_rf = load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/oceania/parameter_set_1/filtered_sequenced_full.mat']);

filt_idx=true(length(seq_rf.station),1);
filt_idx(find(ismember(seq_rf.station,{'AU-PSAA2','AU-PSAA1','AU-PSAA3','AU-BW1H','AU-MANU','AU-RABL','IU-PMG','GE-PMG','IU-SNZO'})))=0;
seq_rf.station=seq_rf.station(filt_idx,:);
seq_rf.dataset_imageRFs_pos_reordered=seq_rf.dataset_imageRFs_pos_reordered(filt_idx,:);

safr_station_details = load('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/south_africa_stations_joel.mat').T;
usa_station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/usa_all_stations_steve.csv');
station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/global_stations_donwloaded_catalog.csv');
station_details.IsLand = landmask(station_details.station_lat,station_details.station_lon);
station_details.net_sta = strcat(station_details.network,'.',station_details.station);
usa_station_details.net_sta = strcat(usa_station_details.Network,'.',usa_station_details.Station);

%%
oce_station_details = station_details(strcmp(station_details.continent,'oceania'),:);
oce_station_details.net_sta = strcat(oce_station_details.network, '-' ,oce_station_details.station);
oce_station_filtered = oce_station_details(ismember(oce_station_details.net_sta, seq_rf.station),:);

sa_station_details = station_details(strcmp(station_details.continent,'south america'),:);
%sa_station_details = sa_station_details(sa_station_details.IsLand==1,:);
asia_station_details = station_details(strcmp(station_details.continent,'asia'),:);
asia_station_details = asia_station_details(asia_station_details.IsLand==1,:);
eu_station_details = station_details(strcmp(station_details.continent,'europe'),:);
eu_station_details = eu_station_details(eu_station_details.IsLand==1,:);
ant_station_details = station_details(strcmp(station_details.continent,'antartica'),:);
ant_station_details = ant_station_details(ant_station_details.IsLand==1,:);
na_station_details = station_details(strcmp(station_details.continent,'north america'),:);
na_station_details = na_station_details(na_station_details.IsLand==1,:);
afr_station_details = station_details(strcmp(station_details.continent,'africa'),:);
afr_station_details = afr_station_details(afr_station_details.IsLand==1,:);

%%
all_stations_to_plot = [oce_station_filtered.station_lat oce_station_filtered.station_lon];
all_stations_to_plot = [all_stations_to_plot; [sa_station_details.station_lat sa_station_details.station_lon];
    [asia_station_details.station_lat asia_station_details.station_lon]; [eu_station_details.station_lat eu_station_details.station_lon];
    [ant_station_details.station_lat ant_station_details.station_lon]; [na_station_details.station_lat na_station_details.station_lon];
    [afr_station_details.station_lat afr_station_details.station_lon];
    [usa_station_details.Latitude usa_station_details.Longitude]];

all_station_to_plot_name = [oce_station_filtered.net_sta; sa_station_details.net_sta; asia_station_details.net_sta;
    eu_station_details.net_sta; ant_station_details.net_sta; na_station_details.net_sta; 
    afr_station_details.net_sta; usa_station_details.net_sta];
%% Plotting of Global Ages - Stp1 Data Load Age
clc;
ageMap = load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/' ...
    'global_age_metadata/IrinaThermal/global-ages-0705-1x1.xyz.txt']);

load coastlines;
exclude_idx = find(coastlon>180);
all_idx = true(size(coastlon));
all_idx(exclude_idx) = false;
coastlon = coastlon(all_idx);
coastlat = coastlat(all_idx);

[latgrid, longrid] = meshgrid(linspace(-89.5,89.5, 3600), linspace(-179, 179, 3600)); %meshgrid(coastlat,coastlon);

F = scatteredInterpolant(ageMap(:,1), ageMap(:,2), ageMap(:,3), 'natural', 'none'); %1 is lon, 2 is lat
crustAge = F(longrid, latgrid);
mAge = max(max(crustAge));
oceanAll = ~landmask(latgrid,longrid);
crustAge(oceanAll) = NaN;

nstations = length(all_stations_to_plot(:,1));
all_stations_age_group = zeros(nstations,1);
for i=1:nstations
    [~,min_latidx] = min(abs(latgrid(1,:)-all_stations_to_plot(i,1)));
    [~,min_lonidx] = min(abs(longrid(:,1)-all_stations_to_plot(i,2)));
    best_age = crustAge(min_lonidx,min_latidx);
    if best_age<=1200
        all_stations_age_group(i,1)=1; %phanerozoic
    elseif best_age<=2500
        all_stations_age_group(i,1)=2; %precambrian
    else
        all_stations_age_group(i,1)=3; %archean
    end 
end
%%
% ageBnds = [0 540 2500 3500];
% totAge = length(ageBnds);
% doms= {'Africa and Eurasia', 'Antarctica', 'North and South America', 'Greenland',  'Australia'}; 
% totDoms = length(doms);

% oceanDom_all = ones(3600,3600);
% for iDom = 1:totDoms    
%     mask domain - 6 each...
%     oceanDom = ~landmask(latgrid,longrid, doms{iDom});
%     oceanDom_all = oceanDom_all .* oceanDom;
%     mask age - 3 each
%     for iEpoch = 1:3
%         
%         crustAgeDom = crustAge;
%         crustAgeAll = crustAge;
%         
%         crustAgeDom(oceanDom) = NaN;
%         crustAgeAll(oceanAll) = NaN;
%              
%         inAge = (crustAge>ageBnds(iEpoch)) & (crustAge<ageBnds(iEpoch+1));
%         crustAgeDom(~inAge) = NaN;
%         
%         
%     end
% 
% end
% oceanDom_all = oceanDom_all == 1;
% crustAge(oceanDom) = NaN;

%% Plotting of Global Ages - Stp2
useMap = crustAge; 
useCols = [[0.624 0.808 0.325];[0.376 0.612 0.831];[0.878 0.098 0.129]];
useTitle = 'Global Stations Under Analysis';

yt_div = mAge/3;
yt = [1 yt_div yt_div*2 yt_div*3];
yyt = yt;
barLabel = 'Age (Ma)';
clims = [0 mAge];
nmLabel = { '0'
    '540 (Phanerozoic)'
    '2500 (Precambrian)'
    '3600 (Archean)'
    };

figure;
m_proj('robinson');
hold on;
%m_coast('color', 'k', 'LineWidth', 0.2);
vw = m_pcolor(longrid, latgrid, useMap); shading flat;
% m_grid('linestyle', 'none', 'fontsize', 10, 'tickdir','out', 'box', 'fancy', 'yticklabels', [], ...
%         'xticklabels', []);
m_grid('tickdir','out','linewi',2);

% m_plot(oce_station_filtered.station_lon, oce_station_filtered.station_lat, 'marker','x', 'color','k','linewi',1,...
%        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% 
% m_plot(usa_station_details.Longitude, usa_station_details.Latitude, 'marker','x', 'color','k','linewi',1,...
%        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% 
% m_plot(sa_station_details.station_lon, sa_station_details.station_lat, 'marker','x', 'color','k','linewi',1,...
%        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% 
% m_plot(eu_station_details.station_lon, eu_station_details.station_lat, 'marker','x', 'color','k','linewi',1,...
%        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% 
% m_plot(asia_station_details.station_lon, asia_station_details.station_lat, 'marker','x', 'color','k','linewi',1,...
%        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% 
% m_plot(ant_station_details.station_lon, ant_station_details.station_lat, 'marker','x', 'color','k','linewi',1,...
%        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% 
% m_plot(na_station_details.station_lon, na_station_details.station_lat, 'marker','x', 'color','k','linewi',1,...
%        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% 
% m_plot(afr_station_details.station_lon, afr_station_details.station_lat, 'marker','x', 'color','k','linewi',1,...
%        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
%
% m_plot(safr_station_details(:,1).Lat_Lon(:,2), safr_station_details(:,1).Lat_Lon(:,1), 'marker','^', 'color','k','linewi',1,...
%        'linest','none','markersize',7,'markerfacecolor',[0.8 0.8 0.8]);

coord_idx = find(all_stations_age_group==3);
m_plot(all_stations_to_plot(coord_idx,2), all_stations_to_plot(coord_idx,1), 'marker','x', 'color','k','linewi',2,...
       'linest','none','markersize',5);
coord_idx = find(all_stations_age_group==2);
m_plot(all_stations_to_plot(coord_idx,2), all_stations_to_plot(coord_idx,1), 'marker','o', 'color','k','linewi',1,...
       'linest','none','markersize',5);
coord_idx = find(all_stations_age_group==1);
m_plot(all_stations_to_plot(coord_idx,2), all_stations_to_plot(coord_idx,1), 'marker','+', 'color','k','linewi',1,...
       'linest','none','markersize',5);


colormap(useCols);
h = colorbar('southoutside'); 
caxis(clims);
set(h, 'fontsize', 9)
set(h, 'YTick', yyt, 'XTickLabel', nmLabel);
h.TickDirection='none';
xlabel(h, barLabel, 'FontSize', 9);

title(useTitle);

%% Find Stations As Per Age
age_coord_idx = find(all_stations_age_group==2);
station_name_filtered_by_age = all_station_to_plot_name(age_coord_idx,:);
station_coord_filtered_by_age = all_stations_to_plot(age_coord_idx,:);
station_name_idx = strcmp(station_name_filtered_by_age(:,2),'south america');
station_name_filtered_by_age_cont = station_name_filtered_by_age(station_name_idx,:);
station_coord_filtered_by_age_cont = station_coord_filtered_by_age(station_name_idx,:);
