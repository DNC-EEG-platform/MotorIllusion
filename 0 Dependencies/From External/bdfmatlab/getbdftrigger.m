function [iTrigger,trigger] = getbdftrigger(bdfst,pins,mode)
%GETBDFTRIGGER  Read trigger channel and return the edges
%   ITRIGGER = GETBDFTRIGGER(BDFST) returns in vector ITRIGGER the indices
%   of the rising edges on any trigger pin from 1 to 16.
%   
%   ITRIGGER = GETBDFTRIGGER(BDFST,PINS) returns the triggers only on the
%   trigger pins specified by the vector PINS.
%
%   ITRIGGER = GETBDFTRIGGER(BDFST,PINS,MODE) specifies the type of edges
%   that are requested. MODE is a string that accept two values, 'rising'
%   or 'falling'.
%
%   [ITRIGGER,TRIGGER] = GETBDFTRIGGER(...) returns the value of the pin
%   that originated the trigger. To any value of ITRIGGER corresponds a
%   value of TRIGGER which indicate on which pin the edge occurs.
%
%   See also READBDFDATA, READBDFHEADER, GETBDFCHANNELS, SETBDFREFERENCE

if(nargin < 3)
    mode = 'rising';
end

if( ~strcmp(mode,'rising') && ~strcmp(mode,'falling') )
    error('mode has illegal value');
end

bRising = false;
if(strcmp(mode,'rising'))
    bRising = true;
end

if(nargin < 2)
    pins = [1:16];
end

pins = reshape(pins,1,[]);

rawtrigger = readbdfdata(bdfst,0,{'Status'});

iTrig = [];
Trig = [];
for i=pins
    mask = 2^(i-1);
    maskedtrigger = bitand(rawtrigger,mask);
    if(bRising)
        ftrig = find(maskedtrigger(2:end)>maskedtrigger(1:end-1))+1;
    else
        ftrig = find(maskedtrigger(2:end)<maskedtrigger(1:end-1))+1;
    end
    iTrig = cat(2, iTrig, ftrig);
    Trig = cat(2, Trig, i*ones(1,length(ftrig)));
end

[iTrigger,iSorted] = sort(iTrig);
trigger = Trig(iSorted);
    

