function Figure3_Composite()
% Composites Figure 3 from its two independently-generated pieces:
%   (a) the world map + legend      -> Figure3_Map.m
%   (b-g) the 2x3 waveform/KDE grid -> Figure3_WaveformsKDE.m
% Both must already have been run (their PNGs live in ../../Figures/Global_Study/).
%
% The panel grid is shifted up to overlap the map's south-pole/Antarctica
% region (blank of any station data) rather than leaving a plain gap --
% the overlap amount is detected automatically from the map's own content,
% and a white pad is added to the panel's top edge first so the paste can
% never clip real content (title text) in either source image.

    out_dir = '../../Figures/Global_Study';
    map_img = imread(fullfile(out_dir, 'Figure3_Map.png'));
    panel_img = imread(fullfile(out_dir, 'Figure3_WaveformsKDE.png'));
    map_gray = rgb2gray(map_img);

    [h_map, w_map, ~] = size(map_img);
    row_extent = sum(map_gray < 250, 2) / w_map;  % fraction of each row that's non-white
    oval_bottom = max(find(row_extent > 0.5));    % bottom rim of the Robinson oval
    antarctica_start = round(oval_bottom * 0.90);  % Antarctica sits in the last ~10% of the oval

    target_w = w_map;
    scale = target_w / size(panel_img, 2);
    new_h = round(size(panel_img, 1) * scale);
    panel_resized = imresize(panel_img, [new_h, target_w]);

    overlap = h_map - antarctica_start + 20;  % +20px margin past Antarctica's start
    panel_padded = cat(1, 255*ones(overlap, target_w, 3, 'uint8'), panel_resized(:,:,1:3));

    panel_h = size(panel_padded, 1);
    composite_h = h_map + panel_h - overlap;
    composite = 255 * ones(composite_h, target_w, 3, 'uint8');
    composite(1:h_map, :, :) = map_img(:,:,1:3);

    paste_start = h_map - overlap + 1;
    region = composite(paste_start:paste_start+panel_h-1, :, :);
    is_content = repmat(rgb2gray(panel_padded) < 250, [1 1 3]);
    region(is_content) = panel_padded(is_content);
    composite(paste_start:paste_start+panel_h-1, :, :) = region;

    out_file = fullfile(out_dir, 'Figure3_Composite.png');
    imwrite(composite, out_file);
    fprintf('Saved %s (overlap=%dpx, map:panel = %.0f:%.0f)\n', out_file, overlap, ...
        100*(h_map-overlap)/composite_h, 100*panel_h/composite_h);
end
