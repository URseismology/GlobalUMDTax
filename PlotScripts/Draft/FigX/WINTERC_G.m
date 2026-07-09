clc
clear
close all

%% CAM22
% Cam_22_Temp_file = "./Data/Velocity_Models/CAM2022-vs-tmp.r0.0.nc";
% Cam_depths = ncread(Cam_22_Temp_file, 'depth');
% 
% longrid = ncread(Cam_22_Temp_file , 'longitude');
% latgrid = ncread(Cam_22_Temp_file , 'latitude');
% deltagrid = 0.1
% longrid_interp = [min(longrid):deltagrid:max(longrid)];
% latgrid_interp = [min(latgrid):deltagrid:max(latgrid)];

%% depth_winterc_g
%depth_winterc_g = [41,51,71,91,101,125,151,175,201,211,231,251,275,301]; %to match CAM2022 slices
%depth_winterc_g = [39:1:301];

%% WINTERC-G
Temperature_winter_data = load('./Data/WINTERC_G/WINTERC-G_Temperature.txt');
Temperature_winter_depth = Temperature_winter_data(:,4);
Temperature_winter_depth = -Temperature_winter_depth;
indices = find(Temperature_winter_depth >= 39 &  Temperature_winter_depth <= 310);

Temperature_winter_data = Temperature_winter_data(indices,:);
%Column number longitude latitude depth (km, <0 downwards) T (ºC)   dT (%) dT(K) 
Temperature_winter_data_long = Temperature_winter_data(:,2);
Temperature_winter_data_long(Temperature_winter_data_long > 180) = Temperature_winter_data_long(Temperature_winter_data_long > 180) - 360;
Temperature_winter_data(:,2) = floor(Temperature_winter_data_long);
Temperature_winter_data(:,3) = floor(Temperature_winter_data(:,3));
Temperature_winter_data(:,4) = -Temperature_winter_data(:,4);


Tlon = Temperature_winter_data(:,2);
Tlat = Temperature_winter_data(:,3);
Tdepths = Temperature_winter_data(:,4);
Temperature = Temperature_winter_data(:,5);


LAB_winter_data = load('./Data/WINTERC_G/WINTERC-G_LAB.txt');
%number longitude latitude depth(km)
LAB_winter_data_long = LAB_winter_data(:,2);
LAB_winter_data_long(LAB_winter_data_long > 180) = LAB_winter_data_long(LAB_winter_data_long > 180) - 360;
LAB_winter_data(:,2) = floor(LAB_winter_data_long);

LAB_winter_data(:,3) = floor(LAB_winter_data(:,3));
LAB_winter_data_lat = LAB_winter_data(:,3);
LAB_winter_data_depths = LAB_winter_data(:,4);

Vp_Vs_winter_data = load('./Data/WINTERC_G/WINTERC-G_Vp-Vs.txt');
Vp_Vs_winter_depth = Vp_Vs_winter_data(:,4);
Vp_Vs_winter_depth = -Vp_Vs_winter_depth
indices_Vp_Vs = find(Vp_Vs_winter_depth >= 39 &  Vp_Vs_winter_depth <= 310);

Vp_Vs_winter_data = Vp_Vs_winter_data(indices_Vp_Vs,:);
%Column number longitude latitude depth(km, <0 downwards) Vp (km/s) Vs(km/s)
Vs_winter_data_long = Vp_Vs_winter_data(:,2);
Vs_winter_data_long(Vs_winter_data_long > 180) = Vs_winter_data_long(Vs_winter_data_long > 180) - 360;
Vp_Vs_winter_data(:,2) = floor(Vs_winter_data_long);
Vp_Vs_winter_data(:,3) = floor(Vp_Vs_winter_data(:,3));
Vp_Vs_winter_data(:,4) = -Vp_Vs_winter_data(:,4);

Vslon = Vp_Vs_winter_data(:,2);
Vslat = Vp_Vs_winter_data(:,3);
Vsdepths = Vp_Vs_winter_data(:,4);
Vs = Vp_Vs_winter_data(:,6);

ETOPO2_data = load('./Data/WINTERC_G/ETOPO2_km_continental.txt');
%longitude latitude topo(km)
ETOPO2_long = ETOPO2_data(:,1);
ETOPO2_long(ETOPO2_long > 180) = ETOPO2_long(ETOPO2_long > 180) - 360;
ETOPO2_data(:,1) = floor(ETOPO2_data(:,1));

ETOPO2_data(:,2) = floor(ETOPO2_data(:,2));
ETOPO2_lat = ETOPO2_data(:,2);
ETOPO2_topo = -ETOPO2_data(:,3);

Density_winter_data = load('./Data/WINTERC_G/WINTERC-G_Density.txt');
%Columnnumber longitude latitude depth(km, <0 downwards) rho(kg/m3) drho(%) drho(kg/m3)
Density_winter_depth = Density_winter_data(:,4);
Density_winter_depth = -Density_winter_depth;
indices_Density = find(Density_winter_depth >= 39 & Density_winter_depth <= 310);

Density_winter_data = Density_winter_data(indices_Density,:);
Density_winter_data_long = Density_winter_data(:,2);
Density_winter_data_long(Density_winter_data_long > 180) = Density_winter_data_long(Density_winter_data_long > 180) - 360;
Density_winter_data(:,2) = floor(Density_winter_data_long);
Density_winter_data(:,3) = floor(Density_winter_data(:,3));
Density_winter_data(:,4) = -Density_winter_data(:,4);

Denslon = Density_winter_data(:,2);
Denslat = Density_winter_data(:,3);
Densdepths = Density_winter_data(:,4);
Density = Density_winter_data(:,5);

  
%% New grid
F_Vs = scatteredInterpolant(Vslon,Vslat,Vsdepths,Vs,'linear', 'none');

F_T = scatteredInterpolant(Tlon,Tlat,Tdepths,Temperature,'linear', 'none');
 
F_LAB = scatteredInterpolant(LAB_winter_data_long,LAB_winter_data_lat, LAB_winter_data_depths, 'linear', 'none');

F_ETOPO2 = scatteredInterpolant(ETOPO2_long,ETOPO2_lat, ETOPO2_topo, 'linear', 'none');

F_Density = scatteredInterpolant(Denslon,Denslat,Densdepths,Density, 'linear', 'none');

%% Model World
save('./Data/Models_CAM22_WINTERC/T_3D_grid_WINT.mat','F_Vs','F_T','F_LAB','F_Density','F_ETOPO2','-v7.3');
