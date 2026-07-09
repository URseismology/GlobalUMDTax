%% Get The Coastal Line of Australia
%%
temp_dir = [pwd '/temp'];
if ~exist(temp_dir,'dir')
    mkdir(temp_dir)
end

files = gunzip('gshhs_c.b.gz', temp_dir);

filename = files{1};
indexfile = gshhs(filename, 'createindex');
S = gshhs(filename, [-45 -8], [111 156]);
delete(filename);
delete(indexfile);
rmdir(temp_dir, 's');
levels = [S.Level];
L1 = S(levels == 1);


%% Read the Oceania Geographic Details Table
oce_geo = readgeotable(['../../Data/GeologicalData/oceania/Geological_Regions_of_Australia.geojson']);

T=geotable2table(oce_geo,["lat","lon"]);
T=T(T.feature~="GR_VOID",:);
%%
%How many different region
uniq_regions = unique(T.regname); 

%How many different rock age class
uniq_rock_age = unique(T.age_class);

%%Plot Total Area based on Age Class
area_per_age = groupsummary(T,"age_class","sum","aprox_area");
area_per_age = sortrows(area_per_age,"sum_aprox_area","ascend");

%resultTable = grpstats(T, 'age_class', {'sum'}, 'DataVars', {'aprox_area', 'lat', 'lon'});
%%
figure;
barh(area_per_age.sum_aprox_area, ...
    'FaceColor',[0 .5 .5],'EdgeColor',[0 .9 .9],'LineWidth',1.5);
y = 1:1:length(area_per_age.sum_aprox_area);
text(area_per_age.sum_aprox_area,y,num2cell(area_per_age.sum_aprox_area));
set(gca,"YTickLabel",area_per_age.age_class);
xlabel('Approx Area (km)');

%%
figure;
%m_proj('miller','lon',[111 156],'lat',[-45 -8]); 
%m_grid('linestyle','none','tickdir','out','linewidth',3);
T_palezoic = T(T.age_class=="Palaeozoic",:);
%[plat,plon] = polyjoin(T_palezoic.lat,T_palezoic.lon);
[plat,plon] = geoquadpt(T_palezoic.lat,T_palezoic.lon);
%m_line([L1.Lon], [L1.Lat], 'color','k','linewi',2);
%m_line(plon, plat, 'color',[0.3, 0.3, 0.3],'linewi',2);






