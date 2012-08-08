%extractFitSelectModelDemo 
%example script for how to extract likelihood distributions from file for lab training dataset
%the raw data files can be created using preprocessDemo

%clear all data and closes any open windows
clear all;
close all;

%get list of all data files - make list of BackSub files and replace
%part of filename for other modalities

filePath1 = 'D:/CrestechNewLab/CrestechTraining/';
fileList1 = dir([filePath1 '*Back2Sub*.dat']); nFile1 = length(fileList1);
filePath2 = 'D:/CrestechNewLab/LabTraining/';
fileList2 = dir([filePath2 '*Back2Sub*.dat']); nFile2 = length(fileList2);

%count total number of files
nFileTotal = nFile1+nFile2;

%create structure to hold all file names
fileListTrain = cell(nFileTotal,1);

%compile complete list
for (cFile = 1:length(fileList1))
    fileListTrain{cFile} = [filePath1 sprintf('Back2Sub%d.dat',cFile)];
end;
for (cFile = 1:length(fileList2))
    fileListTrain{cFile+nFile1} = [filePath2 sprintf('Back2Sub%d.dat',cFile)];
end;

%combine together all face and body positions in one file if not already done
if (~exist('D:/CrestechNewLab/CrestechAndLabTraining.mat'))
    %load in face and body posns - contains fields %bodyPosnSize,facePosnSize,headCentre
    load('D:/CrestechNewLab/crestechTraining');
    bodyPosnSizeAll = bodyPosnSize(1:nFile1); headCentreAll = headCentre(1:nFile1);%facePosnSizeAll = facePosnSize(1:nFile1)
    facePresentFlagAll = facePresentFlag(1:nFile1);
    load('D:/CrestechNewLab/labTraining');
    bodyPosnSizeAll = [bodyPosnSizeAll bodyPosnSize(1:nFile2)];
    %facePosnSizeAll = [facePosnSizeAll facePosnSize(1:nFile2)];
    headCentreAll = [headCentreAll headCentre(1:nFile2)];
    facePresentFlagAll =[facePresentFlagAll facePresentFlag(1:nFile2)];

    %save back to disk in one file
    headCentre = headCentreAll; bodyPosnSize = bodyPosnSizeAll; facePresentFlag = facePresentFlagAll;%facePosnSize = facePosnSizeAll;
    save('D:/CrestechNewLab/CrestechAndLabTraining.mat','bodyPosnSize','headCentre','facePresentFlag');%'facePosnSize'
else;
    load('D:/CrestechNewLab/CrestechAndLabTraining.mat');
end;

% 
 filePath1 = 'D:/CrestechNewLab/CrestechTest/';
 fileList1 = dir([filePath1 '*Back2Sub*.dat']); nFile1 = length(fileList1);
 filePath2 = 'D:/CrestechNewLab/LabTest/';
 fileList2 = dir([filePath2 '*Back2Sub*.dat']); nFile2 = length(fileList2);
 
 %count total number of files
 nFileTotal = nFile1+nFile2;
 %create structure to hold all file names
 fileListTest = cell(nFileTotal,1);
 
 %compile complete list
 for (cFile = 1:length(fileList1))
     fileListTest{cFile} = [filePath1 sprintf('Back2Sub%d.dat',cFile)];
 end;
 for (cFile = 1:length(fileList2))
     fileListTest{cFile+nFile1} = [filePath2 sprintf('Back2Sub%d.dat',cFile)];
 end;
 
 %combine together all face and body positions in one file if not already done
 if (~exist('D:/CrestechNewLab/CrestechAndLabTest.mat'))
     %load in face and body posns - contains fields %bodyPosnSize,facePosnSize,headCentre
     load('D:/CrestechNewLab/crestechTest');
     headCentreAll = headCentre(1:nFile1);%facePosnSizeAll = facePosnSize(1:nFile1)
     facePresentFlagAll = facePresentFlag(1:nFile1);
     load('D:/CrestechNewLab/labTest');
%    bodyPosnSizeAll = [bodyPosnSizeAll bodyPosnSize(1:nFile2)];
    %facePosnSizeAll = [facePosnSizeAll facePosnSize(1:nFile2)];
    headCentreAll = [headCentreAll headCentre(1:nFile2)];
    facePresentFlagAll =[facePresentFlagAll facePresentFlag(1:nFile2)];

   
     %save back to disk in one file
    headCentre = headCentreAll; facePresentFlag = facePresentFlagAll;
      save('D:/CrestechNewLab/CrestechAndLabTest.mat','facePresentFlag','headCentre');
 else;
     load('D:/CrestechNewLab/CrestechAndLabTest.mat');
 end;


%calculate scales of face and body posns  %note that we are using old values here...
SAMPLE_N_BODY = 4; SAMPLE_N_FACE = 4;
[bodyScales faceScales bodyOffsets faceOffsets]=sampleScaleDistsCalcOffsets('D:/DatabaseTrain/LabTraining',SAMPLE_N_BODY,SAMPLE_N_FACE); 

%define gamma values
gammaVals = exp(-2:0.5:2.0);

%=========================================
%RUN ANALYSIS FOR HEADS
%=========================================


%extract likelihood distributions if not already done
if (~exist('D:/CrestechNewLab/CrestechLabTrainingLikeDist.mat'))
     load('D:/CrestechNewLab/CrestechAndLabTraining.mat');
    [mdHeadDist,mdNonHeadDist,bsHeadDist,bsNonHeadDist,skHeadDist,skNonHeadDist,headSampPosns,nonHeadSampPosns]=extractLikelihoodDistributions(...
        fileListTrain,headCentre,bodyScales,faceScales,faceOffsets,bodyOffsets,gammaVals,[]);
    save('D:/CrestechNewLab/CrestechLabTrainingLikeDist','headSampPosns','nonHeadSampPosns','mdHeadDist','mdNonHeadDist','bsHeadDist','bsNonHeadDist','skHeadDist','skNonHeadDist','gammaVals','bodyScales','faceScales','faceOffsets','bodyOffsets');
end;

%load in heads file
if (~exist('D:/CrestechNewLab/CrestechLabTestLikeDist.mat'))
      load('D:/CrestechNewLab/CrestechAndLabTest.mat');
    [mdHeadDist,mdNonHeadDist,bsHeadDist,bsNonHeadDist,skHeadDist,skNonHeadDist,headSampPosns,nonHeadSampPosns]=extractLikelihoodDistributions(...
        fileListTest,headCentre,bodyScales,faceScales,faceOffsets,bodyOffsets,gammaVals,[]);
    save('D:/CrestechNewLab/CrestechLabTestLikeDist','headSampPosns','nonHeadSampPosns','mdHeadDist','mdNonHeadDist','bsHeadDist','bsNonHeadDist','skHeadDist','skNonHeadDist','gammaVals','bodyScales','faceScales','faceOffsets','bodyOffsets');
end;

%now fit curves to training data if file doesn't already exist
if (~exist('D:/CrestechNewLab/CrestechLabTrainingLikeDistFits.mat'))
    FitCurvesToLikelihoodDists('D:/CrestechNewLab/CrestechLabTrainingLikeDist');
end;
    

if (~exist('D:/CrestechNewLab/CrestechLabTrainingLikeDistModel.mat'))
    %then find best gammas using 
    [bestMDGamma,bestBSGamma,bestSKGamma] = findBestGamma('D:/CrestechNewLab/CrestechLabTrainingLikeDist')
    keyboard;
    %then select detectors in the greedy case
    modelsUsed = selectDetectorsGreedy('D:/CrestechNewLab/CrestechLabTrainingLikeDist',bestMDGamma,bestBSGamma,bestSKGamma); 
    %only use first four models...
    disp('Using only first four models (arbitrary)');
    modelsUsed = modelsUsed(1:4,:);
    %or
    %modelsUsed = selectDetectorsExhaustive('D:/DatabaseTrain/LabTrainingLikeDist',bestMDGamma,bestBSGamma,bestSKGamma,3); 

    %save all model parameters
    modelFilename = ['D:/CrestechNewLab/CrestechLabTrainingLikeDist' 'Model'];
    save(modelFilename,'modelsUsed','bestMDGamma','bestBSGamma','bestSKGamma');
else
    load('D:/CrestechNewLab/CrestechLabTrainingLikeDistModel.mat');
end;

%then look at ROC curves for test data
makeROCPlot('D:/CrestechNewLab/CrestechLabTestLikeDist','D:/CrestechNewLab/CrestechLabTrainingLikeDistFits',modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma);
%then look at ROC curves for test data
makeROCPlot('D:/CrestechNewLab/CrestechLabTrainingLikeDist','D:/CrestechNewLab/CrestechLabTrainingLikeDistFits',modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma);
    
    
%take a given frame and calculate the posterior
imageMap =imread('D:/CrestechNewLab/CrestechTest/Image357.jpg','jpg');
mdImage = readProbImage('D:/CrestechNewLab/CrestechTest/MotionPost357.dat');
bsImage = readProbImage('D:/CrestechNewLab/CrestechTest/Back2Sub357.dat');
skImage = readProbImage('D:/CrestechNewLab/CrestechTest/FaceDet357.dat');
[posterior,logLikeRatios]=calculatePosterior('D:/CrestechNewLab/CrestechLabTrainingLikeDist',mdImage,bsImage,skImage,modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma);

%display results from combined tracker (assuming null priors)
figure;
showVisualTracker(imageMap,mdImage,bsImage,skImage,logLikeRatios,posterior);

%load in the head position for this frame
load('D:/CrestechNewLab/CrestechLabTrainingLikeDist');headPosns = headCentre{357};
%plot the posterior map with the likelihood ratios, peaks in map and real head positions
estPosns = analyzePosterior(posterior,headPosns);

break;

%=========================================
%RUN ANALYSIS FOR FACES
%=========================================

%if this flag is set then it only uses samples where face was clearly seen
onlyFacesFlag =1;
%extract likelihood distributions if not already done
if (~exist('D:/CrestechNewLab/CrestechLabTrainingFLikeDist.mat'))
      load('D:/CrestechNewLab/CrestechAndLabTraining.mat');
    [mdHeadDist,mdNonHeadDist,bsHeadDist,bsNonHeadDist,skHeadDist,skNonHeadDist,headSampPosns,nonHeadSampPosns]=extractLikelihoodDistributions(...
        fileListTrain,headCentre,bodyScales,faceScales,faceOffsets,bodyOffsets,gammaVals,facePresentFlag);
    save('D:/CrestechNewLab/CrestechLabTrainingFLikeDist','headSampPosns','nonHeadSampPosns','mdHeadDist','mdNonHeadDist','bsHeadDist','bsNonHeadDist','skHeadDist','skNonHeadDist','gammaVals','bodyScales','faceScales','faceOffsets','bodyOffsets');
end;

%load in heads file
if (~exist('D:/CrestechNewLab/CrestechLabTestFLikeDist.mat'))
      load('D:/CrestechNewLab/CrestechAndLabTest.mat');
    [mdHeadDist,mdNonHeadDist,bsHeadDist,bsNonHeadDist,skHeadDist,skNonHeadDist,headSampPosns,nonHeadSampPosns]=extractLikelihoodDistributions(...
        fileListTest,headCentre,bodyScales,faceScales,faceOffsets,bodyOffsets,gammaVals,facePresentFlag);
    save('D:/CrestechNewLab/CrestechLabTestFLikeDist','headSampPosns','nonHeadSampPosns','mdHeadDist','mdNonHeadDist','bsHeadDist','bsNonHeadDist','skHeadDist','skNonHeadDist','gammaVals','bodyScales','faceScales','faceOffsets','bodyOffsets');
end;

%now fit curves to training data if file doesn't already exist
if (~exist('D:/CrestechNewLab/CrestechLabTrainingFLikeDistFits.mat'))
    FitCurvesToLikelihoodDists('D:/CrestechNewLab/CrestechLabTrainingFLikeDist');
end;
    

if (~exist('D:/CrestechNewLab/CrestechLabTrainingFLikeDistModel.mat'))
    %then find best gammas using 
    [bestMDGamma,bestBSGamma,bestSKGamma] = findBestGamma('D:/CrestechNewLab/CrestechLabTrainingFLikeDist')

    %then select detectors in the greedy case
    modelsUsed = selectDetectorsGreedy('D:/CrestechNewLab/CrestechLabTrainingFLikeDist',bestMDGamma,bestBSGamma,bestSKGamma); 
    %only use first four models...
    disp('Using only first four models (arbitrary)');
    modelsUsed = modelsUsed(1:4,:);
    %or
    %modelsUsed = selectDetectorsExhaustive('D:/DatabaseTrain/LabTrainingLikeDist',bestMDGamma,bestBSGamma,bestSKGamma,3); 

    %save all model parameters
    modelFilename = ['D:/CrestechNewLab/CrestechLabTrainingFLikeDist' 'Model'];
    save(modelFilename,'modelsUsed','bestMDGamma','bestBSGamma','bestSKGamma');
else
    load('D:/CrestechNewLab/CrestechLabTrainingFLikeDistModel.mat');
end;

%then look at ROC curves for test data
makeROCPlot('D:/CrestechNewLab/CrestechLabTestFLikeDist','D:/CrestechNewLab/CrestechLabTrainingFLikeDistFits',modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma);
    
    
%take a given frame and calculate the posterior
imageMap =imread('D:/CrestechNewLab/CrestechTest/Image357.jpg','jpg');
mdImage = readProbImage('D:/CrestechNewLab/CrestechTest/MotionPost357.dat');
bsImage = readProbImage('D:/CrestechNewLab/CrestechTest/Back2Sub357.dat');
skImage = readProbImage('D:/CrestechNewLab/CrestechTest/FaceDet357.dat');
[posterior,logLikeRatios]=calculatePosterior('D:/CrestechNewLab/CrestechLabTrainingFLikeDist',mdImage,bsImage,skImage,modelsUsed,bestMDGamma,bestBSGamma,bestSKGamma);

%display results from combined tracker (assuming null priors)
figure;
showVisualTracker(imageMap,mdImage,bsImage,skImage,logLikeRatios,posterior);

%load in the head position for this frame
load('D:/CrestechNewLab/CrestechLabTrainingFLikeDist');headPosns = headCentre{357};
%plot the posterior map with the likelihood ratios, peaks in map and real head positions
estPosns = analyzePosterior(posterior,headPosns);
