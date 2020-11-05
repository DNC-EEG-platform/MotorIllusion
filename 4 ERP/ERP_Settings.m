%ERP_SETTINGS - Sets configuration variables for part 4 'ERP'
%
% Syntax:  ERP_Settings()
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Note: Gets called automatically from ERP_Run.m
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

% toggle baselining the raw voltages and set time interval w.r.t the trigger
args.baseline = 'yes';
args.baselinetime = [-1.5 -1];

% toggle spatial filter on or off
args.spatialfilter = 'no';

% default settings for classification
default.events.values = [90 70]; % 82/90 = illusion/+plateau, 62/70 = non-illusion/+plateau
default.trial.time.pre = 2; % trial time in seconds before trigger
default.trial.time.post = 3; % trial time in seconds after trigger

% moving average filter lenght in seconds
default.movwinlen = 0.01;

default.xval.type = 'KFold';
default.xval.nouter = 10;
default.xval.ninner = 9;
default.clsf.method = 'lda';
default.xval.maxfeatures = 500;
default.xval.reps = 10;         % repetitions of full x-val procedure
default.clsf.random = false;    % use for creating random permutation models
