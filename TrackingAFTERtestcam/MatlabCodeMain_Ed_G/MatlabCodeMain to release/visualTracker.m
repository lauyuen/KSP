function [posterior, vt,  BckgndSubtrResult  ] = visualTracker(im,vt)
%function [posterior, vtParams] = visualTracker(image,vtParams)
%full implementation of visual tracker - example code on how to use this is in visualTrackerDemo.m
%===================================================================================================

% check to see if this is the first call
vtFieldnames = fieldnames(vt);
if (~sum(strcmp(vtFieldnames,'mdRawMap')))
    %first call - load in model details and initialize fields
    %set up structures for data modules
    vt.mdParams = [];
    vt.bsParams = [];
    %if didn't already pass something here then
    if(~sum(strcmp(vtFieldnames,'skParams')))
        vt.skParams =[];
    end;
    %load in model info
    modelFilename = [vt.modelBasename 'Model']
    load(modelFilename,'modelsUsed','bestMDGamma','bestBSGamma','bestSKGamma');
    %copy into structure
    vt.modelsUsed = modelsUsed;
    vt.mdBestGamma = bestMDGamma;
    vt.bsBestGamma = bestBSGamma;
    vt.skBestGamma = bestSKGamma;
    %put size of images into structure
    [vt.imY vt.imX vt.imZ] = size(im);
    %set previous position to centre of image
    vt.lastPosn = [vt.imX/2  vt.imY/2];
    vt.prevPosn = [vt.imX/2  vt.imY/2];
    %set prior maps to all ones
    vt.priorSpatial = vtPriorSpatial(vt.imX,vt.imY);
    vt.priorNovelty = 0.5*ones(vt.imY,vt.imX);
    vt.priorTracking = 0.5*ones(vt.imY,vt.imX);
    vt.priorAll = 0.5*ones(vt.imY,vt.imX);
    vt.posterior = (5/(vt.imY*vt.imX))*ones(vt.imY,vt.imX);
    %set flags for trcking and novelty to be on
    vt.doNoveltyFlag = 0;
    vt.doTrackingFlag = 0;
end;

%copyImage map
vt.imageMap = im;

%process motion differencing
%[vt.mdRawMap vt.mdParams] = motionPost(vt.imageMap,vt.mdParams);
%process background subtraction
[vt.bsRawMap vt.bsParams] = backSub(vt.imageMap,vt.bsParams);
%process skin detection
%[vt.skRawMap vt.skParams] = skinDet(vt.imageMap,vt.skParams);

%Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed
% Since we commented out skin and frame diferencing,
% avoid crash
vt.mdRawMap = 1 + 0 * vt.bsRawMap;
vt.skRawMap = 1 + 0 * vt.bsRawMap;
%Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed Ed


vt.priorSpatial = vtPriorSpatial(vt.imX,vt.imY);

vt.prevPosterior = vt.posterior;

%process novelty prior
if (vt.doNoveltyFlag)
    vt.priorNovelty = vtPriorNovelty(vt.lastPosn,vt.posterior,vt.bodyKernel);
else
    vt.priorNovelty =ones(size(vt.posterior));
end;

if (vt.doTrackingFlag)
    vt.priorTracking = vtPriorTracking(vt.prevPosterior.*vt.priorNovelty);
    vt.priorAll  = vt.priorTracking.*vt.priorSpatial ;
else
    vt.priorAll =  vt.priorNovelty.*vt.priorSpatial *6.73479/0.002452; %convert to represent total number in scene
    %vt.priorAll =  vt.priorNovelty.*vt.priorSpatial ; %convert to represent total number in scene
end;

%figure(100)
%imagesc(  vt.bsRawMap  )
%imagesc(  vt.mdRawMap  )
%imagesc(  vt.skRawMap  )

BckgndSubtrResult = vt.bsRawMap;
%BckgndSubtrResult = vt.mdRawMap;

%calculate posterior
[vt.posterior,vt.logLikeRatios,vt.posteriorNoPriors, vt.logLikeRatioAll]=calculatePosterior(vt.modelBasename,vt.mdRawMap,vt.bsRawMap,vt.skRawMap,vt.modelsUsed,vt.mdBestGamma,vt.bsBestGamma,vt.skBestGamma,vt.priorAll);

%find best position overall
bestPosn = find(vt.posterior(:)==max(vt.posterior(:)));
vt.prevPosn = vt.lastPosn;
vt.lastPosn = [floor(bestPosn/vt.imY) rem(bestPosn,vt.imY)];
posterior =vt.posterior;