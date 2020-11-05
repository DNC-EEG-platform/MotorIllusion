%RESULTS_RUN - Display and plotting of classification results
% Plots combined classificatio results, displays averages and tests
%
% Syntax:  Results_Run()
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Notes:
%    Select classification outcome mat files in the UI, then click 'add' and 'done'.
%    To work properly, PSD and ERP classification must comprise of two mat
%    files: a) classification results and b) random permutation results
%
% Other m-files required: ???=????
% Subfunctions: none
% External files required: none
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
clc;
close all;

Results_Settings();

% select files to process
files = uipickfiles('Prompt','Select Folders','FilterSpec',args.path.clsfres);

%% sort files into groups

isrand = nan(1,numel(files));
label = cell(1,numel(files));
labelval = nan(1,numel(files));

for f = 1:size(files,2)
    if contains(files{f},'rand')
        isrand(f) = true;
    else
        isrand(f) = false;
    end
    [ filepath , name , ext ] = fileparts( files{f} );
    pos = strfind(name,'_');
    label{f} = name(1:pos-1);
    labelval(f) = prod(double(label{f}));
end

%% iterate across feature type

% initialize combined results struct
uql = unique(label);
s(length(uql)) = struct;

% iterate across different labels (PSD/ERP)
for lab = 1:numel(uql)
    
    usefiles = files(prod(double(uql{lab})) == labelval);
    usernd = isrand(prod(double(uql{lab})) == labelval);
    % extract classification and random permutation results
    for f = 1:2
        load(usefiles{f});
        if usernd(f)
            s(lab).rnd = round(mean(accuracy.testmean,3),2);
        else
            s(lab).clsf = round(mean(mean(accuracy.testmean,3),1),2);
            s(lab).foldclsf = accuracy.testmean;
        end
    end
    
    % use signrank test to see if classification is better than random
    for subj=1:length(s(lab).clsf)
        
        [p(lab,subj),H(lab,subj),~] = signrank(s(lab).rnd(:,subj), s(lab).clsf(subj),...
                                               'tail', 'left', 'alpha', 0.05); %#ok<SAGROW>
    end
    
end

%% plot results

Results_Plots(uql, s, H)

%% display result summary
for lab = 1:numel(uql)
    disp(['Average ',uql{lab},' classification accuray = ',num2str(round(mean(s(lab).clsf)*100)),...
        char(177),num2str(round(std(s(lab).clsf)*100)),'%'])
end