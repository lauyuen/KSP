function r= fitCurvesToLikelihoodDists(likelihoodDistFileName);
%filename should not have .mat at the end
%reads in likelihood distributions and fits curves to the data
%saves parameters of curves in file
%even here, there may be a more recent version due to James which
%non-linearly transforms likelihood distributions.
%===========================================================

%loads bodyScales, faceScales, gammaVals, beHeadDist, mdHeadDist,skHeadDist, bsNonHeadDist, mdNonHeadDist, skNonHeadDist
load(likelihoodDistFileName); 

%plot all distribution
nScaleBody = length(bodyScales);
nScaleFace = length(faceScales);
nGamma = length(gammaVals);

%store information in cell arrays
mixGaussBSHead = cell(nScaleBody,nGamma);mixGaussBSNonHead = cell(nScaleBody,nGamma);
mixGaussMDHead = cell(nScaleBody,nGamma);mixGaussMDNonHead = cell(nScaleBody,nGamma);
mixGaussSKHead = cell(nScaleFace,nGamma);mixGaussSKNonHead = cell(nScaleFace,nGamma);

%Fit all distributions with mixture of Gaussians
for (cGamma = 1:nGamma)
     
    if ((cGamma==nGamma))
        keyboard;    
    end;
    %BACKGROUND SUBTRACTION
    
     hHead = figure; hNonHead = figure;
     for (cScale = 1:nScaleBody)     
       
         
         
         %extract distributions
         thisBSHeadDist = bsHeadDist{cScale,cGamma}; thisBSNonHeadDist = bsNonHeadDist{cScale,cGamma};
         %transform distributions
         goodPoints = find((thisBSNonHeadDist>exp(-30))&(thisBSHeadDist>exp(-30)));
         thisBSHeadDist = log(thisBSHeadDist(goodPoints));
         thisBSNonHeadDist=log(thisBSNonHeadDist(goodPoints));
         %find maximum value (needed for plotting);
         maxVal = max([max(thisBSHeadDist) max(thisBSNonHeadDist)]);
         %fit to background subtraction head distribution and  plot
         figure(hHead);  subplot(3,3,cScale);
         titleText =sprintf('BS Heads Scale %d, Gamma = %4.3f',cScale,gammaVals(cGamma));         
         mixGaussBSHead{cScale,cGamma}= fitAndPlot(thisBSHeadDist,cScale,bodyScales,titleText,maxVal);
         %fit to background subtraction non-head distribution
         figure(hNonHead);  subplot(3,3,cScale);
         titleText =sprintf('BS Non-Heads Scale %d, Gamma = %4.3f',cScale,gammaVals(cGamma));  
         mixGaussBSNonHead{cScale,cGamma} = fitAndPlot(thisBSNonHeadDist,cScale,bodyScales,titleText,maxVal);            
     end;
     
     %MOTION DIFFERENCING
    
     hHead = figure; hNonHead = figure;
     for (cScale = 1:nScaleBody)     
         %extract distributions
         thisMDHeadDist = mdHeadDist{cScale,cGamma}; thisMDNonHeadDist = mdNonHeadDist{cScale,cGamma};
         %transform distributions
         thisMDHeadDist = log(thisMDHeadDist+realmin);
         thisMDNonHeadDist=log(thisMDNonHeadDist+realmin);
         %find maximum value (needed for plotting);
         maxVal = max([max(thisMDHeadDist) max(thisMDNonHeadDist)]);
         %fit to background subtraction head distribution and  plot
         figure(hHead);  subplot(3,3,cScale);
         titleText =sprintf('MD Heads Scale %d, Gamma = %4.3f',cScale,gammaVals(cGamma));         
         mixGaussMDHead{cScale,cGamma}= fitAndPlot(thisMDHeadDist,cScale,bodyScales,titleText,maxVal);
         %fit to background subtraction non-head distribution
         figure(hNonHead);  subplot(3,3,cScale);
         titleText =sprintf('MD Non-Heads Scale %d, Gamma = %4.3f',cScale,gammaVals(cGamma));  
         mixGaussMDNonHead{cScale,cGamma} = fitAndPlot(thisMDNonHeadDist,cScale,bodyScales,titleText,maxVal);            
     end;
     
     %SKIN DETECTION
     
     hHead = figure; hNonHead = figure;
     for (cScale = 1:nScaleFace)     
         %extract distributions
         thisSKHeadDist = skHeadDist{cScale,cGamma}; thisSKNonHeadDist = skNonHeadDist{cScale,cGamma};
         %transform distributions
         minval=min(thisSKHeadDist(find(thisSKHeadDist>0)));
         thisSKHeadDist = max(minval,thisSKHeadDist).^(1/gammaVals(cGamma));
         minval=min(thisSKNonHeadDist(find(thisSKNonHeadDist>0)));
         thisSKNonHeadDist = max(minval,thisSKNonHeadDist).^(1/gammaVals(cGamma));
         %find maximum value (needed for plotting);
         maxVal = max([max(thisSKHeadDist) max(thisSKNonHeadDist)]);
         %fit to background subtraction head distribution and  plot
         figure(hHead);  subplot(3,3,cScale);
         titleText =sprintf('SK Heads Scale %d, Gamma = %4.3f',cScale,gammaVals(cGamma));         
         mixGaussSKHead{cScale,cGamma}= fitAndPlot(thisSKHeadDist,cScale,bodyScales,titleText,maxVal);
         %fit to background subtraction non-headdistribution
         figure(hNonHead);  subplot(3,3,cScale);
         titleText =sprintf('SK Non-Heads Scale %d, Gamma = %4.3f',cScale,gammaVals(cGamma));  
         mixGaussSKNonHead{cScale,cGamma} = fitAndPlot(thisSKNonHeadDist,cScale,bodyScales,titleText,maxVal);            
     end;
end;

distributionFilename = [likelihoodDistFileName 'Fits'];
save(distributionFilename,'mixGaussMDHead','mixGaussMDNonHead','mixGaussBSHead','mixGaussBSNonHead','mixGaussSKHead','mixGaussSKNonHead');
%the best gamma can be found using findBestGamma.m

%===============================================================

%subroutine to fit and plot distributions
function mixGaussDist = fitAndPlot(distribution,cScale,scaleSamples,titleText,maxVal)

%create histogram data from distribution
minVal = min(distribution);maxVal = max(distribution);
X = minVal:(maxVal-minVal)/150:maxVal;
N = hist(distribution,X);
%normalize values so we can plot CDF
N = N/length(distribution);N = N/(X(2)-X(1));
%plot histogram
bar(X,N);hold on;
title(titleText);
xlim([minVal maxVal]);

%fit mixture of gaussians
params = fit3Gauss(distribution,0);
prop = params(1,:);
mu = params(2,:);
sig = params(3,:);
p1 =   prop(1)*(1/(sqrt(2*3.1413*sig(1)*sig(1))))*exp(-0.5*(X-mu(1)).*(X-mu(1))/(sig(1)*sig(1)));
p2 =   prop(2)*(1/(sqrt(2*3.1413*sig(2)*sig(2))))*exp(-0.5*(X-mu(2)).*(X-mu(2))/(sig(2)*sig(2)));
p3 =   prop(3)*(1/(sqrt(2*3.1413*sig(3)*sig(3))))*exp(-0.5*(X-mu(3)).*(X-mu(3))/(sig(3)*sig(3)));
p = p1+p2+p3;
p = p/sum(p);
p = p/(X(2)-X(1));
%plot mixture of Gaussians
mixGaussDist = [prop;mu;sig];
plot(X,p,'g-');

