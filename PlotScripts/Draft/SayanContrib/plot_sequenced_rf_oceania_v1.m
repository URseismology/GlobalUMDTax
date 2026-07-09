%% Load Mat File
clear;clc;
seq_rf = load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/south america/parameter_set_1/filtered_sequenced_full.mat']);
seq_rf_pos = load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/south america/parameter_set_1/filtered_pos_sequenced_full.mat']);
seq_rf_neg = load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/south america/parameter_set_1/filtered_neg_sequenced_full.mat']);

raw_rf = load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/south america/parameter_set_1/all_sta_filt_stack_rf.mat']);
raw_rf_pos = load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/south america/parameter_set_1/all_sta_filt_pos_stack_rf.mat']);
raw_rf_neg = load(['/scratch/tolugboj_lab/Sayan_Swar_WS/PythonEnv/Python_Notebooks/' ...
    'GoGlobal/scripts/rf_prep_slurm_step_7/srtfista_output/south america/parameter_set_1/all_sta_filt_neg_stack_rf.mat']);


seq_rf_neg.sequencedData = seq_rf_neg;
seq_rf_pos.sequencedData = seq_rf_pos;
t = seq_rf_neg.time_vector;
t_dep = t.*10;

%% Remove the Stations which are part of Arrays as they have same charecteristics and also Stations not in Oceania Main Continent & the Stations Not Having any Negative MeanTrace
filt_idx=true(length(seq_rf.station),1);
filt_idx(find(ismember(seq_rf.station,{'AU-PSAA2','AU-PSAA1','AU-PSAA3','AU-BW1H','AU-MANU','AU-RABL','IU-PMG','GE-PMG','IU-SNZO'})))=0;
seq_rf.station=seq_rf.station(filt_idx,:);
seq_rf.dataset_imageRFs_pos_reordered=seq_rf.dataset_imageRFs_pos_reordered(filt_idx,:);

filt_idx=true(length(seq_rf_pos.sequencedData.station),1);
%filt_idx(find(ismember(seq_rf_pos.sequencedData.station,{'AU-PSAA2','AU-PSAA1','AU-PSAA3','AU-BW1H','AU-MANU','AU-RABL','IU-PMG','GE-PMG','IU-SNZO'})))=0;
seq_rf_pos.sequencedData.station=seq_rf_pos.sequencedData.station(filt_idx,:);
%seq_rf_pos.sequencedData.clusters=seq_rf_pos.sequencedData.clusters(filt_idx,:);
seq_rf_pos.sequencedData.dataset_imageRFs_pos_reordered=seq_rf_pos.sequencedData.dataset_imageRFs_pos_reordered(filt_idx,:);

filt_idx=true(length(seq_rf_neg.sequencedData.station),1);
%filt_idx(find(ismember(seq_rf_neg.sequencedData.station,{'AU-PSAA2','AU-PSAA1','AU-PSAA3','AU-BW1H','AU-MANU','AU-RABL','IU-PMG','GE-PMG','IU-SNZO', 'AU-NWAO'})))=0;
seq_rf_neg.sequencedData.station=seq_rf_neg.sequencedData.station(filt_idx,:);
%seq_rf_neg.sequencedData.clusters=seq_rf_neg.sequencedData.clusters(filt_idx,:);
seq_rf_neg.sequencedData.dataset_imageRFs_pos_reordered=seq_rf_neg.sequencedData.dataset_imageRFs_neg_reordered(filt_idx,:);
%% Plot UnSeqeunced Filtered Stacked RF
figure;
sgt=sgtitle(['Receiver Function Plots (Unsequenced Left-Sequenced Right) of South America Stations',newline,'']); sgt.FontSize=12;
set(gcf,'Position',[0.13 0.11 1349 845]);
subplot(3,2,1);
for i=1:size(raw_rf.filt_rf_stck_allsta.rf,1)
    trace=raw_rf.filt_rf_stck_allsta.rf(i,:) - mean(raw_rf.filt_rf_stck_allsta.rf(i,:));

    trace_norm = trace / max(abs(trace));
    yvals = trace_norm + i;
    zeroLine = i * ones(size(t_dep));
    negatives = trace_norm < 0; 
    positives = trace_norm > 0; 
    jbfill(t_dep(positives), yvals(positives), zeroLine(positives), [0 0 1], 'w', 1, 1.0);
    jbfill(t_dep(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], 'w', 1, 1.0);
    hold on

end
xline([60,120,180,240]);
xticks([60 100 140 180 220 260 300 340]);
xlim([60 350]);
ylim([0, size(raw_rf.filt_rf_stck_allsta.rf , 1) + 1]);
xlabel('Depths (km)','fontweight', 'bold');
ylabel('Station Indices')
ntitle('Filtered Unsequenced RF for South America Station','location','south','fontweight', 'bold');
camroll(270)
%% Plot Seqeunced Filtered Stacked RF
subplot(3,2,2);
for i=1:size(seq_rf.dataset_imageRFs_pos_reordered,1)
    trace=seq_rf.dataset_imageRFs_pos_reordered(i,:) - mean(seq_rf.dataset_imageRFs_pos_reordered(i,:));

    trace_norm = trace / max(abs(trace));
    yvals = trace_norm + i;
    zeroLine = i * ones(size(t_dep));
    negatives = trace_norm < 0; 
    positives = trace_norm > 0; 
    jbfill(t_dep(positives), yvals(positives), zeroLine(positives), [0 0 1], 'w', 1, 1.0);
    jbfill(t_dep(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], 'w', 1, 1.0);
    hold on

end
xline([60,120,180,240]);
xticks([60 100 140 180 220 260 300 340]);
xlim([60 350]);
ylim([0, size(seq_rf.dataset_imageRFs_pos_reordered , 1) + 1]);
xlabel('Depths (km)','fontweight', 'bold');
ylabel('Station Indices')
ntitle('Filtered Sequenced RF for South America Station','location','south','fontweight', 'bold');
camroll(270)
%% Plot UnSeqeunced Neg Filtered Stacked RF
subplot(3,2,3);
t = raw_rf_neg.filt_rf_stck_allsta.t_val(1,:);
t_dep = t.*10;

for i=1:size(raw_rf_neg.filt_rf_stck_allsta.rf,1)
    trace=raw_rf_neg.filt_rf_stck_allsta.rf(i,:) - mean(raw_rf_neg.filt_rf_stck_allsta.rf(i,:));

    trace_norm = trace / max(abs(trace));
    yvals = trace_norm + i;
    zeroLine = i * ones(size(t_dep));
    negatives = trace_norm < 0; 
    positives = trace_norm > 0; 
    jbfill(t_dep(positives), yvals(positives), zeroLine(positives), [0 0 1], 'w', 1, 1.0);
    jbfill(t_dep(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], 'w', 1, 1.0);
    hold on

end
xline([60,120,180,240]);
%xticks([60 100 140 180 220 260 300 340]);
xlim([60 350]);
%ylim([0, size(raw_rf_neg.filt_rf_stck_allsta.rf , 1) + 1]);
xlabel('Depths (km)','fontweight', 'bold');
ylabel('Station Indices')
ntitle('Neg-Filtered Unsequenced RF for South America Station','location','south','fontweight', 'bold');
camroll(270)
%% Plot Seqeunced Neg Filtered Stacked RF
subplot(3,2,4);
t = seq_rf_neg.sequencedData.time_vector;
t_dep = t.*10;

for i=1:size(seq_rf_neg.sequencedData.dataset_imageRFs_neg_reordered,1)
    trace=seq_rf_neg.sequencedData.dataset_imageRFs_neg_reordered(i,:) - mean(seq_rf_neg.sequencedData.dataset_imageRFs_neg_reordered(i,:));

    trace_norm = trace / max(abs(trace));
    yvals = trace_norm + i;
    zeroLine = i * ones(size(t_dep));
    negatives = trace_norm < 0; 
    positives = trace_norm > 0; 
    jbfill(t_dep(positives), yvals(positives), zeroLine(positives), [0 0 1], 'w', 1, 1.0);
    jbfill(t_dep(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], 'w', 1, 1.0);
    hold on

end
xline([60,120,180,240]);
%xticks([60 100 140 180 220 260 300 340]);
xlim([60 350]);
ylim([0, size(seq_rf_neg.sequencedData.dataset_imageRFs_neg_reordered , 1) + 1]);
xlabel('Depths (km)','fontweight', 'bold');
ylabel('Station Indices')
ntitle('Neg-Filtered Sequenced RF for South America Station','location','south','fontweight', 'bold');
camroll(270)
%% Plot UnSeqeunced Pos Filtered Stacked RF
subplot(3,2,5)
t = raw_rf_pos.filt_rf_stck_allsta.t_val(1,:);
t_dep = t.*10; 

for i=1:size(raw_rf_pos.filt_rf_stck_allsta.rf,1)
    if sum(raw_rf_pos.filt_rf_stck_allsta.rf(i,:))~=0
        trace=raw_rf_pos.filt_rf_stck_allsta.rf(i,:) - mean(raw_rf_pos.filt_rf_stck_allsta.rf(i,:));
        trace_norm = trace / max(abs(trace));
        yvals = trace_norm + i;
        zeroLine = i * ones(size(t_dep));
        negatives = trace_norm < 0; 
        positives = trace_norm > 0; 
        jbfill(t_dep(positives), yvals(positives), zeroLine(positives), [0 0 1], 'w', 1, 1.0);
        jbfill(t_dep(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], 'w', 1, 1.0);
        hold on
    end

end
xline([60,120,180,240]);
%xticks([60 100 140 180 220 260 300 340]);
xlim([60 350]);
ylim([0, size(raw_rf_pos.filt_rf_stck_allsta.rf, 1) + 1]);
xlabel('Depths (km)','fontweight', 'bold');
ylabel('Station Indices')
ntitle('Pos-Filtered Unsequenced RF for South America Station','location','south','fontweight', 'bold');
camroll(270)
%% Plot Seqeunced Pos Filtered Stacked RF
subplot(3,2,6)
t = seq_rf_pos.sequencedData.time_vector;
t_dep = t.*10; 

for i=1:size(seq_rf_pos.sequencedData.dataset_imageRFs_pos_reordered,1)
    if sum(seq_rf_pos.sequencedData.dataset_imageRFs_pos_reordered(i,:))~=0
        trace=seq_rf_pos.sequencedData.dataset_imageRFs_pos_reordered(i,:) - mean(seq_rf_pos.sequencedData.dataset_imageRFs_pos_reordered(i,:));
        trace_norm = trace / max(abs(trace));
        yvals = trace_norm + i;
        zeroLine = i * ones(size(t_dep));
        negatives = trace_norm < 0; 
        positives = trace_norm > 0; 
        jbfill(t_dep(positives), yvals(positives), zeroLine(positives), [0 0 1], 'w', 1, 1.0);
        jbfill(t_dep(negatives), yvals(negatives), zeroLine(negatives), [1 0 0], 'w', 1, 1.0);
        hold on
    end

end
xline([60,120,180,240]);
%xticks([60 100 140 180 220 260 300 340]);
xlim([60 350]);
ylim([0, size(seq_rf_pos.sequencedData.dataset_imageRFs_pos_reordered , 1) + 1]);
xlabel('Depths (km)','fontweight', 'bold');
ylabel('Station Indices')
ntitle('Pos-Filtered Sequenced RF for South America Station','location','south','fontweight', 'bold');
camroll(270)
%%
% see if I can find nan
% plot the events if I can
% plot the oceania location and see if there is a pattern

