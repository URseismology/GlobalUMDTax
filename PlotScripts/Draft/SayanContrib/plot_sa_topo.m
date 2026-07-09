clear;clc;
%%

load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/south america/parameter_set_1/filtered_neg_sequenced_full.mat']);

station_details = readtable('/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/global_station_catalog_df.csv');
station_details = station_details(strcmp(station_details.continent,'South America'),:);
station_details.net_sta = strcat(station_details.network_code, '-' ,station_details.station_code);
station_filtered = station_details(ismember(station_details.net_sta, sequencedData.station),{'network_code','station_code','station_lat','station_lon','net_sta'});

new_stns_metadata = '/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/SA_Extra.csv';
new_stns_metadata = readtable(new_stns_metadata);

new_sta_ref = '/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/south america/parameter_set_1/south_am_lambda_list.csv';
new_sta_ref = readtable(new_sta_ref);

new_stns_metadata = new_stns_metadata(ismember(new_stns_metadata.Station, new_sta_ref.Station),{'Network','Station','Station_Lat','Station_Lon'});
new_stns_metadata.Properties.VariableNames = {'network_code','station_code','station_lat','station_lon'};
new_stns_metadata.net_sta = strcat(new_stns_metadata.network_code, '-' ,new_stns_metadata.station_code);

station_filtered = [station_filtered; new_stns_metadata];
%%
m_proj('miller','lon',[-84 -31],'lat',[-57 13]);  % African boundaries
m_grid('linestyle','none','tickdir','out','linewidth',3);
[CS,CH]=m_etopo2('contourf',[-7000:500:0 250:250:7000],'edgecolor','none');
m_gshhs('fb2','color','k','linewidth',2);
colormap([ m_colmap('blues',200); flipud(gray(256)) ]);
topoax = m_contfbar(0.85, [.17 .79], CS, CH);
ylabel(topoax, 'Topography (m)');
set(topoax,'fontsize',(12));

for iSta = 1 : length(sequencedData.station)
    sta = strtrim(sequencedData.station(iSta,:));
    sta_row = station_filtered(ismember(station_filtered.net_sta, sta),:);
    lat = sta_row.station_lat;
    lon = sta_row.station_lon;

    m_plot(lon, lat, 'marker','^', 'color','k','linewi',1,'linest','none','markersize',10,'markerfacecolor','k');
    hold on

end

%%
saveas(gcf, ['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/south america/parameter_set_1/' 'sa_sta_topo.jpg']);