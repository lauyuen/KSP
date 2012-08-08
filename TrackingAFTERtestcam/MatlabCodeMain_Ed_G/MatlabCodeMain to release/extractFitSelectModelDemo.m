%extractFitSelectModelDemo 
%example script for how to extract likelihood distributions from file for lab training dataset
%the raw data files can be created using preprocessDemo

%clear all data and closes any open windows
clear all;
close all;

%get list of all data files - make list of BackSub files and replace
%part of filename for other modalities
filePath = 'D:/DatabaseTrain/positive/';
fileList = dir([filePath '*BackSub*.dat']); 
nFile = length(fileList);

%create structure to hold all file names
fileListTrain = cell(nFile,1);
%compile complete list
for (cFile = 1:length(fileList))
    fileListTrain{cFile} = [filePath sprintf('testFileBackSubH%d.dat',cFile-1)];  %not that the files start with index zero so we must subtract one - this is different from teh monnet set.
end;

filePath = 'D:/DatabaseTest/';
fileList = dir([filePath '*BackSub*.dat']); 
nFile = length(fileList);

%create structure to hold all file names
fileListTest = cell(nFile,1);
%compile complete list
for (cFile = 1:length(fileList))
    fileListTest{cFile} = [filePath sprintf('testFile2BackSubH%d.dat',cFile-1)];  %not that the files start with index zero so we must subtract one - this is different from teh monnet set.
end;



%load in heads file
load('D:/DatabaseTrain/LabTraining.mat','facePosnSize','bodyPosnSize','headCentre');

%calculate scales of face and body posns
SAMPLE_N_BODY = 4; SAMPLE_N_FACE = 4;
[bodyScales faceScales bodyOffsets faceOffsets]=sampleScaleDistsCalcOffsets('D:/DatabaseTrain/LabTraining',SAMPLE_N_BODY,SAMPLE_N_FACE); 
%define gamma values
gammaVals = exp(-2:0.5:2.0);

%RUN ANALYSIS FOR HEADS

%if this flag is set then it only uses samples where face was clearly seen
onlyFacesFlag = 0;
%extract likelihood distributions if not already done
if (~exist('D:/DatabaseTrain/LabTrainingLikeDist.mat'))
    [mdHeadDist,mdNonHeadDist,bsHeadDist,bsNonHeadDist,skHeadDist,skNonHeadDist]=extractLikelihoodDistributions(...
        fileListTrain,headCentre,facePosnSize,bodyScales,faceScales,faceOffsets,bodyOffsets,gammaVals,onlyFacesFlag);
    save('D:/DatabaseTrain/LabTrainingLikeDist','mdHeadDist','mdNonHeadDist','bsHeadDist','bsNonHeadDist','skHeadDist','skNonHeadDist','gammaVals','bodyScales','faceScales','faceOffsets','bodyOffsets');
end;

%load in heads file
if (~exist('D:/DatabaseTest/LabTestLikeDist.mat'))
    load('D:/DatabaseTest/LabTest.mat','facePosnSize','headCentre');
    [mdHeadDist,mdNonHeadDist,bsHeadDist,bsNonHeadDist,skHeadDist,skNonHeadDist]=extractLikelihoodDistributions(...
        fileListTest,headCentre,facePosnSize,bodyScales,faceScales,faceOffsets,bodyOffsets,gammaVals,onlyFacesFlag);
    save('D:/DatabaseTest/LabTestLikeDist','mdHeadDist','mdNonHeadDist','bsHeadDist','bsNonHeadDist','skHeadDist','skNonHeadDist','gammaVals','bodyScales','faceScales','faceOffsets','bodyOffsets');
end;

%now fit curves to training data if file doesn't already exist
if (~exist('D:/DatabaseTrain/LabTrainingLikeDistFits.mat'))
    FitCurvesToLikelihoodDists('D:/DatabaseTrain/LabTrainingLikeDist');
end;
    

if (~exist('D:/DatabaseTrain/LabTrainingLikeDistModel.mat'))
    %then find best gammas using 
    [bestMDGamma,bestBSGamma,bestSKGamma] = findBestGamma('D:/DatabaseTrain/LabTrainingLikeDist')

    %then select detectors in the greedy case
    modelsUsed = selectDetectorsGreedy('D:/DatabaseTrain/LabTrainingLikeDist',bestMDGamma,bestBSGamma,bestSKGamma); 
    %only use first four models...
    disp('Using only first four models (arbitrary)');
    modelsUsed = modelsUsed(1:4,:);
    %or
    %modelsUsed = selectDetectorsExhaustive('D:/DatabaseTrain/LabTrainingLikeDist',bestMDGamma,bestBSGamma,bestSKGamma,3); 

    %save all model parameters
    modelFilename = ['D:/DatabaseTrain/LabTrainingLikeDist' 'Model'];
    save(modelFilename,'modelsUsed','bestMDGamma','bestBSGamma','bestSKGamma');
else
    load('D:/DatabaseTrain/LabTrainingLikeDistModel.mat');
end;

%then look at ROC curves for test data
makeROCPlot('D:/DatabaseTest/LabTestLikeDist','D:/DatabaseTrain/LabTrainingLikeDistFits',modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma);
    
    
%take a given frame and calculate the posterior
imageMap =imread('D:/DatabaseTrain/Positive/testFileImage357.jpg','jpg');
mdImage = readProbImage('D:/DatabaseTrain/Positive/testFileMotionDiffH357.dat');
bsImage = readProbImage('D:/DatabaseTrain/Positive/testFileBackSubH357.dat');
skImage = readProbImage('D:/DatabaseTrain/Positive/testFileFaceDetH357.dat');
[posterior,logLikeRatios]=calculatePosterior('D:/DatabaseTrain/LabTrainingLikeDist',mdImage,bsImage,skImage,modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma);

%display results from combined tracker (assuming null priors)
figure;
showVisualTracker(imageMap,mdImage,bsImage,skImage,logLikeRatios,posterior);

%load in the head position for this frame
load('D:/DatabaseTrain/LabTrainingLikeDist');headPosns = headCentre{357}/2;
%plot the posterior map with the likelihood ratios, peaks in map and real head positions
estPosns = analyzePosterior(posterior,headPosns);

%RUN ANALYSIS FOR ALL FACES
 
%if this flag is set then it only uses samples where face was clearly seen
onlyFacesFlag = 1;
%extract likelihood distributions
if (~exist('D:/DatabaseTrain/LabTrainingFaceLikeDist.mat'))
    [mdHeadDist,mdNonHeadDist,bsHeadDist,bsNonHeadDist,skHeadDist,skNonHeadDist]=extractLikelihoodDistributions(...
        fileListTrain,headCentre,facePosnSize,bodyScales,faceScales,faceOffsets,bodyOffsets,gammaVals,onlyFacesFlag);
    save('D:/DatabaseTrain/LabTrainingFaceLikeDist','mdHeadDist','mdNonHeadDist','bsHeadDist','bsNonHeadDist','skHeadDist','skNonHeadDist','gammaVals','bodyScales','faceScales','faceOffsets','bodyOffsets');
end;
    
%load in heads file
if (~exist('D:/DatabaseTest/LabTestFaceLikeDist.mat'))
    load('D:/DatabaseTest/LabTest.mat','facePosnSize','headCentre');
    [mdHeadDist,mdNonHeadDist,bsHeadDist,bsNonHeadDist,skHeadDist,skNonHeadDist]=extractLikelihoodDistributions(...
        fileListTest,headCentre,facePosnSize,bodyScales,faceScales,faceOffsets,bodyOffsets,gammaVals,onlyFacesFlag);
    save('D:/DatabaseTest/LabTestFaceLikeDist','mdHeadDist','mdNonHeadDist','bsHeadDist','bsNonHeadDist','skHeadDist','skNonHeadDist','gammaVals','bodyScales','faceScales','faceOffsets','bodyOffsets');
end;
    
%now fit curves to training data if not already fit
if (~exist('D:/DatabaseTrain/LabTrainingFaceLikeDistFits.mat'))
    FitCurvesToLikelihoodDists('D:/DatabaseTrain/LabTrainingFaceLikeDist');
end;

%find gammas, models if doesn't exist
if (~exist('D:/DatabaseTrain/LabTrainingFaceLikeDistModel.mat'))
    %then find best gammas using 
    [bestMDGamma,bestBSGamma,bestSKGamma] = findBestGamma('D:/DatabaseTrain/LabTrainingFaceLikeDist')

    %then select detectors in the greedy case
    modelsUsed = selectDetectorsGreedy('D:/DatabaseTrain/LabTrainingFaceLikeDist',bestMDGamma,bestBSGamma,bestSKGamma);
    disp('Using only first four models (arbitrary)');
    modelsUsed = modelsUsed(1:3,:);
    %or
    %modelsUsed = selectDetectorsExhaustive('D:/DatabaseTrain/LabTrainingFaceLikeDist',bestMDGamma,bestBSGamma,bestSKGamma,3); 
    %save all model parameters
    modelFilename = ['D:/DatabaseTrain/LabTrainingFaceLikeDist' 'Model'];
    save(modelFilename,'modelsUsed','bestMDGamma','bestBSGamma','bestSKGamma');
else
    load('D:/DatabaseTrain/LabTrainingFaceLikeDistModel.mat');
end;

%then look at ROC curves for test data
makeROCPlot('D:/DatabaseTest/LabTestFaceLikeDist','D:/DatabaseTrain/LabTrainingFaceLikeDistFits',modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma);

%take a given frame and calculate the posterior
imageMap =imread('D:/DatabaseTrain/Positive/testFileImage357.jpg','jpg');
mdImage = readProbImage('D:/DatabaseTrain/Positive/testFileMotionDiffH357.dat');
bsImage = readProbImage('D:/DatabaseTrain/Positive/testFileBackSubH357.dat');
skImage = readProbImage('D:/DatabaseTrain/Positive/testFileFaceDetH357.dat');
[posterior,logLikeRatios]=calculatePosterior('D:/DatabaseTrain/LabTrainingFaceLikeDist',mdImage,bsImage,skImage,modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma);

%display results from combined tracker (assuming null priors)
figure;
showVisualTracker(imageMap,mdImage,bsImage,skImage,logLikeRatios,posterior);

%load in the head position for this frame
load('D:/DatabaseTrain/LabTrainingFaceLikeDist');headPosns = headCentre{357}/2;
%plot the posterior map with the likelihood ratios, peaks in map and real head positions
estPosns = analyzePosterior(posterior,headPosns);
