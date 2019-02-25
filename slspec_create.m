function slspec_create(filename)
fp = fopen(filename,'r'); % .json file from dcm2niix
fcont = fread(fp);
fclose(fp);
cfcont = char(fcont');
i1 = strfind(cfcont,'SliceTiming');
i2 = strfind(cfcont(i1:end),'[');
i3 = strfind(cfcont((i1+i2):end),']');
cslicetimes = cfcont((i1+i2+1):(i1+i2+i3-2));
slicetimes = textscan(cslicetimes,'%f','Delimiter',',');
[sortedslicetimes,sindx] = sort(slicetimes{1});
mb = length(sortedslicetimes)/(sum(diff(sortedslicetimes)~=0)+1);
slspec = reshape(sindx,[mb length(sindx)/mb])'-1;
dlmwrite('slspec.txt',slspec,'delimiter',' ','precision','%3d');
end
