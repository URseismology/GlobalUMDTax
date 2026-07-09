%% Read Data
%Refernece Stations in Africa
clear;
load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/oceania/parameter_set_1/filtered_pos_sequenced_full.mat']);

%% Remove the Stations which are part of Arrays as they have same charecteristics
filt_idx=true(length(sequencedData.station),1);
filt_idx(find(ismember(sequencedData.station,{'AU-PSAA2','AU-PSAA1','AU-PSAA3','AU-BW1H','AU-MANU','AU-RABL','IU-PMG','GE-PMG','IU-SNZO'})))=0;
sequencedData.station=sequencedData.station(filt_idx,:);
sequencedData.clusters=sequencedData.clusters(filt_idx,:);
sequencedData.dataset_imageRFs_pos_reordered=sequencedData.dataset_imageRFs_pos_reordered(filt_idx,:);

%%
%Load Station Details
station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/global_station_catalog_df.csv');
station_details = station_details(strcmp(station_details.continent,'Oceania'),:);
station_details.net_sta = strcat(station_details.network_code, '-' ,station_details.station_code);
station_filtered = station_details(ismember(station_details.net_sta, sequencedData.station),:);

%Read the Oceania Geographic Details Table
oce_geo = readgeotable(['/scratch/tolugboj_lab/Sayan_Swar_WS/' ...
    'PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/' ...
    'geological_data/oceania/Geological_Regions_of_Australia.geojson']);
T = geotable2table(oce_geo,["lat","lon"]);
T = T(T.feature~="GR_VOID",:);
T(T.age_class=="Proterozoic to Mesozoic",:).age_class = "Palaeozoic to Mesozoic"; %fixing bad data
T.age_class_grouped=T.age_class;
T(T.age_class_grouped=="Archaean to Proterozoic","age_class_grouped") = {"Archaean"};
T(T.age_class_grouped=="Proterozoic to Palaeozoic","age_class_grouped") = {"Proterozoic"};
T(T.age_class_grouped=="Palaeozoic to Cainozoic","age_class_grouped") = {"Palaeozoic"};
T(T.age_class_grouped=="Palaeozoic to Mesozoic","age_class_grouped") = {"Palaeozoic"};
T(T.age_class_grouped=="Mesozoic to Cainozoic","age_class_grouped") = {"Mesozoic"};
T(T.age_class_grouped=="Cainozoic","age_class_grouped") = {"Mesozoic"};

temp_dir = [pwd '/temp'];
if ~exist(temp_dir,'dir')
    mkdir(temp_dir)
end

files = gunzip('gshhs_c.b.gz', temp_dir);

filename = files{1};
indexfile = gshhs(filename, 'createindex');
S = gshhs(filename, [-45 -8], [111 156]);
delete(filename);
delete(indexfile);
rmdir(temp_dir, 's');
levels = [S.Level];
L1 = S(levels == 1);
clear temp_dir indexfile files filename station_details;

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

%%Calculate the Area and Age Details of Each Age_Class to Plot
ageRanges = [
    4000;   % Archaean
    250;    % Mesozoic
    540;    % Palaeozoic
    2500;   % Proterozoic
];

area_per_age = groupsummary(T,"age_class_grouped","sum","aprox_area");
area_per_age.age = ageRanges;
area_per_age = sortrows(area_per_age,"age","descend");
area_range = [min(area_per_age.sum_aprox_area),max(area_per_age.sum_aprox_area)];
all_areas = area_per_age.sum_aprox_area;
all_area_norm = round(((all_areas-min(all_areas))/(max(all_areas)-min(all_areas)))*255+1);

%%Count the Number of Stations in Each Clusters For Each Age Class
num_age_class = length(area_per_age.age_class_grouped);
total_clusters = length(unique(all_clusters));
cluster_cnt = zeros(num_age_class,total_clusters);

for i=1:num_age_class
    age_class = area_per_age.age_class_grouped(i);
    T_age = T(T.age_class_grouped==age_class,:);
    nrows = size(T_age,1);
    is_inside = zeros(length(all_stations),1);
    for irow=1 : nrows
        lat_lon_bndry = polyshape(T_age{irow,'lat'}{:},T_age{irow,'lon'}{:});
        is_inside_temp = isinterior(lat_lon_bndry,station_coord(:,1),station_coord(:,2));
        is_inside = is_inside_temp + is_inside;
    end
    matching_clusters_idx = find(is_inside>=1);
    matching_clusters = all_clusters(matching_clusters_idx);
    [clus_cnt,clus] = groupcounts(matching_clusters);
    cluster_cnt(i,clus) = clus_cnt;
end
clear age_class T_age nrows is_inside matching_clusters_idx matching_clusters clus_cnt clus i irow lat_lon_bndry is_inside_temp
clc

%% Plot the Oceania Age Wise Regions
figure(102);clf;
ax1=subplot(6,7,[3:7:42, 7:7:42]);
alpha_value = 0.04;
temp_colmap = unique(slanCM('Pastel1'),'rows'); %interp1(linspace(1,9,9),unique(slanCM('Pastel1'),'rows'),linspace(1,9,10));
temp_colmap = temp_colmap(1:4,:);
alpha_matrix = ones(size(temp_colmap, 1), 1) * alpha_value;
colormap_sel=colormap(temp_colmap);
colormap_sel = [colormap_sel,alpha_matrix];
colormap_sel = colormap_sel(1:4,:);
m_proj('miller','lon',[111 156],'lat',[-45 -8]); 
m_grid('linestyle','none','tickdir','out','linewidth',3);
m_line([L1.Lon], [L1.Lat], 'color',[0 0 0 0.5],'linewi',1);
label_fig = {};
for i=1:length(area_per_age.age_class_grouped)
    T_age = T(T.age_class_grouped==area_per_age.age_class_grouped(i,:),:);
    [lat,lon] = polyjoin(T_age.lat,T_age.lon);
    area_sum = area_per_age.sum_aprox_area;
    m_line(lon, lat, 'color',[0 0 0 0.5],'linewi',1);
    m_hatch(lon,lat,'single',1,0.01,'color',colormap_sel(i,:));
    label_fig{i} = strcat(area_per_age.age_class_grouped(i,:), '(',num2str(area_per_age.age(i)),' mn)');
end
cb = colorbar;cb.TickDirection='out';cb.Ticks=linspace(0.05,0.95,4);cb.TickLabels = label_fig';
cb.Location = "eastoutside"; cb.FontWeight="bold";
hold on
%% Plot the Stations As per Clustering
%Plot the Stations As per Cluster Color
for iSta = 1 : length(sequencedData.station)
    sta = strtrim(sequencedData.station(iSta,:));
    sta_row = station_filtered(ismember(station_filtered.net_sta, sta),:);
    lat = sta_row.station_lat;
    lon = sta_row.station_lon;
    cluster = sequencedData.clusters(iSta);
    
    switch cluster
        case 1        
            m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,...
                'linest','none','markersize',10,'markerfacecolor',[0.459 0.882 1]);
        case 2
            m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,...
                'linest','none','markersize',10,'markerfacecolor',[0.047 0 0.557]);
        case 3
            m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,...
                'linest','none','markersize',10,'markerfacecolor',[0.22 0.702 0.573]);
        case 4
            m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,...
                'linest','none','markersize',10,'markerfacecolor',[0.98 0.98 0.98]);
    end
    hold on
end

%Plot the Rectangle Box with Cluster Information
totSta = length(sequencedData.clusters);
colors = {[0.459 0.882 1],[0.047 0 0.557],[0.22 0.702 0.573],[0.98 0.98 0.98]};
ax2=axes('position',[0.45,0.15,0.2,0.11],'Color','None','Visible','off');
rectangle('position',[0,0,1,1],'FaceColor','white');
for i = 1:4
    staPercnt = num2str((sum(ismember(sequencedData.clusters,i))/totSta)*100, '%.1f');
    x = 0.03; y = 1 - i * 0.24;   
    width = 0.25; height = 0.18;   
    rectangle('Position', [x, y, width, height], 'FaceColor', colors{i});
    mean_traces = 1.*sequencedData.meantraces(:,i); %remove negative sign for positive filtered data
    [~,idx]=max(mean_traces); max_depth = sequencedData.time_vector(idx)*10;

    text(x + width + 0.01, y + height / 2, ['P',num2str(i),': ',staPercnt,'%; Avg Depth: ' num2str(max_depth,'%.2f'), 'km'], 'VerticalAlignment', 'middle','Fontsize',8, 'FontWeight','bold');
end
hold on;

%% Plot the Mean Traces
ax3=subplot(6,7,[1:7:15, 2:7:16]);hold on;
verticalSpacing = 0.5;
plotOrder = [1,2,3,4];
t=sequencedData.time_vector;
for i = 1:length(plotOrder)
    clusterNum = plotOrder(i);
    meanTrace = sequencedData.meantraces(:,clusterNum)'; % Extract the mean stack for the current cluster
    
    % Offset each mean stack plot vertically
    % The order of mean stack is determined by their position in plotOrder
    offsetMeanTrace = meanTrace + (find(plotOrder == clusterNum) - 1) * verticalSpacing;

    % Define the zero line for jbfill with the same offset
    zeroLine = (find(plotOrder == clusterNum) - 1) * verticalSpacing * ones(size(meanTrace));

    % Plot each mean stack with jbfill
    plot(t.*10, offsetMeanTrace, 'k', 'LineWidth', 1.2);
    fillpart = offsetMeanTrace > 0;             %change here
    jbfill(t.*10, offsetMeanTrace, zeroLine, [0.125 0 1], 'none', 0.2, 1);  %change here

    hold on
end

xlabel('Depth (km)','FontWeight','bold');
xlim([60 350]); 
ylim([-0.4, (length(plotOrder) - 1) * verticalSpacing + 0.4]); % Adjust Y-axis limits based on the number of clusters and spacing
yticks;
yticklabels({'\bf \color[rgb]{0.459 0.882 1} P1','\bf \color[rgb]{0.047 0 0.557} P2','\bf \color[rgb]{0.22 0.702 0.573} P3','\bf \color[rgb]{0.98 0.98 0.98} P4'});
rectangle('Position', [x, y, width, height], 'FaceColor', colors{i});
camroll(270)
%% 
ax3=subplot(6,7,[22:7:36, 23:7:37]);hold on;
bh = barh(cluster_cnt,'BarWidth',0.9);
bh(1).FaceColor=[0.459 0.882 1];bh(2).FaceColor=[0.047 0 0.557];bh(3).FaceColor=[0.22 0.702 0.573];bh(4).FaceColor=[0.98 0.98 0.98];
xlim([0 20])
legend({'P1','P2','P3','P4'}, 'Location','best','FontWeight','normal');
set(gca,'YTick',[], 'YTickLabel',[]);
set(gca,'XTick',[],'XTickLabel',[]);

for i=1:size(cluster_cnt,1)
    bhxtips = bh(i).XEndPoints-0.1;
    bhytips = bh(i).YEndPoints+0.5;
    bhlabels = string(bh(i).YData);
    text(bhytips,bhxtips,bhlabels,'HorizontalAlignment','left',...
        'VerticalAlignment','bottom','FontWeight','bold','FontSize',8);
end

cb_bar = colorbar;
cb_bar.Position = [0.11    0.11    0.0138    0.3876];
cb_bar.Ticks=linspace(0.15,0.85,4);cb_bar.TickLabels = area_per_age.age_class_grouped;
cb_bar.FontWeight="bold";

x0=278;
y0=58;
width=1546;
height=746;
set(gcf,'position',[x0,y0,width,height]);
