function writebdfdata(st,data,Limits,Channels)
%WRITEBDFDATA   Write some data on a bdf file
%   WRITEBDFDATA(BDFST,DATA) write the data specified by the matrix DATA on
%   the bdf file pointed by the structure BDFST. Each line of DATA is the
%   piece of data that must be written on a same channel. If the height of
%   DATA is smaller than the number of channels, only the first channels of
%   the bdf file are modified. If the width of DATA is smaller than the
%   length of the bdf file, only the first points of the file are modified.
%
%   If the targeted bdf file does not exist or has not the desired size, a
%   blank file must be preallocated by ALLOCBDFFILE before.
%
%   WRITEBDFDATA(BDFST,DATA,LIMITS) specified the indices between which the
%   data are modified. LIMITS must be an integer or a 2-element vector. If
%   it is a vector LIMITS(1) and LIMITS(2) determine the boundaries the
%   modified samples. If LIMITS is a scalar, it is interpreted as:
%       - the lower limit if LIMITS >= 0
%       - the upper limit if LIMITS <= 0
%   As a consequence, if LIMITS == 0, all the samples are written (default
%   behaviour).
%
%   WRITEBDFDATA(BDFST,DATA,LIMITS,CHANNELS) specifies the channels that
%   must be modified. CHANNELS can be either a vector of integers or a cell
%   array of string containing the labels of the desired electrodes. If
%   CHANNELS is a vector, it specifies the indices of the desired
%   electrodes.
%
%   See also WRITEBDFHEADER, ALLOCBDFFILE
if(~isstruct(st))
    error('The first argument is not a bdf structure!')
end

if(nargin < 4)
    if size(data,1) > st.numberChannels
        error('The height of data is bigger than the number of channels');
    end
    Channels = [1:size(data,1)];
end

if( iscell(Channels) )
    Channels = getbdfchannels(Channels);
end

if(nargin < 3)
    Limits = 0;
end
Limits = [1+Limits;size(data,2)];
if( (Limits(1) < 1) || (Limits(2) > st.numberOfRecords*st.NumSamplesPerRecord) )
    error('The range of required samples is out of the BDF file (%s) limits',st.filename);
end

% Preallocate arrays
Index = (1:length(Channels));
AnalogChann = ones(length(Channels),1);
ScalingValues = zeros(1,length(Channels));


% Compute scaling factors
for ind = Index
    ScalingValues(ind) = st.Channel(Channels(ind)).LSBValue;
end
for ind = Index
    AnalogChann(ind) = ~strncmp(st.Channel(Channels(ind)).Label,'Status',6);
end


% Undo removing reference from data
if(isfield(st,'reftype')&&(st.reftype >= 1))
    dc = zeros(length(ChannEEG),1);
    for iElec = ChannEEG'
        dc(iElec) = st.Channel(iElec).DC;
    end
    data(ChannEEG,:) = data(ChannEEG,:) + repmat(dc,1,Limits(2)-Limits(1)+1);
end
if(isfield(st,'reftype')&&(st.reftype == 2))
    data(ChannEEG,:) = data(ChannEEG,:) + repmat(st.ref(Limits(1):Limits(2)),length(ChannEEG),1);
end


fid = fopen(st.filename,'r+','l');
fseek(fid, st.headerSize, 'bof');
CurrPos = ones(length(Channels),1);

% Write record
iRecLim = ceil(Limits./st.NumSamplesPerRecord);
for iRec = iRecLim(1):iRecLim(2)
    for ind = Index
        iChannel = Channels(ind);
        
        % Select the position of beginning in the record
        offset = max(0, Limits(1) - (iRec-1)*st.NumSamplesPerRecord -1);
        startRecPos = (st.NumSamplesPerRecord*(st.numberChannels*(iRec-1) + iChannel-1) + offset)*3;
        fseek(fid, st.headerSize + startRecPos, 'bof');

        % Select the amount of data of the record that must be written
        numSamples = min(st.NumSamplesPerRecord - offset, Limits(2) - ((iRec-1)*st.NumSamplesPerRecord + offset) );
        
        % Write data
        datchunk = data(ind, CurrPos(ind) : CurrPos(ind) + numSamples-1);
        if AnalogChann(ind)
            fwrite(fid, round(datchunk/ScalingValues(ind)), 'bit24');
        else
            fwrite(fid, datchunk, 'ubit24');
        end
        
        CurrPos(ind) = CurrPos(ind) + numSamples;
    end
end

fclose(fid);