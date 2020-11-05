% This script contains spectral filtering, epoching, artifact rejection and concatenation

% Vibramoov pilot
% Christoph Schneider
% CHUV, 2019
% -------------------------------------------------------------------------

%% Main function
function [] = Preprocessing_Main(args)
%PREPROCESSING_MAIN - Calls preprocessing steps from FieldTrip toolbox
% Specifically:
% - Lowpass filter
% - Epoch data 
% - Check for bad channels (user input required) and interpolate them
% - Concatenate epochs from different runs (= recording files)
% - Trial-wise artifact rejection (user input required)
% - Save preprocessed data in new location
%
% Syntax:  [] = Preprocessing_Main(args)
%
% Inputs:
%    args (struct) - arguments from Preprocessing_Run.m and Preprocessing_Settings.m
%
% Outputs:
%    none
%
% Example: 
%    [] = Preprocessing_Main(args);
%
% Other m-files required: Preprocessing_Settings.m
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

% load settings
Preprocessing_Settings();

% initialize variables
artifact = struct;
data_goodchans = cell(1,length(args.files));

% iterate across recording files
for f = 1:length(args.files)
    
    % extract subject, session and filename
    args.subject = args.files(f).name([4,5] + strfind(args.files(f).name,'sub-'));
    args.session = args.files(f).name([4,5] + strfind(args.files(f).name,'ses-'));
    args.eegfilename = fullfile(args.files(f).folder,args.files(f).name);
    
    
    %% load raw data
    cfg=[];
    cfg.dataset       = args.eegfilename;
    cfg.channel       = 'eeg';
    
    data_raw = ft_preprocessing(cfg);
    
    % carry structure is used to create separate artifact structure
    carry.endsample(f) = data_raw.sampleinfo(end);
    carry.endtime(f) = data_raw.time{1}(end);
    
    %% lowpass filtering of raw data

    cfg=[];
    cfg.continuous   = 'yes';
    cfg.channel       = 'eeg';
    cfg.padding       = 10;
    cfg.reref         = 'no';
    cfg.lpfilter      = 'yes';
    cfg.lpfreq        = args.filter;
    cfg.lpfiltord     = 4;
    cfg.lpfilttype    = 'but';
    cfg.lpfiltdir     = 'twopass';

    
    data_bpfiltered = ft_preprocessing(cfg,data_raw);
    
    
    %% create the trial definition and epoch data
    cfg=[];
    cfg.dataset             = args.eegfilename;
    cfg.trialdef.eventtype  = 'STATUS';
    cfg.trialdef.eventvalue = args.events;
    cfg.trialdef.prestim    = - args.trialspan(1);
    cfg.trialdef.poststim   = args.trialspan(2);
    
    cfg = ft_definetrial(cfg);
    
    trl = cfg.trl;
    carry.trialnum(f) = size(trl,1);
    
    cfg=[];
    cfg.trl = trl;
    cfg.padding = 1;
    
    data_epoched = ft_redefinetrial(cfg,data_bpfiltered);
    
    %% build neighbors structure (for channel interpolation below)
    cfg = [];
    cfg.channel       = data_raw.label;
    cfg.template      = 'elec1010_neighb.mat';
    cfg.elec          = 'standard_1005.elc';
    cfg.method        = 'distance';
    cfg.neighbourdist = args.neighbordistance;
    
    nb = ft_prepare_neighbours(cfg);
    
    
    %% manual bad channel check
    % Use to check for bad channels and interpolate them (see help for more information). 
    % Rejected trials won't be eliminated at this step!
    
    % WARNING! For this to work you have to add the following lines in the
    % ft_rejectvisual file of fieldtrip:
    % | cfg.rejchan = ~chansel;
    % | cfg.rejtrl = ~trlsel;
    % WARNING! Shadowing the ft_rejectvisual.m will trigger a conflict with
    % a private function.
    
    cfg = [];
    cfg.method = 'summary';
    cfg.keepchannel = 'repair';
    cfg.elec          = 'standard_1005.elc';
    cfg.neighbours  = nb;
    cfg.keeptrial   = 'yes';
    data_goodchans{f} = ft_rejectvisual(cfg, data_epoched);
    
    carry.artifactchans(f,:) = data_goodchans{f}.cfg.rejchan;
    
end

%% append runs
% change sample info and time because otherwise overlaps -> crashes
for f = 2:length(args.files)
    data_goodchans{f}.sampleinfo = data_goodchans{f}.sampleinfo + sum(carry.endsample(1:f-1));
end

data_concat = ft_appenddata(cfg,data_goodchans{:});

%% manual artifact rejection
% eliminate trials that are still artifact-ridden after channel fix
cfg = [];
cfg.method = 'summary';
cfg.keepchannel = 'repair';
cfg.elec          = 'standard_1005.elc';
cfg.neighbours  = nb;
cfg.keeptrial   = 'nan';
data_clean_tmp = ft_rejectvisual(cfg, data_concat);

% save artifact trial indices for artifact structure
artifact_concat.chan = data_clean_tmp.cfg.rejchan;
artifact_concat.trial = find(data_clean_tmp.cfg.rejtrl);

cfg = [];
cfg.method = 'trial';
data_clean = ft_rejectvisual(cfg, data_clean_tmp);


%% build artifact structure per run
for f = 1:length(args.files)
    artifact(f).chan = carry.artifactchans(f,:) | artifact_concat.chan;
    artifact(f).trial = artifact_concat.trial((sum(carry.trialnum(1:f-1)) < artifact_concat.trial)...
        & (artifact_concat.trial < sum(carry.trialnum(1:f))));
end

%% save preprocessed data and artifact structure
data_preprocessed = data_clean; %#ok<NASGU>
savefilename = fullfile(args.path.preproc,['sub-',args.subject,'_ses-',args.session,'_task-fps_preprocessed.mat']);
save(savefilename,'data_preprocessed','artifact');

end















