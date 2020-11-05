function [channels,labels] = getbdfchannels(BDFst,str)
%GETBDFCHANNELS  get the indices of channels
%   CHANNELS = GETBDFCHANNELS(BDFST) returns in the vector CHANNELS the
%   indices of the channels corresponding to an electrod, ie it returns the
%   indices of all channels excepting those labelled 'Status'. CHANNELS can
%   be used directly in the function READBDFDATA.
%
%   BDFST must be a structure returned by the function READBDFHEADER
%   describing a bdf file.
%
%   CHANNELS = GETBDFCHANNELS(BDFST,STRINGCELLS) returns in CHANNELS the indices of
%   all channels with the labels corresponding to the cells of STRINGCELLS.
%   STRINGCELLS must be array of cells containing the desired labels
%
%   for example:
%       bdfst = readbdfheader('recording01.bdf');
%       channels = getbdfchannels(bdfst,{'Fp1','F3','AF3'});
%
%       channels =
%                   1
%                   4
%                   2
%
%   See also READBDFHEADER, READBDFDATA

if(nargin < 2)
    channels = [];
    for iChannel=1:BDFst.numberChannels
        if( ~strcmp(BDFst.Channel(iChannel).Label,'Status') && ~strncmp(BDFst.Channel(iChannel).Label,'EX',2) )
            channels = [channels;iChannel];
        end
    end
elseif ischar(str) && strcmp(str,'analog');
    channels = [];
    for iChannel=1:BDFst.numberChannels
        if( ~strcmp(BDFst.Channel(iChannel).Label,'Status') )
            channels = [channels;iChannel];
        end
    end
else
    channels = zeros(length(str),1);
    for i=1:length(str)
        for iChannel=1:BDFst.numberChannels
            if( strcmp(BDFst.Channel(iChannel).Label,str{i}) )
                channels(i) = iChannel;
                break;
            end
        end

        if(channels(i)==0)
            error('Electrode %s has not been found.\n',str{i});
        end
    end
end

if(nargout > 1)
    labels = cell(length(channels),1);
    for iChan = 1:length(channels)
        labels{iChan} = BDFst.Channel(channels(iChan)).Label;
    end
end

