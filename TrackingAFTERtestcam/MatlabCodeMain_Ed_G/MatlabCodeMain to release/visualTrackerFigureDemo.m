function r = visualTrackerDemo
%script to give example of complete visual tracker demo
%loads in a series of jpg images and runs complete visual tracker, including priors on data set


%clear all data and closes any open windows
clear all;
close all;

filePath1 = 'D:/CrestechNewLab/CrestechTest/';
fileList1 = dir([filePath1 '*Back2Sub*.dat']); nFile1 = length(fileList1);
filePath2 = 'D:/CrestechNewLab/NewLabTest/';
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
    headCentreAll = [headCentreAll headCentre(1:nFile2)];
    facePresentFlagAll =[facePresentFlagAll facePresentFlag(1:nFile2)];
   
    %save back to disk in one file
    headCentre = headCentreAll; facePresentFlag = facePresentFlagAll;
    save('D:/CrestechNewLab/CrestechAndLabTest.mat','facePresentFlag','headCentre');
else;
    load('D:/CrestechNewLab/CrestechAndLabTest.mat');
end;


%set up parameters for visual tracker
visTrackParams.modelBasename = 'D:/CrestechNewLab/CrestechLabTrainingLikeDist';       %tell visual tracker which model parameters to use



for (cFrame = 500:610)%length(fileListTest))
    %take a given frame and calculate the posterior
    bsFilename = fileListTest{cFrame};
    mdFilename = strrep(bsFilename,'Back2Sub','MotionPost');
    skFilename = strrep(bsFilename,'Back2Sub','FaceDet');
    imFilename = strrep(bsFilename,'Back2Sub','Image');
    imFilename = strrep(imFilename,'dat','jpg');
    
    %read images
    imageMap = imread(imFilename,'jpg');
    mdImage = readProbImage(mdFilename);
    bsImage = readProbImage(bsFilename);
    skImage = readProbImage(skFilename);
    
    visTrackParams = visualTrackerPreComputed(imageMap,mdImage,bsImage,skImage,visTrackParams);
    
    %load in the head position for this frame
    headPosns = headCentre{cFrame};
    %plot the posterior map with the likelihood ratios, peaks in map and real head positions
    visTrackParams.headPositionsActual = headPosns;
    visTrackParams.headPositionsEstimated = analyzePosterior(visTrackParams.posterior,headPosns);
    
    %display all raw data maps and log likelihood ratios to screen
    showVisualTrackerCVPR(visTrackParams);
    
    pause;
    close all;
    
    drawnow;
end;
    



