% RUN_ALL - Runs all analysis pipeline modules one after the other
% Specifically:
% 1) Fix triggers
% 2) Preprocess data and trigger manual artifact rejection
% 3) Time-frequency analysis (PSD)
% 4) Time-locked analysis (ERP)
% 5) Present and plot classification results
%
% Syntax:  Run_all()
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Notes: 
%    Set local paths first by changing variables in the 'Set_paths.m' file.
%    Single steps of the analysis pipeline can also be called inedependently.
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

clear;

%% change working directory to this file
cd(fileparts(mfilename('fullpath')));

%% Fix triggers
run('1 Trigger fix/Trigger_Run')

%% Preprocess data
run('2 Preprocessing/Preprocessing_Run')

%% Analyze Power spectral densities (PSD)
run('3 PSD/PSD_Run')

%% Analyze Event related potentials (ERP)
run('4 ERP/ERP_Run')

%% Display Classification results
run('5 Classification Results/Results_Run')