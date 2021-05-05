function downsamplebdffile(stsrc,stdst,r)

if(~isstruct(stsrc))
    stsrc = readbdfheader(stsrc);
end

if(~isstruct(stdst))
    dstfilename = stdst; 
    stdst = stsrc;
    stdst.filename = dstfilename;

    NumSamplesPerRecord = stsrc.NumSamplesPerRecord/r;
    SamplingRate = NumSamplesPerRecord / stdst.dataDuration;
    stdst.NumSamplesPerRecord = NumSamplesPerRecord;
    stdst.SamplingRate = SamplingRate;

    for iChannel = 1:stdst.numberChannels
        stdst.Channel(iChannel).NumSamplesPerRecord = NumSamplesPerRecord;
        stdst.Channel(iChannel).SamplingRate = SamplingRate;
    end

    allocbdffile(stdst);		% Allocate the correct size for the bdf file described by stdst
    							% if the file pointed by stdst.filename already exists, its content is discarded
    writebdfheader(stdst);
end

% decimate analog channels
AnalogChannels = getbdfchannels(stsrc,'analog');
for iChannel = AnalogChannels'
    data = readbdfdata(stsrc,0,iChannel);
    writebdfdata(stdst,decimate(data,r),0,iChannel);
end

% downsample digital channels
iChannel = getbdfchannels(stsrc,{'Status'});
data = readbdfdata(stsrc,0,iChannel);
writebdfdata(stdst,downsample(data,r),0,iChannel);


