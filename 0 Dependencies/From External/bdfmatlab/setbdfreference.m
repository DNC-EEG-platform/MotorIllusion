function bdfstruct = setbdfreference(bdfstruct,type)
%SETBDFREFERENCE  Set the reference according to which data is returned
%   SETBDFREFERENCE(BDFST) set the reference to Common Average Reference.
%   Once the reference is set, all subsequent call to READBDFDATA returns
%   data on which the CAR is substracted.
%
%   SETBDFREFERENCE(BDFST,TYPE) specifies the type of reference that must
%   be used. TYPE must be a string that can take one of these values:
%       -'none'      : All reference previously specified is removed. This
%                      is the default reference.
%       -'DCremoval' : The continous component of each electrode is
%                      removed.
%       -'CommonAvg' : The common average of all electrodes is removed.
%                      Specifying 'CommonAvg' implies removing the
%                      continous component of each electrode beforehand.
%                      This is automatically done.
%
%   See also READBDFDATA, READBDFHEADER, GETBDFCHANNELS, GETBDFTRIGGER

ElectrodesCh = getbdfchannels(bdfstruct);

if(nargin<2)
    type = 'CommonAvg';
end

if ((strcmp(type,'DCremoval'))||(strcmp(type,'CommonAvg'))) && (bdfstruct.reftype ~= 1)
    fprintf('DC removal...\n');
    bdfstruct.reftype = 0;
    
    StatusCh = getbdfchannels(bdfstruct,{'Status'});
    
    NRec = bdfstruct.numberOfRecords;
    RecLength = bdfstruct.NumSamplesPerRecord;
    means = zeros(length(ElectrodesCh),NRec);
    weight = zeros(1,NRec);
    CMSmask = 2^20;
    for iRec=1:NRec
        limits = [(iRec-1)*RecLength+1;...
                    iRec*RecLength];
        CMSdata = bitand(readbdfdata(bdfstruct,limits,StatusCh),CMSmask);
        weight(iRec) = sum(CMSdata ~= 0)/RecLength;
        data = readbdfdata(bdfstruct,limits,ElectrodesCh);
        means(:,iRec) = weight(iRec)*mean( data(:,CMSdata ~= 0), 2);
    end

    
%     means = zeros(length(ElectrodesCh),bdfstruct.numberOfRecords);
%     for iRec=1:bdfstruct.numberOfRecords
%         limits = [(iRec-1)*bdfstruct.NumSamplesPerRecord+1;...
%                     iRec*bdfstruct.NumSamplesPerRecord];
%         means(:,iRec) = mean( readbdfdata(bdfstruct,limits,ElectrodesCh), 2);
%     end
    for iElec=ElectrodesCh'
        bdfstruct.Channel(iElec).DC = sum(means(iElec,:))/sum(weight);
    end
    clear means;
    bdfstruct.reftype = 1;
end

if(strcmp(type,'CommonAvg')) && (bdfstruct.reftype ~= 2)
    fprintf('Common average reference...\n');
    bdfstruct.ref = zeros(1,bdfstruct.NumSamplesPerRecord*bdfstruct.numberOfRecords);
    for iRec=1:bdfstruct.numberOfRecords
        limits = [(iRec-1)*bdfstruct.NumSamplesPerRecord+1;...
                    iRec*bdfstruct.NumSamplesPerRecord];
        bdfstruct.ref(limits(1):limits(2)) = mean( readbdfdata(bdfstruct,limits,ElectrodesCh), 1);
    end
    bdfstruct.reftype = 2;
elseif(strcmp(type,'none'))
    bdfstruct.reftype = 0;
    if(isfield(bdfstruct,'ref'))
        bdfstruct = rmfield(bdfstruct, 'ref');
    end
end
        
