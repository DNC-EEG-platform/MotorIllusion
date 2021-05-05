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
% May 2021
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
    tri_bsl = repmat( mean(spect(sub).illusion_full.powspctrm(:,:,:,time<=0),4,'omitnan'),...
        [1,1,1,length(time)]);
    trc_bsl = repmat( mean(spect(sub).control_full.powspctrm(:,:,:,time<=0),4,'omitnan'),...
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
features = nan(default.xval.reps, size(files,2), size(feats{1,1},2));

for rep = 1:default.xval.reps
    for sub = 1:size(files,2)
        
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

% save 
if default.clsf.random
    save(fullfile(args.path.clsfres,'PSD_clsf_random.mat'),'accuracy','features')
else
    save(fullfile(args.path.clsfres,'PSD_clsf.mat'),'accuracy','features')
end

disp('--> Classification finished')
%% Plot classification feature distribution

% --- decompose feature vector into frequency x channel matrix
meanfeats = squeeze(mean(mean(features,1),2));
nch = numel(spect(1).illusion.label); % number of channels
nbd = 3; % number of frequency bands
nt = numel(meanfeats)/nbd/nch; % number of time points

fx = 1:length(meanfeats);
timepoints = mod(fx,nt); 
timepoints(timepoints==0) = nt;
bands = mod( floor((fx-1)./nt)+1, nbd); 
bands(bands==0) = nbd;
chans = floor((fx-1)./(nbd * nt))+1;

fmat = nan(nt,nbd,nch);
for t = 1:nt
    for b = 1:nbd
        for ch = 1:nch
            fmat(t,b,ch) = meanfeats((bands==b) & (chans==ch) & (timepoints==t));
        end
    end
end


%% --- Plot relative frequency of certain channel-frequency combination

% Composite plot of relative feature choices during classification
figure;
tiledlayout(2,2, 'Padding', 'loose','TileSpacing','none');

nexttile(2)
cfg = [];
cfg.marker = 'on';
cfg.elec = 'standard_1020.elc';
tmpcfg = keepfields(cfg, {'layout', 'rows', 'columns', 'commentpos', 'scalepos', 'elec', 'grad', 'opto', 'showcallinfo'});

tmp = spect(1).illusion;
tmp.dimord = 'freq_chan';
tmp.freq = 1;
tmp.time = 1;
tmp = rmfield(tmp,'powspctrm');
tmp.powspctrm = squeeze(sum(mean(fmat,1),2))./3;

cfg.comment = 'no';
cfg.layout = ft_prepare_layout(tmpcfg, tmp);
cfg.layout.pos = cfg.layout.pos * 0.8;
red = gray;
red(:,1) = red(:,1).*0+1;
red = flipud(red);
colormap(red)
cfg.colorbar = 'EastOutside';
cfg.zlim = [0.0018, 0.0049];

ft_topoplotTFR(cfg, tmp); title('Channel feature choice')

nexttile(3)
plotmat = mean(fmat,3)';
imagesc(plotmat)
caxis([0.0018 0.0049])
colormap(red)
ylabel('frequency band')
yticks(1:3)
yticklabels({'Alpha','Low Beta','High Beta'});
xlabel('time periods [s]')
set(gca,'YDir','normal')
xticks(1:6);
xticklabels({'0 - 0.5 s','0.5 - 1 s','1 - 1.5 s','1.5 - 2 s','2 - 2.5 s','2.5 - 3 s'});

nexttile(1)
bar(mean(plotmat,1),'FaceColor',[0.7,0.8,1])
hold on;
h = errorbar(mean(plotmat,1),std(plotmat,[],1)/sqrt(size(plotmat,1)),'LineStyle','none','Color','k');
h.CapSize = 0;
xticks(1:6);
xticklabels({'0 - 0.5 s','0.5 - 1 s','1 - 1.5 s','1.5 - 2 s','2 - 2.5 s','2.5 - 3 s'});
yticklabels({'0.001','0.002','0.003','0.004','0.005'});
set(gca,'XAxisLocation','top');
xlim([0.5,6.5])

nexttile(4)
bar(mean(plotmat,2),'FaceColor',[0.7,0.8,1])
hold on;
h = errorbar(mean(plotmat,2),std(plotmat,[],2)/sqrt(size(plotmat,2)),'LineStyle','none','Color','k');
h.CapSize = 0;
xticks(1:3);
xticklabels({'alpha/mu','low beta','high beta'});
xlim([0.5,3.5])
set(gca,'XAxisLocation','top','YAxisLocation','right','xdir','reverse');
camroll(-90)

% -------------------------------------------------------------------------
% Topoplots of feature location per frequency band

figure;
subplot(1,3,1)
% topoplot across channels
cfg = [];
cfg.marker = 'on';
cfg.elec = 'standard_1020.elc';
tmpcfg = keepfields(cfg, {'layout', 'rows', 'columns', 'commentpos', 'scalepos', 'elec', 'grad', 'opto', 'showcallinfo'});

tmp = spect(1).illusion;
tmp.dimord = 'freq_chan';
tmp.freq = 1;
tmp.time = 1;
tmp = rmfield(tmp,'powspctrm');
tmp.powspctrm = squeeze(mean(fmat(:,1,:),1));

cfg.comment = 'no';
cfg.layout = ft_prepare_layout(tmpcfg, tmp);
cfg.layout.pos = cfg.layout.pos * 0.8;
cfg.colormap = colormap(redblue);
cfg.colorbar = 'South';
cfg.zlim = [0 1] * 10^(-2);

ft_topoplotTFR(cfg, tmp); title('Alpha band feature choice')

subplot(1,3,2)
% topoplot across channels
cfg = [];
cfg.marker = 'on';
cfg.elec = 'standard_1020.elc';
tmpcfg = keepfields(cfg, {'layout', 'rows', 'columns', 'commentpos', 'scalepos', 'elec', 'grad', 'opto', 'showcallinfo'});

tmp = spect(1).illusion;
tmp.dimord = 'freq_chan';
tmp.freq = 1;
tmp.time = 1;
tmp = rmfield(tmp,'powspctrm');
tmp.powspctrm = squeeze(mean(fmat(:,2,:),1));

cfg.comment = 'no';
cfg.layout = ft_prepare_layout(tmpcfg, tmp);
cfg.layout.pos = cfg.layout.pos * 0.8;
cfg.colormap = colormap(redblue);
cfg.colorbar = 'South';
cfg.zlim = [0 1] * 10^(-2);

ft_topoplotTFR(cfg, tmp); title('Low beta band feature choice')

subplot(1,3,3)
% topoplot across channels
cfg = [];
cfg.marker = 'on';
cfg.elec = 'standard_1020.elc';
tmpcfg = keepfields(cfg, {'layout', 'rows', 'columns', 'commentpos', 'scalepos', 'elec', 'grad', 'opto', 'showcallinfo'});

tmp = spect(1).illusion;
tmp.dimord = 'freq_chan';
tmp.freq = 1;
tmp.time = 1;
tmp = rmfield(tmp,'powspctrm');
tmp.powspctrm = squeeze(mean(fmat(:,3,:),1));

cfg.comment = 'no';
cfg.layout = ft_prepare_layout(tmpcfg, tmp);
cfg.layout.pos = cfg.layout.pos * 0.8;
cfg.colormap = colormap(redblue);
cfg.colorbar = 'South';
cfg.zlim = [0 1] * 10^(-2);

ft_topoplotTFR(cfg, tmp); title('High beta band feature choice')


