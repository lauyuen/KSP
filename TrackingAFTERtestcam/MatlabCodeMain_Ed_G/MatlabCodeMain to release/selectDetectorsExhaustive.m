function modelsUsed = selectDetectorsGreedy(distributionFilename,mdGammaIndex,bsGammaIndex,skGammaIndex,nLevels);
%Creates table in Figure 6 of WACV paper
%Contains greedy algorithm to add scales to increase area under ROC curve
%ROCAreaTableCum is a table with the cumulative area under the ROC curve in teh first column
%the second, third and fourth columns indicate the motion differencing, background subtraction and skin detection modules respectively
%=============================================================


%loads distributions
%vars: bodyScales, faceScales, gammaVals, bsHeadDist, mdHeadDist,skHeadDist, bsNonHeadDist, mdNonHeadDist, skNonHeadDist
load(distributionFilename)
%loads fits to distributions
%vars: mixGaussMDHead, mixGaussMDNonHead, mixGaussBSHead, mixGaussBSNonHead, mixGaussSKHead, mixGaussSKNonHead
load([distributionFilename 'Fits']);

%define number of sequential models to try
nModels = 7;

%initialize arrays to hold all data for a given gamma
mdHeadData = []; mdNonHeadData = [];
skHeadData = []; skNonHeadData = [];
bsHeadData = []; bsNonHeadData = [];

%initialize arrays to hold models for a given gamma
mdHeadModel = cell(length(bodyScales),1);mdNonHeadModel = cell(length(bodyScales),1);
bsHeadModel = cell(length(bodyScales),1);bsNonHeadModel = cell(length(bodyScales),1);
skHeadModel = cell(length(faceScales),1);skNonHeadModel = cell(length(faceScales),1);

%EXTRACT RELEVANT DATA AND DO NON-LINEAR TRANSFORM

%extract motion differencing data
for (cScale = 1:length(bodyScales))
    %extract head data
    thisMDData = mdHeadDist{cScale,mdGammaIndex}';
    %do non linear transform
    thisMDData = log(thisMDData+realmin);
  %store data
    mdHeadData = [mdHeadData;thisMDData]; 
    %extract non-head data
    thisMDData = mdNonHeadDist{cScale,mdGammaIndex}';
    %do non linear transform
    thisMDData = log(thisMDData+realmin);
    %store data
    mdNonHeadData = [mdNonHeadData;thisMDData];
    %extract models and store
    mdHeadModel{cScale} = mixGaussMDHead{cScale,mdGammaIndex};
    mdNonHeadModel{cScale} = mixGaussMDNonHead{cScale,mdGammaIndex};
end;

%extract skin detection data
for (cScale = 1:length(faceScales))
    %extract head data
    thisSKData = skHeadDist{cScale,skGammaIndex}';
    %do non linear transform
    minVal = min(thisSKData(find(thisSKData>0)));
    thisSKData = max(minVal,thisSKData).^(1/gammaVals(skGammaIndex));
    %store data
    skHeadData = [skHeadData;thisSKData];         
    %extract non-head data
    thisSKData = skNonHeadDist{cScale,skGammaIndex}';
    %do non linear transform
    minVal = min(thisSKData(find(thisSKData>0)));
    thisSKData = max(minVal,thisSKData).^(1/gammaVals(skGammaIndex));
    %store data
    skNonHeadData = [skNonHeadData;thisSKData];
    %extract and store models
    skHeadModel{cScale} = mixGaussSKHead{cScale,skGammaIndex};
    skNonHeadModel{cScale} = mixGaussSKNonHead{cScale,skGammaIndex};
end;

%extract background subtraction data
for (cScale = 1:length(bodyScales))
    %extract head data
    thisBSData = bsHeadDist{cScale,bsGammaIndex}';
    %do nonlinear transform
    thisBSData = thisBSData+(thisBSData<exp(-20)).*exp(-20);
    thisBSData = log(thisBSData);
    %store data
    bsHeadData = [bsHeadData;thisBSData];
    %extract non-head data
    thisBSData = bsNonHeadDist{cScale,bsGammaIndex}';
    %do non linear transform
    thisBSData = thisBSData+(thisBSData<exp(-20)).*exp(-20);
    thisBSData = log(thisBSData);
    %store data
    bsNonHeadData = [bsNonHeadData;thisBSData];
    %extract models and store
    bsHeadModel{cScale} = mixGaussBSHead{cScale,bsGammaIndex};
    bsNonHeadModel{cScale} = mixGaussBSNonHead{cScale,bsGammaIndex};
end;
    

bestROCArea = 0.5;
bestModel = [];
allModels = generateModels([length(bodyScales) length(bodyScales) length(faceScales)],nLevels);
nModels = length(allModels);

%fore each model added
for (cModel = 1:nModels)
    thisModel = allModels{cModel};
    [likeRatioMDHead, likeRatioMDNonHead]= getLikeData(mdHeadData,mdHeadModel,mdNonHeadData,mdNonHeadModel,thisModel(:,1));
    [likeRatioBSHead, likeRatioBSNonHead]= getLikeData(bsHeadData,bsHeadModel,bsNonHeadData,bsNonHeadModel,thisModel(:,2));
    [likeRatioSKHead, likeRatioSKNonHead]= getLikeData(skHeadData,skHeadModel,skNonHeadData,skNonHeadModel,thisModel(:,3));
    roc = buildRoc(likeRatioMDHead+likeRatioBSHead+likeRatioSKHead,likeRatioMDNonHead+likeRatioBSNonHead+likeRatioSKNonHead);
    ROCArea = rocArea(roc);
    if (ROCArea>bestROCArea)
        bestROCArea = ROCArea;
        fprintf('Best ROC Area So Far = %f\n',bestROCArea);
        bestModel = thisModel
    end;
end;    
    

%create Latex format table of models added
for (c1 = 1:size(bestModel,1))
    if (bestModel(c1,1)~=0)
        fprintf('Motion & %d x %d \\\\\n',round(exp(bodyScales(bestModel(c1,1),1))),round(exp(bodyScales(bestModel(c1,1),2)))) ;
    end
    if (bestModel(c1,2)~=0)
        fprintf('Foreground & %d x %d  \\\\\n',round(exp(bodyScales(bestModel(c1,2),1))),round(exp(bodyScales(bestModel(c1,2),2)))) ;
    end 
    if (bestModel(c1,3)~=0)
        fprintf('Skin & %d x %d  \\\\\n',round(exp(faceScales(bestModel(c1,3),1))),round(exp(faceScales(bestModel(c1,3),2)))) ;
    end
end;

%return best model
modelsUsed = bestModel;



%==========================================================================

%find the best likelihood for one of 3 models for each data points
function [likeRatioHead, likeRatioNonHead] = getLikeData(headData, headModels, nonHeadData, nonHeadModels, modelsUsed)

modelsUsed = modelsUsed(find(modelsUsed~=0));

nHeadData = length(headData(1,:));
nNonHeadData = length(nonHeadData(1,:));
likeRatioHead = zeros(1,nHeadData);
likeRatioNonHead = zeros(1,nNonHeadData);

for (cModel = 1:length(modelsUsed))
    pHead = getMixGaussProb(headModels{modelsUsed(cModel)},headData(modelsUsed(cModel),:))+realmin;
    pNonHead = getMixGaussProb(nonHeadModels{modelsUsed(cModel)},headData(modelsUsed(cModel),:))+realmin;
    likeRatioHead = likeRatioHead+ log(pHead./pNonHead);
    
    pHead = getMixGaussProb(headModels{modelsUsed(cModel)},nonHeadData(modelsUsed(cModel),:))+realmin;
    pNonHead = getMixGaussProb(nonHeadModels{modelsUsed(cModel)},nonHeadData(modelsUsed(cModel),:))+realmin;
    likeRatioNonHead = likeRatioNonHead+ log(pHead./pNonHead);
end;
 

 
%===========================================================

%evaluate the likekihood term for the mixture of Gaussians
function p = getMixGaussProb(params,X)
prop = params(1,:);
mu = params(2,:);
sig = params(3,:);
p1 =   prop(1)*(1/(sqrt(2*3.1413*sig(1)*sig(1))))*exp(-0.5*(X-mu(1)).*(X-mu(1))/(sig(1)*sig(1)));
p2 =   prop(2)*(1/(sqrt(2*3.1413*sig(2)*sig(2))))*exp(-0.5*(X-mu(2)).*(X-mu(2))/(sig(2)*sig(2)));
p3 =   prop(3)*(1/(sqrt(2*3.1413*sig(3)*sig(3))))*exp(-0.5*(X-mu(3)).*(X-mu(3))/(sig(3)*sig(3)));
p = p1+p2+p3;


%=============================================================

function models = generateModels(scales,nLevels)
%scales is a 1x3 matrix containing the number of MD, BS and SK scales respectively.
%nLevels is the number of allowable scales for each of MD BS and SK

%sum total number of models
totalModels = sum(scales(:));
%generate all combinations of models
modelsRaw = generateModelCombinations(totalModels,nLevels);
%convert models to format understood by rest of program;

models = cell(size(modelsRaw));
nModel = length(modelsRaw);

%for each model
for(cModel = 1:nModel)
    thisModelRaw = modelsRaw{cModel};
    thisModel = zeros(length(thisModelRaw),3);
    %for each model component
    for (cComponent = 1:length(thisModelRaw));
        index = thisModelRaw(cComponent);
        if(index<=scales(1))
            thisModel(cComponent,:) = [index 0 0 ];    
        elseif (index<=(scales(1)+scales(2)))
            thisModel(cComponent,:) = [0 index-scales(1) 0];
        else
            thisModel(cComponent,:) = [0 0 index-scales(1)-scales(2)];
        end;
    end;
    models{cModel} = thisModel;
end;
        

%==================================================================
function models=generateModelCombinations(nModels,nLevels)
%takes a number and generates a cell array containing all combinations of 1,2,3 and 4 and 5 models.



if (nLevels>6)
    disp('Too many levels - not implemented yet');
    return;
end;


totalModels = 0;

%generate single combinations
for (c1 = 1:nModels)
    %increment number of models
    totalModels = totalModels+1;
    %add one to this 
    models{totalModels} = c1;
end;

if(nLevels==1)
    return;
end;
    

%generate double combinations
for (c1 = 1:nModels-1)
    for(c2 = c1+1:nModels)
        %increment number of models
        totalModels = totalModels+1;
        %add one to this 
        models{totalModels} = [c1 c2];
    end;
end;

if(nLevels==2)
    return;
end;


%generate triple combinations
for (c1 = 1:nModels-2)
    for(c2 = (c1+1):nModels-1)
        for(c3 = (c2+1):nModels)
            %increment number of models
            totalModels = totalModels+1;
            %add one to this 
            models{totalModels} = [c1 c2 c3];
        end
    end;
end;

if(nLevels==3)
    return;
end;


%generate quadruple combinations
for (c1 = 1:nModels-3)
    for(c2 = (c1+1):nModels-2)
        for(c3 = (c2+1):nModels-1)
            for(c4 = (c3+1):nModels)
                %increment number of models
                totalModels = totalModels+1;
                %add one to this 
                models{totalModels} = [c1 c2 c3 c4];
            end;
        end
    end;
end;

if(nLevels==4)
    return;
end;

%generate quintuple combinations
for (c1 = 1:nModels-4)
    for(c2 = (c1+1):nModels-3)
        for(c3 = (c2+1):nModels-2)
            for(c4 = (c3+1):nModels-1)
                for(c5 = (c4+1):nModels)
                    %increment number of models
                    totalModels = totalModels+1;
                    %add one to this 
                    models{totalModels} = [c1 c2 c3 c4 c5];
                end;
            end;
        end
    end;
end;

if(nLevels==5)
    return;
end;

%generate quintuple combinations
for (c1 = 1:nModels-5)
    for(c2 = (c1+1):nModels-4)
        for(c3 = (c2+1):nModels-3)
            for(c4 = (c3+1):nModels-2)
                for(c5 = (c4+1):nModels-1)
                    for(c6= (c5+1):nModels)
                         %increment number of models
                         totalModels = totalModels+1;
                         %add one to this 
                         models{totalModels} = [c1 c2 c3 c4 c5 c6];
                    end;
                end;
            end;
        end
    end;
end;
