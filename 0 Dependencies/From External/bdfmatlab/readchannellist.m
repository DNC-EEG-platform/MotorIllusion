function Channels = readchannellist(channelfilename)
%READCHANNELLIST create a structure array for changing the label
%   CHANNELLIST = READCHANNELLIST(FILENAME) return the structure array for
%   relabeling the channels of a bdf structure by reading the content of
%   FILENAME. Each line in this file must described a conversion according
%   to the following template:
%           OldLabel -> NewLabel
%
%   The structure array returned is intended to be used with CHANGELABELS
%
%
%   See also CHANGELABELS

fid = fopen(channelfilename, 'r');
 
Channels = struct('oldLabel',{},'newLabel',{});
iChannel = 1;
while 1
    tline = fgetl(fid);
    if(~ischar(tline)), break, end,
    if strcmp(deblank(tline),''), continue, end,
    
    Channels(iChannel).oldLabel = char(sscanf(tline,' %s -> %*s '));
    Channels(iChannel).newLabel = char(sscanf(tline,' %*s -> %s '));
    iChannel = iChannel+1;
end



fclose(fid);
