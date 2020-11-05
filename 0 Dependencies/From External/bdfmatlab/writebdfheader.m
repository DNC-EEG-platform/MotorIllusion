function writebdfheader(st)
%WRITEBDFHEADER  write the header of a bdf file
%   WRITEBDFHEADER(BDFST) write the header of the bdf file
%   pointed by the structure BDFST.
%
%   BDFST is a structure describing of the bdf file. This structure is
%   intended to be used by functions like WRITEBDFHEADER or GETBDFCHANNELS
%
%   If the targeted bdf file does not exist or has not the desired size, a
%   blank file must be preallocated by ALLOCBDFFILE before.
%
%
%   See also WRITEBDFDATA, ALLOCBDFFILE


% Open file
fid = fopen(st.filename, 'r+', 'l');
if(fid==-1)
    error('error: can''t open file\n');
end
fseek(fid,0,'bof');

% Write the format
fwrite(fid,255,'uint8');
fwrite(fid,'BIOSEMI','char');

% Write global header
fwrite(fid, st.SubjectIdentification, 'char');
fwrite(fid, st.RecordingIdentification, 'char');
fwrite(fid, st.RecordingDate, 'char');
fwrite(fid, st.RecordingTime, 'char');
fprintf(fid,'%-8u',st.headerSize);
fprintf(fid,'%-44s','24BIT');
fprintf(fid,'%-8u',st.numberOfRecords);
fprintf(fid,'%-8u',st.dataDuration);
fprintf(fid,'%-4u',st.numberChannels);


% Write headers for the channels
fprintf(fid,'%-16s',st.Channel(:).Label);
fprintf(fid,'%-80s',st.Channel(:).TransducerType);
fprintf(fid,'%-8s',st.Channel(:).Unit);
fprintf(fid,'%-8i',st.Channel(:).PhysicalMin);
fprintf(fid,'%-8i',st.Channel(:).PhysicalMax);
fprintf(fid,'%-8i',st.Channel(:).DigitalMin);
fprintf(fid,'%-8i',st.Channel(:).DigitalMax);
fprintf(fid,'%-80s',st.Channel(:).Prefiltering);
fprintf(fid,'%-8u',st.Channel(:).NumSamplesPerRecord);
fprintf(fid,'%-32s',st.Channel(:).Reserved);

fclose(fid);