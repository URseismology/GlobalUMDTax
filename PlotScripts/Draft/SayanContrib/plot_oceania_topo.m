%% Plot the topo of Oceania with RF Depths
clear;clc;

temp_dir = [pwd '/temp'];
if ~exist(temp_dir,'dir')
    mkdir(temp_dir)
end

files = gunzip('gshhs_c.b.gz', temp_dir);

filename = files{1};

indexfile = gshhs(filename, 'createindex');
S = gshhs(filename, [-45 -9], [111 156]);
delete(filename);
delete(indexfile);
rmdir(temp_dir, 's');
levels = [S.Level];
L1 = S(levels == 1);

%%
figure;
%ax1=subplot(2,3,[2,3,5,6]);hold on; %remove comment for subplot
% set the project as a regular map plot
m_proj('miller','lon',[111 156],'lat',[-45 -9]);
caxis([-6000 3000]);   % set the colorbar range
%colormap([m_colmap('blues',80); flipud(gray(48)) ])   % set the colorbar color -- m_colmap('gland', 100)

%[ELEV,LONG,LAT] = m_etopo2([100 170 -47 -7]);    % get the elevation (topography)
%m_image(LONG(1,:),LAT(:,1),ELEV);

% set the lat&lon grid and labels
m_grid('linestyle','none','tickdir','out','linewidth',3, 'box', 'on');

% set the colorbar display
%topoax = m_contfbar(1,[.17 .79], 'ELEV',[-6000:3000],'axfrac',.02,'endpiece','no','levels','match','edgecolor','none'); 

[CS,CH]=m_etopo2('contourf',[-6000:500:0 50:100:3000],'edgecolor','none');
colormap([ m_colmap('blues',80); flipud( gray(48) ) ]);
topoax = m_contfbar(0.98,[.17 .79],CS,CH); %set(topoax,'fontsize',(9-1));

set(topoax,'fontsize',(12));
ylabel(topoax, 'Topography (m)');
hold on;

% xs = 0:0.1:50;
% ys1 = 24/25 * xs - 21.5;
% m_line(xs, ys1, 'color', [0.502 0.502 0.502], 'linewi',2)
% hold on

m_line([L1.Lon], [L1.Lat], 'color', 'k', 'linewi',2); hold on

% set the size of the plot
x0=247;
y0=487;
width=1314;
height=583;
set(gcf,'position',[x0,y0,width,height]);

% save the figure
%fig = gcf;

%%Refernece Stations in Africa
load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/oceania/parameter_set_1/filtered_neg_sequenced_full.mat']);

% station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/global_station_catalog_df.csv');
% station_details = station_details(strcmp(station_details.continent,'Oceania'),:);
% station_details.net_sta = strcat(station_details.network_code, '-' ,station_details.station_code);
% station_filtered = station_details(ismember(station_details.net_sta, sequencedData.station),:);
%%
filt_idx=true(length(sequencedData.station),1);
filt_idx(find(ismember(sequencedData.station,{'AU-PSAA2','AU-PSAA1','AU-PSAA3','AU-BW1H','AU-MANU','AU-RABL','IU-PMG','GE-PMG','IU-SNZO', 'AU-NWAO'})))=0;
sequencedData.station=sequencedData.station(filt_idx,:);
sequencedData.clusters=sequencedData.clusters(filt_idx,:);
sequencedData.dataset_imageRFs_pos_reordered=sequencedData.dataset_imageRFs_pos_reordered(filt_idx,:);

%%
%Load Station Details
station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/global_station_catalog_df.csv');
station_details = station_details(strcmp(station_details.continent,'Oceania'),:);
station_details.net_sta = strcat(station_details.network_code, '-' ,station_details.station_code);
station_filtered = station_details(ismember(station_details.net_sta, sequencedData.station),:);


%%

%%Plot the Stations for Oceania
for iSta = 1 : length(sequencedData.station)
    sta = strtrim(sequencedData.station(iSta,:));
    sta_row = station_filtered(ismember(station_filtered.net_sta, sta),:);
    lat = sta_row.station_lat;
    lon = sta_row.station_lon;
    cluster = sequencedData.clusters(iSta);
    
%     switch cluster
%         case 1        
%             m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,...
%                 'linest','none','markersize',10,'markerfacecolor','r');
%         case 2
%             m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,...
%                 'linest','none','markersize',10,'markerfacecolor','m');
%         case 3
%             m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,...
%                 'linest','none','markersize',10,'markerfacecolor','y');
%         case 4
%             m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,...
%                 'linest','none','markersize',10,'markerfacecolor','b');
%     end
%     hold on

    m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,'linest','none','markersize',10,'markerfacecolor','k');
    hold on

end

%% Draw Rectangle Lengend Part - Commenting the below Just to get the Topo Plot 
% totSta = length(sequencedData.clusters);
% colors = {'r', 'm', 'y', 'b'};
% ax2=axes('position',[0.45,0.15,0.2,0.11],'Color','None','Visible','off');
% rectangle('position',[0,0,1,1],'FaceColor','white');
% for i = 1:4
%     staPercnt = num2str(sum(ismember(sequencedData.clusters,i))/totSta, '%.2f');
%     x = 0.03; y = 1 - i * 0.24;   
%     width = 0.25; height = 0.18;   
%     rectangle('Position', [x, y, width, height], 'FaceColor', colors{i});
%     mean_traces = -1.*sequencedData.meantraces(:,i); %remove negative sign for positive filtered data
%     [~,idx]=max(mean_traces); max_depth = sequencedData.time_vector(idx)*10;
% 
%     text(x + width + 0.01, y + height / 2, ['C',num2str(i),': ',staPercnt,'%; Avg Depth: ' num2str(max_depth,'%.2f'), 'km'], 'VerticalAlignment', 'middle','Fontsize',8);
% end
% hold on;
%%
% ax3=subplot(2,3,[1,4]);hold on;
% verticalSpacing = 0.5;
% plotOrder = [1,2,3,4];
% plotColors = {'r', 'm', 'y', 'b'};
% t=sequencedData.time_vector;
% for i = 1:length(plotOrder)
%     clusterNum = plotOrder(i);
%     meanTrace = sequencedData.meantraces(:,clusterNum)'; % Extract the mean stack for the current cluster
%     
%     % Offset each mean stack plot vertically
%     % The order of mean stack is determined by their position in plotOrder
%     offsetMeanTrace = meanTrace + (find(plotOrder == clusterNum) - 1) * verticalSpacing;
% 
%     % Define the zero line for jbfill with the same offset
%     zeroLine = (find(plotOrder == clusterNum) - 1) * verticalSpacing * ones(size(meanTrace));
% 
%     % Plot each mean stack with jbfill
%     plot(t.*10, offsetMeanTrace, 'k', 'LineWidth', 1.2);
%     fillpart = offsetMeanTrace < 0;             %change here
%     jbfill(t.*10, offsetMeanTrace, zeroLine, plotColors{i}, 'none', 0.2, 1);  %change here
% 
%     hold on
% end
% 
% xlabel('Depth (km)');
% ylabel('Clusters');
% xlim([60 350]); 
% ylim([-0.4, (length(plotOrder) - 1) * verticalSpacing + 0.4]); % Adjust Y-axis limits based on the number of clusters and spacing
% yticks;
% yticklabels({'C1','C2','C3','C4'});
% camroll(270)

%%
saveas(gcf, ['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/oceania/parameter_set_1/' 'oceania_sta_topo.jpg']);
%saveas(h3,[dir_path 'rf_fista_summary' num2str(i)],'png')

