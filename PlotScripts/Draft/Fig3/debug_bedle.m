% debug_bedle.m
addpath('../../Data/m_map');
f = figure('Position', [100, 100, 1000, 600]);

m_proj('robinson', 'lon', [-180 180], 'lat', [-90 90]);
m_coast('color', [0.5 0.5 0.5]);
m_grid('box', 'fancy');
title('Individual KML Craton Polygons (from BedlePlotter)');
hold on;

kml_dir = '../../Draft/BedlePlotter/digitization';
kml_files = dir(fullfile(kml_dir, '*.kml'));

colors = lines(length(kml_files));

for i = 1:length(kml_files)
    filename = fullfile(kml_dir, kml_files(i).name);
    str = fileread(filename);
    idx1 = strfind(str, '<coordinates>');
    idx2 = strfind(str, '</coordinates>');
    
    if ~isempty(idx1) && ~isempty(idx2)
        coord_str = str(idx1(1)+13:idx2(1)-1);
        C = textscan(coord_str, '%f,%f,%f');
        lon = C{1};
        lat = C{2};
        
        % Plot each KML as a distinct polygon
        if length(lon) > 1
            m_line(lon, lat, 'color', colors(i,:), 'linewidth', 2.0);
            
            % Add a label at the centroid
            mlon = mean(lon(~isnan(lon)));
            mlat = mean(lat(~isnan(lat)));
            [name, ~] = strtok(kml_files(i).name, '.');
            m_text(mlon, mlat, name, 'color', colors(i,:), 'fontweight', 'bold', 'fontsize', 8, 'interpreter', 'none');
        end
    end
end

out_dir = '../../Figures/Global_Study';
if ~isfolder(out_dir), mkdir(out_dir); end
exportgraphics(f, fullfile(out_dir, 'Debug_Bedle.png'), 'Resolution', 300);
