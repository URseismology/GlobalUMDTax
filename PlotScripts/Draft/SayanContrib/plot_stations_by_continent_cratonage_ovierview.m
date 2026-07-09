%% Plotting of Global Ages - Stp1 Data Load Stations
continent = 'asia';
outpt_dir = ['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/' continent '/parameter_set_1/'];

station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/global_station_catalog_df.csv');
%station_details.IsLand = landmask(station_details.station_lat,station_details.station_lon);
station_details.net_sta = strcat(station_details.network_code,'.',station_details.station_code);

%change continent accordingly
country_station_details = station_details(strcmp(station_details.continent,'Asia'),:);
country_station_details = country_station_details(:,[1,3,6,7,15]); %,13,14
country_station_details = renamevars(country_station_details,["network_code","station_code"],["network","station"]);

%change file name accordingly
country_extra_station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/ASIA_Extra.csv');
%country_extra_station_details.IsLand = landmask(country_extra_station_details.Station_Lat,country_extra_station_details.Station_Lon);
country_extra_station_details.net_sta = strcat(country_extra_station_details.Network,'.',country_extra_station_details.Station);
country_extra_station_details= removevars(country_extra_station_details,{'DataCenter'});
country_extra_station_details = renamevars(country_extra_station_details,["Network","Station","Station_Lat","Station_Lon"],["network","station","station_lat","station_lon"]);
%country_extra_station_details.IsLand = ones(size(country_extra_station_details,1),1);

country_all_stations =  [country_station_details; country_extra_station_details];

%%
country_rf_filtered = readtable(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/' ...
    'rf_prep_slurm_step_7/srtfista_output/' continent '/parameter_set_1/' continent '_lambda_list.csv']);
country_rf_filtered.net_sta = strcat(country_rf_filtered.Network,'.',country_rf_filtered.Station);
country_all_stations_rf_filtered = innerjoin(country_all_stations,country_rf_filtered);
country_all_stations_rf_filtered = country_all_stations_rf_filtered(:,[1,2,3,4,5,6,7,9,10]);
[~,ia] = unique(country_all_stations_rf_filtered(:,7),'rows');
country_all_stations_rf_filtered = country_all_stations_rf_filtered(ia,:);
clear ia;

%%
all_stations_to_plot = [country_all_stations_rf_filtered.station_lat country_all_stations_rf_filtered.station_lon];
all_station_to_plot_name = country_all_stations_rf_filtered.net_sta;


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

[latgrid, longrid] = meshgrid(linspace(-89.5,89.5, 600), linspace(-179, 179, 600)); %meshgrid(coastlat,coastlon);

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

%% Plotting of Global Ages - Stp2
useMap = crustAge; 
useCols = [[0.624 0.808 0.325];[0.376 0.612 0.831];[0.878 0.098 0.129]];
useTitle = 'Asia Stations Under Analysis';

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

h3=figure(1);
m_proj('miller');
hold on;
%m_coast('color', 'k', 'LineWidth', 0.2);
vw = m_pcolor(longrid, latgrid, useMap); shading flat;
% m_grid('linestyle', 'none', 'fontsize', 10, 'tickdir','out', 'box', 'fancy', 'yticklabels', [], ...
%         'xticklabels', []);
m_grid('tickdir','in','linewi',2);

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

x0=474;
y0=124;
width=1279;
height=984;
set(gcf,'position',[x0,y0,width,height]);

saveas(h3,[outpt_dir 'europe_stations_plot_global_craton_flat'],'png');
%%
%h4=figure(2);
%geoscatter(all_stations_to_plot(:,1),all_stations_to_plot(:,2));
%saveas(h4,[outpt_dir 'europe_stations_plot'],'png');

