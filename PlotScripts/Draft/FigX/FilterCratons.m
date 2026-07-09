S = shaperead('Data/global_tectonics/plates&provinces/shp/cratons.shp');
areas = [S.area];
[sorted_areas, idx] = sort(areas, 'descend');
fprintf('Top 10 Craton Areas:\n');
for i = 1:min(10, length(idx))
    fprintf('%s (Group: %s): %g\n', S(idx(i)).prov_name, S(idx(i)).prov_group, S(idx(i)).area);
end

% Filter for supercratons (e.g. area > 500,000)
S_filtered = S(areas > 500000);
shapewrite(S_filtered, 'Data/global_tectonics/plates&provinces/shp/supercratons.shp');
fprintf('Saved supercratons.shp with %d polygons (down from %d).\n', length(S_filtered), length(S));
