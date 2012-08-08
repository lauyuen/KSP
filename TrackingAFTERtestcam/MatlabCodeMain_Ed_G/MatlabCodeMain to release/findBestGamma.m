function [bestMDGammaIndex,bestBSGammaIndex,bestSKGammaIndex]= findBestGamma(distributionFilename)
%make WACV Figure 5 
%plots the area under the ROC curve as a function of the exponent, gamma
%===============================================

%loads distributions
%vars: bodyScales, faceScales, gammaVals, bsHeadDist, mdHeadDist,skHeadDist, bsNonHeadDist, mdNonHeadDist, skNonHeadDist
load(distributionFilename)
%loads fits to distributions
%vars: mixGaussMDHead, mixGaussMDNonHead, mixGaussBSHead, mixGaussBSNonHead, mixGaussSKHead, mixGaussSKNonHead
load([distributionFilename 'Fits']);

%create datastructure to hold results
MDROCArea = zeros(length(bodyScales),length(gammaVals));
BSROCArea = zeros(length(bodyScales),length(gammaVals));
SKROCArea = zeros(length(faceScales),length(gammaVals));

%BACKGROUND SUBTRACTION

%for each exponent value and scale
for (cGamma =1:length(gammaVals))
    for (cScale = 1:length(bodyScales))
        %extract data for this scale and gamma
        bsHeadData = bsHeadDist{cScale,cGamma};
        bsNonHeadData = bsNonHeadDist{cScale,cGamma};
        %non linearly transform data in same way as for fit
        bsHeadData = bsHeadData(find(bsHeadData>exp(-20)));
        bsHeadData = log(bsHeadData);
        bsNonHeadData = bsNonHeadData(find(bsNonHeadData>exp(-20)));
        bsNonHeadData = log(bsNonHeadData);        
        %extract model that goes with data
        bsHeadModel = mixGaussBSHead{cScale,cGamma};
        bsNonHeadModel = mixGaussBSNonHead{cScale,cGamma};
        %calculate the likelihoods
        [logLikeHead logLikeNonHead] = getLogLikelihood(bsHeadData,bsHeadModel,bsNonHeadData,bsNonHeadModel);
        %build ROC curve
        roc = buildRoc(logLikeHead,logLikeNonHead);   
        %measure area under ROC and store
        BSROCArea(cScale,cGamma) = rocArea(roc);
    end;
end;

%SKIN DETECTION
 
%for each exponent value and scale
for (cGamma =1:length(gammaVals))
    for (cScale = 1:length(faceScales))
        %extract data for this scale and gamma
        skHeadData = skHeadDist{cScale,cGamma};
        skNonHeadData = skNonHeadDist{cScale,cGamma};
        %non linearly transform data in same way as for fit
        minVal = min(skHeadData(find(skHeadData>0)));
        skHeadData = max(minVal,skHeadData).^(1/gammaVals(cGamma));
        minVal = min(skNonHeadData(find(skNonHeadData>0)));
        skNonHeadData = max(minVal,skNonHeadData).^(1/gammaVals(cGamma));
        %extract model that goes with data
        skHeadModel = mixGaussSKHead{cScale,cGamma};
        skNonHeadModel = mixGaussSKNonHead{cScale,cGamma};
        %calculate the likelihoods
        [logLikeHead logLikeNonHead] = getLogLikelihood(skHeadData,skHeadModel,skNonHeadData,skNonHeadModel);
        %build ROC curve
        roc = buildRoc(logLikeHead,logLikeNonHead);
        %measure area under ROC and store
        SKROCArea(cScale,cGamma) = rocArea(roc);
    end;
end;

%MOTION DIFFERENCING

%for each exponent value and scale
for (cGamma =1:length(gammaVals))
    for (cScale = 1:length(bodyScales))
        %extract data for this scale and gamma
        mdHeadData = mdHeadDist{cScale,cGamma};
        mdNonHeadData = mdNonHeadDist{cScale,cGamma};
        %non linearly transform data in same way as for fit
        mdHeadData = log(mdHeadData+realmin);
        mdNonHeadData = log(mdNonHeadData+realmin);        
        %extract model that goes with data
        mdHeadModel = mixGaussMDHead{cScale,cGamma};
        mdNonHeadModel = mixGaussMDNonHead{cScale,cGamma};
        %calculate the likelihoods
        [logLikeHead logLikeNonHead] = getLogLikelihood(mdHeadData,mdHeadModel,mdNonHeadData,mdNonHeadModel);
        %build ROC curve
        roc = buildRoc(logLikeHead,logLikeNonHead);
        %measure area under ROC and store
        MDROCArea(cScale,cGamma) = rocArea(roc);
    end;
end;

%PLOT FIGURES

figStyles=['r- ';'b--';'m: ';'g-.';'k.-';'m- ';'b: ';'r: ';'g- '];


%plot motion differencing results
figure;
legendString = cell(length(bodyScales),1);
for (c1 = 1:length(bodyScales))
    semilogx(gammaVals,MDROCArea(c1,:),figStyles(c1,:));hold on;  
    legendString{c1} = sprintf('%d x %d',round(exp(bodyScales(c1,1))), round(exp(bodyScales(c1,2))));
end;

title('Motion Differencing');
set(gca,'Box','Off');
ylabel('Area under ROC Curve');
xlabel('Exponent, \gamma');
legend(legendString,4);
xlim([0.1 10]);
ylim([0.5 1]);
set(gca,'Position',[0.13 0.15 0.775 0.815])
set(gcf,'PaperPosition',[0.25 2.5 4 3.0]);

%plot background subtract results
figure;
legendString = cell(length(bodyScales),1);
for (c1 = 1:length(bodyScales))
    semilogx(gammaVals,BSROCArea(c1,:),figStyles(c1,:));hold on;  
    legendString{c1} = sprintf('%d x %d',round(exp(bodyScales(c1,1))), round(exp(bodyScales(c1,2))));
end;

title('Background Subtraction');
set(gca,'Box','Off');
ylabel('Area under ROC Curve');
xlabel('Exponent, \gamma');
legend(legendString,4);
xlim([0.1 10]);
ylim([0.5 1]);
set(gca,'Position',[0.13 0.15 0.775 0.815])
set(gcf,'PaperPosition',[0.25 2.5 4 3.0]);

%plot background subtract results
figure;
legendString = cell(length(bodyScales),1);
for (c1 = 1:length(faceScales))
    semilogx(gammaVals,SKROCArea(c1,:),figStyles(c1,:));hold on;  
    legendString{c1} = sprintf('%d x %d',round(exp(faceScales(c1,1))), round(exp(faceScales(c1,2))));
end;

title('Skin Detection');
set(gca,'Box','Off');
ylabel('Area under ROC Curve');
xlabel('Exponent, \gamma');
legend(legendString,4);
xlim([0.1 10]);
ylim([0.5 1]);
set(gca,'Position',[0.13 0.15 0.775 0.815])
set(gcf,'PaperPosition',[0.25 2.5 4 3.0]);


%plot one patricular scale
figure;
semilogx(gammaVals,mean(MDROCArea),'b.:');hold on;  
semilogx(gammaVals,mean(BSROCArea),'r.-');hold on;
semilogx(gammaVals,mean(SKROCArea),'g.-.');hold on;

set(gca,'Box','Off');
ylabel('Area under ROC Curve');
xlabel('Exponent, \gamma');
legend('Motion','Foreground','Skin',4);
xlim([0.1 10]);
ylim([0.5 1]);
set(gca,'Position',[0.13 0.15 0.775 0.815])
set(gcf,'PaperPosition',[0.25 2.5 4 3.0]);
%print -depsc2 perfGamma


%extract best gamma averaged over all scales
meanMD = mean(MDROCArea); bestMDGammaIndex = find(meanMD==max(meanMD(:)));
meanBS = mean(BSROCArea); bestBSGammaIndex = find(meanBS==max(meanBS(:)));
meanSK = mean(SKROCArea); bestSKGammaIndex = find(meanSK==max(meanSK(:)));


%=====================================================================

%return likelihood ratios
function [likeRatioHead,likeRatioNonHead] = getLogLikelihood(headData,headModel,nonHeadData,nonHeadModel)

pHead = getMixGaussProb(headModel,headData)+realmin;
pNonHead = getMixGaussProb(nonHeadModel,headData)+realmin;
logRatio= log(pHead./pNonHead);
likeRatioHead = logRatio;

pHead = getMixGaussProb(headModel,nonHeadData)+realmin;
pNonHead = getMixGaussProb(nonHeadModel,nonHeadData)+realmin;
logRatio = log(pHead./pNonHead);
likeRatioNonHead = log(pHead./pNonHead);

%=====================================================================

function p = getMixGaussProb(params,X)
prop = params(1,:);
mu = params(2,:);
sig = params(3,:);
p1 =   prop(1)*(1/(sqrt(2*3.1413*sig(1)*sig(1))))*exp(-0.5*(X-mu(1)).*(X-mu(1))/(sig(1)*sig(1)));
p2 =   prop(2)*(1/(sqrt(2*3.1413*sig(2)*sig(2))))*exp(-0.5*(X-mu(2)).*(X-mu(2))/(sig(2)*sig(2)));
p3 =   prop(3)*(1/(sqrt(2*3.1413*sig(3)*sig(3))))*exp(-0.5*(X-mu(3)).*(X-mu(3))/(sig(3)*sig(3)));
p = p1+p2+p3;

 
