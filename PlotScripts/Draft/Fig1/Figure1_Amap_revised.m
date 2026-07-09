function Figure1_Amap_revised()
    clear; close all; clc;
    addpath('./Data/m_map');
    addpath('./Data/landmask');
    addpath('./Data/slanCM');

    %% 1. Load Artemieva Global Crustal Age Model
    disp('Loading Artemieva Age Model...');
    AGE_FILE = '../../Data/MachineLearningData/IrinaThermal/global-ages-0705-1x1.nc';

    lon_age = ncread(AGE_FILE, 'lon');
    lat_age = ncread(AGE_FILE, 'lat');
    z_age = ncread(AGE_FILE, 'z'); % size [360 180]

    [LON_AGE, LAT_AGE] = ndgrid(lon_age, lat_age);
    LON_AGE(LON_AGE > 180) = LON_AGE(LON_AGE > 180) - 360;

    F_Age = scatteredInterpolant(double(LON_AGE(:)), double(LAT_AGE(:)), double(z_age(:)), 'linear', 'none');

    longridinterp = -180:0.5:180;
    latgridinterp = -90:0.5:90;
    [yq, xq] = meshgrid(latgridinterp, longridinterp);
    xq = double(xq); yq = double(yq);

    Age_Grid = F_Age(xq, yq);
    ocean_mask = ~landmask(yq, xq);
    Age_Grid(ocean_mask) = NaN;

    % Discretize ages: 1=Phanerozoic, 2=Proterozoic, 3=Archean
    Age_Discrete = zeros(size(Age_Grid));
    Age_Discrete(Age_Grid >= 0 & Age_Grid < 540) = 1;
    Age_Discrete(Age_Grid >= 540 & Age_Grid < 2500) = 2;
    Age_Discrete(Age_Grid >= 2500 & Age_Grid <= 3600) = 3;
    Age_Discrete(isnan(Age_Grid) | Age_Grid < 0) = NaN;

    custom_cmap = [
        0.88, 0.88, 0.88; % Phanerozoic (0-540 Ma)
        0.88, 0.80, 0.65; % Proterozoic (540-2500 Ma)
        0.35, 0.50, 0.65  % Archean (>2500 Ma)
    ];

    %% 2. Load Station Data & ML Results
    disp('Loading Station Data...');
    Data_CAM22_ML = readtable('Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv');
    Data_Global_RF_Meta = readtable('Data/MachineLearningData/rf_global_clustering/data/Data_Global_R1Meta.csv');

    st_lon = Data_Global_RF_Meta.Longitude;
    st_lat = Data_Global_RF_Meta.Latitude;
    st_depth = Data_CAM22_ML.Neg_Depth;
    st_c = Data_CAM22_ML.GMM_k4;

    valid_idx = ~isnan(st_depth);
    st_lon = st_lon(valid_idx);
    st_lat = st_lat(valid_idx);
    st_c = st_c(valid_idx);

    % Generate both versions of the plot
    generate_plot(st_lon, st_lat, st_c, xq, yq, Age_Discrete, custom_cmap, false, 'Figures/Global_Study/Figure1_Amap_revised_v1.png');
    generate_plot(st_lon, st_lat, st_c, xq, yq, Age_Discrete, custom_cmap, true, 'Figures/Global_Study/Figure1_Amap_revised_v2.png');
end

function generate_plot(st_lon, st_lat, st_c, xq, yq, Age_Discrete, custom_cmap, thin_flag, output_filename)
    f = figure('Name', 'Figure 1: Age-Craton Map', 'Position', [50, 100, 1600, 600], 'Visible', 'off');

    % Cluster subsets
    idx_c1 = find(st_c == 2); % Melt
    idx_c2 = find(st_c == 3); % Rheological
    idx_c3 = find(st_c == 0); % Metasomatic
    idx_c4 = find(st_c == 1); % Deep Structural

    if thin_flag
        disp('Applying station thinning (within 1 degree)...');
        [lon_c1, lat_c1] = thin_stations(st_lon(idx_c1), st_lat(idx_c1));
        [lon_c2, lat_c2] = thin_stations(st_lon(idx_c2), st_lat(idx_c2));
        [lon_c3, lat_c3] = thin_stations(st_lon(idx_c3), st_lat(idx_c3));
        [lon_c4, lat_c4] = thin_stations(st_lon(idx_c4), st_lat(idx_c4));
    else
        lon_c1 = st_lon(idx_c1); lat_c1 = st_lat(idx_c1);
        lon_c2 = st_lon(idx_c2); lat_c2 = st_lat(idx_c2);
        lon_c3 = st_lon(idx_c3); lat_c3 = st_lat(idx_c3);
        lon_c4 = st_lon(idx_c4); lat_c4 = st_lat(idx_c4);
    end

    % Base size: 30 reduced by 30% is 21
    psz = 21;

    %% PANEL A: C1, C2, C3
    ax_a = axes('Position', [0.03, 0.18, 0.44, 0.78]);
    m_proj('robinson', 'long', [-180 180]);
    hold on;
    m_pcolor(xq, yq, Age_Discrete);
    colormap(ax_a, custom_cmap);
    caxis([1 3]);
    shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1);
    plot_plate_boundaries();

    % C1: Red Circle
    h_c1 = m_scatter(lon_c1, lat_c1, psz, 'o', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', [0.8 0.1 0.1], 'LineWidth', 0.8);
    % C2: Blue Circle with Dot
    h_c2 = m_scatter(lon_c2, lat_c2, psz, 'o', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', [0.1 0.3 0.8], 'LineWidth', 0.8);
    m_scatter(lon_c2, lat_c2, psz/12, 'o', 'MarkerFaceColor', [0.1 0.3 0.8], 'MarkerEdgeColor', [0.1 0.3 0.8]);
    % C3: Green Circle with Cross
    h_c3 = m_scatter(lon_c3, lat_c3, psz, 'o', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', [0.1 0.6 0.3], 'LineWidth', 0.8);
    m_scatter(lon_c3, lat_c3, psz, '+', 'MarkerEdgeColor', [0.1 0.6 0.3], 'LineWidth', 0.8);

    legend([h_c1, h_c2, h_c3], {'C1 (Melt: Red Circle)', 'C2 (Rheological: Blue Circle+Dot)', 'C3 (Metasomatic: Green Circle+Cross)'}, 'Location', 'southoutside', 'Orientation', 'horizontal', 'FontSize', 9);

    %% PANEL B: C4
    ax_b = axes('Position', [0.53, 0.18, 0.44, 0.78]);
    m_proj('robinson', 'long', [-180 180]);
    hold on;
    m_pcolor(xq, yq, Age_Discrete);
    colormap(ax_b, custom_cmap);
    caxis([1 3]);
    shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1);
    plot_plate_boundaries();

    % C4: Black Circle with Star
    h_c4 = m_scatter(lon_c4, lat_c4, psz, 'o', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'k', 'LineWidth', 0.8);
    m_scatter(lon_c4, lat_c4, psz*0.8, 'p', 'MarkerFaceColor', [0.2 0.2 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 0.6);

    legend(h_c4, {'C4 (Deep Structural: Black Circle+Star)'}, 'Location', 'southoutside', 'Orientation', 'horizontal', 'FontSize', 9);

    % Shared colorbar
    c = colorbar('southoutside');
    c.Position = [0.15, 0.08, 0.7, 0.03];
    c.Ticks = [1.33 2.0 2.66];
    c.TickLabels = {'Phanerozoic (0-540 Ma)', 'Proterozoic (540-2500 Ma)', 'Archean (>2500 Ma)'};
    c.Label.String = 'Tectonic Crustal Age';
    c.Label.FontWeight = 'bold';

    % Save figure
    exportgraphics(f, output_filename, 'Resolution', 300);
    disp(['Figure saved as ' output_filename]);
end

function [new_lon, new_lat] = thin_stations(lon, lat)
    n = length(lon);
    if n == 0
        new_lon = []; new_lat = [];
        return;
    end
    groups = {};
    grouped = false(n, 1);
    for i = 1:n
        if grouped(i), continue; end
        dists = sqrt((lon - lon(i)).^2 + (lat - lat(i)).^2);
        idx = find(dists <= 1 & ~grouped);
        groups{end+1} = idx;
        grouped(idx) = true;
    end
    new_lon = zeros(length(groups), 1);
    new_lat = zeros(length(groups), 1);
    for g = 1:length(groups)
        new_lon(g) = mean(lon(groups{g}));
        new_lat(g) = mean(lat(groups{g}));
    end
end

function plot_plate_boundaries()
    S_plates = shaperead('Data/global_tectonics/plates&provinces/shp/plate_boundaries.shp');
    for i = 1:length(S_plates)
        ptype = S_plates(i).type;
        x = S_plates(i).X;
        y = S_plates(i).Y;
        
        if strcmp(ptype, 'subduction zone') || strcmp(ptype, 'collision zone')
            if strcmp(ptype, 'subduction zone')
                pc = [0.1 0.3 0.6]; % Muted Blue
            else
                pc = 'k';
            end
            m_line(x, y, 'color', pc, 'linewidth', 1.0);
            
            if strcmp(ptype, 'subduction zone')
                valid = find(~isnan(x) & ~isnan(y));
                if isempty(valid), continue; end
                mx = x(valid(1));
                my = y(valid(1));
                dist = 0;
                for k = 2:length(valid)
                    idx = valid(k);
                    prev = valid(k-1);
                    if idx ~= prev + 1
                        dist = 0;
                        mx(end+1) = x(idx);
                        my(end+1) = y(idx);
                        continue;
                    end
                    d = sqrt((x(idx) - x(prev))^2 + (y(idx) - y(prev))^2);
                    dist = dist + d;
                    if dist >= 10
                        mx(end+1) = x(idx);
                        my(end+1) = y(idx);
                        dist = 0;
                    end
                end
                m_line(mx, my, 'color', pc, 'linestyle', 'none', 'marker', '^', 'markersize', 1.8, 'markerfacecolor', pc);
            end
        else
            m_line(x, y, 'color', [0.7 0.7 0.7], 'linewidth', 0.6);
        end
    end
end
