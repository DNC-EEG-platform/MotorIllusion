function st = readbdfheader(filename)
%READBDFHEADER  read the header of a bdf file
%   BDFST = ReadBDFHeader(FILENAME) read the header of the bdf file
%   specified by FILENAME.
%
%   BDFST is a structure describing of the bdf file. This structure is
%   intended to be used by functions like READBDFDATA or GETBDFCHANNELS
%
%
%   See also READBDFDATA, GETBDFCHANNELS

if(~ischar(filename))
    error('The specified filename is invalid\n');
end

% Open file
fid = fopen(filename, 'r', 'l');
if(fid==-1)
    error('error: can''t open file');
end

% Check the format
codeini = fread(fid, 1, 'uchar');
identity = fread(fid, [1 7], '*char');
if((codeini~=255) || (~strcmp(identity,'BIOSEMI')))
	fclose(fid);
    error('bad format');
end

% Read global header
st.SubjectIdentification = fread(fid, [1 80], '*char');
st.RecordingIdentification = fread(fid, [1 80], '*char');
st.RecordingDate = fread(fid, [1 8], '*char');
st.RecordingTime = fread(fid, [1 8], '*char');
st.headerSize = str2num( fread(fid,[1 8],'*char'));
dataFormat = fread(fid, [1 44], '*char' );
st.numberOfRecords = str2num( fread(fid,[1 8],'*char') );
st.dataDuration = str2num( fread(fid,[1 8],'*char') );
st.numberChannels = str2num( fread(fid,[1 4],'*char') );
st.filename = filename;
st.numberElectrods = 0;
st.reftype = 0;


% Read headers for the channels
st.Channel = struct(...
    'Label', deblank(num2cell( fread(fid, [16 st.numberChannels], '*char')', 2 )),...
    'TransducerType', deblank(num2cell( fread(fid, [80 st.numberChannels], '*char')', 2 )),...
    'Unit', deblank(num2cell( fread(fid, [8 st.numberChannels], '*char')', 2 )),...
    'PhysicalMin', num2cell( str2num(fread(fid, [8 st.numberChannels], '*char')') ),...
    'PhysicalMax', num2cell( str2num(fread(fid, [8 st.numberChannels], '*char')') ),...
    'DigitalMin', num2cell( str2num(fread(fid, [8 st.numberChannels], '*char')') ),...
    'DigitalMax', num2cell( str2num(fread(fid, [8 st.numberChannels], '*char')') ),...
    'Prefiltering', deblank(num2cell( fread(fid, [80 st.numberChannels], '*char')', 2 )),...
    'NumSamplesPerRecord', num2cell( str2num(deblank(fread(fid, [8 st.numberChannels], '*char')')) ),...
    'Reserved', deblank(num2cell( fread(fid, [32 st.numberChannels], '*char')', 2 )),...
    'SamplingRate',1024 ...
    );

st.SamplingRate = st.Channel(1).NumSamplesPerRecord/st.dataDuration;
st.NumSamplesPerRecord = st.Channel(1).NumSamplesPerRecord;
st.LSBValue = (st.Channel(1).PhysicalMax - st.Channel(1).PhysicalMin) / (st.Channel(1).DigitalMax - st.Channel(1).DigitalMin);
for iChannel = 1:st.numberChannels
    if(strcmp(st.Channel(iChannel).Label,'Status') == false)
        st.numberElectrods = st.numberElectrods + 1;
    end
    st.Channel(iChannel).SamplingRate = st.Channel(iChannel).NumSamplesPerRecord/st.dataDuration;
    st.Channel(iChannel).LSBValue = (st.Channel(iChannel).PhysicalMax - st.Channel(iChannel).PhysicalMin) / (st.Channel(iChannel).DigitalMax - st.Channel(iChannel).DigitalMin);
    if(st.SamplingRate ~= st.Channel(iChannel).SamplingRate)
        warning('Channels have not the same sampling rate');
    end
end


% compute the number of records if unknown
if(st.numberOfRecords == -1)
    fseek(fid, 0, 'eof');
    FileSize = ftell(fid);
    RecordSize = 0;
    for iChannel = 1:st.numberChannels
        RecordSize = RecordSize + st.Channel(iChannel).NumSamplesPerRecord*3;
    end
    st.numberOfRecords = (FileSize - st.headerSize)/RecordSize;
end

fclose(fid);