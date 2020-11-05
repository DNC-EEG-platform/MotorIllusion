% SET_PATHS - Sets local paths and creates folder structure
% Specifically creates:
% a) the path structure lookup table in the dependencies which is used by all the other scripts
% b) all the folders if not yet existing 
%
% Syntax:  Set_paths()
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% How-to: 
%    Change all fields in the 'path' variable below to match your local
%    folder structure. Then run this script.
%    Note: the folder specified in 'path.rawdata' and 'path.sequences' must 
%    exist  already and contain the raw data and stimulation sequences. 
%    All other folders will be created if they do not exist yet.
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

%% Path settings for the whole processing pipeline

% Path to the raw data files
path.rawdata = '/Users/christoph/Desktop/CHUV/Vibramoov/Data_Raw';

% Path to the Vibramoov sequence files (for trigger extraction)
path.sequences = '/Users/christoph/Desktop/CHUV/Vibramoov/Sequences';

% Path to the save directory after fixing triggers
path.data = '/Users/christoph/Desktop/CHUV/Vibramoov/Data_Fixed';

% Path to preprocessed data (after filtering, artifact removal)
path.preproc = '/Users/christoph/Desktop/CHUV/Vibramoov/Data_Preprocessed';

% Path to PSD data
path.psd = '/Users/christoph/Desktop/CHUV/Vibramoov/Data_PSD';

% Path to ERP data
path.erp = '/Users/christoph/Desktop/CHUV/Vibramoov/Data_ERP';

% Path to Classification Results
path.clsfres = '/Users/christoph/Desktop/CHUV/Vibramoov/Results';


% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%% check if folder in 'path.rawdata' exists

if exist(path.rawdata,'dir') ~= 7
    error('Specified raw data folder does not exist. Cancel path creation.');
end

%% check if other folders exist already; if not create them

fds = fields(path);

for k = 1:numel(fds)
    if exist(path.(fds{k}),'dir') ~= 7
        mkdir(path.(fds{k}));
    end
end

%% make path lookup table available to all functions

fn = fullfile( fileparts(mfilename('fullpath')), '0 Dependencies','Internal', 'paths.mat' );
save(fn,'path');

%% check if Fieldtrip is there
try
    ft_defaults
catch
    error('FieldTrip toolbox not installed or not on the Matlab path.')
end

disp('--> Paths set.')