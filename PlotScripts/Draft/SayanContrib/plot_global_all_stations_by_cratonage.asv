clear;clc;
outpt_dir = ['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/'];
station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/All_Final_list_of_Global_Stations.csv');

all_stations_to_plot = [station_details.Station_Lat station_details.Station_Lon];


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

%saveas(h3,[outpt_dir 'all_final_global_stations'],'png');