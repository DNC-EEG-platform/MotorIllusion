function    label = readlabelfile(filename)

fid = fopen(filename);
label = fscanf(fid,'%i\n',inf);
fclose(fid);