%PREPROCESSING_RUN - Preprocessing and manual artifact rejection
% Does spectral filtering, data epoching, recording concatenation and
% artifact rejection
%
% Syntax:  Preprocessing_Run()
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
% Other m-files required: Preprocessing_Settings.m, Preprocessing_Main.m
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

close all;
clear;
clc;

%% Load .bdf files and call main function

Preprocessing_Settings();

% open UI to select folders to process
folders = uipickfiles('Prompt','Select Folders','FilterSpec',args.path.data);

for sub = 1:size(folders,2)
    disp(['++++ Processing folder ',num2str(sub),' of ',num2str(size(folders,2)),' ++++']);
    
    % find files in folder
    args.pathname = folders{sub};
    session = dir(fullfile(folders{sub},['*','ses','*']));
    
    % iterate over sessions
    for ses = 1:size({session.name},2)
        % find recording files
        sesname = {session.name}; sesname = sesname{ses};
        args.files = dir(fullfile(folders{sub},session.name,'eeg','*.*df'));
        
        % call analysis function
        Preprocessing_Main(args);
        
    end
end






