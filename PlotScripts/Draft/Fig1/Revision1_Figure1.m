clear 
close all
clc

addpath('./Data/m_map', './Data/slanCM', './Data/landmask')

%% Geo features
S1 = shaperead('./Data/ContinentCoastlines/ne_110m_coastline/ne_110m_coastline.shp');
S_craton = shaperead('./Data/global_tectonics/plates&provinces/shp/cratons.shp');
S1X = S1.X; S1X = S1X';
S1Y = S1.Y; S1Y = S1Y';

%% Sequenced RFs
RF_C0 = load('./Data/MachineLearningData/RFs/sequenced_cluster0.mat').rf_matrix_sorted;
t=load('./Data/MachineLearningData/RFs/sequenced_cluster0.mat').time_vector;
RF_C1 = load('./Data/MachineLearningData/RFs/sequenced_cluster1.mat').rf_matrix_sorted;
RF_C2 = load('./Data/MachineLearningData/RFs/sequenced_cluster2.mat').rf_matrix_sorted;
RF_C3 = load('./Data/MachineLearningData/RFs/sequenced_cluster3.mat').rf_matrix_sorted;

%% Data
%Synthesis RF images
Data_Global_RF_Meta = readtable('./Data/MachineLearningData/rf_global_clustering/data/Data_Global_R1Meta.csv');
Data_Global_RF_ML = readtable('./Data/MachineLearningData/rf_global_clustering/results/clustered_data_Neg_CAM22.csv');

%match extra check
%[Lia,Locb] = ismember(string(Data_Global_RF_Meta.StationName), string(Data_Global_RF_ML.StationName))

Data_Global_RF = Data_Global_RF_Meta;
Data_Global_RF.GMM_k4 = Data_Global_RF_ML.GMM_k4
Data_Global_RF.Category = Data_Global_RF_ML.Category
Data_Global_RF.Checkname  = Data_Global_RF_ML.StationName

iVL = find(ismember(string(Data_Global_RF.Category), ["LVL","HVL"]) == 1);
Data_Global_RF_VL = Data_Global_RF(iVL,:);

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
Data_Global_RF_C3 = Data_Global_RF(iC3,:)

%%
%vote map
votmap1 = load("./Data/GlobalVs_Models/votemap_100_km");
xq = votmap1.xq;yq = votmap1.yq;
Nmodels = votmap1.Nmodels;
refpos = votmap1.VpercThreshpos; refneg = votmap1.VpercThreshneg;
totvotpos1 = votmap1.totvotespos;
totvotesneg1 = votmap1.totvotesneg;

%% Operations
%masking oceans on votmap
%maskocean = ~landmask(yq,xq);save('./Data/maskocean.mat','maskocean','-v7.3');
maskocean = load('./Data/maskocean.mat').maskocean;
totvotpos1(maskocean) = -1;
totvotesneg1(maskocean) = -1;


%%
fs = 26
mscDep = 350; 

%colormap vote map
%lower,bound of caxis
hlow = -1;  cscale = length(hlow:1:Nmodels)-1;
cmap = flipud(slanCM('gray',cscale)); cmap2 = slanCM('bilbao',cscale);%tempo,gray
cmap(1,:) = [0.8000    0.8000    0.8000]; cmap2(1,:) = [0.8000    0.8000    0.8000];
cmap(2,:) = [0.8196    0.7804    0.7216]; cmap2(2,:) = [0.8196    0.7804    0.7216];


comcmap = [flipud(cmap2((2:end),:));cmap((2:end),:)];

psz = 150;


%% Top of Figure 1
figure(1)
set(gcf,'Position',[200,500,2500,1500])
clf

%NorthAmerica---------------------------------------------------------------------------
pos1 = [0.02 0.53 0.3 0.45];
ax1 = subplot('Position',pos1)
m_proj('miller','lat',[10 70],'lon',[-135 -52]) 
hold on
m_pcolor(xq,yq,totvotpos1)
for ic = 1:length(S1)      
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',3);  
end
for ic = 1:length(S_craton)
        m_line(S_craton(ic).X, S_craton(ic).Y, 'color', [0.4 0.4 0.4], 'linewidth', 1.5, 'linestyle', '--');
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
caxis([hlow Nmodels])
colormap(ax1,cmap)
m_grid('box','fancy','grid','none','tickdir','out','backcolor','w','fontsize',fs-5)

%inset----------
posi1 = [pos1(1)-0.01 pos1(2)+0.27 0.168 0.168];
axi1 = axes('Position',posi1)
m_proj('miller','lat',[10 70],'lon',[-135 -52]) 
hold on
m_pcolor(xq,yq,totvotesneg1)
for ic = 1:length(S1)      
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',3);  
end
for ic = 1:length(S_craton)
        m_line(S_craton(ic).X, S_craton(ic).Y, 'color', [0.4 0.4 0.4], 'linewidth', 1.5, 'linestyle', '--');
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

        m_scatter(Data_Global_RF_C1.Longitude(nC1), Data_Global_RF_C1.Latitude(nC1),psz-50,...
                  'Marker',marker,'MarkerFaceColor',[0.8392    0.5412    0.0941], 'MarkerEdgeColor','k','LineWidth',1.5);
end




caxis([hlow Nmodels])
colormap(axi1,cmap2)
m_grid('linewi',2,'linest','none','tickdir','out','xticklabels',[],'yticklabels',[])
%----------------------------------------------------------------------------------------------------------








%Europe-----------------------------------------------------------------------------------------------------
pos2 = [0.347 0.53 0.3 0.45];
ax2 = subplot('Position',pos2)

m_proj('miller','lat',[35 80],'lon',[-15 60]) 
hold on
m_pcolor(xq,yq,totvotpos1)
for ic = 1:length(S1)
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',3);  
end
for ic = 1:length(S_craton)
        m_line(S_craton(ic).X, S_craton(ic).Y, 'color', [0.4 0.4 0.4], 'linewidth', 1.5, 'linestyle', '--');
end

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



caxis([hlow Nmodels])
colormap(gca,cmap)


% h=colorbar('northoutside')
% h.Limits = [hlow Nmodels];
m_grid('box','fancy','grid','none','tickdir','out','backcolor','w','fontsize',fs-5)

%inset
posi2 = [pos2(1)-0.01 pos2(2)+0.27 0.168 0.168];
axi2 = axes('Position',posi2)
m_proj('miller','lat',[35 80],'lon',[-15 60]) 
hold on
m_pcolor(xq,yq,totvotesneg1)
for ic = 1:length(S1)      
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',3);  
end
for ic = 1:length(S_craton)
        m_line(S_craton(ic).X, S_craton(ic).Y, 'color', [0.4 0.4 0.4], 'linewidth', 1.5, 'linestyle', '--');
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

        m_scatter(Data_Global_RF_C1.Longitude(nC1), Data_Global_RF_C1.Latitude(nC1),psz-50,...
                  'Marker',marker,'MarkerFaceColor',[0.8392    0.5412    0.0941], 'MarkerEdgeColor','k','LineWidth',1.5);
end


caxis([hlow Nmodels])
colormap(axi2,cmap2)
m_grid('linewi',2,'linest','none','tickdir','out','xticklabels',[],'yticklabels',[])




%Asia
pos3 = [0.68 0.53 0.3 0.45];
ax3 = subplot('Position',pos3)
m_proj('miller','lat',[3 80],'lon',[60 179]) 
hold on
m_pcolor(xq,yq,totvotpos1)
for ic = 1:length(S1)
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',3);
end
for ic = 1:length(S_craton)
        m_line(S_craton(ic).X, S_craton(ic).Y, 'color', [0.4 0.4 0.4], 'linewidth', 1.5, 'linestyle', '--');
end

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


caxis([hlow Nmodels])
colormap(gca,cmap)

% h=colorbar('northoutside')
% h.Limits = [hlow Nmodels];
m_grid('box','fancy','grid','none','tickdir','out','backcolor','w','fontsize',fs-5)
%inset
posi3 = [pos3(1)-0.015 pos3(2)+0.27 0.168 0.168];
axi3 = axes('Position',posi3)
m_proj('miller','lat',[3 80],'lon',[60 179]) 
hold on
m_pcolor(xq,yq,totvotesneg1)
for ic = 1:length(S1)      
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',3);  
end
for ic = 1:length(S_craton)
        m_line(S_craton(ic).X, S_craton(ic).Y, 'color', [0.4 0.4 0.4], 'linewidth', 1.5, 'linestyle', '--');
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

        m_scatter(Data_Global_RF_C1.Longitude(nC1), Data_Global_RF_C1.Latitude(nC1),psz-50,...
                  'Marker',marker,'MarkerFaceColor',[0.8392    0.5412    0.0941], 'MarkerEdgeColor','k','LineWidth',1.5);
end


caxis([hlow Nmodels])
colormap(axi3,cmap2)
m_grid('linewi',2,'linest','none','tickdir','out','xticklabels',[],'yticklabels',[])








%South America
pos4 = [0.02 0.05 0.3 0.45];
ax4 = subplot('Position',pos4)
m_proj('miller','lat',[-60 20],'lon',[-118 -20]) 
hold on
m_pcolor(xq,yq,totvotpos1)
for ic = 1:length(S1)
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',3);  
end
for ic = 1:length(S_craton)
        m_line(S_craton(ic).X, S_craton(ic).Y, 'color', [0.4 0.4 0.4], 'linewidth', 1.5, 'linestyle', '--');
end

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


caxis([hlow Nmodels])
colormap(gca,cmap)
% h=colorbar('northoutside')
% h.Limits = [hlow Nmodels];
m_grid('box','fancy','grid','none','tickdir','out','backcolor','w','fontsize',fs-5)
%inset
posi4 = [pos4(1)-0.01 pos4(2)+0.015 0.168 0.168];
axi4 = axes('Position',posi4)
m_proj('miller','lat',[-60 20],'lon',[-118 -20]) 
hold on
m_pcolor(xq,yq,totvotesneg1)
for ic = 1:length(S1)      
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',3);  
end
for ic = 1:length(S_craton)
        m_line(S_craton(ic).X, S_craton(ic).Y, 'color', [0.4 0.4 0.4], 'linewidth', 1.5, 'linestyle', '--');
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

        m_scatter(Data_Global_RF_C1.Longitude(nC1), Data_Global_RF_C1.Latitude(nC1),psz-50,...
                  'Marker',marker,'MarkerFaceColor',[0.8392    0.5412    0.0941], 'MarkerEdgeColor','k','LineWidth',1.5);
end

caxis([hlow Nmodels])
colormap(axi4,cmap2)
m_grid('linewi',2,'linest','none','tickdir','out','xticklabels',[],'yticklabels',[])



%Africa
pos5 = [0.347 0.05 0.3 0.45];
ax5 = subplot('Position',pos5)
m_proj('miller','lat',[-38 38],'lon',[-25 62]) 
hold on
m_pcolor(xq,yq,totvotpos1)
for ic = 1:length(S1)
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',3); 
end
for ic = 1:length(S_craton)
        m_line(S_craton(ic).X, S_craton(ic).Y, 'color', [0.4 0.4 0.4], 'linewidth', 1.5, 'linestyle', '--');
end

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


%arabia
caxis([hlow Nmodels])
colormap(gca,cmap)
% h=colorbar('northoutside')
% h.Limits = [hlow Nmodels];
m_grid('box','fancy','grid','none','tickdir','out','backcolor','w','fontsize',fs-5)
%inset
posi5 = [pos5(1)-0.01 pos5(2)+0.015 0.168 0.168];
axi5 = axes('Position',posi5)
m_proj('miller','lat',[-38 38],'lon',[-25 62]) 
hold on
m_pcolor(xq,yq,totvotesneg1)
for ic = 1:length(S1)      
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',3);  
end
for ic = 1:length(S_craton)
        m_line(S_craton(ic).X, S_craton(ic).Y, 'color', [0.4 0.4 0.4], 'linewidth', 1.5, 'linestyle', '--');
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

        m_scatter(Data_Global_RF_C1.Longitude(nC1), Data_Global_RF_C1.Latitude(nC1),psz-50,...
                  'Marker',marker,'MarkerFaceColor',[0.8392    0.5412    0.0941], 'MarkerEdgeColor','k','LineWidth',1.5);
end



%arabia
caxis([hlow Nmodels])
colormap(axi5,cmap2)
m_grid('linewi',2,'linest','none','tickdir','out','xticklabels',[],'yticklabels',[])



%Oceania
pos6 = [0.68 0.05 0.3 0.45];
ax6 = subplot('Position',pos6)
m_proj('miller','lat',[-50 5],'lon',[85.5 155]) 
hold on
m_pcolor(xq,yq,totvotpos1)
for ic = 1:length(S1)
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',3);  
end
for ic = 1:length(S_craton)
        m_line(S_craton(ic).X, S_craton(ic).Y, 'color', [0.4 0.4 0.4], 'linewidth', 1.5, 'linestyle', '--');
end
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


%SE asia
caxis([hlow Nmodels])
colormap(gca,cmap)
%h=colorbar('northoutside')
%h.Limits = [hlow Nmodels];
m_grid('box','fancy','grid','none','tickdir','out','backcolor','w','fontsize',fs-5)
%inset
posi6 = [pos6(1)-0.015 pos6(2)+0.015 0.168 0.168];
axi6 = axes('Position',posi6)
m_proj('miller','lat',[-50 5],'lon',[85.5 155]) 
hold on
m_pcolor(xq,yq,totvotesneg1)
for ic = 1:length(S1)      
        m_line(S1(ic).X, S1(ic).Y, 'color','k' , 'linewidth',3);  
end
for ic = 1:length(S_craton)
        m_line(S_craton(ic).X, S_craton(ic).Y, 'color', [0.4 0.4 0.4], 'linewidth', 1.5, 'linestyle', '--');
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

        m_scatter(Data_Global_RF_C1.Longitude(nC1), Data_Global_RF_C1.Latitude(nC1),psz-50,...
                  'Marker',marker,'MarkerFaceColor',[0.8392    0.5412    0.0941], 'MarkerEdgeColor','k','LineWidth',1.5);
end

caxis([hlow Nmodels])
colormap(axi6,cmap2)
m_grid('linewi',2,'linest','none','tickdir','out','xticklabels',[],'yticklabels',[])


%% Bottom of Figure 1
figure(2)
set(gcf,'Position',[200,500,2500,500])
clf

%colorbar Votmap
pos23 = [0.35 0.3 0.3 0.1];
ax23 = subplot('Position',pos23)
caxis([-Nmodels Nmodels])
colormap(gca,comcmap)
h=colorbar('northoutside','AxisLocation','in','fontsize', fs-5);
h.Limits = [-Nmodels Nmodels];
hYtic = h.YTickLabel;
k = length(hYtic);
for i = 1:4
    hYtic{i} = hYtic{k};
    k = k-1
end
h.YTickLabel = hYtic;
hpos = get(h,'Position')
hpos(4) = hpos(4) + 0.03
hpos(3) = hpos(3) - 0.05
hpos(1) = hpos(1) + 0.025
set(h,'position',hpos)
barname = strcat("Number of Models (Vs < ", num2str(refneg), " % ; Vs > ", num2str(refpos),"%)")
ylabel(h,barname,'fontweight','bold','fontsize', fs);
axis off


%legend
% Dummy plots for legend entries
pos23b = [0.35 0.6 0.3 0.1];
ax23b = subplot('Position',pos23b)
h1 = plot(nan, nan,'Color',[0.3882    0.3569    0.5294],'LineWidth', 10); 
hold on
h2 = plot(nan, nan, 'Color',[0.6706    0.3961    0.6157],'LineWidth',10); 
h3 = plot(nan, nan,'Color', [0.4353    0.6392    0.4745],'LineWidth', 10); 
h4 = plot(nan, nan, 'Color',[0.8392    0.5412    0.0941], 'LineWidth', 10); 
% Create legend
lgd = legend([h1 h2 h3 h4], {'Melt-Shaped LAB (C1)', 'Rheologically-Shaped MLD (C2)','Metasomatic Boundary (C3)','Deep Structural Fabric (C4)'}, ...
    'FontSize',fs);
axis off
lgd.Position = [0.45 0.6 0.1 0.15];


%newC1 (Melt,C2)
pos24a = [0.68 0.55 0.14 0.3];
ax24a = subplot('Position',pos24a)
RFs = RF_C2
for ii = 1:size(RFs,1)
       
    trace = RFs(ii, :) - mean(RFs(ii, :));
    trace_norm = trace / max(abs(trace));
    zeroLine = ii * ones(size(t))
    yvals = trace_norm + ii;
    zeroLine = ii * ones(size(t));
    negatives = trace_norm < 0;
    positives = trace_norm > 0;


    jbfill(t(positives), yvals(positives), zeroLine(positives), [0 0 1], 'none', 1,1.0);
    jbfill(t(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], 'none', 1,1.0);

    hold on 
  
end
ylim([0 size(RFs,1)])
xlim([6 max(t)])
xticks([6,10:5:30]);xticklabels([60,100:50:300]);
xlabel('Depth (km)','fontsize',fs-10, 'fontweight', 'bold')
box on
set(gca,'linewidth',4,'fontsize',fs-10, 'XMinorTick','on','YMinorTick','on','YAxisLocation', 'right','XColor', [0.3882    0.3569    0.5294],'YColor', [0.3882    0.3569    0.5294])
ax = gca;
ax.XAxis.TickLabelColor = [0 0 0]; 
ax.YAxis.TickLabelColor = [0 0 0];
ax.XAxis.Label.Color = [0 0 0];
ax.YAxis.Label.Color = [0 0 0];
camroll(270)

% newC2 (Rheology, C3)
pos24b = [0.83 0.55 0.14 0.3];
ax24b = subplot('Position',pos24b)
RFs = RF_C3
for ii = 1:size(RFs,1)
       
    trace = RFs(ii, :) - mean(RFs(ii, :));
    trace_norm = trace / max(abs(trace));
    zeroLine = ii * ones(size(t))
    yvals = trace_norm + ii;
    zeroLine = ii * ones(size(t));
    negatives = trace_norm < 0;
    positives = trace_norm > 0;


    jbfill(t(positives), yvals(positives), zeroLine(positives), [0 0 1], 'none', 1,1.0);
    jbfill(t(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], 'none', 1,1.0);

    hold on 
  
end
ylim([0 size(RFs,1)])
xlim([6 max(t)])
xticks([6,10:5:30]);xticklabels([60,100:50:300]);


box on
set(gca,'linewidth',4,'fontsize',fs-10,'XTickLabel', [],'XMinorTick','on','YMinorTick','on','YAxisLocation', 'right','XColor', [0.6706    0.3961    0.6157],'YColor', [0.6706    0.3961    0.6157])
ax = gca;
ax.XAxis.TickLabelColor = [0 0 0]; 
ax.YAxis.TickLabelColor = [0 0 0];
ax.XAxis.Label.Color = [0 0 0];
ax.YAxis.Label.Color = [0 0 0];
camroll(270)

%newC3 (Metasomatism,C0)
pos24c = [0.68 0.15 0.14 0.3];
ax24c = subplot('Position',pos24c)
RFs = RF_C0
for ii = 1:size(RFs,1)
       
    trace = RFs(ii, :) - mean(RFs(ii, :));
    trace_norm = trace / max(abs(trace));
    zeroLine = ii * ones(size(t))
    yvals = trace_norm + ii;
    zeroLine = ii * ones(size(t));
    negatives = trace_norm < 0;
    positives = trace_norm > 0;


    jbfill(t(positives), yvals(positives), zeroLine(positives), [0 0 1], 'none', 1,1.0);
    jbfill(t(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], 'none', 1,1.0);

    hold on 
  
end
ylim([0 size(RFs,1)])
xlim([6 max(t)])
xticks([6,10:5:30]);xticklabels([60,100:50:300]);

xlabel('Depth (km)','fontsize',fs-10, 'fontweight', 'bold')
ylabel('Station Index','fontsize',fs-10, 'fontweight', 'bold')
box on
set(gca,'linewidth',4,'fontsize',fs-10,'XMinorTick','on','YMinorTick','on','YAxisLocation', 'right','XColor', [0.4353    0.6392    0.4745],'YColor', [0.4353    0.6392    0.4745])
ax = gca;
ax.XAxis.TickLabelColor = [0 0 0]; 
ax.YAxis.TickLabelColor = [0 0 0];
ax.XAxis.Label.Color = [0 0 0];
ax.YAxis.Label.Color = [0 0 0];
camroll(270)

%newC4 (Structural, C1)
pos24d = [0.83 0.15 0.14 0.3];
ax24d = subplot('Position',pos24d)
RFs = RF_C1
for ii = 1:size(RFs,1)
       
    trace = RFs(ii, :) - mean(RFs(ii, :));
    trace_norm = trace / max(abs(trace));
    zeroLine = ii * ones(size(t))
    yvals = trace_norm + ii;
    zeroLine = ii * ones(size(t));
    negatives = trace_norm < 0;
    positives = trace_norm > 0;


    jbfill(t(positives), yvals(positives), zeroLine(positives), [0 0 1], 'none', 1,1.0);
    jbfill(t(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], 'none', 1,1.0);

    hold on 
  
end
ylim([0 size(RFs,1)])
xlim([6 max(t)])
xticks([6,10:5:30]);xticklabels([60,100:50:300]);

ylabel('Station Index','fontsize',fs-10, 'fontweight', 'bold')
box on
set(gca,'linewidth',4,'fontsize',fs-10,'xticklabels',[],'XMinorTick','on','YMinorTick','on','YAxisLocation', 'right','XColor', [0.8392    0.5412    0.0941],'YColor', [0.8392    0.5412    0.0941])
ax = gca;
ax.XAxis.TickLabelColor = [0 0 0]; 
ax.YAxis.TickLabelColor = [0 0 0];
ax.XAxis.Label.Color = [0 0 0];
ax.YAxis.Label.Color = [0 0 0];
camroll(270)

%%
saveas(figure(1),'./Figures/Global_Study/Revision1_Final_Figure_1_top.pdf')
saveas(figure(2),'./Figures/Global_Study/Revision1_Final_Figure_1_bottom.pdf')