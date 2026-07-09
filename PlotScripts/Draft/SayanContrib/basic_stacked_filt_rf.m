filepath = ['/gpfs/fs2/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv' ...
    '/Python_Notebooks/GoGlobal/scripts/rf_prep_slurm_step_7/' ...
    'srtfista_output/south america/parameter_set_1/all_sta_filt_neg_stack_rf.mat'];

load(filepath);
stack_filt_rf = filt_rf_stck_allsta.rf;
stack_filt_t = filt_rf_stck_allsta.t_val;

%%
figure;

t = stack_filt_t(1,:);
jbfill(t, max(stack_filt_rf(1,:), 0),zeros(1, length(t)),[0 0 1],'k', 1, 1.0);
jbfill(t, min(stack_filt_rf(1,:), 0),zeros(1, length(t)),[1 0 0],'k', 1, 1.0);
% xlim(twin);grid on
% ylim([-1 1]);
set(gca, 'xtick', xticks, 'xticklabel', new_labels);
hold on;


%% Joe's Stack Code
figure;
for ii = 1:size(stack_filt_rf, 1)
    try
%         symbol = char(sta_symbols{ii});
%         sta_class =  char(sta_classes(ii));
%         geoprovince = char(Geoprovinces(ii));
%         if sta_class == 1
%            color =  [0,0.4471,0.7412];
%         elseif sta_class == 2
%            color = [0.9294,0.6941,0.1255];
%         elseif sta_class == 3
%            color = [0.4667,0.6745,0.1882];
%         elseif sta_class == 4
%            color = [0.8510,0.3255,0.0980];
%         end
        %%%%%
        trace = stack_filt_rf(ii, :) - mean(stack_filt_rf(ii, :));
        trace_norm = trace / max(abs(trace));
        %trace_norm = -trace_norm;
%         t_vec =  linspace(0.05,50.05,1001);
        yvals = trace_norm + ii;
        zeroLine = ii * ones(size(t));
        negatives = trace_norm < 0;
        positives = trace_norm > 0;
        jbfill(t(positives), yvals(positives), zeroLine(positives), [0 0 1], 'k', 1,1.0);
        jbfill(t(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], 'k', 1,1.0);
        hold on
        plot(-0.8,ii, 'marker','o','linewi',1,'color', color,...
                'linest','none','markersize',10,'markerfacecolor',color)
%        igeo = find(ismember(Geoprovinces, geoprovince) == 1)
%         if length(igeo) == 1
%            %postext = igeo
%            %text(-3,postext,geoprovince,'HorizontalAlignment', 'center', 'fontsize',15)
%            plot([-0,-3],[igeo,igeo],'color','k', 'linestyle', '--', 'linewidth',2)
%         elseif length(igeo) > 1
% %            postext = (igeo(end) + igeo(1))/2
% %            if ii == igeo(end)
% %               text(-3,postext,geoprovince, 'HorizontalAlignment', 'center','fontsize',15)
% %            end
%            plot([-1.8,-3],[igeo(1),igeo(1)],'color','k', 'linestyle', '--', 'linewidth',2)
%            plot([-1.8,-3],[igeo(end),igeo(end)],'color','k', 'linestyle', '--', 'linewidth',2)
%         end
    catch
%         symbol
        continue
    end
    %plot(t, yvals, 'k');  % Commented out to remove the black zero line
end
xline([6,12,18,24])
xlim([6 35]);
ylim([0, size(stack_filt_rf , 1) + 1]);  % Adjusted for spacing
% xticks = linspace(0, 36, 7);
% new_labels = (xticks + 6)*10;
% set(gca, 'xtick', xticks, 'xticklabel', new_labels,'XMinorTick','on');
xlabel('Depths (km)','fontweight', 'bold');
ylabel('Station Indices');
% camroll(270);