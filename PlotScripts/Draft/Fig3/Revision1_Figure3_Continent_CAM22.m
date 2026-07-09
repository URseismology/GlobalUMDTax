
clear 
close all
clc

addpath /Users/jjoel/Desktop/Softwares/M_map/m_map;
addpath slanCM/
addpath landmask/

%%
S1 = shaperead('./Data/ContinentCoastlines/ne_110m_coastline/ne_110m_coastline.shp');
S1X = S1.X; S1X = S1X';
S1Y = S1.Y; S1Y = S1Y';

%%
%Original Tables
%Synthesis RF images
Data_Global_RF_Meta = readtable('./Data/MachineLearningData/rf_global_clustering/data/Data_Global_R1Meta.csv');
Data_Global_RF_ML = readtable('./Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv');

%match extra check
%[Lia,Locb] = ismember(string(Data_Global_RF_Meta.StationName), string(Data_Global_RF_ML.StationName))
Data_Global_RF = Data_Global_RF_Meta;
Data_Global_RF.GMM_k4 = Data_Global_RF_ML.GMM_k4;
Data_Global_RF.Category = Data_Global_RF_ML.Category;
Data_Global_RF.Checkname  = Data_Global_RF_ML.StationName;
Data_Global_RF.TectonicType  = Data_Global_RF_ML.TectonicType;


%% By Cluster

%--Cluster1-3 or Cluster0-2
iC0 = find(Data_Global_RF.GMM_k4 == 0)
Data_Global_RF_C0 = Data_Global_RF(iC0,:);

iC1 = find(Data_Global_RF.GMM_k4 == 1)
Data_Global_RF_C1 = Data_Global_RF(iC1,:);

iC2 = find(Data_Global_RF.GMM_k4 == 2)
Data_Global_RF_C2 = Data_Global_RF(iC2,:);

%--Cluster3 or Cluster4
iC3 = find(Data_Global_RF.GMM_k4 == 3)
Data_Global_RF_C3 = Data_Global_RF(iC3,:);


%% Tectonic Regionalization Model
AniModelfile = "./Data/Anisotropy_Model/3DLGL-TPESv-depth.v2022-11.r0.0.nc";
%ncdisp(AniModelfile);
longrid = ncread(AniModelfile,'longitude');latgrid = ncread(AniModelfile, 'latitude');
longridinterp = min(longrid):0.5:max(longrid);latgridinterp = min(latgrid):0.5:max(latgrid);

TecRegnfile = "./Data/TectonicRegionalization/SL2013sv_TectRegn_2d/SL2013sv_Cluster_2d";
TecRegn =  load(TecRegnfile); 
%1-Lon 2-Lat 3-Type
%Type key:1-Cratons,2-Precambrian F&T Belts and Modified Cratons,3-Phanerozoic Continents
%4-Ridges & Backarcs,5-Oceanic,6-Oldest Oceanic

F_TecReg = scatteredInterpolant(TecRegn(:,1),TecRegn(:,2),TecRegn(:,3),'linear', 'none');

[yq,xq] = meshgrid(latgridinterp,longridinterp);
xq = double(xq); yq = double(yq);
TecRegMap = F_TecReg(xq,yq); 
%maskocean = ~landmask(yq,xq);
%TecRegMap(maskocean) = NaN;

%%
fs = 26
psz =100

%% Plot

minTec = 1; maxTec = 7;
%cmapTec = slanCM('gray',7); %pink
cmapTec(1,:) = [0 0 0];
cmapTec(2,:) = [0.5020    0.5020    0.5020];
cmapTec(3,:) = [ 0.6588    0.5490    0.5490];
cmapTec(4,:) = [0.8196    0.7804    0.7216];
cmapTec(5,:) = [0.8000    0.8000    0.8000];
cmapTec(6,:) = [1    1    1];

Tecticks = [minTec:1:maxTec];
Tecscale = length(Tecticks)-1;
szcmapTec = size(cmapTec,1);


%%
figure(1)
set(gcf,'Position',[200,500,2000,1200])
clf

%NorthAmerica and SouthAmerica---------------------------------------------------------------------------
pos1 = [0.04 0.1 0.3 0.8];
ax1 = subplot('Position',pos1)
m_proj('miller','lat',[-60 55],'lon',[-135 -20]) 
hold on
m_pcolor(xq,yq,TecRegMap);

for ic = 1:length(S1)      
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',4);  
end

% Plot discontinuities ----- Get the current color limits
for nCO = 1:size(Data_Global_RF_C0,1)
        % Map the data value to an index
        % Ensure the index is within the valid range [1, N]
        if string(Data_Global_RF_C0.Category(nCO)) == "LVD"
            marker = 'o';
        elseif string(Data_Global_RF_C0.Category(nCO)) == "LVL"
            marker = 's';
        elseif string(Data_Global_RF_C0.Category(nCO)) == "HVL"
            marker = 'v';
        end

        m_scatter(Data_Global_RF_C0.Longitude(nCO), Data_Global_RF_C0.Latitude(nCO),psz,...
                  'Marker',marker,'MarkerFaceColor',[0.4353    0.6392    0.4745], 'MarkerEdgeColor','k','LineWidth',1.5);
end




for nC2 = 1:size(Data_Global_RF_C2,1)
        % Map the data value to an index
        % Ensure the index is within the valid range [1, N]
        if string(Data_Global_RF_C2.Category(nC2)) == "LVD"
            marker = 'o';
        elseif string(Data_Global_RF_C1.Category(nC2)) == "LVL"
            marker = 's';
        elseif string(Data_Global_RF_C1.Category(nC2)) == "HVL"
            marker = 'v';
        end

        m_scatter(Data_Global_RF_C2.Longitude(nC2), Data_Global_RF_C2.Latitude(nC2),psz,...
                  'Marker',marker,'MarkerFaceColor',[0.3882    0.3569    0.5294], 'MarkerEdgeColor','k','LineWidth',1.5);
end

for nC3 = 1:size(Data_Global_RF_C3,1)
        % Map the data value to an index
        % Ensure the index is within the valid range [1, N]
        if string(Data_Global_RF_C3.Category(nC3)) == "LVD"
            marker = 'o';
        elseif string(Data_Global_RF_C3.Category(nC3)) == "LVL"
            marker = 's';
        elseif string(Data_Global_RF_C3.Category(nC3)) == "HVL"
            marker = 'v';
        end

        m_scatter(Data_Global_RF_C3.Longitude(nC3), Data_Global_RF_C3.Latitude(nC3),psz,...
                  'Marker',marker,'MarkerFaceColor',[ 0.6706    0.3961    0.6157], 'MarkerEdgeColor','k','LineWidth',1.5);
end

colormap(gca,cmapTec)
caxis([minTec maxTec]);

m_grid('linestyle','-','ytick',[],'xtick',[],'tickdir','out','linewi',2,'gridcolor','k','backcolor','w','fontsize',fs)




%Africa and Europe--------------------------------------------------------------------------
pos1 = [0.34 0.215 0.3 0.57];
ax1 = subplot('Position',pos1)
m_proj('miller','lat',[-38 75],'lon',[-20 60]) 
hold on
m_pcolor(xq,yq,TecRegMap);
for ic = 1:length(S1)      
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',4);  
end

% Plot discontinuities ----- Get the current color limits
for nCO = 1:size(Data_Global_RF_C0,1)
        % Map the data value to an index
        % Ensure the index is within the valid range [1, N]
        if string(Data_Global_RF_C0.Category(nCO)) == "LVD"
            marker = 'o';
        elseif string(Data_Global_RF_C0.Category(nCO)) == "LVL"
            marker = 's';
        elseif string(Data_Global_RF_C0.Category(nCO)) == "HVL"
            marker = 'v';
        end

        m_scatter(Data_Global_RF_C0.Longitude(nCO), Data_Global_RF_C0.Latitude(nCO),psz,...
                  'Marker',marker,'MarkerFaceColor',[0.4353    0.6392    0.4745], 'MarkerEdgeColor','k','LineWidth',1.5);
end




for nC2 = 1:size(Data_Global_RF_C2,1)
        % Map the data value to an index
        % Ensure the index is within the valid range [1, N]
        if string(Data_Global_RF_C2.Category(nC2)) == "LVD"
            marker = 'o';
        elseif string(Data_Global_RF_C1.Category(nC2)) == "LVL"
            marker = 's';
        elseif string(Data_Global_RF_C1.Category(nC2)) == "HVL"
            marker = 'v';
        end

        m_scatter(Data_Global_RF_C2.Longitude(nC2), Data_Global_RF_C2.Latitude(nC2),psz,...
                  'Marker',marker,'MarkerFaceColor',[0.3882    0.3569    0.5294], 'MarkerEdgeColor','k','LineWidth',1.5);
end

for nC3 = 1:size(Data_Global_RF_C3,1)
        % Map the data value to an index
        % Ensure the index is within the valid range [1, N]
        if string(Data_Global_RF_C3.Category(nC3)) == "LVD"
            marker = 'o';
        elseif string(Data_Global_RF_C3.Category(nC3)) == "LVL"
            marker = 's';
        elseif string(Data_Global_RF_C3.Category(nC3)) == "HVL"
            marker = 'v';
        end

        m_scatter(Data_Global_RF_C3.Longitude(nC3), Data_Global_RF_C3.Latitude(nC3),psz,...
                  'Marker',marker,'MarkerFaceColor',[ 0.6706    0.3961    0.6157], 'MarkerEdgeColor','k','LineWidth',1.5);
end





colormap(gca,cmapTec)
caxis([minTec maxTec]);
h= colorbar('southoutside', 'fontsize', fs+5);
h.Limits = [1 maxTec] 
barname = "Tectonic Regionalization";
ylabel(h,barname,'fontweight','bold','fontsize', fs+5);
x=get(h,'Position');
x(1) = x(1) - 0.05
x(2)= x(2) - 0.07;
x(3)= x(3) + 0.1;
x(4)= x(4) + 0.01;
set(h,'Position',x)
m_grid('linestyle','-','ytick',[],'xtick',[],'tickdir','out','linewi',2,'gridcolor','k','backcolor','w','fontsize',fs)

h.Ticks = [1.5 2.5 3.5 4.5 5.5 6.5];
TecRegticklabels = h.TickLabels;
TecRegticklabels{1} = 'C';
TecRegticklabels{2} = 'PB&MC';
TecRegticklabels{3} = 'P';
TecRegticklabels{4} = 'R&B';
TecRegticklabels{5} = 'O';
TecRegticklabels{6} = 'Old O';

h.TickLabels = TecRegticklabels;



%Asia and Oceania--------------------------------------------------------------------------
pos1 = [0.64 0.215 0.3 0.57];
ax1 = subplot('Position',pos1)
m_proj('miller','lat',[-50 80],'lon',[60 179]) 
hold on
m_pcolor(xq,yq,TecRegMap);
for ic = 1:length(S1)      
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',4);  
end

% Plot discontinuities ----- Get the current color limits
for nCO = 1:size(Data_Global_RF_C0,1)
        % Map the data value to an index
        % Ensure the index is within the valid range [1, N]
        if string(Data_Global_RF_C0.Category(nCO)) == "LVD"
            marker = 'o';
        elseif string(Data_Global_RF_C0.Category(nCO)) == "LVL"
            marker = 's';
        elseif string(Data_Global_RF_C0.Category(nCO)) == "HVL"
            marker = 'v';
        end

        m_scatter(Data_Global_RF_C0.Longitude(nCO), Data_Global_RF_C0.Latitude(nCO),psz,...
                  'Marker',marker,'MarkerFaceColor',[0.4353    0.6392    0.4745], 'MarkerEdgeColor','k','LineWidth',1.5);
end




for nC2 = 1:size(Data_Global_RF_C2,1)
        % Map the data value to an index
        % Ensure the index is within the valid range [1, N]
        if string(Data_Global_RF_C2.Category(nC2)) == "LVD"
            marker = 'o';
        elseif string(Data_Global_RF_C1.Category(nC2)) == "LVL"
            marker = 's';
        elseif string(Data_Global_RF_C1.Category(nC2)) == "HVL"
            marker = 'v';
        end

        m_scatter(Data_Global_RF_C2.Longitude(nC2), Data_Global_RF_C2.Latitude(nC2),psz,...
                  'Marker',marker,'MarkerFaceColor',[0.3882    0.3569    0.5294], 'MarkerEdgeColor','k','LineWidth',1.5);
end

for nC3 = 1:size(Data_Global_RF_C3,1)
        % Map the data value to an index
        % Ensure the index is within the valid range [1, N]
        if string(Data_Global_RF_C3.Category(nC3)) == "LVD"
            marker = 'o';
        elseif string(Data_Global_RF_C3.Category(nC3)) == "LVL"
            marker = 's';
        elseif string(Data_Global_RF_C3.Category(nC3)) == "HVL"
            marker = 'v';
        end

        m_scatter(Data_Global_RF_C3.Longitude(nC3), Data_Global_RF_C3.Latitude(nC3),psz,...
                  'Marker',marker,'MarkerFaceColor',[ 0.6706    0.3961    0.6157], 'MarkerEdgeColor','k','LineWidth',1.5);
end

colormap(gca,cmapTec)
caxis([minTec maxTec]);
m_grid('linestyle','-','ytick',[],'xtick',[],'tickdir','out','linewi',2,'gridcolor','k','backcolor','w','fontsize',fs)


%Map in  Lower Left Inset
pos = [.002 .18 .19 .19]
axes('position',pos)
m_proj('robinson', 'clongitude', 0) 
hold on
m_pcolor(xq(:,:,1),yq(:,:,1),TecRegMap);
for ic = 1:length(S1)      
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',2);  
end
for nC1 = 1:size(Data_Global_RF_C1,1)
        % Map the data value to an index
        % Ensure the index is within the valid range [1, N]
        if string(Data_Global_RF_C1.Category(nC1)) == "LVD"
            marker = 'o';
        elseif string(Data_Global_RF_C1.Category(nC1)) == "LVL"
            marker = 's';
        elseif string(Data_Global_RF_C1.Category(nC1)) == "HVL"
            marker = 'v';
        end

        m_scatter(Data_Global_RF_C1.Longitude(nC1), Data_Global_RF_C1.Latitude(nC1),psz-80,...
                  'Marker',marker,'MarkerFaceColor',[0.8392    0.5412    0.0941], 'MarkerEdgeColor','k','LineWidth',1.5);
end
colormap(gca,cmapTec)
caxis([minTec maxTec]);
m_grid('linestyle','-','ytick',[],'xtick',[],'tickdir','out','linewi',2,'gridcolor','k','backcolor','w','fontsize',fs)



%Inset Bar chart
pos = [.06 .4 .09 .17]
axes('position',pos)
x = ["C1" "C2" "C3" "C4"];
y = [size(Data_Global_RF_C2,1), size(Data_Global_RF_C3,1),... 
     size(Data_Global_RF_C0,1), size(Data_Global_RF_C1,1)];
y = (y/size(Data_Global_RF,1))*100;
b = bar(x,y)
b.FaceColor = 'flat';
b.CData = [[0.3882    0.3569    0.5294];[0.6706    0.3961    0.6157];[0.4353    0.6392    0.4745];[0.8392    0.5412    0.0941]]
b.LineWidth=2
ylabel('Percentage(%)','fontsize',fs-5)
set(gca,'fontsize',fs,'LineWidth',2)
axis on


%% Figure 3 - bottom
colors = cmapTec(1:end,:);   % should be 6x3 colormap

figure(2)
set(gcf,'Position',[200,500,2500,500])
clf
subplot(1,4,1)
h = histogram(Data_Global_RF_C2.TectonicType, ...
    'NumBins', 6, ...
    'Visible', 'off');

edges  = h.BinEdges; centers = edges(1:end-1) + diff(edges)/2;
counts = h.Values; countpercentC2 = round((counts*100)/ size(Data_Global_RF_C2,1),0);

hold on

for k = 1:length(counts)
    histogram(Data_Global_RF_C2.TectonicType, ...
        'BinEdges', edges(k:k+1), ...
        'FaceColor', colors(k,:), ...
        'EdgeColor', 'k','FaceAlpha',1,'LineWidth',2);

    if countpercentC2(k) ~=0
        textpercent = [num2str(countpercentC2(k)), '%']
        text(centers(k), counts(k)+10 ,textpercent,'fontsize',fs,'HorizontalAlignment','center', 'VerticalAlignment','top')
    end
end
hold off
set(gca,'linewidth',5,'fontsize',fs,'XTick',[],'YMinorTick','on','XColor', [0.3882    0.3569    0.5294],'YColor', [0.3882    0.3569    0.5294])
ax = gca;
ax.XAxis.TickLabelColor = [0 0 0]; 
ax.YAxis.TickLabelColor = [0 0 0];
ax.XAxis.Label.Color = [0 0 0];
ax.YAxis.Label.Color = [0 0 0];
box on 
ylabel('count','fontsize',fs+10)
title('C1 -> Melt','fontsize',fs)
ylim([0,150])


subplot(1,4,2)
h = histogram(Data_Global_RF_C3.TectonicType, ...
    'NumBins', 6, ...
    'Visible', 'off');

edges  = h.BinEdges; centers = edges(1:end-1) + diff(edges)/2;
counts = h.Values;countpercentC3 = round((counts*100)/ size(Data_Global_RF_C3,1),0);

hold on
for k = 1:length(counts)
    histogram(Data_Global_RF_C3.TectonicType, ...
        'BinEdges', edges(k:k+1), ...
        'FaceColor', colors(k,:), ...
        'EdgeColor', 'k','FaceAlpha',1,'LineWidth',2);
    if countpercentC3(k) ~=0
        textpercent = [num2str(countpercentC3(k)), '%']
        text(centers(k), counts(k)+10 ,textpercent,'fontsize',fs,'HorizontalAlignment','center', 'VerticalAlignment','top')
    end
end
hold off
set(gca,'linewidth',5,'fontsize',fs,'XTick',[],'YMinorTick','on','XColor', [0.6706    0.3961    0.6157],'YColor', [0.6706    0.3961    0.6157])
ax = gca;
ax.XAxis.TickLabelColor = [0 0 0]; 
ax.YAxis.TickLabelColor = [0 0 0];
ax.XAxis.Label.Color = [0 0 0];
ax.YAxis.Label.Color = [0 0 0];
box on
title('C2 -> Rheological','fontsize',fs)
ylim([0,150])



subplot(1,4,3)
h = histogram(Data_Global_RF_C0.TectonicType, ...
    'NumBins', 6, ...
    'Visible', 'off');

edges  = h.BinEdges; centers = edges(1:end-1) + diff(edges)/2;
counts = h.Values;countpercentC0 = round((counts*100)/ size(Data_Global_RF_C0,1),0);
hold on
for k = 1:length(counts)
    histogram(Data_Global_RF_C0.TectonicType, ...
        'BinEdges', edges(k:k+1), ...
        'FaceColor', colors(k,:), ...
        'EdgeColor', 'k','FaceAlpha',1,'LineWidth',2);
    if countpercentC0(k) ~=0
        textpercent = [num2str(countpercentC0(k)), '%']
        text(centers(k), counts(k)+10 ,textpercent,'fontsize',fs,'HorizontalAlignment','center', 'VerticalAlignment','top')
    end
end
hold off
set(gca,'linewidth',5,'fontsize',fs,'XTick',[],'YMinorTick','on','XColor', [0.4353    0.6392    0.4745],'YColor', [0.4353    0.6392    0.4745])
ax = gca;
ax.XAxis.TickLabelColor = [0 0 0]; 
ax.YAxis.TickLabelColor = [0 0 0];
ax.XAxis.Label.Color = [0 0 0];
ax.YAxis.Label.Color = [0 0 0];
box on
title('C3 -> Metasomatism','fontsize',fs)
ylim([0,150])

subplot(1,4,4)
h = histogram(Data_Global_RF_C1.TectonicType, ...
    'NumBins', 6, ...
    'Visible', 'off');

edges  = h.BinEdges; centers = edges(1:end-1) + diff(edges)/2;
counts = h.Values;countpercentC1 = round((counts*100)/ size(Data_Global_RF_C1,1),0);
hold on
for k = 1:length(counts)
    histogram(Data_Global_RF_C1.TectonicType, ...
        'BinEdges', edges(k:k+1), ...
        'FaceColor', colors(k,:), ...
        'EdgeColor', 'k','FaceAlpha',1,'LineWidth',2);

    if countpercentC1(k) ~=0
        textpercent = [num2str(countpercentC1(k)), '%']
        text(centers(k), counts(k)+10 ,textpercent,'fontsize',fs,'HorizontalAlignment','center', 'VerticalAlignment','top')
    end
end
hold off



set(gca,'linewidth',5,'fontsize',fs,'XTick',[],'YMinorTick','on','XColor', [0.8392    0.5412    0.0941],'YColor', [0.8392    0.5412    0.0941])
ax = gca;
ax.XAxis.TickLabelColor = [0 0 0]; 
ax.YAxis.TickLabelColor = [0 0 0];
ax.XAxis.Label.Color = [0 0 0];
ax.YAxis.Label.Color = [0 0 0];
box on
title('C4 -> Structural','fontsize',fs)
ylim([0,150])
%% Save
saveas(figure(1),'./Figures/Global_Study/Revision1_Final_Figure_3_a_CAM22.pdf')
saveas(figure(2),'./Figures/Global_Study/Revision1_Final_Figure_3_b_CAM22.pdf')

