function r= labelIdentity()
%Label head data with identity


%clear all data and closes any open windows
clear all;
close all;

%Get file lists and lists of head positions
pathName = 'E:/CrestechNewLab/';
databaseName = 'Training';
[fileList headPositions] = getFileListPosns(pathName, databaseName);
nImage =  length(fileList);

imTemp = imread(fileList{1},'jpg');
[imY imX] = size(imTemp);

%load in labels if they don't exist
labelName = [pathName 'label' databaseName '.mat'];
if (exist(labelName))
    load(labelName,'labels');
    nIndividual = size(labels,3);
else
    labels = [];
end;

%create temporary label structure
tempStruc.x = 0;            %x position of this point
tempStruc.y = 0;            %y position of this point
tempStruc.occluded = 0;     %occluded version of this point
tempStruc.used = 0;         %flag indicating this one already used

%create empty figure and resize
figure;
set(gcf,'Position',[1025          52         888        1062]);


%main loop - continue while new people need to be added
while(1)
    %find next unlabelled person
    [thisImage thisHead] = findNextUnlabelled(labels,headPositions);
    %return if no more unlabelled heads
    if (thisImage==0)
        return;
    end;
    
    %expand the labels array to incorporate this 
    labels = [labels repmat(tempStruc,nImage,1)];

    %copy the first point into the structure
    labels(thisImage,end).x = headPositions{thisImage}(thisHead,1);
    labels(thisImage,end).y = headPositions{thisImage}(thisHead,2);
    labels(thisImage,end).occluded = 0;
    labels(thisImage,end).used = 1;
    
    thisLabel = size(labels,2);
    %update the currentImage
    thisImage = thisImage+1;
    if (thisImage>nImage)
        thisImage = 1;
    end;
    
    %set quit flag to null
    saveAndQuitFlag = 0;
    
    %label subsequent images in turn
    while(1)
        %display imageas
        displayImages(thisImage,thisLabel,headPositions,fileList,labels);
      
        %get response
        [x y button] = ginput(1);
        
        %do something based on button press
        switch(button)
            case 1   %left mouse button  - select nearest point not already selected
                %can only add point if either previous or next is same label or label already present
                if((labels(thisImage,thisLabel).used==1)|(thisImage>1&labels(thisImage-1,thisLabel).used==1)|(thisImage<nImage&labels(thisImage+1,thisLabel).used==1))
                    %quit if didn't select this image
                    y = y-imY;
                    if (x<1)|(x>imX)|(y<1)|(y>imY)
                        continue;
                    end;
                    
                    %make list of potential points
                    possiblePoints = [];
                    heads = headPositions{thisImage};
                    nHeads = size(heads,1);
                    nLabel = size(labels,2);
                    %can't add point if there are no heads in this frame
                    if (nHeads==0)
                        continue;
                    end;
                    %count number of points not already taken
                    for (cHead = 1:nHeads)
                        foundFlag = 0;
                        for (cLabel = 1:nLabel)
                            if (labels(thisImage,cLabel).x==heads(cHead,1)&labels(thisImage,cLabel).y==heads(cHead,2)&(labels(thisImage,cLabel).used==0))
                                foundFlag = 1;
                            end;
                        end;
                        %if didn't find then add to possible points
                        if (~foundFlag)
                            possiblePoints = [possiblePoints;heads(cHead,:)];
                        end;
                    end;
                    
                    %if all points taken then quit
                    nPossiblePoints =size(possiblePoints,1);
                    if(nPossiblePoints==0)
                        continue;
                    end;
                    
                    %calculate dist to each point
                    dist = sqrt(sum((possiblePoints-repmat([x y],nPossiblePoints,1)).^2,2));
                    smallestDistIndex = find(dist==min(dist));
                    
                    %add this label
                    labels(thisImage,thisLabel).x = possiblePoints(smallestDistIndex(1),1);
                    labels(thisImage,thisLabel).y = possiblePoints(smallestDistIndex(1),2);
                    labels(thisImage,thisLabel).used = 1;
                    labels(thisImage,thisLabel).occluded = 0;
                    
                    %increment frame
                    thisImage = thisImage+1;
                    if (thisImage>nImage)
                        thisImage = 1;
                    end;
                    
                end;
            case 3   %right mouse button
                %can only add point if either previous or next is same label or label already present
                if((labels(thisImage,thisLabel).used==1)|(thisImage>1&labels(thisImage-1,thisLabel).used==1)|(thisImage<nImage&labels(thisImage+1,thisLabel).used==1))
                    %only add if it was actually in centre image
                    y = y-imY;
                    if (x<1)|(x>imX)|(y<1)|(y>imY)
                        continue;
                    end;
                    labels(thisImage,thisLabel).used = 1;
                    labels(thisImage,thisLabel).occluded = 1;
                    labels(thisImage,thisLabel).x = x;
                    labels(thisImage,thisLabel).y = y;
                    
                    %increment frame
                    thisImage = thisImage+1;
                    if (thisImage>nImage)
                        thisImage = 1;
                    end;
                    
                end;                
            case 27  %escape key - quit out of program
                saveAndQuitFlag = 1;
                break;
            case 8  %backspace key  - delete this point
                %can only delete if at end of chain
                if (thisImage==1)|(thisImage==nImage)|~((labels(thisImage-1,thisLabel).used)&(labels(thisImage+1,thisLabel).used))
                     labels(thisImage,thisLabel).used = 0;   
                      labels(thisImage,thisLabel).x = 0;   
                     labels(thisImage,thisLabel).y = 0;   
                    
                 end;
                %decrement frame
                thisImage = thisImage-1;
                if (thisImage<1)
                    thisImage = nImage;
                end;
                
                
                
            case 127 %delete key - delete this whole label
                nLabel = size(labels,2);
                if (nLabel>1)
                    goodLabels = find(1:nLabel~=thisLabel);
                    labels = labels(:,goodLabels);                    
                    %find labels that are in view
                    labelsInView = getLabelsInView(labels,thisImage);
                    if (isempty(labelsInView))
                        thisLabel = 1;
                    else
                        thisLabel = labelsInView(1);
                    end;                
                    
                end;
            case 28  %left key - previous label
                labelsInView = getLabelsInView(labels,thisImage);
                nLabelsInView = length(labelsInView);
                if (nLabelsInView>0)
                    thisLabelIndex = find(labelsInView==thisLabel);
                    if (isempty(thisLabelIndex))
                        thisLabel = labelsInView(1);
                    else
                        thisLabelIndex = thisLabelIndex-1;
                        if (thisLabelIndex==0)
                            thisLabelIndex = nLabelsInView;
                        end;
                        thisLabel = labelsInView(thisLabelIndex);
                    end;
                end;
                
            case 29  %right key - next label
                labelsInView = getLabelsInView(labels,thisImage);
                nLabelsInView = length(labelsInView);
                if (nLabelsInView>0)
                    thisLabelIndex = find(labelsInView==thisLabel);
                    if (isempty(thisLabelIndex))
                        thisLabel = labelsInView(1);
                    else
                        thisLabelIndex = thisLabelIndex+1;
                        if (thisLabelIndex>nLabelsInView)
                            thisLabelIndex = 1;
                        end;
                        thisLabel = labelsInView(thisLabelIndex);
                    end;
                end;
                
            case 30  %up key - previous image
                thisImage = thisImage-1;
                if (thisImage<1)
                    thisImage = nImage;
                end;
            case 31  %down key - next image
                  %right key - next image
                thisImage = thisImage+1;
                if (thisImage>nImage)
                    thisImage = 1;
                end;
            case 110 %n key - add new label
                break;
            case 115 %s key - save data
            save(labelName,'labels');    
        
        end;        
    end;
    
    if (saveAndQuitFlag)
         save(labelName,'labels');   
        return;
    end;
end;


%=============================================================================
%find all labels which are present in the three views 
function labelsInView = getLabelsInView(labels,thisImage)

%count total number of images
nImage = size(labels,1);
nLabel = size(labels,2);

%special case if image = first or last;
if (thisImage==1)
    displayImages = [nImage-1 nImage 1 2 3];
elseif (thisImage==2)
    displayImages = [nImage 1 2 3 4];
elseif  (thisImage==nImage)
   displayImages = [nImage-2 nImage-1 nImage 1 2];
elseif (thisImage==nImage-1)
    displayImages = [nImage-3 nImage-2 nImage-1 nImage 1];
else
    displayImages = [thisImage-2 thisImage-1 thisImage thisImage+1 thisImage+2];
end;

usedLabels = zeros(1,nLabel);
for (cImage = 2:4)
    for (cLabel = 1:nLabel)
        if (labels(displayImages(cImage),cLabel).used)
            usedLabels(cLabel) = 1;
        end;
    end
end;

labelsInView = find(usedLabels);

%=============================================================================
%display images and labels to screen
function displayImages(thisImage,thisLabel,headPositions,fileList,labels);

%count total number of images
nImage = length(fileList);

%special case if image = first or last;
if (thisImage==1)
    displayImages = [nImage-1 nImage 1 2 3];
elseif (thisImage==2)
    displayImages = [nImage 1 2 3 4];
elseif  (thisImage==nImage)
   displayImages = [nImage-2 nImage-1 nImage 1 2];
elseif (thisImage==nImage-1)
    displayImages = [nImage-3 nImage-2 nImage-1 nImage 1];
else
    displayImages = [thisImage-2 thisImage-1 thisImage thisImage+1 thisImage+2];
end;
     
%read in all three images and conctenate
im1 = imread(fileList{displayImages(2)},'jpg');
im2 = imread(fileList{displayImages(3)},'jpg');
im3 = imread(fileList{displayImages(4)},'jpg');
allImages = cat(1,im1,im2,im3);

%display images
hold off;
image(allImages);hold on;axis off;
[ySize xSize zSize] = size(im1);

%plot border around current image
plot([1 1 xSize xSize 1],[ySize*2,ySize+1,ySize+1,ySize*2 ySize*2],'r-','LineWidth',3);

%plot all of the actual head positions in yellow
for (c1 = 2:4)
    theseHeadPositions = headPositions{displayImages(c1)};
    if (~isempty(theseHeadPositions))
        plot(theseHeadPositions(:,1),theseHeadPositions(:,2)+(c1-2)*ySize,'c.');   
    end;
end;

%extract all labels from these five frames
nLabel = size(labels,2);
xPosns = zeros(5,nLabel);
yPosns = zeros(5,nLabel);
used = zeros(5,nLabel);
occluded = zeros(5,nLabel);

for (cLabel = 1:nLabel)
     for (cFrame = 1:5)
         xPosns(cFrame,cLabel) = labels(displayImages(cFrame),cLabel).x;
         yPosns(cFrame,cLabel) = labels(displayImages(cFrame),cLabel).y;
         used(cFrame,cLabel) = labels(displayImages(cFrame),cLabel).used;
         occluded(cFrame,cLabel) = labels(displayImages(cFrame),cLabel).occluded;
     end;
end;

%plot lines (red if not current, white if current)
for (cLabel = 1:nLabel)
    for (cFrame = 2:5)
        if (used(cFrame,cLabel)&used(cFrame-1,cLabel))
            if (cLabel==thisLabel)
                plot([xPosns(cFrame-1,cLabel) xPosns(cFrame,cLabel)],[yPosns(cFrame-1,cLabel)+(cFrame-3)*ySize yPosns(cFrame,cLabel)+(cFrame-2)*ySize],'w-');    
            else
                plot([xPosns(cFrame-1,cLabel) xPosns(cFrame,cLabel)],[yPosns(cFrame-1,cLabel)+(cFrame-3)*ySize yPosns(cFrame,cLabel)+(cFrame-2)*ySize],'r-');                    
            end;
        end;
    end;
end; 

%plot all of the current heads in red visible or green (occluded)
for (cLabel = 1:nLabel)
    for (cFrame = 2:4)
        if (used(cFrame,cLabel))
            if (cLabel==thisLabel)
                plot(xPosns(cFrame,cLabel), yPosns(cFrame,cLabel)+(cFrame-2)*ySize,'wo');    
            else
                plot(xPosns(cFrame,cLabel), yPosns(cFrame,cLabel)+(cFrame-2)*ySize,'ro');                    
            end;
        end;
    end;
end; 

set(gcf,'Name',sprintf('Image %d of %d, Label %d of %d',thisImage,nImage,thisLabel,nLabel));




%=============================================================================
function [thisImage,thisHead]= findNextUnlabelled(labels,headPositions);

%count number of images
nImage = length(headPositions);
nLabel = size(labels,2);


%first identify which image is the first with an unlabelled point
for (cImage = 1:nImage)
    %actual head number
    nActualHeads = size(headPositions{cImage},1);
    %labelled head number
    nLabelledHeads = 0;
    for (cLabel = 1:nLabel)
        nLabelledHeads = nLabelledHeads+(labels(cImage,cLabel).used&(~labels(cImage,cLabel).occluded));
    end;
    %if found one that isn't accounted for then break
    if (nActualHeads>nLabelledHeads)
        thisImage = cImage;
        break;
    end;
    %if got to last image then return
    if (cImage==nImage)
        thisImage = 0; thisHead = 0; return;
    end;
end;

%create heads used flag
headsUsed = zeros(nActualHeads,1);

%now figure out which head it is
for(cLabel = 1:nLabel)
    %if this label is tagged and not occluded
    if (labels(thisImage,cLabel).used&~labels(thisImage,cLabel).occluded)    
        for (cHead = 1:nActualHeads)
            if (labels(thisImage,cLabel).x==headPositions{thisImage}(cHead,1)&labels(thisImage,cLabel).y==headPositions{thisImage}(cHead,2))
                %[thisImage cLabel labels(thisImage,cLabel).x labels(thisImage,cLabel).y headPositions{thisImage}(cHead,1) headPositions{thisImage}(cHead,2)]
                headsUsed(cHead) = 1;
                break;
            end;
        end;    
    end;
end;

headsToBeUsed = find(~headsUsed);
thisHead = headsToBeUsed(1);



%=============================================================================

%get list of all data files - make list of BackSub files and replace
%part of filename for other modalities
%ignores first 20 frames as these are empty.
function [fileList,headPositions] = getFileListPosns(pathName,databaseName);

filePath1 = [pathName 'Crestech' databaseName '/'];              %'D:/CrestechNewLab/CrestechTraining/';
fileList1 = dir([filePath1 '*Image*.jpg']); nFile1 = length(fileList1);
filePath2 = [pathName 'Lab' databaseName '/'];
fileList2 = dir([filePath2 '*Image*.jpg']); nFile2 = length(fileList2);

%count total number of files
nFileTotal = nFile1+nFile2-20-20;

%create structure to hold all file names
fileList = cell(nFileTotal,1);

%compile complete list
for (cFile = 21:length(fileList1))
    fileList{cFile-20} = [filePath1 sprintf('Image%d.jpg',cFile)];
end;
for (cFile = 21:length(fileList2))
    fileList{cFile-20+nFile1-20} = [filePath2 sprintf('Image%d.jpg',cFile)];
end;

%combine together all face and body positions in one file if not already done
if (~exist([pathName 'CrestechAndLab' databaseName '.mat']))
    %load in face and body posns - contains fields %bodyPosnSize,facePosnSize,headCentre
    load([pathName 'crestech' databaseName]);
    bodyPosnSizeAll = bodyPosnSize(21:nFile1); 
    headCentreAll = headCentre(21:nFile1);
    facePresentFlagAll = facePresentFlag(21:nFile1);
    load([pathName 'lab' databaseName]);
    bodyPosnSizeAll = [bodyPosnSizeAll bodyPosnSize(21:nFile2)];
    headCentreAll = [headCentreAll headCentre(21:nFile2)];
    facePresentFlagAll =[facePresentFlagAll facePresentFlag(21:nFile2)];

    %save back to disk in one file
    headCentre = headCentreAll; bodyPosnSize = bodyPosnSizeAll; facePresentFlag = facePresentFlagAll;
    save([pathName 'CrestechAndLab' databaseName '.mat'],'bodyPosnSize','headCentre','facePresentFlag');
else;
    load([pathName 'CrestechAndLab' databaseName '.mat']);
end;

headPositions = headCentre;
