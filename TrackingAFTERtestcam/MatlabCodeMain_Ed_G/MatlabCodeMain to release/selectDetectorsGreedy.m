function modelsUsed = selectDetectorsGreedy(distributionFilename,mdGammaIndex,bsGammaIndex,skGammaIndex);
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
nModels = 10;

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
    

% RUN THROUGH EACH MODEL IN TURN AND SEE IF IT IMPROVES THE SITUATION

ROCAreaTableCum = zeros(nModels,4);          %table containing list of modules added so far and the cumulative area under the ROC curve 

%list of MD,SK,BS modules current used in total model
curMDScaleArray = [];curSKScaleArray = [];curBSScaleArray = [];

%storage for previous best log likelihood ratios
prevBestLikelihoodMDHead = zeros(1,length(mdHeadData));
prevBestLikelihoodMDNonHead = zeros(1,length(mdNonHeadData));
prevBestLikelihoodBSHead = zeros(1,length(bsHeadData));
prevBestLikelihoodBSNonHead = zeros(1,length(bsNonHeadData));
prevBestLikelihoodSKHead = zeros(1,length(skHeadData));
prevBestLikelihoodSKNonHead = zeros(1,length(skNonHeadData));

%fore each model added
for cModel = 1:nModels
    ROCAreaTable = zeros(length(bodyScales)*2+length(faceScales), 4);      %table where first column is ROC area and second third and fourth columns indicate which component was added
    cComponent = 1;                                                        %counter for which rown in the table we are in/ which component we are adding
    
    %TRY ADDING ALL POSSIBLE MODULES (INCLUDING REPEATS) STORE DATA IN ROC_AREA_TABLE
    
    %motion differencing
    for (cMDScale = 1:length(bodyScales))
        [bestLikeRatioMDHead, bestLikeRatioMDNonHead] = getLikeData(mdHeadData,mdHeadModel,mdNonHeadData,mdNonHeadModel,[curMDScaleArray cMDScale]);
        roc = buildRoc(bestLikeRatioMDHead + prevBestLikelihoodBSHead+prevBestLikelihoodSKHead, bestLikeRatioMDNonHead + prevBestLikelihoodSKNonHead + prevBestLikelihoodBSNonHead);
        ROCAreaTable(cComponent,1) = rocArea(roc);
        ROCAreaTable(cComponent,2) = cMDScale;
        ROCAreaTable(cComponent,3) = 0;
        ROCAreaTable(cComponent,4) = 0;
        cComponent = cComponent + 1;
    end;
    

    %background subtract
    for (cBSScale= 1:length(bodyScales))             
        [bestLikeRatioBSHead, bestLikeRatioBSNonHead] = getLikeData(bsHeadData,bsHeadModel,bsNonHeadData,bsNonHeadModel,[curBSScaleArray cBSScale]);
        roc = buildRoc(bestLikeRatioBSHead + prevBestLikelihoodSKHead+prevBestLikelihoodMDHead, bestLikeRatioBSNonHead + prevBestLikelihoodMDNonHead + prevBestLikelihoodSKNonHead);
        ROCAreaTable(cComponent,1) = rocArea(roc);
        ROCAreaTable(cComponent,2) = 0;
        ROCAreaTable(cComponent,3) = cBSScale;
        ROCAreaTable(cComponent,4) = 0;
        cComponent =  cComponent + 1;       
    end;
    
        %skin detection
    for (cSKScale = 1:length(faceScales))
        [bestLikeRatioSKHead, bestLikeRatioSKNonHead] = getLikeData(skHeadData,skHeadModel,skNonHeadData,skNonHeadModel,[curSKScaleArray cSKScale]);              
        roc = buildRoc(bestLikeRatioSKHead + prevBestLikelihoodBSHead+prevBestLikelihoodMDHead, bestLikeRatioSKNonHead + prevBestLikelihoodMDNonHead + prevBestLikelihoodBSNonHead);
        ROCAreaTable(cComponent,1) = rocArea(roc);
        ROCAreaTable(cComponent,2) = 0;
        ROCAreaTable(cComponent,3) = 0;
        ROCAreaTable(cComponent,4) = cSKScale;
        cComponent = cComponent + 1;   
    end


    %sort the table by the area under the ROC - best area is at top      
    ROCAreaTable = flipud(sortRows(ROCAreaTable))
    %display best module to screen
    fprintf(['Selecting: mdSc = ', num2str(ROCAreaTable(1, 2)), ', bsSc = ', num2str(ROCAreaTable(1,3)), ', skSc = ', num2str(ROCAreaTable(1,4)), '\n']);
    %add the best models to the total model
    ROCAreaTableCum(cModel,:) = ROCAreaTable(1,:);
    %if motion difference module was added
    if (ROCAreaTable(1,2))
        [bestLikeRatioMDHead, bestLikeRatioMDNonHead] = getLikeData(mdHeadData,mdHeadModel,mdNonHeadData,mdNonHeadModel,[curMDScaleArray ROCAreaTable(1,2)]);
        prevBestLikelihoodMDHead = bestLikeRatioMDHead;
        prevBestLikelihoodMDNonHead = bestLikeRatioMDNonHead;
    end; 
    %if background subtraction module was added
    if (ROCAreaTable(1,3))
        [bestLikeRatioBSHead, bestLikeRatioBSNonHead] = getLikeData(bsHeadData,bsHeadModel,bsNonHeadData,bsNonHeadModel,[curBSScaleArray ROCAreaTable(1,3)]);
        prevBestLikelihoodBSHead = bestLikeRatioBSHead;
        prevBestLikelihoodBSNonHead = bestLikeRatioBSNonHead;        
    end;
       %if skin detection module was added
    if (ROCAreaTable(1,4))
        [bestLikeRatioSKHead, bestLikeRatioSKNonHead] = getLikeData(skHeadData,skHeadModel,skNonHeadData,skNonHeadModel,[curSKScaleArray ROCAreaTable(1,4)]);
        prevBestLikelihoodSKHead = bestLikeRatioSKHead;
        prevBestLikelihoodSKNonHead = bestLikeRatioSKNonHead;        
    end;

    %update total list of motion differencing/ skin detection/ background subtraction
    curMDScaleArray = [curMDScaleArray ROCAreaTable(1, 2)];
    curBSScaleArray = [curBSScaleArray ROCAreaTable(1, 3)]; 
    curSKScaleArray = [curSKScaleArray ROCAreaTable(1, 4)];
end

%plot roc of all detectors 
roc = buildRoc(prevBestLikelihoodSKHead + prevBestLikelihoodBSHead+prevBestLikelihoodMDHead, prevBestLikelihoodSKNonHead + prevBestLikelihoodMDNonHead + prevBestLikelihoodBSNonHead);
figure;
plot(roc(:,2),roc(:,1),'r-');
xlim([0 1]); ylim([0 1]);


%plot graph of models added
figure;
plot(1:nModels,ROCAreaTableCum(:,1),'ro-');
xlabel('Model Number');
ylabel('Area under ROC');
xlim([0.5 7.5]);
ylim([0.8 1]);


%create Latex format table of models added
for (c1 = 1:nModels)
    if (ROCAreaTableCum(c1,2)~=0)
        fprintf('Motion & %d x %d & %f \\\\\n',round(exp(bodyScales(ROCAreaTableCum(c1,2),1))),round(exp(bodyScales(ROCAreaTableCum(c1,2),2))),ROCAreaTableCum(c1,1)) ;
    end
    if (ROCAreaTableCum(c1,3)~=0)
        fprintf('Foreground & %d x %d & %f \\\\\n',round(exp(bodyScales(ROCAreaTableCum(c1,3),1))),round(exp(bodyScales(ROCAreaTableCum(c1,3),2))),ROCAreaTableCum(c1,1)) ;
    end 
    if (ROCAreaTableCum(c1,4)~=0)
        fprintf('Skin & %d x %d & %f \\\\\n',round(exp(faceScales(ROCAreaTableCum(c1,4),1))),round(exp(faceScales(ROCAreaTableCum(c1,4),2))),ROCAreaTableCum(c1,1)) ;
    end
end;

%find best model

%use models up to best value
%bestModel = find(ROCAreaTableCum(:,1)==max(ROCAreaTableCum(:,1)));
%modelsUsed = ROCAreaTableCum(1:bestModel,2:4);


%create list of models that were successfully added for output
for (c1 = 1:nModels)
    %if adding this model made things worse then skip out
    if ((c1>1)&((ROCAreaTableCum(c1,1)-ROCAreaTableCum(c1-1,1))<0))
        break;
    end;
    modelsUsed(c1,1:3) = ROCAreaTableCum(c1,2:4);
end;


%==========================================================================

%find the best likelihood for one of 3 models for each data points
function [bestLikeRatioHead, bestLikeRatioNonHead] = getLikeData(foreData, foreModels, backData, backModels, scaleFlag)
% in this context "best" means "average"
nModels = length(foreModels);
% work with person data
logRatio = zeros(nModels,length(foreData));
for (cModel = 1:length(foreModels))
    pHead = getMixGaussProb(foreModels{cModel},foreData(cModel,:))+realmin;
    pNonHead = getMixGaussProb(backModels{cModel},foreData(cModel,:))+realmin;
    logRatio(cModel,:) = log(pHead./pNonHead);
end;

goodScales = find(scaleFlag>0);
bestLikeRatioHead = sum(logRatio(scaleFlag(goodScales),:),1);

% work with non-person data
logRatio = zeros(nModels,length(backData));
for (cModel = 1:length(backModels))
    pHead = getMixGaussProb(foreModels{cModel},backData(cModel,:))+realmin;
    pNonHead = getMixGaussProb(backModels{cModel},backData(cModel,:))+realmin;
    logRatio(cModel,:) = log(pHead./pNonHead);
end;

goodScales = find(scaleFlag>0);
bestLikeRatioNonHead = sum(logRatio(scaleFlag(goodScales),:),1);%/length(goodScales);

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
