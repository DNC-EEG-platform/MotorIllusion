function allocbdffile(st)
%ALLOCBDFFILE preallocation the file size
%   ALLOCBDFFILE(BDFST) create a blank bdf file of the required size
%   specified by BDFST. If the targeted file already exists, the existing
%   content is discarded.
%
%   See also WRITEBDFDATA, WRITEBDFHEADER
fid = fopen(st.filename,'w');

%filesize = st.headerSize + st.numberChannels*3*(st.numberOfRecords*st.NumSamplesPerRecord);

fwrite(fid, zeros(1,st.headerSize),'char');
for i = 1:st.numberOfRecords
    fwrite(fid, zeros(1,st.numberChannels*3*st.NumSamplesPerRecord),'char');
end

fclose(fid);