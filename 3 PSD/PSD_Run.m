%PSD_RUN - Time-frequency batch analysis
% Computes power spectral density (PSD) values from preprocessed data,
% creates plots and performs classification.
%
% Syntax:  PSD_Run()
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
% Other m-files required: PSD_Settings.m, PSD_Main.m, PSD_Plots.m, Xval.m
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

% load settings
PSD_Settings();

% select files
files = uipickfiles('Prompt','Select Folders','FilterSpec',args.path.preproc);

%% load or compute PSD values

for sub = 1:size(files,2)
    disp(['++++ Processing file ',num2str(sub),' of ',num2str(size(files,2)),' ++++']);
    
    % extract file name and subject ID
    args.filename = files{sub};
    args.sub = sub;
    
    % call analysis function
    spect(sub) = PSD_Main(args); %#ok<SAGROW>
end

% establish general time line and spectral values for PSD samples
time = round( spect(1).illusion.time + 1, 2); % the +1 is because the used trigger is 1 second after vibration start
freqvec = spect(1).illusion.freq;

%% time-frequeny plots and topoplots

PSD_Plots(spect, time, freqvec)

%% Classification

disp('--> Start classification')
% iterate over subjects
for sub = 1:size(files,2)
    
    labels = cat(1, spect(sub).illusion_full.trialinfo, spect(sub).control_full.trialinfo);
    timevec = spect(sub).illusion_full.time + 1;
    
    % compute baseline values for illusion and control trials
    tri_bsl = repmat( nanmean(spect(sub).illusion_full.powspctrm(:,:,:,time<=0),4),...
        [1,1,1,length(time)]);
    trc_bsl = repmat( nanmean(spect(sub).control_full.powspctrm(:,:,:,time<=0),4),...
        [1,1,1,length(time)]);
    
    % compute ERD/ERS values
    tri = ( spect(sub).illusion_full.powspctrm -  tri_bsl )./...
        tri_bsl;
    trc = ( spect(sub).control_full.powspctrm -  trc_bsl )./...
        trc_bsl;
    trials = cat(1, tri, trc);
    
    % iterate over repetitions and call Xval function
    parfor rep = 1:default.xval.reps
        disp(['[ repetition ',num2str(rep),', subject ',num2str(sub),']'])
        [acc{rep,sub}, cvp{rep,sub}, feats{rep,sub}, feat_time{rep,sub}] = Xval(default, timevec, trials, labels, 'PSD');
    end
end

% reorganize accuracies and features in a matrix
features = nan(default.xval.reps, size(files,2), size(acc{1,1}.train,2));

for rep = 1:default.xval.reps
    for sub = 1:size(files,2)
        
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

% save 
if default.clsf.random
    save(fullfile(args.path.clsfres,'PSD_clsf_random.mat'),'accuracy')
else
    save(fullfile(args.path.clsfres,'PSD_clsf.mat'),'accuracy','features')
end

disp('--> Classification finished')
%% Plot classification feature distribution

% --- decompose feature vector into frequency x channel matrix
meanfeats = squeeze(mean(mean(features,1),2));
nch = numel(spect(1).illusion.label); % number of channels
nf = numel(meanfeats)/nch; % number of non-NaN frequency bins

fx = 1:length(meanfeats);
freqs = mod(fx,nf); 
freqs(freqs==0) = nf;
chans = floor((fx-1)./nf)+1;

fmat = nan(nf,nch);
for f = 1:nf
    for ch = 1:nch
        fmat(f,ch) = meanfeats((freqs==f) & (chans==ch));
    end
end


% --- Plot relative frequency of certain channel-frequency combination
% chosen during classification
figure;

subplot(1,3,1)
% color grid plot (channels x frequency band)
imagesc(fmat)
colormap(redblue)
caxis([-1,1]*max(max(fmat)))
xlabel('channels')
xticks(1:17)
ylabel('frequency [Hz]')
set(gca,'YDir','normal')
yticks(4:5:24);
yticklabels({'10','15','20','25','30'});
colorbar

subplot(1,3,2)
% bar plot across frequencies
bar(mean(fmat,2))
xticks(4:5:24);
xticklabels({'10','15','20','25','30'});
xlabel('frequency [Hz]')
ylabel('relative frequency')

subplot(1,3,3)
% topoplot across channels
cfg = [];
cfg.marker = 'on';
cfg.elec = 'standard_1020.elc';
tmpcfg = keepfields(cfg, {'layout', 'rows', 'columns', 'commentpos', 'scalepos', 'elec', 'grad', 'opto', 'showcallinfo'});

tmp = spect(1).illusion;
tmp.dimord = 'freq_chan';
tmp.freq = 1:24;
tmp.time = 1;
tmp = rmfield(tmp,'powspctrm');
tmp.powspctrm = fmat;

cfg.comment = 'no';
cfg.layout = ft_prepare_layout(tmpcfg, tmp);
cfg.layout.pos = cfg.layout.pos * 0.8;
cfg.colormap = colormap(redblue);
cfg.colorbar = 'South';

ft_topoplotTFR(cfg, tmp); title('Grand mu band average')
