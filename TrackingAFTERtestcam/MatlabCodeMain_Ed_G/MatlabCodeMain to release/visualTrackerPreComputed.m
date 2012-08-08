function vt = visualTracker(im,mdRaw,bsRaw,skRaw,vt)
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
    modelFilename = [vt.modelBasename 'Model'];
    load(modelFilename,'modelsUsed','bestMDGamma','bestBSGamma','bestSKGamma');
    %copy into structure
    vt.modelsUsed = modelsUsed;
    vt.mdBestGamma = bestMDGamma;
    vt.bsBestGamma = bestBSGamma;
    vt.skBestGamma = bestSKGamma;
    %put size of images into structure
    [vt.imY vt.imX vt.imZ] = size(im);
    %set previous position to centre of image
    vt.lastPosn = [vt.imX/2; vt.imY/2];
    %set prior maps to all ones
    vt.priorSpatial = vtPriorSpatial(vt.imX,vt.imY);
    vt.priorNovelty = 0.5*ones(vt.imY,vt.imX);
    vt.priorTracking = 0.5*ones(vt.imY,vt.imX);
    
    %set flags for trcking and novelty to be on
    vt.doNoveltyFlag = 1;
    vt.doTrackingFlag = 1;
end;

%copyImage map
vt.imageMap = im;

vt.mdRawMap = mdRaw;
vt.bsRawMap = bsRaw;
vt.skRawMap = skRaw;

%process novelty prior
if (vt.doNoveltyFlag)
    vt.priorNovelty = vtPriorNovelty(vt.lastPosn,vt.posterior);
else
    vt.priorNovelty = vt.posterior;
end;

if (vt.doTrackingFlag)
    vt.priorTracking = vtPriorTracking(vt.priorNovelty);
    vt.priorSpatial  = vt.priorTracking+vt.priorSpatial(vt.imX,vt.imY);
else
    vt.priorSpatial =  vt.priorSpatial(vt.imX,vt.imY)*6.73479/0.002452; %convert to represent total number in scene
end;

%calculate posterior
[vt.posterior,vt.logLikeRatios,vt.posteriorNoTrackNov]=calculatePosterior(vt.modelBasename,mdRaw,bsRaw,skRaw,vt.modelsUsed,vt.mdBestGamma,vt.bsBestGamma,vt.skBestGamma,vt.priorSpatial);
%find best position overall
bestPosn = find(vt.posterior(:)==max(vt.posterior(:)));
vt.lastPosn = [floor(bestPosn/vt.imY) rem(bestPosn,vt.imY)];