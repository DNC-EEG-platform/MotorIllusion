%PREPROCESSING_SETTINGS - Sets configuration variables for part 2 'Preprocessing'
%
% Syntax:  Preprocessing_Settings()
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Note: Gets called automatically from Preprocessing_Run.m
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: paths.mat created by Set_paths.m
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

% add dependencies on relative path
pth = fullfile( fileparts(fileparts(mfilename('fullpath'))), '0 Dependencies' );
addpath(genpath(pth));

% automatically set paths via the paths.mat file
tmp = load('paths.mat');
args.path = tmp.path; 

% trigger values of events of interst
args.events = [90, 70];

% trial time before and after trigger event
args.trialspan = [-1.5, 3];

% spectral lowpass filter cutoff value in Hz
args.filter = 40;

% distance of neighbors for spatial filter
args.neighbordistance = 50; % in mm
