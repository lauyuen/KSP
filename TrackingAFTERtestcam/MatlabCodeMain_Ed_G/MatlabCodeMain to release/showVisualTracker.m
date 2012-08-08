function h = showVisualTrackerIJVC(visualTrackParams,posterior)
%displays results from visual tracker module
%examples of how to use are in extractFitSelectModelDemo and visualTrackerDemo
%===========================================================================================

imageMap = visualTrackParams.imageMap;
mdImage = visualTrackParams.mdRawMap;
bsImage = visualTrackParams.bsRawMap;
skImage = visualTrackParams.skRawMap;
likelihoodRatios = visualTrackParams.logLikeRatios;
priorSpatial = visualTrackParams.priorSpatial;
priorNovelty = visualTrackParams.priorNovelty;
priorTracking = visualTrackParams.priorTracking;
posteriorNoPriors = visualTrackParams.posteriorNoPriors;
priorAll = visualTrackParams.priorAll;
prevPosterior = visualTrackParams.prevPosterior;

   
bestPosn = find(posterior(:)==max(posterior(:)));
peakPosn = [floor(bestPosn/size(bsImage,1)) rem(bestPosn,size(bsImage,1))];
peakPosn = visualTrackParams.prevPosn;


%number of components
nComponents = length(likelihoodRatios);

%calculate max and min values for likelihood ratios
maxVal = max([max(likelihoodRatios{1}.data(:)) max(likelihoodRatios{2}.data(:)) max(likelihoodRatios{3}.data(:))]);
minVal = min([max(likelihoodRatios{1}.data(:)) min(likelihoodRatios{2}.data(:)) min(likelihoodRatios{3}.data(:))]);


 
subplot(4,2,1); hold off; %original frame
hold off;imagesc(imageMap); axis off;
hold on; plot(peakPosn(1),peakPosn(2),'r.');
title('Original Image');
subplot(4,2,2); hold off;%Combined log likelihood ratio
imagesc(likelihoodRatios{1}.data+likelihoodRatios{2}.data+likelihoodRatios{3}.data);axis off; colormap(gray);
title('Log Likelihood Ratio');
hold on; plot(peakPosn(1),peakPosn(2),'r.');

subplot(4,2,3); hold off;%Motion data for frame i
hold off;imagesc(mdImage,[0 1]); axis off; colormap(gray);
hold on; plot(peakPosn(1),peakPosn(2),'r.');
title('Motion Differencing Data');
subplot(4,2,4); hold off;%Motion log likelihood ratio data for frame i
imagesc(likelihoodRatios{3}.data,[minVal maxVal]); axis off; colormap(gray);
hold on; plot(peakPosn(1),peakPosn(2),'r.');
title(likelihoodRatios{3}.description);
subplot(4,2,5); hold off;%Fore ground data for frame i
hold off;imagesc(bsImage,[0 1]); axis off; colormap(gray);
hold on; plot(peakPosn(1),peakPosn(2),'r.');
title('Background Subtraction Data');
subplot(4,2,6); hold off;%Foreground log like ratio
imagesc(likelihoodRatios{1}.data,[minVal maxVal]); axis off; colormap(gray);
hold on; plot(peakPosn(1),peakPosn(2),'r.');
title(likelihoodRatios{1}.description);
subplot(4,2,7); hold off;%Skin data
hold off;imagesc(skImage,[0 1]); axis off; colormap(gray);
hold on; plot(peakPosn(1),peakPosn(2),'r.');
title('Skin Detection Data');
subplot(4,2,8); hold off;%Skin log like ratio
imagesc(likelihoodRatios{2}.data,[minVal maxVal]); axis off; colormap(gray);
hold on; plot(peakPosn(1),peakPosn(2),'r.');
title(likelihoodRatios{2}.description);

  
%  h2 = figure;
%  subplot(3,2,1);  %posterior for frame
% hold off;imagesc(prevPosterior); axis off; colormap(gray);
% hold on; plot(peakPosn(1),peakPosn(2),'r.');
% title('Previous Posterior Image');
% 
% subplot(3,2,2);  %prior for frame i+1 after motion
% hold off;imagesc(priorTracking); axis off; colormap(gray);
% hold on; plot(peakPosn(1),peakPosn(2),'r.');
% title('Tracking Component');
% 
% subplot(3,2,3);  %integration region for tracking (novelty);
% hold off;imagesc(priorNovelty); axis off; colormap(gray);
% hold on; plot(peakPosn(1),peakPosn(2),'r.');
% title('Integration region for tracking (novelty)');
% 
% subplot(3,2,4);  %Appearance Prior
% hold off;imagesc(priorSpatial); axis off; colormap(gray);
% hold on; plot(peakPosn(1),peakPosn(2),'r.');
% title('Spatial Prior');
% 
% subplot(3,2,5);  %Posterior over integration region(with hole)
% hold off;imagesc(priorNovelty.*prevPosterior); axis off; colormap(gray);
% hold on; plot(peakPosn(1),peakPosn(2),'r.');
% title('Posterior over integration region(with hole)');
% 
% subplot(3,2,6);  %Prior for frame i+1, including appearance prior
% hold off; imagesc(priorAll); axis off; colormap(gray);
% hold on; plot(peakPosn(1),peakPosn(2),'r.');
% title('All Priors');
% 
% 
% pause;
%  close(h2);
 subplot(4,2,2);