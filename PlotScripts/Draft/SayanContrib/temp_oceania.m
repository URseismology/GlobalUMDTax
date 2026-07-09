% fig2=figure;
% colors = {'red', 'green', 'blue', 'yellow'};
% rectangle('Position', [0, 0, 1, 1]);
% for i = 1:4
%     % Define rectangle coordinates and size
%     x = 0.1; y = i * 0.05;   
%     width = 0.1; height = 0.05;   
%     rectangle('Position', [x, y, width, height], 'FaceColor', colors{i});
%     text(x + width + 0.05, y + height / 2, ['Cluster ' num2str(i)], 'VerticalAlignment', 'middle');
% end
% ax2=axes;

%%
% clf
% load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
%     'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/oceania/parameter_set_1/filtered_neg_sequenced_full.mat']);
% verticalSpacing = 0.5;
% plotOrder = [1,2,4,3];
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
%     plot(t, offsetMeanTrace, 'k', 'LineWidth', 1.2);
%     fillpart = offsetMeanTrace > 0;             %change here
%     jbfill(t, offsetMeanTrace, zeroLine, 'blue', 'none', 0.2, 1);  %change here
% 
%     hold on
% end
% 
% xlabel('Time (s)');
% ylabel('Clusters');
% xlim([6 30]); 
% ylim([-0.4, (length(plotOrder) - 1) * verticalSpacing + 0.4]); % Adjust Y-axis limits based on the number of clusters and spacing
% yticks;
% yticklabels({'C1','C2','C4','C3'});
% camroll(270)

%%
% load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
%      'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/oceania/parameter_set_1/filtered_neg_sequenced_full.mat']);
% 
% 
% load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
%     'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/oceania/parameter_set_1/filtered_neg_sequenced_full.mat']);
% 
% station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/global_station_catalog_df.csv');
% station_details = station_details(strcmp(station_details.continent,'Oceania'),:);
% station_details.net_sta = strcat(station_details.network_code, '-' ,station_details.station_code);
% station_filtered = station_details(ismember(station_details.net_sta, sequencedData.station),:);
% station_map = zeros(size(sequencedData.station,1),3);
% for iSta = 1 : length(sequencedData.station)
%     sta = strtrim(sequencedData.station(iSta,:));
%     sta_row = station_filtered(ismember(station_filtered.net_sta, sta),:);
%     sta_row = sta_row(1,:);
%     station_map(iSta,1) = sta_row.station_lat;
%     station_map(iSta,2) = sta_row.station_lon;
%     station_map(iSta,3) = sequencedData.clusters(iSta,:);
% end

% edges = min(station_map(:,2)):10:max(station_map(:,2));
% h1 = station_map(find(station_map(:,3)==1),2); h1=histcounts(h1,edges);
% h2 = station_map(find(station_map(:,3)==2),2); h2=histcounts(h2,edges);
% h3 = station_map(find(station_map(:,3)==3),2); h3=histcounts(h3,edges);
% h4 = station_map(find(station_map(:,3)==4),2); h4=histcounts(h4,edges);


%% 
% figure;
% scat_col=[[1 0 0];[1 0 1];[1 1 0];[0 0 1]];
% c_map=scat_col(station_map(:,3),:);
% scatter(station_map(:,2),station_map(:,1),120,c_map, ...
%     'filled','^','linewidth',1.5)

%%
% temp_dir = [pwd '/temp'];
% if ~exist(temp_dir,'dir')
%     mkdir(temp_dir)
% end
% 
% files = gunzip('gshhs_c.b.gz', temp_dir);
% 
% filename = files{1};
% indexfile = gshhs(filename, 'createindex');
% S = gshhs(filename, [-45 -8], [111 156]);
% delete(filename);
% delete(indexfile);
% rmdir(temp_dir, 's');
% levels = [S.Level];
% L1 = S(levels == 1);
% 
% oce_geo = readgeotable(['/scratch/tolugboj_lab/Sayan_Swar_WS/' ...
%     'PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/' ...
%     'geological_data/oceania/Geological_Regions_of_Australia.geojson']);
% 
% T=geotable2table(oce_geo,["lat","lon"]);
% T=T(T.feature~="GR_VOID",:);
% 
% ageRanges = [
%     4000;   % Archaean
%     2500;   % Archaean to Proterozoic
%     66;     % Cainozoic
%     251;    % Mesozoic
%     145;    % Mesozoic to Cainozoic
%     541;    % Palaeozoic
%     230;    % Palaeozoic to Cainozoic
%     320;    % Palaeozoic to Mesozoic
%     2500;   % Proterozoic
%     260;    % Proterozoic to Mesozoic
%     750;    % Proterozoic to Palaeozoic
% ];
% 
% area_per_age = groupsummary(T,"age_class","sum","aprox_area");
% area_per_age.age = ageRanges;
% area_per_age = sortrows(area_per_age,"age","descend");
% area_range = [min(area_per_age.sum_aprox_area),max(area_per_age.sum_aprox_area)];
% all_areas = area_per_age.sum_aprox_area;
% all_area_norm = round(((all_areas-min(all_areas))/(max(all_areas)-min(all_areas)))*255+1);
% 
% 
% figure;
% alpha_value = 0.04;
% temp_colmap=interp1(linspace(1,9,9),unique(slanCM('Pastel1'),'rows'),linspace(1,9,11));
% alpha_matrix = ones(size(temp_colmap, 1), 1) * alpha_value;
% colormap_sel=colormap(temp_colmap);%unique(slanCM('Set3'),'rows'));
% colormap_sel = [colormap_sel,alpha_matrix];
% colormap_sel = colormap_sel(1:11,:);
% m_proj('miller','lon',[111 156],'lat',[-45 -8]); 
% m_grid('linestyle','none','tickdir','out','linewidth',3);
% m_line([L1.Lon], [L1.Lat], 'color',[0 0 0 0.5],'linewi',1);
% label_fig = {};
% for i=1:length(area_per_age.age_class)
%     T_age = T(T.age_class==area_per_age.age_class(i,:),:);
%     [lat,lon] = polyjoin(T_age.lat,T_age.lon);
%     area_sum = area_per_age.sum_aprox_area;
%     m_line(lon, lat, 'color',[0 0 0 0.5],'linewi',1);
%     %m_patch(lon,lat,colormap_sel(all_area_norm(i)));
%     m_hatch(lon,lat,'single',1,0.01,'color',colormap_sel(i,:));
%     label_fig{i} = strcat(area_per_age.age_class(i,:), '(',num2str(area_per_age.age(i)),' mn)');
% end
% %colormap(colormap_sel);
% cb = colorbar;cb.TickLabels = label_fig';%area_per_age.age_class;
% cb.Location = "eastoutside";


%%
%cb.Ruler.TickLabelRotation=45;
% figure;
% m_proj('miller','lon',[111 156],'lat',[-45 -8]); 
% m_grid('linestyle','none','tickdir','out','linewidth',3);
% m_line([L1.Lon], [L1.Lat], 'color','k','linewi',2);
% m_line(lon, lat, 'color',[0.3, 0.3, 0.3],'linewi',2);

%%
%figure
%m_proj('lambert','long',[-160 -40],'lat',[30 80]);
%m_coast('patch',[1 1 1]);
%m_elev('contourf',[500:500:6000]);
%m_grid('box','fancy','tickdir','in');
%colormap(flipud(copper));
%%
% m_proj('lambert','lon',[-10 20],'lat',[33 48]); 
% 
% [CS,CH]=m_etopo2('contourf',[-5000:500:0 250:250:3000],'edgecolor','none');
% m_grid('linestyle','none','tickdir','out','linewidth',3);

%%
% clf
% m_proj('lambert','lat',[5 24],'long',[105 125]);
% 
% set(gcf,'color','w')   % Set background colour before m_image call
% 
% caxis([-6000 0]);
% colormap(flipud([flipud(m_colmap('blues',10));m_colmap('jet',118)]));
% %m_etopo2('shadedrelief','gradient',3);
%  
% m_gshhs_i('patch',[.8 .8 .8]);
%  
% m_grid('box','fancy');
% 
% ax=m_contfbar(.97,[.5 .9],[-6000 0],[-6000:100:000],'edgecolor','none','endpiece','no');
% xlabel(ax,'meters','color','k');

%%
% load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
%     'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/oceania/parameter_set_1/filtered_neg_sequenced_full.mat']);
% figure;
% verticalSpacing = 0.5;
% plotOrder = [1,2,3,4];
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
%     jbfill(t.*10, offsetMeanTrace, zeroLine, [0.957 0 0], 'none', 0.2, 1);  %change here
% 
%     hold on
% end
% 
% xlabel('Depth (km)');
% ylabel('Clusters');
% xlim([60 350]); 
% ylim([-0.4, (length(plotOrder) - 1) * verticalSpacing + 0.4]); % Adjust Y-axis limits based on the number of clusters and spacing
% yticks;
% yticklabels({'N1','N2','N3','N4'});
% ax2=axes('position',[-0.1,0,0.1,1],'Color','g','Visible','on');
%rectangle('Position', [-2, 1, 20, 0.2], 'FaceColor', 'b');
%camroll(270)
%% Plotting of Global Ages - Stp1 Data Load Stations

% seq_rf = load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
%     'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/oceania/parameter_set_1/filtered_sequenced_full.mat']);
% 
% filt_idx=true(length(seq_rf.station),1);
% filt_idx(find(ismember(seq_rf.station,{'AU-PSAA2','AU-PSAA1','AU-PSAA3','AU-BW1H','AU-MANU','AU-RABL','IU-PMG','GE-PMG','IU-SNZO'})))=0;
% seq_rf.station=seq_rf.station(filt_idx,:);
% seq_rf.dataset_imageRFs_pos_reordered=seq_rf.dataset_imageRFs_pos_reordered(filt_idx,:);
% 
% safr_station_details = load('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/south_africa_stations_joel.mat').T;
% usa_station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/usa_all_stations_steve.csv');
% station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/global_stations_donwloaded_catalog.csv');
% station_details.IsLand = landmask(station_details.station_lat,station_details.station_lon);
% station_details.net_sta = strcat(station_details.network,'.',station_details.station);
% usa_station_details.net_sta = strcat(usa_station_details.Network,'.',usa_station_details.Station);
%%
% usa_station_details.continent = repmat({'usa & alaska'}, size(usa_station_details,1),1);

%%
% oce_station_details = station_details(strcmp(station_details.continent,'oceania'),:);
% oce_station_details.net_sta = strcat(oce_station_details.network, '-' ,oce_station_details.station);
% oce_station_filtered = oce_station_details(ismember(oce_station_details.net_sta, seq_rf.station),:);
% 
% sa_station_details = station_details(strcmp(station_details.continent,'south america'),:);
% %sa_station_details = sa_station_details(sa_station_details.IsLand==1,:);
% asia_station_details = station_details(strcmp(station_details.continent,'asia'),:);
% %asia_station_details = asia_station_details(asia_station_details.IsLand==1,:);
% eu_station_details = station_details(strcmp(station_details.continent,'europe'),:);
% %eu_station_details = eu_station_details(eu_station_details.IsLand==1,:);
% ant_station_details = station_details(strcmp(station_details.continent,'antartica'),:);
% %ant_station_details = ant_station_details(ant_station_details.IsLand==1,:);
% na_station_details = station_details(strcmp(station_details.continent,'north america'),:);
% %na_station_details = na_station_details(na_station_details.IsLand==1,:);
% afr_station_details = station_details(strcmp(station_details.continent,'africa'),:);
% %afr_station_details = afr_station_details(afr_station_details.IsLand==1,:);

%%
% all_stations_to_plot = [oce_station_filtered.station_lat oce_station_filtered.station_lon];
% all_stations_to_plot = [all_stations_to_plot; [sa_station_details.station_lat sa_station_details.station_lon];
%     [asia_station_details.station_lat asia_station_details.station_lon]; [eu_station_details.station_lat eu_station_details.station_lon];
%     [ant_station_details.station_lat ant_station_details.station_lon]; [na_station_details.station_lat na_station_details.station_lon];
%     [afr_station_details.station_lat afr_station_details.station_lon]; [usa_station_details.Latitude usa_station_details.Longitude]];
% 
% all_station_to_plot_name = [[oce_station_filtered.net_sta oce_station_filtered.continent]; [sa_station_details.net_sta sa_station_details.continent];
%  [asia_station_details.net_sta asia_station_details.continent]; [eu_station_details.net_sta eu_station_details.continent];
%  [ant_station_details.net_sta ant_station_details.continent]; [na_station_details.net_sta na_station_details.continent];
%  [afr_station_details.net_sta afr_station_details.continent]; [usa_station_details.net_sta usa_station_details.continent];
%  ];
%% Plotting of Global Ages - Stp1 Data Load Age
% clc;
% ageMap = load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/' ...
%     'global_age_metadata/IrinaThermal/global-ages-0705-1x1.xyz.txt']);
% 
% load coastlines;
% exclude_idx = find(coastlon>180);
% all_idx = true(size(coastlon));
% all_idx(exclude_idx) = false;
% coastlon = coastlon(all_idx);
% coastlat = coastlat(all_idx);
% 
% [latgrid, longrid] = meshgrid(linspace(-89.5,89.5, 3600), linspace(-179, 179, 3600)); %meshgrid(coastlat,coastlon);
% 
% F = scatteredInterpolant(ageMap(:,1), ageMap(:,2), ageMap(:,3), 'natural', 'none'); %1 is lon, 2 is lat
% crustAge = F(longrid, latgrid);
% mAge = max(max(crustAge));
% oceanAll = ~landmask(latgrid,longrid);
% crustAge(oceanAll) = NaN;

%%
% nstations = length(all_stations_to_plot(:,1));
% all_stations_age_group = zeros(nstations,1);
% for i=1:nstations
%     [~,min_latidx] = min(abs(latgrid(1,:)-all_stations_to_plot(i,1)));
%     [~,min_lonidx] = min(abs(longrid(:,1)-all_stations_to_plot(i,2)));
%     best_age = crustAge(min_lonidx,min_latidx);
%     if best_age<=1200
%         all_stations_age_group(i,1)=1; %phanerozoic
%     elseif best_age<=2500
%         all_stations_age_group(i,1)=2; %precambrian
%     else
%         all_stations_age_group(i,1)=3; %archean
%     end 
% end
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
% useMap = crustAge; 
% useCols = [[0.624 0.808 0.325];[0.376 0.612 0.831];[0.878 0.098 0.129]];
% useTitle = 'Global Stations Under Analysis';
% 
% yt_div = mAge/3;
% yt = [1 yt_div yt_div*2 yt_div*3];
% yyt = yt;
% barLabel = 'Age (Ma)';
% clims = [0 mAge];
% nmLabel = { '0'
%     '540 (Phanerozoic)'
%     '2500 (Precambrian)'
%     '3600 (Archean)'
%     };
% 
% figure;
% m_proj('robinson');
% hold on;
% %m_coast('color', 'k', 'LineWidth', 0.2);
% vw = m_pcolor(longrid, latgrid, useMap); shading flat;
% % m_grid('linestyle', 'none', 'fontsize', 10, 'tickdir','out', 'box', 'fancy', 'yticklabels', [], ...
% %         'xticklabels', []);
% m_grid('tickdir','out','linewi',2);
% 
% % m_plot(oce_station_filtered.station_lon, oce_station_filtered.station_lat, 'marker','x', 'color','k','linewi',1,...
% %        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% % 
% % m_plot(usa_station_details.Longitude, usa_station_details.Latitude, 'marker','x', 'color','k','linewi',1,...
% %        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% % 
% % m_plot(sa_station_details.station_lon, sa_station_details.station_lat, 'marker','x', 'color','k','linewi',1,...
% %        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% % 
% % m_plot(eu_station_details.station_lon, eu_station_details.station_lat, 'marker','x', 'color','k','linewi',1,...
% %        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% % 
% % m_plot(asia_station_details.station_lon, asia_station_details.station_lat, 'marker','x', 'color','k','linewi',1,...
% %        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% % 
% % m_plot(ant_station_details.station_lon, ant_station_details.station_lat, 'marker','x', 'color','k','linewi',1,...
% %        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% % 
% % m_plot(na_station_details.station_lon, na_station_details.station_lat, 'marker','x', 'color','k','linewi',1,...
% %        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% % 
% % m_plot(afr_station_details.station_lon, afr_station_details.station_lat, 'marker','x', 'color','k','linewi',1,...
% %        'linest','none','markersize',6,'markerfacecolor',[0.8 0.8 0.8]);
% %
% % m_plot(safr_station_details(:,1).Lat_Lon(:,2), safr_station_details(:,1).Lat_Lon(:,1), 'marker','^', 'color','k','linewi',1,...
% %        'linest','none','markersize',7,'markerfacecolor',[0.8 0.8 0.8]);
% 
% coord_idx = find(all_stations_age_group==3);
% m_plot(all_stations_to_plot(coord_idx,2), all_stations_to_plot(coord_idx,1), 'marker','x', 'color','k','linewi',2,...
%        'linest','none','markersize',5);
% coord_idx = find(all_stations_age_group==2);
% m_plot(all_stations_to_plot(coord_idx,2), all_stations_to_plot(coord_idx,1), 'marker','o', 'color','k','linewi',1,...
%        'linest','none','markersize',5);
% coord_idx = find(all_stations_age_group==1);
% m_plot(all_stations_to_plot(coord_idx,2), all_stations_to_plot(coord_idx,1), 'marker','+', 'color','k','linewi',1,...
%        'linest','none','markersize',5);
% 
% 
% colormap(useCols);
% h = colorbar('southoutside'); 
% caxis(clims);
% set(h, 'fontsize', 9)
% set(h, 'YTick', yyt, 'XTickLabel', nmLabel);
% h.TickDirection='none';
% xlabel(h, barLabel, 'FontSize', 9);
% 
% title(useTitle);
%% Find Stations As Per Age and Continent
% age_coord_idx = find(all_stations_age_group==2);
% station_name_filtered_by_age = all_station_to_plot_name(age_coord_idx,:);
% station_coord_filtered_by_age = all_stations_to_plot(age_coord_idx,:);
% station_name_idx = strcmp(station_name_filtered_by_age(:,2),'south america');
% station_name_filtered_by_age_cont = station_name_filtered_by_age(station_name_idx,:);
% station_coord_filtered_by_age_cont = station_coord_filtered_by_age(station_name_idx,:);
% %all_stations_age_group(age_coord_idx,:);













f





