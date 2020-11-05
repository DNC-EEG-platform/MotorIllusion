function st = changelabels(st,ChannelList)
%CHANGELABELS   Modify the labels of some electrodes
%   CHANGELABELS(BDFST,CHANNELLIST) change the label of the channels in
%   BDFST according to the array of structure CHANNELLIST. Each element of
%   CHANNELLIST must contain the fields oldLabel and newLabel (each is a
%   string).
%
%   See also READCHANNELLIST, WRITEBDFHEADER
index = zeros(length(ChannelList),1);
for i = 1:length(ChannelList)
    index(i) = getbdfchannels(st,{ChannelList(i).oldLabel});
end
for i = 1:length(ChannelList)
    st.Channel(index(i)).Label = ChannelList(i).newLabel;
end


% % Read Header
% srcSt = readbdfheader(filename);
% 
% % Check that channels to be changed have no index superior to the number of
% % channels
% for i=1:numberChannels
%     if(ChannelList(i).index > srcSt.numberChannels)
%         error('Some index are greater than the number of channels');
%     end
% end
% 
% % Open file
% fidsrc = fopen(filename, 'r', 'l');
% if(fidsrc==-1)
%     error('error: can''t open file\n');
% end
% 
% 
% % Open destination file
% fiddest = fopen(newFilename, 'w', 'l');
% if(fiddest==-1)
%     error('error: can''t open file\n');
% end
% 
% Index = ones(1,numberChannels);
% for i=1:numberChannels
%     Index = ChannelList(i).index;
%     
% end
% 
% 
% % Copy header
% fwrite(fiddest, fread(fidsrc, 184, '*uchar'), 'uchar');
% fprintf(fiddest, '%-8u', (numberChannels+1)*256);
% fseek(fidsrc,8,'cof');
% fwrite(fiddest, fread(fidsrc, 60, '*uchar'), 'uchar');
% fprintf(fiddest, '%-4u', numberChannels);
% fseek(fidsrc,4,'cof');
% 
% % Channels header
% Label = zeros(numberChannels,16);
% TransducerType = zeros(numberChannels,80);
% Unit = zeros(numberChannels,8);
% PhysicalMin = zeros(numberChannels,8);
% PhysicalMax = zeros(numberChannels,8);
% DigitalMin = zeros(numberChannels,8);
% DigitalMax = zeros(numberChannels,8);
% Prefiltering = zeros(numberChannels,80);
% NumSamplesPerRecord = zeros(numberChannels,8);
% Reserved = zeros(numberChannels,32);
% 
% for i=1:numberChannels
%     iSrcChannel = ChannelList(i).index;
%     Label(i,:) = sprintf('%-16s',ChannelList(i).label);
%     TransducerType(i,:) = sprintf('%-80s',srcSt.Channel(iSrcChannel).TransducerType);
%     Unit(i,:) = sprintf('%-8s',srcSt.Channel(iSrcChannel).Unit);
%     PhysicalMin(i,:) = sprintf('%-8i',srcSt.Channel(iSrcChannel).PhysicalMin);
%     PhysicalMax(i,:) = sprintf('%-8i',srcSt.Channel(iSrcChannel).PhysicalMax);
%     DigitalMin(i,:) = sprintf('%-8i',srcSt.Channel(iSrcChannel).DigitalMin);
%     DigitalMax(i,:) = sprintf('%-8i',srcSt.Channel(iSrcChannel).DigitalMax);
%     Prefiltering(i,:) = sprintf('%-80s',srcSt.Channel(iSrcChannel).Prefiltering);
%     NumSamplesPerRecord(i,:) = sprintf('%-8u',srcSt.Channel(iSrcChannel).NumSamplesPerRecord);
%     Reserved(i,:) = sprintf('%-32s',srcSt.Channel(iSrcChannel).Reserved);
% end
% 
% fwrite(fiddest,Label','uchar');
% fwrite(fiddest,TransducerType','uchar');
% fwrite(fiddest,Unit','uchar');
% fwrite(fiddest,PhysicalMin','uchar');
% fwrite(fiddest,PhysicalMax','uchar');
% fwrite(fiddest,DigitalMin','uchar');
% fwrite(fiddest,DigitalMax','uchar');
% fwrite(fiddest,Prefiltering','uchar');
% fwrite(fiddest,NumSamplesPerRecord','uchar');
% fwrite(fiddest,Reserved','uchar');
% 
% % Copy data
% SrcChunkLength = srcSt.NumSamplesPerRecord*srcSt.numberChannels*3;
% SrcRecordLength = srcSt.NumSamplesPerRecord*3;
% srcHeaderSize = srcSt.headerSize;
% for iRecord = 0:srcSt.numberOfRecords-1
%     for i=1:numberChannels
%         iSrcChannel = ChannelList(i).index-1;
%         pos = srcHeaderSize + SrcChunkLength*iRecord + SrcRecordLength*iSrcChannel;
%         fseek(fidsrc, pos, 'bof');
%         fwrite(fiddest, fread(fidsrc, SrcRecordLength, '*uchar'), 'uchar');
%     end
% end
% 
% 
% fclose(fiddest);
% fclose(fidsrc);