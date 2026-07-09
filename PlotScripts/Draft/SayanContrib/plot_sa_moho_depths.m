%%
clc;
sa_coastline = readtable(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/' ...
    'station_metadata/geological_data/south america/SA_Coastline.csv']);
sa_coast_lat = sa_coastline.Latitude;
sa_coast_lon = sa_coastline.Longitude;
coastline = polyshape(sa_coast_lon,sa_coast_lat);

%% Using the Moho Depth Data From the Paper and Supplements of the following two Papers
% https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2018JB016811
% https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2009JB006829

filepath1 = '/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/moho_models/south america/sa_moho_data.dat';
moho_model_data1 = readtable(filepath1);
filepath2 = '/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/moho_models/south america/sa_moho_model_2013_2018.dat';
moho_model_data2 = readtable(filepath2);
moho_model_data1 = moho_model_data1(:,{'Station','Lon','Lat','H_km'});
moho_model_data2 = moho_model_data2(:,{'Var1','Var2','Var3','Var5'});
moho_model_data2.Properties.VariableNames = {'Station','Lon','Lat','H_km'};
moho_model = [moho_model_data1;moho_model_data2];

filtidx = find(isnan(moho_model.Lat) == 0);
moho_model = moho_model(filtidx,:);
filtidx=find(isnan(moho_model.Lon) == 0);
moho_model = moho_model(filtidx,:);
filtidx=find(isnan(moho_model.H_km) == 0);
moho_model = moho_model(filtidx,:);
moho_model.isinside = zeros(size(moho_model,1),1);

[~,moho_unqidx] = unique(moho_model.Station,'stable');
moho_allrows = true(height(moho_model),1);
moho_allrows(moho_unqidx) = false;
moho_model(moho_allrows,:) = [];

%%
for i=1:size(moho_model,1)
    lati = moho_model(i,:).Lat;
    loni = moho_model(i,:).Lon;
    if isinterior(coastline, loni, lati) == 1
        moho_model(i,:).isinside = 1;
    end
end
moho_model_filt = moho_model(moho_model.isinside==1,:);

latitudes = moho_model_filt.Lat;
longitudes = moho_model_filt.Lon;
velocities = moho_model_filt.H_km;

lat_range = -62:0.15:22;   %linspace(-62, 22, 500); 
lon_range = -108:0.15:-24; %linspace(-30, -90, 500);

[lat_grid, lon_grid] = meshgrid(lat_range, lon_range);

%velocity_grid = griddata(longitudes, latitudes, velocities, lon_grid, lat_grid, 'cubic');
F = scatteredInterpolant(latitudes,longitudes,velocities, 'natural');                  
velocity_grid = F(lat_grid,lon_grid);

%%5 times faster (~40 secs) by using in polygon
samask = inpolygon(lon_grid,lat_grid,sa_coast_lon,sa_coast_lat);
samask = logical(samask - 1);
velocity_grid(samask) = nan;

%% Slow with this Traditional Method (~5 mins) thus commenting
% tic
% afrmask = zeros(561, 561);
% mapsize = size(afrmask);
% for xi = 1:mapsize(2)
%     loni = lon_grid(xi,1);
%     for yi = 1:mapsize(1)
%         lati = lat_grid(1,yi);
% 
%         if isinterior(coastline, loni, lati) == 1
%             afrmask(xi, yi) = 1;
%         end
%     end
% end
% 
% afrmask = logical(afrmask - 1);
% velocity_grid(afrmask) = nan;
% disp('looping:')
% disp(toc);


%%
figure;clf;
%colormap(m_colmap('jet',10));
mycolsmap = [0.184 0.133 0.686; 0.118 0.2 0.875; 0.145 0.29 0.957; 0.22 0.616 0.965; 0.286 0.843 0.98; 0.314 0.933 0.992; 0.314 0.965 0.851; 0.58 0.992 0.741; 0.906 0.984 0.616; 0.984 0.875 0.443; 0.973 0.678 0.271; 0.965 0.373 0.361; 0.969 0.553 0.549; 0.961 0.71 0.702; 0.992 0.898 0.898; 1 1 1];
colormap(mycolsmap);
m_proj('miller','lon',[-90 -30],'lat',[-62 22]); 
m_grid('linestyle','none','tickdir','out','linewidth',3);

m_pcolor(lon_grid,lat_grid,velocity_grid); 
hold on
m_line(sa_coast_lon,sa_coast_lat,'color',[0 0 0],'linewi',2);
hold on
colorbar;
caxis([20,60]);

%% Trying on Crust 1.0 Moho Model
% https://igppweb.ucsd.edu/~gabi/crust1.html

filepath3 = '/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/GoGlobal/scripts/station_metadata/moho_models/global_moho_depth.csv';
moho_model_data3 = readtable(filepath3);
moho_model_data3.Properties.VariableNames = {'Lon','Lat','H_km'};

isinside_vect = isinterior(coastline, moho_model_data3.Lon, moho_model_data3.Lat);
moho_model_data3.isinside = isinside_vect;

moho_model_new_filt = moho_model_data3(moho_model_data3.isinside==1,:);
moho_model_new_filt.H_km = moho_model_new_filt.H_km*(-1);

latitudes = moho_model_new_filt.Lat;
longitudes = moho_model_new_filt.Lon;
velocities = moho_model_new_filt.H_km;

lat_range = -62:0.15:22;   %linspace(-62, 22, 500); 
lon_range = -108:0.15:-24; %linspace(-30, -90, 500);

[lat_grid, lon_grid] = meshgrid(lat_range, lon_range);

%velocity_grid = griddata(longitudes, latitudes, velocities, lon_grid, lat_grid, 'cubic');
F = scatteredInterpolant(latitudes,longitudes,velocities,'natural');                  
velocity_grid = F(lat_grid,lon_grid);

samask = inpolygon(lon_grid,lat_grid,sa_coast_lon,sa_coast_lat);
samask = logical(samask - 1);
velocity_grid(samask) = nan;

%%
%figure;clf;
%geoscatter(latitudes,longitudes);

figure;clf;
m_proj('miller','lon',[-90 -30],'lat',[-62 22]); 

mycolsmap = [0.184 0.133 0.686; 0.118 0.2 0.875; 0.145 0.29 0.957; 0.22 0.616 0.965; 0.286 0.843 0.98; 0.314 0.933 0.992; 0.314 0.965 0.851; 0.58 0.992 0.741; 0.749 1 0.847; 0.906 0.984 0.616; 0.984 0.875 0.443; 0.973 0.678 0.271; 0.8 0.467 0; 0.965 0.373 0.361; 0.969 0.553 0.549; 0.961 0.71 0.702; 0.992 0.898 0.898; 0.988 0.929 0.929; 0.894 0.902 0.902; 1 1 1];
colormap(mycolsmap);
m_pcolor(lon_grid,lat_grid,velocity_grid); 
m_line(sa_coast_lon,sa_coast_lat,'color',[0 0 0],'linewi',2);
cb = colorbar;
caxis([20,70]);






