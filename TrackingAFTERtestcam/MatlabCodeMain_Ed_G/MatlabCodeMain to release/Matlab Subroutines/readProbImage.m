function  r= readProbImage(filename)
%reads in a probability image saved from C++

fid = fopen(filename);
if (fid==0)
    r = 0;
    return;
end;

format = fread(fid,1,'int32');
x = fread(fid,1,'int32');
y = fread(fid,1,'int32');

r = fread(fid,x*y,'real*4');

r = reshape(r,x,y);
r = r';

fclose(fid);
