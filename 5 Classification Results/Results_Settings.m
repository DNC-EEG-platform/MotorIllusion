%RESULTS_SETTINGS - Sets configuration variables for part 5 'Classification Results'
%
% Syntax:  Results_Settings()
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Note: Gets called automatically from Results_Run.m
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

