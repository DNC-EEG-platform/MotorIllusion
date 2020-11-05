function [trialavg, trials] = ERP_Main(args)
%ERP_MAIN - Extract timelocked data windows and averages for ERPs
% Specifically:
% - epoch to defined time window
% - baseline trials to pre-vibration interval
% - add information about percentage of rejected trials due to artifacts
%
% Syntax:  [] = ERP_Main(args)
%
% Inputs:
%    args (struct) - arguments from ERP_Run.m and ERP_Settings.m
%
% Outputs:
%    none
%
% Example: 
%    [] = ERP_Main(args);
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
% November 2020
%------------- BEGIN CODE --------------

%% load data

% loads it to the variable 'data_preprocessed'
load(args.filename);

%% compute percentages of rejected trials for illusion, control and combined
% 216 trials in total by protocol, 108 per condition

rejtrials.all = (1 - length(data_preprocessed.trialinfo)/216) * 100; %#ok<NODEF>
rejtrials.illu = (1 - sum(data_preprocessed.trialinfo==90)/108) * 100; 
rejtrials.ctrl = (1 - sum(data_preprocessed.trialinfo==70)/108) * 100;
rejchan = data_preprocessed.cfg.previous.rejchan;

%% spatial filtering

if strcmp(args.spatialfilter,'yes')
    cfg = [];
    cfg.method      = 'spline';
    cfg.elec        = 'standard_1005.elc';
    cfg.trials      = 'all';
    cfg.feedback    = 'no';
    data_preprocessed    = ft_scalpcurrentdensity(cfg, data_preprocessed);
end

%% extract timelocked trials and trial averages

% illusion trials
cfg = [];
cfg.trials = find(data_preprocessed.trialinfo==90);
cfg.channel = 'eeg';
cfg.removemean = 'yes';
trialavg.illusion = ft_timelockanalysis(cfg, data_preprocessed);
cfg.keeptrials = 'yes';
trials.illusion = ft_timelockanalysis(cfg, data_preprocessed);

% control trials
cfg = [];
cfg.channel = 'eeg';
cfg.removemean = 'yes';
cfg.trials = find(data_preprocessed.trialinfo==70);
trialavg.control = ft_timelockanalysis(cfg, data_preprocessed);
cfg.keeptrials = 'yes';
trials.control = ft_timelockanalysis(cfg, data_preprocessed);

%% baseline trials 

if strcmp(args.baseline,'yes')    
    cfg = [];
    cfg.baseline = args.baselinetime;
    cfg.channel = 'eeg';
    
    trialavg.illusion = ft_timelockbaseline(cfg, trialavg.illusion);
    trialavg.control = ft_timelockbaseline(cfg, trialavg.control);
    
    trials.illusion = ft_timelockbaseline(cfg, trials.illusion);
    trials.control = ft_timelockbaseline(cfg, trials.control);   
end

%% add extra info about artifacts

trials.rejtrials = rejtrials;
trials.rejchan = rejchan;

