%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Tolulope Olugboji
% Figure 0: A global analysis of cratonic crustal structure using avalaible
%           If we are to study cratons, we must first define (and visualize) their surface extent
%           Typically this can be done by:
%           1. Tomography (best summarized by cluster analysis e.g., Lekic & Romanowicz, 2010; Shaeffer & Lebedev, 2015)
%           2. Age of basement - Artemieva, 2006?
%           3. How does this statistics hold up when compared with Jordan, 1981, regionalization paper?
clear
clc
close all

Crust1Dir = '/Users/olugboji/Documents/UMD_Seismo/transdimUSANT/matlabscripts/parseCrustModels/';
ldDir = '/Users/olugboji/Documents/UMD_Seismo/transdimUSANT/scripts/7_GlobalCratons/MetaData/';
saveDir = '/Users/olugboji/Documents/UMD_Seismo/transdimUSANT/scripts/7_GlobalCratons/4Pub/';

saveStat = figure('units', 'normalized', 'Position',[0 0 0.5 1], ...
    'DefaultAxesFontSize', 18);

ROW = 2;   % 
COLS = 2; % 

gap = [0.005 0.01];
marg_h = [0.01 0.01];
marg_w = [0.02 0.02];


        
% load baseline grid from crust1
load([Crust1Dir 'Crust1pnt0Types.mat'])
[latgrid, longrid] = meshgrid(latPnts, lonPnts);

% Age epochs - phanerezoic, proterozoic, archean, hadean
ageBnds = [0 540 2500 3500];
totAge = length(ageBnds);
            
doms={'eurasia', 'Antarctica', 'africa',  'namerica', 'samerica', ...
    'greenland',  'australia'};
totDoms = length(doms);

ratioCont_DomAge = zeros(totDoms, totAge-1);
  
ocean = ~landmask(latgrid,longrid);


ThreeColBasmntAge;          % load colormap for basement age

ha = tight_subplot(ROW, COLS,gap, marg_h, marg_w);
iView = 1;

for shwMap = 2
    
    switch shwMap
        case 1
            % statistics and visualization from GTR1
            load([ldDir 'GTR1.mat']);
            
            F = scatteredInterpolant(GTRlatgrd(:), GTRlongrd(:), GTR1_int(:), 'natural', 'none');
            GTR1map = F(latgrid, longrid );
            GTR1map(ocean) = nan;
            
            useMap = GTR1map; useCols = rangeReg;
            
            useTitle = 'GTR1 [Jordan, (1981); Jordan & Paulson (2013)]';
            %yt = [1 2 3 4 5 6];
            yyt = yts;
            clims = [0 6.8];
            barLabel = 'Regions';
            nmLabel = { ''
                'A,B,C: Oceans'
                ''
                'P: Orogens'
                'Q: Platforms'
                'S: Shields'
                };
            
        case 2
            % statistics and visualizations from Artemieva
            % -------------------------------------------------- 1. Artemieva Age Data
            inArtFile = ...
                '/Users/olugboji/TerraMount/olugbojiRAID/olugbojiProjects/crustalModels/IrinaThermal/global-ages-0705-1x1.xyz.txt';
            ageMap = load(inArtFile);
            
            F = scatteredInterpolant(ageMap(:,1), ageMap(:,2), ageMap(:,3), 'natural', 'none');
            crustAge = F(longrid, latgrid);
            mAge = max(max(crustAge));
            
            %ageBnds = [540 2500 3500];
            %totAge = length(ageBnds);

            oceanAll = ~landmask(latgrid,longrid);
            
            for iDom = 1:totDoms
                
                %mask domain - 6 each...
                oceanDom = ~landmask(latgrid,longrid, doms{iDom});
                
                %mask age - 3 each
                for iEpoch = 1:3
                    
                    crustAgeDom = crustAge;
                    crustAgeAll = crustAge;
                    
                    crustAgeDom(oceanDom) = NaN;
                    crustAgeAll(oceanAll) = NaN;
                    
                    
                    inAge = (crustAge>ageBnds(iEpoch)) & (crustAge<ageBnds(iEpoch+1));
                    crustAgeDom(~inAge) = NaN;
                    
                    ratioCont =  sum(~isnan(crustAgeDom), 'all') ./ ...
                        sum(~isnan(crustAgeAll), 'all')
                    
                    ratioCont_DomAge(iDom, iEpoch) = ratioCont;
                end
            end
            
            %crustAge = crustAgeDom;
            crustAge(oceanDom) = NaN;
            %crustAge(ocean) = NaN;
            %ratioContOcean =  sum(~isnan(crustAge), 'all') ./ length(crustAge(:));
            
            
            
            useMap = crustAge; useCols = rangeCols;
            useTitle = 'TC1 [Artemieva (2006)]';
            
            yyt = yt;
            barLabel = 'Age (Ma)';
            clims = [0 mAge];
            nmLabel = { '0'
                '1100'
                '2500'
                '3500'
                };
            
            
            
        case 3
            % statistics and visualizations from Lekic
            load([ldDir 'LekicRomanowicz2011_SEMum_tectonic_clustering.mat'])   
            F = scatteredInterpolant(lts(:), wrapTo180(lngs(:)), T(:), 'natural', 'none');
            LekicReg6 = F(latgrid, longrid );
            LekicReg6(ocean) = nan;
            useMap = LekicReg6; useCols = rangeLekic; %useCols = 'jet'; 
            clims = [0 5.5];
            yyt = 0:1:Nclust;
            nmLabel = { '1' '2' '3' '4' '5' '6'};
            barLabel = 'Cluister Index (N)';
            
            useTitle = 'k Means [Lekic & Romanowicz (2011)]';
            
            %plot(cntrs(j,:),deps,'-','color',boje(j,:));
            %ylim([60 max(deps)]); set(gca,'ydir','reverse');
            %ylabel('Depth (km)'); xlabel('Vs (km/s)');

            %subplot(1,2,2); 
            %contourf(lngs,lts,T,Nclust);
    end
    
    %ha = tight_subplot(ROW, COLS,gap, marg_h, marg_w);
    %iView = 1;
    
    axes(ha(shwMap))
    
    load coastlines
    m_proj('robinson');
    hold on
    m_coast('color', 'k', 'LineWidth', 2);
    
    vw = m_pcolor(longrid, latgrid, useMap); shading flat;
    %vw = m_pcolor(GTRlongrd, GTRlatgrd,  GTR1_int); shading flat;
    %m_line(coastlon,coastlat, 'color', [0.5 0.5 0.5], 'linewidth',1);
    m_grid2('linestyle', 'none', 'fontsize', 20, 'tickdir','in', 'box', 'fancy', 'yticklabels', [], ...
        'xticklabels', []);
    
    colormap(ha(shwMap), useCols);
    h = colorbar('southoutside'); caxis(clims);%caxis([0  mAge]); 
    set(h, 'fontsize', 13)
    set(h, 'YTick', yyt, 'XTickLabel', nmLabel );
    %text(0, 0, nmLabel, 'Rotation', -30);
    xlabel(h, barLabel, 'FontSize', 18);
    %set(lH, 'Rotation', -30)
    
    title(useTitle);
    
end


% summary tables here ...
axes(ha(shwMap + 1))


saveFigs = 0;
usePDF = 1;

if(saveFigs)
    saveFile = [saveDir 'Fig0_Cratons_Stats.pdf'];
    saveFig(saveFile, usePDF, saveStat);
end

%% here for summary tables ...

ContByAge = sum(ratioCont_DomAge,1);
ContByReg = sum(ratioCont_DomAge,2);

ContPreCamb = ratioCont_DomAge(:,2) + ratioCont_DomAge(:,3);
ContArc =  ratioCont_DomAge(:,3);
ContPhan =  ratioCont_DomAge(:,1);

%[ContPreCamb, ind] = sort(ContPreCamb, 'descend');
%Name = doms(ind);
%Name{:}
ContAllCamb = [ContByReg, ContPreCamb, ContPhan, ContArc ] .* 100
%ContPreCamb* 100

close all
figure
b = bar(ContAllCamb','stacked', 'FaceAlpha', 0.41)
legend(upper(doms), 'fontsize', 20)
xticklabels({'Entire History', 'Precambrian ( > 0.5 Ga)', ...
    'Phanerezoic ( < 0.5 Ga)', 'Archean ( > 2.4 Ga)' })
ylabel('Fractional Area (%)')
xlabel('Continents Sorted by Age')
xlim([0.5 5])
grid on

b(3).LineWidth = 2
b(3).FaceAlpha = 1

fontsize(20, 20, 13, 20)