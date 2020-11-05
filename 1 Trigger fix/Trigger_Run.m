%TRIGGER_RUN - Fixes trigger channels on recorded EEG data
% Specifically, merges recorded binary trigger values with the trial
% information stored in the 'Sequences' folder
%
% Syntax:  Trigger_Run()
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Notes: 
%    Select subject folders in the UI, then click 'add' and 'done'.
%
% Other m-files required: Trigger_Settings.m, Trigger_Main.m
% Subfunctions: none
% External files required: sequences files
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
close all force;
clc;

% Load defaults
% -------------------------------------------------------------------------
Trigger_Settings()

% Select folders
% -------------------------------------------------------------------------
folders = uipickfiles('Prompt','Select Folders','FilterSpec',default.path.rawdata);

for sub = 1:size(folders,2)
    disp(['++++ Processing folder ',num2str(sub),' of ',num2str(size(folders,2)),' ++++']);
    
    % find sub-folders which correspond to sessions
    args.pathname = folders{sub};
    session = dir(fullfile(folders{sub},['*',default.sessionstring,'*']));
    
    % iterate over sessions
    for r = 1:size({session},2)
        
        sesname = {session.name}; sesname = sesname{r};
        % get list of eeg recording files in session folder
        eegfiles = dir(fullfile(folders{sub},session.name,'eeg','*.*df'));
        args.filenames = eegfiles;
        
        % call analysis function
        Trigger_Main(args);
        
    end
end

disp('---> Batch file processing end <---')