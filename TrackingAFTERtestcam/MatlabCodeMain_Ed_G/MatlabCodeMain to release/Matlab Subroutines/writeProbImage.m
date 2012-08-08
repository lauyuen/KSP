function r= writeProbImage(A,filename)

fid = fopen(filename,'w');
if (fid==0)
    r = 0;
    return;
end;

format = 1;
fwrite(fid,format,'int32');
x = size(A,2);
y = size(A,1);
fwrite(fid,x,'int32');
fwrite(fid,y,'int32');
A = A';
A = reshape(A,x*y,1);
fwrite(fid,A,'real*4');
fclose(fid);
