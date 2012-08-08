%extractFitSelectModelDemo 
%example script for how to extract likelihood distributions from file forMonnet dataset
%the raw data files can be created using preprocessDemo

%clear all data and closes any open windows
clear all;
close all;

%get list of all data files - make list of BackSub files and replace
%part of filename for other modalities

filePath1 = 'D:/monnet/trioA1cam1/';
fileList1 = dir([filePath1 '*BackSub*.dat']); nFile1 = length(fileList1);
filePath2 = 'D:/monnet/trioA1cam2/';
fileList2 = dir([filePath2 '*BackSub*.dat']); nFile2 = length(fileList2);
filePath3 = 'D:/monnet/trioA1cam3/';
fileList3 = dir([filePath3 '*BackSub*.dat']); nFile3 = length(fileList3);
filePath4 = 'D:/monnet/trioA1cam4/';
fileList4 = dir([filePath4 '*BackSub*.dat']); nFile4 = length(fileList4);

%count total number of files
nFileTotal = nFile1+nFile2+nFile3+nFile4;

%create structure to hold all file names
fileList = cell(nFileTotal,1);

%compile complete list
for (cFile = 1:length(fileList1))
    fileList{cFile} = [filePath1 sprintf('testFile2BackSubH%d.dat',cFile)];
end;
for (cFile = 1:length(fileList2))
    fileList{cFile+nFile1} = [filePath2 sprintf('testFile2BackSubH%d.dat',cFile)];
end;
for (cFile = 1:length(fileList3))
    fileList{cFile+nFile1+nFile2} = [filePath3 sprintf('testFile2BackSubH%d.dat',cFile)];
end;
for (cFile = 1:length(fileList4))
    fileList{cFile+nFile1+nFile2+nFile3} = [filePath4 sprintf('testFile2BackSubH%d.dat',cFile)];
end;

%combine together all face and body positions in one file if not already done
if (~exist('D:/monnet/trioA1All.mat'))
    %load in face and body posns - contains fields %bodyPosnSize,facePosnSize,headCentre
    load('D:/monnet/trioA1Cam1');
    bodyPosnSizeAll = bodyPosnSize(1:nFile1); facePosnSizeAll = facePosnSize(1:nFile1); headCentreAll = headCentre(1:nFile1);
    load('D:/monnet/trioA1Cam2');
    bodyPosnSizeAll = [bodyPosnSizeAll bodyPosnSize(1:nFile2)];
    facePosnSizeAll = [facePosnSizeAll facePosnSize(1:nFile2)];
    headCentreAll = [headCentreAll headCentre(1:nFile2)];
    load('D:/monnet/trioA1Cam3');
    bodyPosnSizeAll = [bodyPosnSizeAll bodyPosnSize(1:nFile3)];
    facePosnSizeAll = [facePosnSizeAll facePosnSize(1:nFile3)];
    headCentreAll = [headCentreAll headCentre(1:nFile3)];
    load('D:/monnet/trioA1Cam4');
    bodyPosnSizeAll = [bodyPosnSizeAll bodyPosnSize(1:nFile4)];
    facePosnSizeAll = [facePosnSizeAll facePosnSize(1:nFile4)];
    headCentreAll = [headCentreAll headCentre(1:nFile4)];

    %save back to disk in one file
    headCentre = headCentreAll; bodyPosnSize = bodyPosnSizeAll; facePosnSize = facePosnSizeAll;
    save('D:/monnet/trioA1All','bodyPosnSize','facePosnSize','headCentre');
else;
    load('D:/monnet/trioA1All');
end;

%calculate scales of face and body posns
SAMPLE_N_BODY = 4; SAMPLE_N_FACE = 4;
[bodyScales faceScales bodyOffsets faceOffsets]=sampleScaleDistsCalcOffsets('D:/monnet/trioA1All',SAMPLE_N_BODY,SAMPLE_N_FACE); 

%define gamma values
gammaVals = exp(-2:0.5:2.0);

%RUN ANALYSIS FOR FACES ONLY

%if this flag is set then it only uses samples where face was clearly seen
onlyFacesFlag = 1;
%extract likelihood distributions
[mdHeadDist,mdNonHeadDist,bsHeadDist,bsNonHeadDist,skHeadDist,skNonHeadDist]=extractLikelihoodDistributions(...
    fileList,headCentre,facePosnSize,bodyScales,faceScales,faceOffsets,bodyOffsets,gammaVals,onlyFacesFlag);
save('D:/Monnet/trioA1AllFaceLikeDist','mdHeadDist','mdNonHeadDist','bsHeadDist','bsNonHeadDist','skHeadDist','skNonHeadDist','gammaVals','bodyScales','faceScales','faceOffsets','bodyOffsets');


%now use program "FitCurvesToLikelihoodDists"
FitCurvesToLikelihoodDists('D:/Monnet/trioA1AllFaceLikeDist');

%then find best gammas using 
[bestMDGamma,bestBSGamma,bestSKGamma] = findBestGamma('D:/Monnet/trioA1AllFaceLikeDist')

%then select detectors in the greedy case
modelsUsed = selectDetectorsGreedy('D:/Monnet/trioA1AllFaceLikeDist',bestMDGamma,bestBSGamma,bestSKGamma);
%or
%modelsUsed = selectDetectorsExhaustive('D:/Monnet/trioA1AllFaceLikeDist',bestMDGamma,bestBSGamma,bestSKGamma,3); 

%then look at ROC curves
makeROCPlot('D:/Monnet/trioA1AllFaceLikeDist',modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma);

%save all model parameters
modelFilename = ['D:/Monnet/trioA1AllFaceLikeDist' 'Model'];
save(modelFilename,'modelsUsed','bestMDGamma','bestBSGamma','bestSKGamma');

%take a given frame and calculate the posterior
imageMap =imread('D:/Monnet/duoA1Cam3/testFile2Image357.jpg','jpg');
mdImage = readProbImage('D:/Monnet/duoA1Cam3/testFile2MotionDiffH357.dat');
bsImage = readProbImage('D:/Monnet/duoA1Cam3/testFile2BackSubH357.dat');
skImage = readProbImage('D:/Monnet/duoA1Cam3/testFile2FaceDetH357.dat');
[posterior,logLikeRatios]=calculatePosterior('D:/Monnet/trioA1AllFaceLikeDist',mdImage,bsImage,skImage,modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma);

%display results from combined tracker (assuming null priors)
showVisualTracker(imageMap,mdImage,bsImage,skImage,logLikeRatios,posterior);

%load in the head position for this frame
load('D:/monnet/duoA1Cam3');headPosns = headCentre{357}/2;
%plot the posterior map with the likelihood ratios, peaks in map and real head positions
estPosns = analyzePosterior(posterior,headPosns);

%RUN ANALYSIS FOR ALL HEADS

%if this flag is set then it only uses samples where face was clearly seen
onlyFacesFlag = 0;
%extract likelihood distributions
[mdHeadDist,mdNonHeadDist,bsHeadDist,bsNonHeadDist,skHeadDist,skNonHeadDist]=extractLikelihoodDistributions(...
    fileList,headCentre,facePosnSize,bodyScales,faceScales,faceOffsets,bodyOffsets,gammaVals,onlyFacesFlag);
save('D:/Monnet/trioA1AllLikeDist','mdHeadDist','mdNonHeadDist','bsHeadDist','bsNonHeadDist','skHeadDist','skNonHeadDist','gammaVals','bodyScales','faceScales','faceOffsets','bodyOffsets');

%now use program "FitCurvesToLikelihoodDists"
FitCurvesToLikelihoodDists('D:/Monnet/trioA1AllLikeDist'); 

%then find best gammas using 
[bestMDGamma,bestBSGamma,bestSKGamma] = findBestGamma('D:/Monnet/trioA1AllLikeDist') 

%then select detectors in the greedy case
modelsUsed = selectDetectorsGreedy('D:/Monnet/trioA1AllLikeDist',bestMDGamma,bestBSGamma,bestSKGamma); 
%or select models exhaustively - using all combinations of 3 detectors in this case
%modelsUsed = selectDetectorsExhaustive('D:/Monnet/trioA1AllLikeDist',bestMDGamma,bestBSGamma,bestSKGamma,3); 

%then look at ROC curves
makeROCPlot('D:/Monnet/trioA1AllLikeDist',modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma); 

%save all model parameters
modelFilename = ['D:/Monnet/trioA1AllLikeDist' 'Model'];
save(modelFilename,'modelsUsed','bestMDGamma','bestBSGamma','bestSKGamma');

%take a given frame and calculate the posterior
imageMap= imread('D:/Monnet/duoA1Cam3/testFile2Image357.jpg','jpg');
mdImage = readProbImage('D:/Monnet/duoA1Cam3/testFile2MotionDiffH357.dat');
bsImage = readProbImage('D:/Monnet/duoA1Cam3/testFile2BackSubH357.dat');
skImage = readProbImage('D:/Monnet/duoA1Cam3/testFile2FaceDetH357.dat');

%calculate posterior
[posterior,logLikeRatios]=calculatePosterior('D:/Monnet/trioA1AllLikeDist',mdImage,bsImage,skImage,modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma);

%display results from combined tracker (assuming null priors)
showVisualTracker(imageMap,mdImage,bsImage,skImage,logLikeRatios,posterior);

%load in the head position for this frame
load('D:/monnet/duoA1Cam3');headPosns = headCentre{357}/2;
%plot the posterior map with the likelihood ratios, peaks in map and real head positions
estPosns = analyzePosterior(posterior,headPosns);



