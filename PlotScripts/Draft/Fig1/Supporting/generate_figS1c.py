import re

with open('FigureS1b_Maps_Stats.m', 'r') as f:
    code = f.read()

# Extract preamble (imports and grid loading)
preamble = re.search(r'function FigureS1b_Maps_Stats\(\).*?%% 4. Load Clustering Statistics', code, re.DOTALL).group(0)
preamble = preamble.replace('FigureS1b_Maps_Stats', 'FigureS1c_MapsLocs')

# Extract plot_plate_boundaries
plot_plate = re.search(r'function plot_plate_boundaries\(\).*?end\n$', code, re.DOTALL).group(0)

# Build new code
new_code = preamble + """
    disp('Loading Clustering Statistics...');
    stats_dir = '/Users/tolumorayo/SynologyDrive/1.UofR_Seismology/3_Projects/Pr1_GlobalUMDNature/6_Submit/3_PNAS/rf_global_clustering/results/';
    meta_dir = '/Users/tolumorayo/SynologyDrive/1.UofR_Seismology/3_Projects/Pr1_GlobalUMDNature/6_Submit/3_PNAS/rf_global_clustering/data/';
    
    cam22_opts = detectImportOptions(fullfile(stats_dir, 'clustered_data_Neg_CAM22.csv'));
    cam22_data = readtable(fullfile(stats_dir, 'clustered_data_Neg_CAM22.csv'), cam22_opts);
    
    meta_opts = detectImportOptions(fullfile(meta_dir, 'Data_Global_R1Meta.csv'));
    meta_data = readtable(fullfile(meta_dir, 'Data_Global_R1Meta.csv'), meta_opts);
    
    st_lon = meta_data.Longitude;
    st_lat = meta_data.Latitude;
    st_depth = cam22_data.Neg_Depth;
    st_c = cam22_data.GMM_k4;
    
    valid_idx = ~isnan(st_depth);
    st_lon = st_lon(valid_idx);
    st_lat = st_lat(valid_idx);
    st_c = st_c(valid_idx);
    
    % Indices for each cluster based on raw GMM_k4
    % raw 2 = C1, raw 3 = C2, raw 0 = C3, raw 1 = C4
    idx_c1 = find(st_c == 2);
    idx_c2 = find(st_c == 3);
    idx_c3 = find(st_c == 0);
    idx_c4 = find(st_c == 1);
    
    %% 5. Setup Figure and Layout (4x2 grid)
    f = figure('Name', 'Figure 2c: Maps and Locations', 'Position', [100, 50, 1200, 1600], 'Color', 'w', 'Visible', 'off');
    
    w_panel = 0.41;
    h_panel = 0.162; 
    px_left1 = 0.05;
    px_left2 = 0.50;
    
    % Contiguous layout positions with zero vertical gap between actual maps
    py = [0.05 + 3*h_panel, 0.05 + 2*h_panel, 0.05 + h_panel, 0.05];
    
    % Helper to plot locations
    function plot_locs_left()
        psz = 12;
        m_scatter(st_lon(idx_c1), st_lat(idx_c1), psz, 'o', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', [0.8 0.1 0.1], 'LineWidth', 0.8);
        m_scatter(st_lon(idx_c2), st_lat(idx_c2), psz, 'o', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', [0.1 0.3 0.8], 'LineWidth', 0.8);
        m_scatter(st_lon(idx_c3), st_lat(idx_c3), psz, 'o', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', [0.1 0.6 0.3], 'LineWidth', 0.8);
    end

    function plot_locs_right()
        psz = 12;
        m_scatter(st_lon(idx_c4), st_lat(idx_c4), psz, 'o', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'k', 'LineWidth', 0.8);
        m_scatter(st_lon(idx_c4), st_lat(idx_c4), psz*0.8, 'p', 'MarkerFaceColor', [0.2 0.2 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 0.6);
    end

    %% Panel 1: Temperature (Top)
    disp('Plotting Panel 1: Temperature...');
    % Left
    ax1L = axes('Position', [px_left1, py(1), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, Temp_Grid); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax1L, slanCM('thermal')); caxis(ax1L, [300 1500]);
    plot_locs_left();
    title(ax1L, 'Temperature (CAM22) - Clusters C1, C2, C3', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Right
    ax1R = axes('Position', [px_left2, py(1), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, Temp_Grid); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax1R, slanCM('thermal')); caxis(ax1R, [300 1500]);
    plot_locs_right();
    title(ax1R, 'Temperature (CAM22) - Cluster C4', 'FontSize', 12, 'FontWeight', 'bold');
    
    c1 = colorbar(ax1R, 'eastoutside');
    c1.Label.String = 'Temperature (°C)';
    c1.Label.FontWeight = 'bold'; c1.Label.FontSize = 12;

    %% Panel 2: Vote Map
    disp('Plotting Panel 2: Vote Map...');
    % Left
    ax2L = axes('Position', [px_left1, py(2), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, totvotpos1); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax2L, slanCM('bilbao')); caxis(ax2L, [0 9]);
    plot_locs_left();
    
    % Right
    ax2R = axes('Position', [px_left2, py(2), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, totvotpos1); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax2R, slanCM('bilbao')); caxis(ax2R, [0 9]);
    plot_locs_right();
    
    c2 = colorbar(ax2R, 'eastoutside');
    c2.Label.String = 'Craton Vote Map (Votes)';
    c2.Label.FontWeight = 'bold'; c2.Label.FontSize = 12;

    %% Panel 3: Attenuation
    disp('Plotting Panel 3: Attenuation...');
    % Left
    ax3L = axes('Position', [px_left1, py(3), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, ln_Q_inv); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax3L, slanCM('vik'));
    plot_locs_left();
    
    % Right
    ax3R = axes('Position', [px_left2, py(3), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, ln_Q_inv); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax3R, slanCM('vik'));
    plot_locs_right();
    
    c3 = colorbar(ax3R, 'eastoutside');
    c3.Label.String = 'Attenuation ln(Q^{-1})';
    c3.Label.FontWeight = 'bold'; c3.Label.FontSize = 12;

    %% Panel 4: Shear-Velocity (Bottom)
    disp('Plotting Panel 4: Shear Velocity...');
    % Left
    ax4L = axes('Position', [px_left1, py(4), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, dvs_Grid); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax4L, flipud(slanCM('vik'))); caxis(ax4L, [-5 5]); 
    plot_locs_left();
    
    % Right
    ax4R = axes('Position', [px_left2, py(4), w_panel, h_panel]);
    m_proj('robinson', 'long', [-180 180]); hold on;
    m_pcolor(xq, yq, dvs_Grid); shading flat;
    m_coast('color', [0.3 0.3 0.3], 'linewidth', 1);
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 1, 'xticklabels', [], 'yticklabels', []);
    plot_plate_boundaries();
    colormap(ax4R, flipud(slanCM('vik'))); caxis(ax4R, [-5 5]); 
    plot_locs_right();
    
    c4 = colorbar(ax4R, 'eastoutside');
    c4.Label.String = 'dVs/Vs (%)';
    c4.Label.FontWeight = 'bold'; c4.Label.FontSize = 12;

    %% Save Figure
    exportgraphics(f, '../../../Figures/Global_Study/FigureS1c_MapsLocs.png', 'Resolution', 300);
    disp('Figure saved as Figures/Global_Study/FigureS1c_MapsLocs.png');
end

""" + plot_plate

with open('FigureS1c_MapsLocs.m', 'w') as f:
    f.write(new_code)
