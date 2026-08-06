% Make maps showing correspondence between slab positions and vote maps of
% tomography. Ved, June 28, 2019

clear; close all; addpath('../../CODES/m_map1.4/'); addpath('../../CODES/crameri_v1.05/crameri/'); 

% Load subduction zone positions and ages from Young et al. 2018
load('Reconstructed_Subduction_Zones_Youngeta2018.mat'); 

% % FOR VAN DER MEER
% % Columns are: Slab Name	Abbreviation	Slab Midpoint Location Depth	
% % Slab Midpoint Location Lon	Slab Midpoint Location Lat	Geological record Lon	
% % Geological record Lat	SlabBase (km) Depth	SlabBase (km) Error	SlabTop (km) Depth	
% % SlabTop (km) Error	SlabAge (Ma) Base Max	SlabAge (Ma) Base Min	
% % SlabAge Top (Ma) Min	SlabAge Top (Ma) Max	AvgSinkingRate (mm/yr) Base Rate	
% % AvgSinkingRate (mm/yr) Base Error	AvgSinkingRate (mm/yr) Top Rate	
% % AvgSinkingRate (mm/yr) Top Error
% 
% slabs = csvread('Dataset_from_vanderMeer2018.csv',1,2); % start read with 2nd row and 3rd column

% Load Vp and Vs vote maps from Cottaar & Lekic, 2016

% Vote results from clustering analysis Cottaar & Lekic 2016
Vp_struct = importdata('cluster_votes_Vp_CottaarLekic2016.txt'); 
 
% Vote results from clustering analysis Cottaar & Lekic 2016
Vs_struct = importdata('cluster_votes_Vs_CottaarLekic2016.txt'); 

% Select depth range for plotting
%dep_rng = [1000 1600]; % And 1300 to 1800 for mesozoic
                       % And 2000 to 2500 for paleozoic
                       % 2200 to 2700 km for 200-300 My works well
                       % 50-140 Ma for 1000-1600 km
                       % 110-200 Ma for 1600-2200 km
                       % 200-260 for 2200-2800 km
dep_rng = [800 1000];  
                       
% Select era for which to plot slabs
era = 'age'; % Specify era or write "age" and then the age min and max are used
min_age = 50; max_age = 140; age_inc = 30; % Age inc has to be 30 or 60 and max_age-min_age should be a multiple of age_inc

% Now, reshape the Vp_struct and Vs_struct into a 3D matrix assuming same
% lat,lon,dep sampling for Vp and Vs 
unq_lon = unique(Vp_struct.data(:,1));   % Unique longitudes
unq_lat = unique(Vp_struct.data(:,2));   % Unique latitudes
unq_dep = flipud(unique(Vp_struct.data(:,3)));   % Unique Depths. Have to flipud because unique commands sorts order
Vp_fast = reshape(Vp_struct.data(:,6),length(unq_lat),length(unq_lon),length(unq_dep));           % Pull out the fast votes and reshape
Vs_fast = reshape(Vs_struct.data(:,6),length(unq_lat),length(unq_lon),length(unq_dep));           % Pull out the fast votes and reshape

% Now, find and stack depths specified in dep_rng
indx_dep = find(unq_dep>=min(dep_rng) & unq_dep<=max(dep_rng)); 

Vp_map = mean(Vp_fast(:,:,indx_dep),3); Vp_map(Vp_map<3) = 0; Vp_map(Vp_map>=3) = 1; 
Vs_map = mean(Vs_fast(:,:,indx_dep),3); Vs_map(Vs_map<3) = 0; Vs_map(Vs_map>=3) = 1; 

%% Now plot everything up
%Cenozoic
%min_age = 0; max_age = 65; 
%Mesozoic
%min_age = 65; max_age = 251; 
%Paleozoic
%min_age = 251; max_age = 410; 

age_inc = 10; % Age increment to use (must be multiple of 10 My)
load coast.mat; 

figure(10); 
axesm('robinson'); hold on; 
pcolorm(unq_lat,unq_lon,Vp_map); shading flat;  
cmap1 = flipud(colormap('gray'));
set(gca,'Colormap',cmap1); 
plotm(lat,long,'m'); gridm;   
cmap = jet(42); 
for j = 1:length(sz)
    if(sz(j).age>=min_age && sz(j).age<=max_age && mod(sz(j).age,age_inc)==0)
        plotm(sz(j).lat,sz(j).lon,'-','color',cmap(sz(j).age/10+1,:)); 
    end
end
colorbar; 
% cmap2 = flipud(crameri('batlow'));
 era_name = era; 
switch(lower(era))
    case 'cenozoic'
        min_age = 0; max_age = 60; % Era limits in increments of 10My
    case 'mesozoic'
        min_age = 60; max_age = 250; 
    case 'paleozoic'
        min_age = 260; max_age = 410; 
    case 'age'
        disp('Using specified min and max ages for plot'); 
        era_name = ['age_' num2str(min_age) '-' num2str(max_age) 'Ma']; 
end

figure(20); set(gcf,'position',[10 10 800 600]); 
subplot('position',[0.05 0.2 0.9 0.8]); hold on; 
%hold on; 
m_proj('robinson','clo',0); 
a = m_pcolor(unq_lon-180,unq_lat,fftshift(Vs_map,2)); shading flat; 
m_coast('line','color',[0 0 0.5]); %m_grid('fancy'); 
m_grid('xtick',0,'xticklabel',[],'ytick',0,'yticklabel',[],'linestyle','none','tickdir','in','linewidth',2);

%cmap = crameri('batlow',((max_age-min_age)/age_inc + 1)); 
%cmap = crameri('batlow',(floor(260-50)/30 + 1)); 
cmap = jet((floor(260-50)/30 + 1));

for j = 1:length(sz)
    if(sz(j).age>=min_age && sz(j).age<=max_age && mod(sz(j).age-min_age,age_inc)==0)
        m_plot(sz(j).lon,sz(j).lat,'-','color',cmap(floor((sz(j).age-50)/30)+1,:),'linewidth',2); 
    end
end
%set(a,'FaceAlpha',0.3); 
cmap2 = (crameri('grayC',6)); set(gca,'colormap',cmap2); caxis([0 4]);
%h = colorbar; set(h,'Ticks',[0:1:5],'TickLabels',{'0','1','2','3','4','5'},'TickDirection','out','Fontsize',10); 
%set(get(h,'title'),'string','Number of Votes as Fast','Fontsize',12,'rotation',270,'position',[30 120 0]); 
title(['V_S ' num2str(dep_rng(1)) '-' num2str(dep_rng(2)) ' km'],'fontsize',14); 


subplot('position',[0.05 0.05 0.9 0.15]); set(gca,'colormap',cmap); 
set(gca,'visible','off'); 
h2 = colorbar('location','north'); 
ages =  50:30:260;
for j = 1:length(ages)
    imena{j} = num2str(ages(j)); 
end
caxis([50 260]); 
set(h2,'Ticks',ages,'TickLabels',imena,'position',[0.06 0.16 0.8 0.04],'TickDirection','out','Fontsize',10); 
set(get(h2,'title'),'string','Age (My)','Fontsize',12); 

set(gcf,'Units','Inches');
pos = get(gcf,'position');
set(gcf,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
%print(gcf,'-dpdf','-painters',['newcolor_MajorityVoteSlabs_' era_name '_Vs_' num2str(dep_rng(1)) '-' num2str(dep_rng(2)) 'km.pdf']); 


figure(30); set(gcf,'position',[10 10 800 600]); 
subplot('position',[0.05 0.2 0.9 0.8]); hold on; 
m_proj('robinson','clo',0); 
a = m_pcolor(unq_lon-180,unq_lat,fftshift(Vp_map,2)); shading flat; 
m_coast('line','color',[0 0 0.5]); 
m_grid('xtick',0,'xticklabel',[],'ytick',0,'yticklabel',[],'linestyle','none','tickdir','in','linewidth',2);

for j = 1:length(sz)
    if(sz(j).age>=min_age && sz(j).age<=max_age && mod(sz(j).age-min_age,age_inc)==0)
        m_plot(sz(j).lon,sz(j).lat,'-','color',cmap(floor((sz(j).age-50)/30)+1,:),'linewidth',2); 
    end
end
%set(a,'FaceAlpha',0.3); 
cmap2 = (crameri('grayC',6)); set(gca,'colormap',cmap2); caxis([0 4]);
%h = colorbar; set(h,'Ticks',[0:1:5],'TickLabels',{'0','1','2','3','4','5'},'TickDirection','out','Fontsize',10); 
%set(get(h,'title'),'string','Number of Votes as Fast','Fontsize',12,'rotation',270,'position',[30 120 0]); 
title(['V_P ' num2str(dep_rng(1)) '-' num2str(dep_rng(2)) ' km'],'fontsize',14); 


subplot('position',[0.05 0.05 0.9 0.15]); set(gca,'colormap',cmap); 
set(gca,'visible','off'); 
h2 = colorbar('location','north'); 
ages =  50:30:260;
for j = 1:length(ages)
    imena{j} = num2str(ages(j)); 
end
caxis([50 260]); 
set(h2,'Ticks',ages,'TickLabels',imena,'position',[0.06 0.16 0.8 0.04],'TickDirection','out','Fontsize',10); 
set(get(h2,'title'),'string','Age (My)','Fontsize',12); 

set(gcf,'Units','Inches');
pos = get(gcf,'position');
set(gcf,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
%print(gcf,'-dpdf','-painters',['newcolor_MajorityVoteSlabs_' era_name '_Vp_' num2str(dep_rng(1)) '-' num2str(dep_rng(2)) 'km.pdf']); 


