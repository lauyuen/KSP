function r= labelFaces

%select faces that are adjacent to one another
clear all;
close all;

%get file names and head positions
[headCentreTrain fileListTrain headCentreTest fileListTest] = getFileListHeads();
nImage = length(headCentreTrain);
 


%load in tracking data if it exists
if exist('D:/CrestechNewLab/CrestechTraining/FaceLabels.mat')
    load('D:/CrestechNewLab/CrestechTraining/FaceLabels.mat','labels','nIndividual');
else
    labels = cell(nImage,1);
    for (cImage = 1:nImage)
        nHeads = size(headCentreTrain{cImage},1);
        labels{cImage} = zeros(nHeads,1);    
    end;
    nIndividual = 0;
end;

figure;
set(gcf,'Position',[520   165   560   945]);

%while all faces have not been identified

while(1)
    %find next unallocated face
    for (cImage = 1:nImage)
        todoLabels = find(labels{cImage}(:,1)==0);
        if (length(todoLabels>0))
            break;
        end;
    end;
    %if got to end then quit
    if (cImage==nImage);
        break;
    end;
   
    %run through each image in turn until face leaves scene
    nIndividual = nIndividual+1;
    labels{cImage}(toDoLabels(1),1) = nIndividual;
    cImage = cImage+1;  %cImage must be at least 2;
    while(1)
        drawFrames(cImage,nIndividual,headCentreTrain,fileListTrain);
        
    end;
    
    
end;

function r= drawFrames(cImage,cIndividual,headCentres,fileList);

if(cImage==1)
    %first image
elseif(cImage==length(headCentres))
    
    %last image
else
    theseFiles = fileList{cImage-1:cImage+1};
    theseCentres = headCentres{cImage-1:cImage+1};
    
    %read these files, concatenate and draw
    im1 = imread(theseFiles{1},'jpg');
    im2 = imread(theseFiles{2},'jpg');
    im3 = imread(theseFiles{3},'jpg');
    [imY imX] = size(im1);

    %combine images
    im = cat(1,im1,im2,im3);
    %draw cool looking square around central image
    plot([1 1 imX imX 1],[imY*2 imY+1 imY+1 imY*2 imY*2],'r-','LineWidth',2);
    
    
    %draw images
    image(im);axis off;
    hold on;
    
    %extract points matrix
    
    
    
end;
    




%========================================================================

%get filenames and head positions
function [headCentreTrain,fileListTrain,headCentreTest,fileListTest] = getFileListHeads();

%define file path
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
headCentreTrain = headCentre;


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
 
 headCentreTest = headCentre;