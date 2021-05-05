function [TFR] = PSD_Main(args)
%PSD_MAIN - Computes and saves power spectral densities (PSD)
% Specifically:
% - Baseline removal
% - Spatial filtering
% - PSD computation via wavelet analysis
% - Save PSDs in new location
%
% Syntax:  [] = PSD_Main(args)
%
% Inputs:
%    args (struct) - arguments from PSD_Run.m and PSD_Settings.m
%
% Outputs:
%    none
%
% Example: 
%    [] = PSD_Main(args);
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
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

%% load preprocessed data

fn = split(args.filename,filesep);
subjID = fn{end}(1:6);

loadfilename = fullfile(args.path.psd,[subjID,'_PSD.mat']);

if exist(loadfilename,'file') && strcmp(args.loadpsd,'yes')   % load PSDs from file and skip computation
    
    load(loadfilename,'TFR');
    
else  % compute PSDs

    load(args.filename); % loads data inside the variable 'data_preprocessed'
    
    %% baseline voltages
    
    if strcmp(args.baseline,'yes')
        cfg = [];
        cfg.baseline = args.baselinetime;
        cfg.channel = 'eeg';
        data_preprocessed = ft_timelockbaseline(cfg, data_preprocessed); %#ok<NODEF>
    end
    
    %% spatial filtering
    
    if strcmp(args.spatialfilter,'yes')
        cfg = [];
        cfg.method      = 'spline';
        cfg.elec        = 'standard_1005.elc';
        cfg.trials      = 'all';
        cfg.feedback    = 'no';
        data_preprocessed    = ft_scalpcurrentdensity(cfg, data_preprocessed);
    end
    
    %% compute PSD
    
    cfg             = [];
    cfg.output      = 'pow';
    cfg.channel     = 'all';
    cfg.method      = 'wavelet';
    cfg.width       = 7;
    cfg.pad         = 'nextpow2';
    cfg.foi         = 1:1:30;                       % analysis 1 to 30 Hz in steps of 1 Hz
    cfg.t_ftimwin   = ones(length(cfg.foi),1).*1;   % length of time window = 0.5 sec
    cfg.toi         = -1.5:0.05:3;                  % the time window "slides" from -0.5 to 1.5 in 0.05 sec steps
    
    % for illusion trials
    cfg.trials = find(data_preprocessed.trialinfo==90);
    TFR.illusion = ft_freqanalysis(cfg, data_preprocessed);
    
    % for control trials
    cfg.trials = find(data_preprocessed.trialinfo==70);
    TFR.control = ft_freqanalysis(cfg, data_preprocessed);
    
    %--- repeat computation but keep trials separate
    cfg.keeptrials = 'yes';
    cfg.trials = find(data_preprocessed.trialinfo==90);
    TFR.illusion_full = ft_freqanalysis(cfg, data_preprocessed);
    
    cfg.trials = find(data_preprocessed.trialinfo==70);
    TFR.control_full = ft_freqanalysis(cfg, data_preprocessed);
    
    % save PSD data
    filename = fullfile(args.path.psd,[subjID,'_PSD.mat']);
    save(filename,'TFR');
    
end

if args.logging
    TFR.illusion.powspctrm = log(TFR.illusion.powspctrm);
    TFR.control.powspctrm = log(TFR.control.powspctrm);
    TFR.illusion_full.powspctrm = log(TFR.illusion_full.powspctrm);
    TFR.control_full.powspctrm = log(TFR.control_full.powspctrm);
end
