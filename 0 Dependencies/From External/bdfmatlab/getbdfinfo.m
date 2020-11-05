function res = getbdfinfo(filename, field)

bdfst = readbdfheader(filename);
if(~isfield(bdfst,field))
    error('This information is not available in the bdffile!\n');
end

res = getfield(bdfst,field);
    
