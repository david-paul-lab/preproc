function split_bvalue_data(bvecfile,bvalfile,ecvolumes)

bvecs = importdata(bvecfile);
bvals = importdata(bvalfile);
ecvolumes = importdata(ecvolumes);
index = find(bvals <= 1000);

% write out text file with updated bvals
updated_bvals = bvals(index);
fid = fopen('b1000.bval','w+');
fprintf(fid,'%d ',updated_bvals);

% write out text file with updated bvecs
updated_bvecs = bvecs(:,index);
fid = fopen('b1000.bvec','w+');
for i = 1:size(updated_bvecs,1)
    fprintf(fid,'%-.6g',updated_bvecs(i,1));
    fprintf(fid,' %-.6g',updated_bvecs(i,2:end));
    fprintf(fid,'\n');
end

% write out text file with list of b=1000 volumes (with b=0 included)
bvals1000_volumes = ecvolumes(index);
fid = fopen('b1000volumes.txt','w+');
for i = 1:length(bvals1000_volumes)
    if i < length(bvals1000_volumes)
    fprintf(fid,'%s\n',bvals1000_volumes{i});
    else
    fprintf(fid,'%s',bvals1000_volumes{i});
    end
end
