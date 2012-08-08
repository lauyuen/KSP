function [mdOutMap,md] = motionDiff(im,md);
%function [mdOutMap,mdParams] = motionDiff(im,mdParams);
%implements motion differencing on a series of images
%im is a uint8 color image
%mdParams is  empty/ommitted for the first frame and should subsequently be passed back to the routine

%IF WE ARE LOOKING AT THE FIRST FRAME
if (~exist('md')|(isempty(md)))
    %store last frame
    md.lastFrame = double(im);
    %store size of image
    [md.imY md.imX dummy] = size(im);
    %return zeros
    mdOutMap = zeros(md.imY,md.imX);
%NOT THE FIRST FRAME
else
    %convert frame to double
    im = double(im);
    %find difference with previous frame
    diff = abs(im-md.lastFrame);
    %sum across color channels
    diff = sum(diff,3);
    %rescale to between zero and one
    mdOutMap = diff/(255*3);
    %store last frame
    md.lastFrame = im;
end;
