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
% May 2021
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

save ERPs
save(fullfile(args.path.erp,'ERPs.mat'),'trials', 'trialavg');

%% Cluster permutation test

% concatenate trial averages per channel
for sub = 1:size(trialavg,2)
    plotx.illusion(sub,:,:) = squeeze(median(trials(sub).illusion.trial,1));
    plotx.control(sub,:,:) = squeeze(median(trials(sub).control.trial,1));
end

% average across channels
data1 = squeeze(mean(plotx.illusion,2));
data2 = squeeze(mean(plotx.control,2));

% apply moving average filter (Fs = 500 Hz)
data1 = movmean(data1',default.movwinlen*500)';
data2 = movmean(data2',default.movwinlen*500)';

% perform test
[ signif,fpos,nsignif ] = permstattest({data1,data2},1000,0.05,0.05,'ttest',-1,3);

pval = nan(1,size(data1,2));
for t = 1:size(data1,2)
   [~,pval(t)] = ttest(data1(:,t),data2(:,t)) ;
end

% extract cluster positions
clusterpos = [find( diff(signif) == 1)+1, find( diff(signif) == -1)+1];

%% calculate effect size (Cohen's D)

time = trials(1).illusion.time;
usesamples = time > time(clusterpos(1)) & time < time(clusterpos(2));
m1 = mean(data1(:,usesamples),[2,1]);
m2 = mean(data2(:,usesamples),[2,1]);
s = std(mean(cat(1,data1(:,usesamples),data2(:,usesamples)),2));
d = (m1-m2)/s;
dips(["Effect size represented by Cohen's d: ", num2str(d)]);

%% Plot ERPs in time and space

flag = 1;
ERP_Plots(trials, trialavg, plotx, clusterpos, flag)

%% Classification

disp('--> Start classification')
% iterate over subjects
for sub = 1:numel(trialavg)
    
    % prepare ERP features
    trx.erp = cat(1, trials(sub).illusion.trial, trials(sub).control.trial);
    labels.erp = cat(1, trials(sub).illusion.trialinfo, trials(sub).control.trialinfo);
    timevec.erp = trials(1).illusion.time + 1;
    
    parfor rep = 1:default.xval.reps
        tic
        disp(['[ repetition ',num2str(rep),', subject ',num2str(sub),']'])
        [acc{rep,sub}, cvp{rep,sub}, feats{rep,sub}, feat_time{rep,sub}] = Xval(default, timevec, trx, labels, 'ERP');
        toc
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
        M.labels = acc{rep, sub}.test_mean_labels(:);
        M.scores = acc{rep, sub}.test_mean_score(:);
    end
end

% display accuracy on screen
disp(['Mean training accuracy = ', num2str( mean(mean(accuracy.train,3),1) )]);
disp(['Mean single trial test accuracy = ', num2str( mean(mean(accuracy.test,3),1) )]);
disp(['Mean averaged test accuracy = ', num2str( mean(mean(accuracy.testmean,3),1) )]);

% save classification results
if default.clsf.random
    save(fullfile(args.path.clsfres,'ERP_clsf_random.mat'),'accuracy','features')
else
    save(fullfile(args.path.clsfres,'ERP_clsf.mat'),'accuracy','features')
end

disp('--> Classification finished')
%% plot feature frequency

% take average across repetitions and subjects
plotfeat = squeeze(mean(mean(features,1),2));
featsem = std(squeeze(mean(features,1)),[],1)'./sqrt(size(features,2));
timev = feat_time{1,1} + 0.048;

% plot relative feature frequency in bar plot with standard error of the
% mean
figure;
bar(timev, plotfeat);
hold on;
er = errorbar(timev, plotfeat, featsem, featsem);
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
xlabel('Time [s]');
ylabel('Relative frequency [a.u.]')

fx = squeeze(mean(features,1));
mfx = mean(plotfeat);

h = nan(1,size(fx,2));
p = nan(1,size(fx,2));
t = struct;
for tp = 1:size(fx,2)
    [h(tp),p(tp),~,t(tp)] = ttest(fx(:,tp),mfx,'tail','right');
end

hold on
scatter(timev(logical(h)),plotfeat(logical(h)) + featsem(logical(h)) + 0.005,'*k')
