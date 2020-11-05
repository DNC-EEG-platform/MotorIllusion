%ERP_RUN - Event-related potentials (ERP) batch analysis
% Computes ERP values from preprocessed data, creates plots and performs
% classification.
%
% Syntax:  ERP_Run()
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Notes: 
%    Select subject mat files in the UI, then click 'add' and 'done'.
%
% Other m-files required: ERP_Settings.m, ERP_Main.m, ERP_Plots.m, Xval.m
% Subfunctions: none
% External files required: none
%
% Author: Christoph Schneider
% Acute Neurorehabilitation Unit (LRNA)
% Division of Neurology, Department of Clinical Neurosciences
% Centre Hospitalier Universitaire Vaudois (CHUV)
% Rue du Bugnon 46, CH-1011 Lausanne, Switzerland
%
% email: christoph.schneider.phd@gmail.com 
% November 2020
%------------- BEGIN CODE --------------

clear;
clc;
close all;

ERP_Settings();

% select files to process
files = uipickfiles('Prompt','Select Folders','FilterSpec',args.path.preproc);

% iterate over subjects
for sub = 1:size(files,2)
    
    disp(['++++ Processing file ',num2str(sub),' of ',num2str(size(files,2)),' ++++']);
    args.filename = files{sub};
    args.sub = sub;
    
    % call extraction and analysis function
    [trialavg(sub), trials(sub)] = ERP_Main(args); %#ok<SAGROW>
end

% save ERDs
save(fullfile(args.path.erp,'ERPs.mat'),'trials', 'trialavg');


%% Cluster permutation test

% concatenate trial averages per channel
for sub = 1:size(trialavg,2)
    plotx.illusion(sub,:,:) = squeeze(mean(trials(sub).illusion.trial,1));
    plotx.control(sub,:,:) = squeeze(mean(trials(sub).control.trial,1));
end

% average across trials
data1 = squeeze(mean(plotx.illusion,2));
data2 = squeeze(mean(plotx.control,2));

% apply moving average filter (Fs = 500 Hz)
data1 = movmean(data1,default.movwinlen*500);
data2 = movmean(data2,default.movwinlen*500);

% perform test
[ signif,fpos,nsignif ] = permstattest({data1,data2},1000,0.05,0.05,'ttest',0,3);

% extract cluster positions
clusterpos = [find( diff(signif) == 1)+1, find( diff(signif) == -1)+1];

%% Plot ERPs in time and space

ERP_Plots(trials, trialavg, plotx, clusterpos)

%% Classification

disp('--> Start classification')
% iterate over subjects
for sub = 1:numel(trialavg)
    
    % prepare ERP features
    trx.erp = cat(1, trials(sub).illusion.trial, trials(sub).control.trial);
    labels.erp = cat(1, trials(sub).illusion.trialinfo, trials(sub).control.trialinfo);
    timevec.erp = trials(1).illusion.time + 1;
    default.clusterpos = timevec.erp(clusterpos);
    
    parfor rep = 1:default.xval.reps
        disp(['[ repetition ',num2str(rep),', subject ',num2str(sub),']'])
        [acc{rep,sub}, cvp{rep,sub}, feats{rep,sub}, feat_time{rep,sub}] = Xval(default, timevec, trx, labels, 'ERP');
    end
end

%% iterate over repetitions and call Xval function
features = nan(default.xval.reps, size(files,2), size(feats{1, 1},2));

for rep = 1:default.xval.reps
    for sub = 1:numel(trialavg)
        
        accuracy.train(rep, sub, :) = acc{rep, sub}.train;
        accuracy.test(rep, sub, :) = acc{rep, sub}.test;
        accuracy.testmean(rep, sub, :) = acc{rep, sub}.test_mean;
        features(rep,sub,:) = sum(feats{rep, sub},1)./sum(sum(feats{rep, sub}));
        
    end
end

% display accuracy on screen
disp(['Mean training accuracy = ', num2str( mean(mean(accuracy.train,3),1) )]);
disp(['Mean single trial test accuracy = ', num2str( mean(mean(accuracy.test,3),1) )]);
disp(['Mean averaged test accuracy = ', num2str( mean(mean(accuracy.testmean,3),1) )]);

% save classification results
if default.clsf.random
    save(fullfile(args.path.clsfres,'ERP_clsf_random.mat'),'accuracy')
else
    save(fullfile(args.path.clsfres,'ERP_clsf.mat'),'accuracy','features')
end

disp('--> Classification finished')
%% plot feature frequency

% take average across repetitions and subjects
plotfeat = squeeze(mean(mean(features,1),2));
featsem = std(squeeze(mean(features,1)),[],1)'./sqrt(size(features,2));
time = feat_time{1,1};

% plot relative feature frequency in bar plot with standard error of the
% mean
figure;
bar(time, plotfeat);
hold on;
er = errorbar(time, plotfeat, featsem, featsem);
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
xlabel('Time [s]');
ylabel('Relative frequency [a.u.]')

