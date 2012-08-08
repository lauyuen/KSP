function [likeRatioFore,likeRatioBack] = getLogLikelihood(foreData,foreModel,backData,backModel)

pFore = getMixGaussProb(foreModel,foreData)+realmin;
pBack = getMixGaussProb(backModel,foreData)+realmin;
logRatio= log(pFore./pBack);
likeRatioFore = logRatio;

pFore = getMixGaussProb(foreModel,backData)+realmin;
pBack = getMixGaussProb(backModel,backData)+realmin;
logRatio = log(pFore./pBack);
likeRatioBack = log(pFore./pBack);




 
