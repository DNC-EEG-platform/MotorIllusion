function  [] = Trigger_Main(fileargs)
%TRIGGER_MAIN - Updates trigger channel to be useful for analysis
% Attaches additional trigger channels that use information from the
% pre-programmed sequences to have information about the stimulation
% frequencies. Saves updated .bdf files in new location.
%
% Syntax:  [] = Trigger_Main(fileargs)
%
% Inputs:
%    fileargs (struct) - paths and files defined in Trigger_Run.m
%
% Outputs:
%    none
%
% Example: 
%    [] = Trigger_Main(args);
%
% Other m-files required: Trigger_Settings.m
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

close all force;
clearvars -except fileargs;
disp('-------------------------------------------------------------------')

% Load defaults
Trigger_Settings()

% iterate over eeg raw recording files
for f = 1:size(fileargs.filenames,1)
    
    % extract filename from arguments
    eegfilenames = {fileargs.filenames.name};
    eegfilefolder = {fileargs.filenames.folder};
    eegfilenameX = eegfilenames{f};
    
    % load recording file header and eeg data
    eegheader = readbdfheader(fullfile(eegfilefolder{f},eegfilenameX));
    eegdata = readbdfdata(eegheader);
    trigger.orig = eegdata(17,:);   % trigger channel was on position 17
    
    % load predefined stimulation sequence for this recording
    eeg_run = str2double(eegfilenameX([4,5] + strfind(eegfilenameX,'run-')));
    seq = readtable(fullfile(default.path.sequences,['Protocol',num2str(eeg_run),'.txt']));
    vib0 = seq.x_Out5_;
    
    % find ratio of samples between the eeg recording and in the sequence file
    len.eegtrig = [find(trigger.orig>0, 1, 'first'), find(trigger.orig>0, 1, 'last')];
    len.seq = [find(vib0>0, 1, 'first'), find(vib0>0, 1, 'last')];
    factor = (len.eegtrig(2)-len.eegtrig(1))/(len.seq(2) - len.seq(1));
    
    % plot to see match of triggers with information from sequence file
    figure;
    plot(len.eegtrig(1):len.eegtrig(2),trigger.orig(len.eegtrig(1):len.eegtrig(2))>0);
    hold on;
    y = ((len.seq(1):len.seq(2))-1).*factor + len.eegtrig(1);
    vib0((length(y)+1):end) = [];
    plot(y,vib0>0);
    legend({'raw signal triggers', 'sequence file activations'});
    
    % initiate corresponding time vectors
    time = (1:length(trigger.orig)) ./ eegheader.SamplingRate;
    z = y./eegheader.SamplingRate;
    
    % find start of new trial (= vibration sequence)
    trialstarts = NaN(length(vib0),1);
    trialstarts(1) = 1;
    trialstarts(2:end) = diff(vib0>0)>0;
    % inscribe trigger value to trials from sequence file
    trialstarts(logical(trialstarts)) = vib0(logical(trialstarts));
    
    % find peaks in raw trigger channel
    [pks,idx] = findpeaks(vib0, 'MinPeakDistance',5, 'MinPeakHeight',40);
    
    % initialize trigger structure
    trigger.full = zeros(size(trigger.orig));
    trigger.start = zeros(size(trigger.orig));
    trigger.plateau = zeros(size(trigger.orig));
    
    % iterate over all samples and write trigger values from sequence file
    % into the trigger structure aligned with the eeg timeline.
    for t = 1:length(vib0)
        [~, indexOfMin] = min(abs(z(t)-time));
        trigger.full(indexOfMin) = vib0(t);
        trigger.start(indexOfMin) = trialstarts(t);
        trigger.plateau(indexOfMin) = trialstarts(t);
        % check if trigger value (= vibration frequency) reached trial
        % maximum
        if ismember(t,idx)
            trigger.plateau(indexOfMin) = pks(ismember(idx,t));
        end
    end
    
    
    %% update information + data and save in .bdf
    eegheader.numberChannels = 20;
    eegheader.Channel(18:20) = eegheader.Channel(17);
    eegheader.Channel(17).Label = 'TRIG1';  % original triggers
    eegheader.Channel(18).Label = 'TRIG2';  % full sequence triggers
    eegheader.Channel(19).Label = 'TRIG3';  % sequence start triggers
    eegheader.Channel(20).Label = 'STATUS'; % sequence plateau triggers
    
    % create file name for updated eeg file
    oldfilename = fullfile(eegfilefolder{f},eegfilenameX);
    newfilename = strrep(eegheader.filename,default.path.rawdata,default.path.data);
    eegheader.filename = newfilename;
    
    % overwrite attached trigger channels with structure from above
    eegdata(18:20,:) = cat(1,trigger.full,trigger.start,trigger.plateau);
    
    % make new directory and copy original file there
    mkdir(fileparts(newfilename))
    copyfile(oldfilename,newfilename)
    
    % update original file in new location
    writebdfdata(eegheader,eegdata);
    writebdfheader(eegheader);
    
end
end
