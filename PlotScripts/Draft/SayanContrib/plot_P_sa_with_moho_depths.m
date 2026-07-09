clear;clc;

%%
sa_coastline = readtable(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/' ...
    '../../Data/GeologicalData/south america/SA_Coastline.csv']);
sa_coast_lat = sa_coastline.Latitude;
sa_coast_lon = sa_coastline.Longitude;
coastline = polyshape(sa_coast_lon,sa_coast_lat);

filepath3 = '/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/moho_models/global_moho_depth.csv';
moho_model_data3 = readtable(filepath3);
moho_model_data3.Properties.VariableNames = {'Lon','Lat','H_km'};

isinside_vect = isinterior(coastline, moho_model_data3.Lon, moho_model_data3.Lat);
moho_model_data3.isinside = isinside_vect;

moho_model_new_filt = moho_model_data3(moho_model_data3.isinside==1,:);
moho_model_new_filt.H_km = moho_model_new_filt.H_km*(-1);

latitudes = moho_model_new_filt.Lat;
longitudes = moho_model_new_filt.Lon;
velocities = moho_model_new_filt.H_km;

lat_range = -62:0.15:22;   %linspace(-62, 22, 500); 
lon_range = -108:0.15:-24; %linspace(-30, -90, 500);

[lat_grid, lon_grid] = meshgrid(lat_range, lon_range);

%velocity_grid = griddata(longitudes, latitudes, velocities, lon_grid, lat_grid, 'cubic');
F = scatteredInterpolant(latitudes,longitudes,velocities,'natural');                  
velocity_grid = F(lat_grid,lon_grid);

samask = inpolygon(lon_grid,lat_grid,sa_coast_lon,sa_coast_lat);
samask = logical(samask - 1);
velocity_grid(samask) = nan;

%% 
load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/south america/parameter_set_1/filtered_pos_sequenced_full.mat']);
%%
station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/global_station_catalog_df.csv');
station_details = station_details(strcmp(station_details.continent,'South America'),:);
station_details.net_sta = strcat(station_details.network_code, '-' ,station_details.station_code);
station_filtered = station_details(ismember(station_details.net_sta, sequencedData.station),{'network_code','station_code','station_lat','station_lon','net_sta'});

%%
new_stns_metadata = '/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/SA_Extra.csv';
new_stns_metadata = readtable(new_stns_metadata);

new_sta_ref = '/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/south america/parameter_set_1/south_am_lambda_list.csv';
new_sta_ref = readtable(new_sta_ref);

new_stns_metadata = new_stns_metadata(ismember(new_stns_metadata.Station, new_sta_ref.Station),{'Network','Station','Station_Lat','Station_Lon'});
new_stns_metadata.Properties.VariableNames = {'network_code','station_code','station_lat','station_lon'};
new_stns_metadata.net_sta = strcat(new_stns_metadata.network_code, '-' ,new_stns_metadata.station_code);

station_filtered = [station_filtered; new_stns_metadata];

%%
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

%%
sa_tectonic_boundaries = readtable(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/' ...
    '../../Data/GeologicalData/south america/SA_Tectonic_Regions.csv']);

amazonian_craton1 = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'Amazonian_Craton_1'),:);
amazonian_craton2 = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'Amazonian_Craton_2'),:);
andean_region = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'Andean_region'),:);
big_basin = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'Big_Basin'),:);
lv_craton = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'LV_Craton'),:);
proto_1 = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'Proterozoic_Province_1'),:);
proto_2 = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'Proterozoic_Province_2'),:);
proto_3 = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'Proterozoic_Province_3'),:);
sm_craton_1 = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'Small_Craton_1'),:);
sm_craton_2 = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'Small_Craton_2'),:);
sm_craton_3 = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'Small_Craton_3'),:);
sm_craton_4 = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'Small_Craton_4'),:);
sm_craton_5 = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'Small_Craton_5'),:);
soafrans_craton = sa_tectonic_boundaries(strcmp(sa_tectonic_boundaries.Region,'Soafrans_Craton'),:);

all_tectonic_regions = [amazonian_craton1; amazonian_craton2; andean_region; big_basin; ...
    lv_craton; proto_1; proto_2; proto_3; sm_craton_1; sm_craton_2; ...
    sm_craton_3; sm_craton_4; sm_craton_5; soafrans_craton];
all_tectonic_regions(all_tectonic_regions.Region=="Amazonian_Craton_1","Region_Grouped") = {"Cratons"};
all_tectonic_regions(all_tectonic_regions.Region=="Amazonian_Craton_2","Region_Grouped") = {"Cratons"};
all_tectonic_regions(all_tectonic_regions.Region=="LV_Craton","Region_Grouped") = {"Cratons"};
all_tectonic_regions(all_tectonic_regions.Region=="Small_Craton_1","Region_Grouped") = {"Cratons"};
all_tectonic_regions(all_tectonic_regions.Region=="Small_Craton_2","Region_Grouped") = {"Cratons"};
all_tectonic_regions(all_tectonic_regions.Region=="Small_Craton_3","Region_Grouped") = {"Cratons"};
all_tectonic_regions(all_tectonic_regions.Region=="Small_Craton_4","Region_Grouped") = {"Cratons"};
all_tectonic_regions(all_tectonic_regions.Region=="Small_Craton_5","Region_Grouped") = {"Cratons"};
all_tectonic_regions(all_tectonic_regions.Region=="Soafrans_Craton","Region_Grouped") = {"Cratons"};

all_tectonic_regions(all_tectonic_regions.Region=="Proterozoic_Province_1","Region_Grouped") = {"Proterozoic Provinces"};
all_tectonic_regions(all_tectonic_regions.Region=="Proterozoic_Province_2","Region_Grouped") = {"Proterozoic Provinces"};
all_tectonic_regions(all_tectonic_regions.Region=="Proterozoic_Province_3","Region_Grouped") = {"Proterozoic Provinces"};

all_tectonic_regions(all_tectonic_regions.Region=="Big_Basin","Region_Grouped") = {"Basin"};

all_tectonic_regions(all_tectonic_regions.Region=="Andean_region","Region_Grouped") = {"Andean Region"};

%%
unq_tectonic_region_grp = unique(all_tectonic_regions.Region_Grouped);
tot_tectonic_region_grp = length(unq_tectonic_region_grp);

total_clusters = length(unique(all_clusters));
cluster_cnt = zeros(tot_tectonic_region_grp,total_clusters);

for j=1:tot_tectonic_region_grp
    T = all_tectonic_regions(strcmp(all_tectonic_regions.Region_Grouped, unq_tectonic_region_grp{j}),:);
    all_unq_tectonic_regions = unique(T.Region);
    num_unq_tectonic_regions = size(all_unq_tectonic_regions,1);
    is_inside = zeros(length(all_stations),1);
    for i=1:num_unq_tectonic_regions
        T_sub = T(strcmp(T.Region, all_unq_tectonic_regions{i}),:);
        geo_shape = polyshape(T_sub.Latitude,T_sub.Longitude);
        is_inside_temp = isinterior(geo_shape,station_coord(:,1),station_coord(:,2));
        is_inside = is_inside_temp + is_inside;
    end
    matching_clusters_idx = find(is_inside>=1);
    matching_clusters = all_clusters(matching_clusters_idx);
    [clus_cnt,clus] = groupcounts(matching_clusters);
    cluster_cnt(j,clus) = clus_cnt;
end

%%
h1=figure;clf;
ax1=subplot(1,1,1);
m_proj('miller','lon',[-90 -30],'lat',[-62 22]); 

mycolsmap = [0.184 0.133 0.686; 0.118 0.2 0.875; 0.145 0.29 0.957; 0.22 0.616 0.965; 0.286 0.843 0.98; 0.314 0.933 0.992; 0.314 0.965 0.851; 0.58 0.992 0.741; 0.749 1 0.847; 0.906 0.984 0.616; 0.984 0.875 0.443; 0.973 0.678 0.271; 0.8 0.467 0; 0.965 0.373 0.361; 0.969 0.553 0.549; 0.961 0.71 0.702; 0.992 0.898 0.898; 0.988 0.929 0.929; 0.894 0.902 0.902; 1 1 1];
colormap(mycolsmap);
m_pcolor(lon_grid,lat_grid,velocity_grid); 
m_line(sa_coast_lon,sa_coast_lat,'color',[0 0 0],'linewi',2);
cb = colorbar();
ylabel(cb, 'Moho Depth (km)', 'fontweight','bold');      
caxis([20,70]);

hold on;
m_grid('linestyle','none','tickdir','in','linewidth',2);

for iSta = 1 : length(sequencedData.station)
    sta = strtrim(sequencedData.station(iSta,:));
    sta_row = station_filtered(ismember(station_filtered.net_sta, sta),:);
    lat = sta_row(1,:).station_lat;
    lon = sta_row(1,:).station_lon;
    cluster = sequencedData.clusters(iSta);
    switch cluster
        case 1        
            m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,...
                'linest','none','markersize',12,'markerfacecolor',[0.459 0.882 1],'markeredgecolor','k','linewidth',2);
            m_text(lon,lat,sta,'Fontsize',7, 'FontWeight','bold');
        case 2
            m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,...
                'linest','none','markersize',12,'markerfacecolor',[0.047 0 0.557],'markeredgecolor','k','linewidth',2);
            m_text(lon,lat,sta,'Fontsize',7, 'FontWeight','bold');
        case 3
            m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,...
                'linest','none','markersize',12,'markerfacecolor',[0.22 0.702 0.573],'markeredgecolor','k','linewidth',2);
            m_text(lon,lat,sta,'Fontsize',7, 'FontWeight','bold');
        case 4
            m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,...
                'linest','none','markersize',12,'markerfacecolor',[0.98 0.98 0.98],'markeredgecolor','k','linewidth',2);
            m_text(lon,lat,sta,'Fontsize',7, 'FontWeight','bold');
    end
    hold on
end
title("South America PVG Clustering Overlayed with Crust 1.0 Moho Model",'Interpreter','none');
hold on 

%Plot the Rectangle Box with Cluster Information
totSta = length(sequencedData.clusters);
colors = {[0.459 0.882 1],[0.047 0 0.557],[0.22 0.702 0.573],[0.98 0.98 0.98]};
ax2=axes('position',[0.5,0.15,0.17,0.1],'Color','None','Visible','off');
rectangle('position',[0,0,1,1],'FaceColor','white');
for i = 1:4
    staPercnt = num2str((sum(ismember(sequencedData.clusters,i))/totSta)*100, '%.1f');
    x = 0.03; y = 1.08 - i * 0.24;   
    width = 0.1; height = 0.08;   
    rectangle('Position', [x, y, width, height], 'FaceColor', colors{i});
    mean_traces = 1.*sequencedData.meantraces(:,i); %remove negative sign for positive filtered data
    [~,idx]=max(mean_traces); max_depth = sequencedData.time_vector(idx)*10;

    text(x + width + 0.01, y + height / 2, ['P',num2str(i),': ',staPercnt,'%; Avg Depth: ' num2str(max_depth,'%.2f'), 'km'], 'VerticalAlignment', 'middle','Fontsize',8, 'FontWeight','bold');
end

set(gcf,'position',[519 95 1403 989]);
saveas(h1,'/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/south america/parameter_set_1/sa_pvg_with_moho','png');






























