function [skOutMap,sk] = skinDet(im,sk);
%function [skOutMap,skParams] = motionDiff(im,skParams);
%implements skin detection on a series of images
%im is a uint8 color image
%skParams is set to the name of the lookupTableFile for the first frame and should subsequently be passed back to the routine

DEFAULT_LUT = 'SkinDetTrainingDataMonnetLUT';

%if sk contains filename
if (exist('sk')&ischar(sk))
    %load in look up table
    filename = sk;
    load(sk);
    sk.postProb = postProb; clear postProb;
%sk contains no filename but is empty
elseif (~exist('sk')|isempty(sk))
    %load in default table
    load(defaultLUT);
    sk.postProb = postProb; clear postProb;
end;

%look up skin posterior
im = round((double(im)+1)/2);
%find index in table
index = im(:,:,1)+(im(:,:,2)-1)*128+(im(:,:,3)-1)*128*128;
%calculate posterior map
skOutMap = sk.postProb(index);
