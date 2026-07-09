% PlotCratons.m
% Exploratory script to plot global craton outlines from various datasets.

clear; clc; close all;

% 1. Setup paths
addpath('../../Data/m_map');

% 2. Initialize map
figure('Position', [100, 100, 1400, 900], 'Color', 'w');
m_proj('robinson', 'long', [-180 180], 'lat', [-90 90]);
m_coast('color', [0.6 0.6 0.6], 'linewidth', 1);
m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1);
hold on;

%% 3. Plot Global EarthByte Cratons (Blue) - COMMENTED OUT
% craton_shp = '../../Data/EarthByte_Craton_Boundaries/Craton_Data/Craton_Boundaries.shp';
% if isfile(craton_shp)
%     S_cratons = shaperead(craton_shp, 'UseGeoCoords', true);
%     for i = 1:length(S_cratons)
%         m_plot(S_cratons(i).Lon, S_cratons(i).Lat, 'b-', 'LineWidth', 1.5);
%     end
% end

%% 4. Plot Global Tectonics Cratons (Red) - RETAINED
gprv_shp = '../../Data/global_tectonics/plates&provinces/shp/cratons.shp';
if isfile(gprv_shp)
    S_gprv = shaperead(gprv_shp, 'UseGeoCoords', true);
    for i = 1:length(S_gprv)
        m_plot(S_gprv(i).Lon, S_gprv(i).Lat, 'r-', 'LineWidth', 1);
    end
end

%% 4b. Plot Global Tectonics Plate Boundaries (Black) - RETAINED
plate_shp = '../../Data/global_tectonics/plates&provinces/shp/plate_boundaries.shp';
if isfile(plate_shp)
    S_plate = shaperead(plate_shp, 'UseGeoCoords', true);
    for i = 1:length(S_plate)
        m_plot(S_plate(i).Lon, S_plate(i).Lat, 'k-', 'LineWidth', 1.5);
    end
end

%% 5. Plot North America Physiographic Regions (Green) - COMMENTED OUT
% na_physio = '../../Data/GeologicalData/north america/physio_shp/physio.shp';
% if isfile(na_physio)
%     S_na = shaperead(na_physio, 'UseGeoCoords', true);
%     for i = 1:length(S_na)
%         m_plot(S_na(i).Lon, S_na(i).Lat, 'g-', 'LineWidth', 1);
%     end
% end

%% 6. Plot Oceania Geological Regions (Cyan) - COMMENTED OUT
% oceania_geo = '../../Data/GeologicalData/oceania/Geological_Regions_of_Australia.shp';
% if isfile(oceania_geo)
%     S_oce = shaperead(oceania_geo, 'UseGeoCoords', true);
%     for i = 1:length(S_oce)
%         m_plot(S_oce(i).Lon, S_oce(i).Lat, 'c-', 'LineWidth', 1);
%     end
% end

%% 7. Plot Africa Cratons from CSV (Magenta) - COMMENTED OUT (Fixed lat/lon order)
% africa_csv_dir = '../../Data/GeologicalData/Africa/Archean_Blocks/';
% if isfolder(africa_csv_dir)
%     csv_files = dir(fullfile(africa_csv_dir, '*.csv'));
%     for i = 1:length(csv_files)
%         filepath = fullfile(africa_csv_dir, csv_files(i).name);
%         try
%             data = readtable(filepath); % Use readtable since it has headers
%             if size(data, 2) >= 2
%                 % Headers are 'latitude', 'longitude'
%                 m_plot(data.longitude, data.latitude, 'm-', 'LineWidth', 1.5);
%             end
%         catch
%             warning(['Could not read or plot: ', filepath]);
%         end
%     end
% end

%% 8. Plot Africa Lekic Cratons (Black dashed) - COMMENTED OUT (Fixed color to black)
% lekic_mat = '../../Data/GeologicalData/Africa/geoData/AfricaCratons_Lekic.mat';
% if isfile(lekic_mat)
%     load(lekic_mat); % Loads AfricaCratons struct
%     fields = fieldnames(AfricaCratons);
%     for i = 1:length(fields)
%         craton_data = AfricaCratons.(fields{i});
%         % Lekic outlines are [Lon, Lat]
%         m_plot(craton_data(:,1), craton_data(:,2), 'k--', 'LineWidth', 2.5);
%     end
% end

%% 9. Add title and legend
title('Global Craton Outlines and Plate Boundaries (Global Tectonics only)', 'FontSize', 16);

h(1) = plot(NaN, NaN, 'r-', 'LineWidth', 1);
h(2) = plot(NaN, NaN, 'k-', 'LineWidth', 1.5);
legend(h, {'Global Tectonics Cratons', 'Plate Boundaries'}, 'Location', 'southoutside', 'Orientation', 'horizontal');
