function [data,st] = readbdfdata(st,Limits,Channels)
%READBDFDATA  read the data of a BDF file
%   DATA = READBDFDATA(BDFST) read all the data of each channel of the bdf
%   file specified by BDFST structure.
%
%   BDFST must be a structure previously created by the READBDFHEADER
%   function.
%
%   DATA is an array whose each row contain the data of one channel of the
%   bdf file.
%
%   DATA = READBDFDATA(FILENAME) same as before but FILENAME will be
%   passed silently to READBDFHEADER and the returned structure will be
%   used. BE CAREFULL! If you use this alternative, no reference will be
%   computed. (As if SETBDFREFERENCE is called with TYPE=='none'))
%
%   DATA = READBDFDATA(...,LIMITS) read the data between LIMITS(1) and
%   LIMITS(2). LIMITS must be a vector of 2 elements or a scalar. LIMITS(1)
%   and LIMITS(2) must be indices of sample. If LIMITS is a scalar, it is
%   interpreted as:
%       - the lower limit if LIMITS >= 0
%       - the upper limit if LIMITS <= 0
%   As a consequence, if LIMITS == 0, all the samples are read.
%
%   DATA = READBDFDATA(...,LIMITS,CHANNELS) read the data of the channels
%   indexed by the vector CHANNELS. The rows of DATA will be ordered by the
%   order of the CHANNELS vector. CHANNELS can also be a cell array of
%   string containing the labels of the desired eletrodes. In that case,
%   the indices are obtained by passing the cell array to GETBDFCHANNELS.
%
%   [DATA,BDFST] = READBDFDATA(...) returns the structure used for reading
%   the data (useful if a filename is passed as first argument).
%
%   Example:
%               % Read the header of the BDF file
%               bdfst = readbdfheader('example.bdf');
%               bdfst = setbdfreference(bdfst,'CommonAvg');
%               
%               % Specify channels
%               DesiredChannels = {'FC1','F7','Oz'};
%               ChIndices = getbdfchannels(bdfst,DesiredChannels);
%               
%               % Specify the limits of the extracted signals
%               TimeLimits = [1.5 4.8]; % Time limits in seconds
%               Limits = round(TimeLimits*bdfst.SamplingRate);
%
%               % Read the data and plot them
%               data = readbdfdata(bdfst,Limits,ChIndices);
%               t = [Limits(1):Limits(2)]*bdfst.SamplingRate;
%               subplot(3,1,1)
%               plot(t,data(1,:));
%               subplot(3,1,2)
%               plot(t,data(2,:));
%               subplot(3,1,3)
%               plot(t,data(3,:));
%
%               
%   See also READBDFHEADER, GETBDFCHANNELS, SETBDFREFERENCE


if(~isstruct(st))
    st = readbdfheader(st);
end

if(nargin < 3)
    Channels = [1:st.numberChannels];
end

if( iscell(Channels) )
    Channels = getbdfchannels(st,Channels);
end

if(nargin < 2)
    Limits = 0;
end
if(length(Limits)==1) 
    if(Limits >= 0)
        Limits = [1+Limits;st.numberOfRecords*st.NumSamplesPerRecord];
    else
        Limits = [1;st.numberOfRecords*st.NumSamplesPerRecord+Limits];
    end
elseif( (Limits(1) < 1) || (Limits(2) > st.numberOfRecords*st.NumSamplesPerRecord) )
    error('The range of required samples is out of the BDF file (%s) limits',st.filename);
end

% Allocate size for channel data to be read
data = zeros(length(Channels),Limits(2)-Limits(1)+1);
Index = (1:length(Channels));
CurrPos = ones(length(Channels),1);
AnalogChann = ones(length(Channels),1);

% Compute scaling factors
ScalingValues = zeros(1,length(Channels));
for ind = Index
    ScalingValues(ind) = st.Channel(Channels(ind)).LSBValue;
end

for ind = Index
    AnalogChann(ind) = ~strncmp(st.Channel(Channels(ind)).Label,'Status',6);
end

fid = fopen(st.filename,'r');
fseek(fid, st.headerSize, 'bof');

% Read record;
iRecLim = ceil(Limits./st.NumSamplesPerRecord);
for iRec = iRecLim(1):iRecLim(2)
    for ind = Index
        iChannel = Channels(ind);
        
        % Select the position of beginning in the record
        offset = max(0, Limits(1) - (iRec-1)*st.NumSamplesPerRecord -1);
        startRecPos = (st.NumSamplesPerRecord*(st.numberChannels*(iRec-1) + iChannel-1) + offset)*3;
        fseek(fid, st.headerSize + startRecPos, 'bof');
        
        % Select the amount of data of the record that must be read
        %numSamples = min(st.NumSamplesPerRecord - offset, Limits(2) - (iRec-1)*st.NumSamplesPerRecord);
        numSamples = min(st.NumSamplesPerRecord - offset, Limits(2) - ((iRec-1)*st.NumSamplesPerRecord + offset) );
        
        % Read data
        %debugdata = fread(fid, [1 numSamples], 'bit24');
        if AnalogChann(ind)
            data(ind, CurrPos(ind) : CurrPos(ind) + numSamples-1) = fread(fid, [1 numSamples], 'bit24')*ScalingValues(ind);
        else
            data(ind, CurrPos(ind) : CurrPos(ind) + numSamples-1) = fread(fid, [1 numSamples], 'ubit24');
        end
        
        CurrPos(ind) = CurrPos(ind) + numSamples;
    end
end

% scale signals
ChannEEG = find(AnalogChann);
%data(ChannEEG,:) = data(ChannEEG,:) * 31.25e-9;
if(isfield(st,'reftype')&&(st.reftype >= 1))
    dc = zeros(length(ChannEEG),1);
    for iElec = ChannEEG'
        dc(iElec) = st.Channel(iElec).DC;
    end
    data(ChannEEG,:) = data(ChannEEG,:) - repmat(dc,1,Limits(2)-Limits(1)+1);
end
if(isfield(st,'reftype')&&(st.reftype == 2))
    data(ChannEEG,:) = data(ChannEEG,:) - repmat(st.ref(Limits(1):Limits(2)),length(ChannEEG),1);
end
%ChannTRI = find(CurrPos);
%data(ChannTRI,:) = data(ChannTRI,:) + 16777216;

fclose(fid);