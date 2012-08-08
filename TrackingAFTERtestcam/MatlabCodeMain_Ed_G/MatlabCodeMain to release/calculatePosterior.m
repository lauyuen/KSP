function [posterior,logLikeRatios,posteriorNoPriors, logLikeRatioAll]=calculatePosterior(distributionFilename,mdImage,bsImage,skImage,modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma,prior)
% loads in the raw data maps, integrates over given set of scales and
% assesses with model - produces maps givenHead and nonHead for all three
% modules - from these calculates posterior
% the output likelihoodRatios is a cell array containing the maps for each likelihood component
% modelsUsed is array returned by selectDetectorsGreedy, bestMDGamma etc. returned by find best gamma
%===================================================================

%if prior not passed then create
if (~exist('prior'))
    prior = 0.5*ones(size(mdImage));
end;

%loads distributions
%vars: bodyScales, faceScales, gammaVals, bsHeadDist, mdHeadDist,skHeadDist, bsNonHeadDist, mdNonHeadDist, skNonHeadDist
load(distributionFilename)
%loads fits to distributions
%vars: mixGaussMDHead, mixGaussMDNonHead, mixGaussBSHead, mixGaussBSNonHead, mixGaussSKHead, mixGaussSKNonHead
load([distributionFilename 'Fits']);

%count number of models present
nModel = size(modelsUsed,1);

%declare cell array for likelihood ratio images
logLikeRatios = cell(nModel,1);
%declare array for total log like ratio across all modules
logLikeRatioAll = zeros(size(mdImage));

%run through each model component
for (cModel =1:nModel)
    %find which model we are using 
    modelType = find(modelsUsed(cModel,:)>0);
    %switch depending on model
    switch(modelType)
        case 1         %motion differencing
            %get scale
            mdScale = round(exp(bodyScales(modelsUsed(cModel,modelType),:)));
            %get offset 
            mdOffset = -round(bodyOffsets(modelsUsed(cModel,modelType),:));
            %extract data
            headData = extractData(mdImage,mdScale,mdOffset,gammaVals(bestMDGamma));
            %transform data through non-linearity
            headData = log(headData+0.000000000000001);
            %extract models
            headModel = mixGaussMDHead{modelsUsed(cModel,modelType),bestMDGamma};
            nonHeadModel = mixGaussMDNonHead{modelsUsed(cModel,modelType),bestMDGamma};
            %add to legend
            logLikeRatios{cModel}.description = ['Motion ' sprintf('%d x %d',round(exp(bodyScales(modelsUsed(cModel,modelType),1))), round(exp(bodyScales(modelsUsed(cModel,modelType),2))))];
        case 2         %background subtraction
            %get scale
            bsScale = round(exp(bodyScales(modelsUsed(cModel,modelType),:)));
            %get offset 
            bsOffset = -round(bodyOffsets(modelsUsed(cModel,modelType),:));
            %extract data
            headData = extractData(bsImage,bsScale,bsOffset,gammaVals(bestBSGamma));
            %transform data through non-linearity
            headData = log(headData+0.00000000000001);       
            %extract models
            headModel = mixGaussBSHead{modelsUsed(cModel,modelType),bestBSGamma};
            nonHeadModel = mixGaussBSNonHead{modelsUsed(cModel,modelType),bestBSGamma};
            %add to legend
            logLikeRatios{cModel}.description= ['Foreground ' sprintf('%d x %d',round(exp(bodyScales(modelsUsed(cModel,modelType),1))), round(exp(bodyScales(modelsUsed(cModel,modelType),2))))];          
        case 3         %skin detection
            %get scale
            skScale = round(exp(faceScales(modelsUsed(cModel,modelType),:)));
            %get offset 
            skOffset = -round(faceOffsets(modelsUsed(cModel,modelType),:));
            %extract data
            headData = extractData(skImage,skScale,skOffset,gammaVals(bestSKGamma));
            %transform data through non-linearity
            minVal = min(headData(find(headData>0)));
            headData = max(minVal,headData).^(1/gammaVals(bestSKGamma));
            %extract models
            headModel = mixGaussSKHead{modelsUsed(cModel,modelType),bestSKGamma};
            nonHeadModel = mixGaussSKNonHead{modelsUsed(cModel,modelType),bestMDGamma};
            %add to legend
            logLikeRatios{cModel}.description = ['Skin ' sprintf('%d x %d',round(exp(faceScales(modelsUsed(cModel,modelType),1))), round(exp(faceScales(modelsUsed(cModel,modelType),2))))];            
    end;  %switch
 
    %extract log likelihood ratio
    thisRatio = getLogLikeRatio(reshape(headData,[],1),headModel,nonHeadModel);
    thisRatio = reshape(thisRatio,size(bsImage));
    %store log likelihood ratios
    logLikeRatios{cModel}.data = thisRatio;
    %total log log like ratio so far (used to calculate posterior)
    logLikeRatioAll = logLikeRatioAll+thisRatio;
end;  %cModel


posteriorNoPriors  = 1./(1+exp(-logLikeRatioAll));

logPriorRatio = log(prior+realmin)-log(1-prior);

%fprintf('Prior Variance: %f Data Variance: %f\n',var(logPriorRatio(:)),var(logLikeRatioAll(:)));
%fprintf('Prior Max-Min: %f Data Max-Min %f\n',max(logPriorRatio(:))-min(logPriorRatio(:)),max(logLikeRatioAll(:))-min(logLikeRatioAll(:)));



logLikeRatioAll = logLikeRatioAll+logPriorRatio;

%calculate posterior and display
posterior = 1./(1+exp(-logLikeRatioAll));


%=======================================================================

%raises map to the gamma and convolves with kernel
function data = extractData(imageIn,scale,offset,gamma);

%store size of image
[ySize xSize] = size(imageIn);
%raise image to power of gamma
imageIn = imageIn.^gamma;
%convolve image with rectangular kernel
imageIn = conv2(ones(1,scale(2)),ones(1,scale(1)),imageIn)/(scale(1)*scale(2));
%offset image by correct amount
imageIn = imageIn(offset(2)+1:end,offset(1)+1:end);
data = imageIn(1:ySize,1:xSize);


%=======================================================================

%returns likelihood ratio of being a head vs probability of being non head
function logLike = getLogLikeRatio(data,model1,model2);

prop = model1(1,:);
mu = model1(2,:);
sig = model1(3,:);

 

zf1=(data-mu(1))./sig(1);
zf2=(data-mu(2))./sig(2);
zf3=(data-mu(3))./sig(3);

p1 =   prop(1)*(1/(sqrt(2*3.1413*sig(1)*sig(1))))*exp(-0.5*zf1.*zf1);
p2 =   prop(2)*(1/(sqrt(2*3.1413*sig(2)*sig(2))))*exp(-0.5*zf2.^2);
p3 =   prop(3)*(1/(sqrt(2*3.1413*sig(3)*sig(3))))*exp(-0.5*zf3.^2);
pModel1 = p1+p2+p3+0.0000000000000000000001;   



prop = model2(1,:);
mu   = model2(2,:);
sig  = model2(3,:);


zb1=(data-mu(1))./sig(1);
zb2=(data-mu(2))./sig(2);
zb3=(data-mu(3))./sig(3);

p1 =   prop(1)*(1/(sqrt(2*3.1413*sig(1)*sig(1))))*exp(-0.5*zb1.^2);
p2 =   prop(2)*(1/(sqrt(2*3.1413*sig(2)*sig(2))))*exp(-0.5*zb2.^2);
p3 =   prop(3)*(1/(sqrt(2*3.1413*sig(3)*sig(3))))*exp(-0.5*zb3.^2);
pModel2 = p1+p2+p3+0.0000000000000000000001;


logLike = log(pModel1./pModel2);


