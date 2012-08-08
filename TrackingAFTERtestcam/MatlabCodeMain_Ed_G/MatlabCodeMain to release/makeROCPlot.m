function r= makeROCPlot(distributionFilename,fitsName,modelsUsed,gammaMDIndex,gammaBSIndex,gammaSKIndex);
%makes ROC for the Head detection database % note - format has recently changed so you can load in test data with training fits!
%creates Figure 7a for paper
%modelsUsed is an n x 3 matrix.
%each row has one non-zero entry which corresponds to the scale used
%column of non-zero entry determines whether motion differencing,background subtraction or skin detection respectively
%=========================================================================

%loads distributions
%vars: bodyScales, faceScales, gammaVals, bsHeadDist, mdHeadDist,skHeadDist, bsNonHeadDist, mdNonHeadDist, skNonHeadDist
load(distributionFilename)
%loads fits to distributions
%vars: mixGaussMDHead, mixGaussMDNonHead, mixGaussBSHead, mixGaussBSNonHead, mixGaussSKHead, mixGaussSKNonHead
load(fitsName);

%establish number of models to be added
nModel = size(modelsUsed,1);
%count number of data points
nData = length(mdHeadDist{1,1});

%declare log likelihood arrays (initialize=0);
logLikeAllHead = zeros(nData,1);
logLikeAllNonHead = zeros(nData,1);

%create figure
figure;
legendText = cell(nModel,1);
plotStyles=['r- ';'b- ';'b: ';'b-.';'b: ';'m- ';'b: ';'r: ';'g- ';'k- ';'r- ';'b- ';'m- '];
plotColors=[1 0 0 ; 0 0 1; 1 0 1; 0.0 0.0 0.0 ; 0.7 0.7 1.0; 0.5 0 0; 0 0 0.5; 0 0.5 0.5; 0.5 0.5 0; 1 1 0];
plotLineWidths = [2;1;1;1;1;1;1;1;1;1;1];



%for each model
for (cModel = 1:nModel)
    %find which model we are using 
    modelType = find(modelsUsed(cModel,:)>0);
    %switch depending on model
    switch(modelType)
        case 1         %motion differencing
            %extract data
            headData = mdHeadDist{modelsUsed(cModel,modelType),gammaMDIndex};
            nonHeadData = mdNonHeadDist{modelsUsed(cModel,modelType),gammaMDIndex};
            %transform data through non-linearity
            headData = log(headData+realmin);
            nonHeadData = log(nonHeadData+realmin);
            %extract models
            headModel = mixGaussMDHead{modelsUsed(cModel,modelType),gammaMDIndex};
            nonHeadModel = mixGaussMDNonHead{modelsUsed(cModel,modelType),gammaMDIndex};
            %add to legend
            legendText{cModel} = ['Motion ' sprintf('%d x %d',round(exp(bodyScales(modelsUsed(cModel,modelType),1))), round(exp(bodyScales(modelsUsed(cModel,modelType),2))))];
        case 2         %background subtraction
            %extract data
            headData = bsHeadDist{modelsUsed(cModel,modelType),gammaBSIndex};
            nonHeadData = bsNonHeadDist{modelsUsed(cModel,modelType),gammaBSIndex};
            %transform data through non-linearity
            headData = headData+(headData<exp(-20)).*exp(-20);
            nonHeadData = nonHeadData+(nonHeadData<exp(-20)).*exp(-20);
            headData = log(headData);
            nonHeadData = log(nonHeadData);        
            %extract models
            headModel = mixGaussBSHead{modelsUsed(cModel,modelType),gammaBSIndex};
            nonHeadModel = mixGaussBSNonHead{modelsUsed(cModel,modelType),gammaBSIndex};
            legendText{cModel} = ['Foreground ' sprintf('%d x %d',round(exp(bodyScales(modelsUsed(cModel,modelType),1))), round(exp(bodyScales(modelsUsed(cModel,modelType),2))))];          
        case 3         %skin detection
            %extract data
            headData = skHeadDist{modelsUsed(cModel,modelType),gammaSKIndex};
            nonHeadData = skNonHeadDist{modelsUsed(cModel,modelType),gammaSKIndex};
            %transform data through non-linearity
            minVal = min(headData(find(headData>0)));
            headData = max(minVal,headData).^(1/gammaVals(gammaSKIndex));
            minVal = min(nonHeadData(find(nonHeadData>0)));
            nonHeadData = max(minVal,nonHeadData).^(1/gammaVals(gammaSKIndex));
            %extract models
            headModel = mixGaussSKHead{modelsUsed(cModel,modelType),gammaSKIndex};
            nonHeadModel = mixGaussSKNonHead{modelsUsed(cModel,modelType),gammaSKIndex};
            legendText{cModel} = ['Skin ' sprintf('%d x %d',round(exp(faceScales(modelsUsed(cModel,modelType),1))), round(exp(faceScales(modelsUsed(cModel,modelType),2))))];            
    end;
    [logLikeHead logLikeNonHead] = getLogLikelihood(headData,headModel,nonHeadData,nonHeadModel);
    logLikeAllHead = logLikeAllHead+logLikeHead;
    logLikeAllNonHead = logLikeAllNonHead+logLikeNonHead;
    
    %add this to figure;
    thisRoc = buildRoc(logLikeHead,logLikeNonHead);
    rocArea(thisRoc)
    
    %reserve the first plot style for the "all" graph so that it always looks the same
    plot(thisRoc(:,2),thisRoc(:,1),plotStyles(cModel+1,:),'Color',plotColors(cModel+1,:),'LineWidth',plotLineWidths(cModel+1)); hold on;
end;

%calculate ROC for whole detector and plot
totalRoc = buildRoc(logLikeAllHead,logLikeAllNonHead);
rocArea(totalRoc)
%plot the total ROC
plot(totalRoc(:,2),totalRoc(:,1),plotStyles(1,:),'Color',plotColors(1,:),'LineWidth',plotLineWidths(1));

%draw legend
legendText{nModel+1} = 'Combined';
legend(legendText,4);

%draw line along identity
%plot([0 1],[0 1],'k--');

%trimming for graph
xlabel('p(False Positive)');
ylabel('p(Hit)');
set(gca,'Box','Off');
set(gca,'Position',[0.13 0.15 0.775 0.815])
set(gcf,'PaperPosition',[0.25 2.5 4 3.5]);



%==================================================================

%return likelihood ratios
function [likeRatioFore,likeRatioBack] = getLogLikelihood(foreData,foreModel,backData,backModel)

pFore = getMixGaussProb(foreModel,foreData)+realmin;
pBack = getMixGaussProb(backModel,foreData)+realmin;
logRatio= log(pFore./pBack);
likeRatioFore = logRatio;

pFore = getMixGaussProb(foreModel,backData)+realmin;
pBack = getMixGaussProb(backModel,backData)+realmin;
logRatio = log(pFore./pBack);
likeRatioBack = log(pFore./pBack);


function p = getMixGaussProb(params,X)
prop = params(1,:);
mu = params(2,:);
sig = params(3,:);
p1 =   prop(1)*(1/(sqrt(2*3.1413*sig(1)*sig(1))))*exp(-0.5*(X-mu(1)).*(X-mu(1))/(sig(1)*sig(1)));
p2 =   prop(2)*(1/(sqrt(2*3.1413*sig(2)*sig(2))))*exp(-0.5*(X-mu(2)).*(X-mu(2))/(sig(2)*sig(2)));
p3 =   prop(3)*(1/(sqrt(2*3.1413*sig(3)*sig(3))))*exp(-0.5*(X-mu(3)).*(X-mu(3))/(sig(3)*sig(3)));
p = p1+p2+p3;


 
