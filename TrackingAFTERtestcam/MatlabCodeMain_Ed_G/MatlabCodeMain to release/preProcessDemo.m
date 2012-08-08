function r = preProcessDemo
%function r = preProcessDemo
%example script which runs through a series of .jpg files and creates a series of .dat files.  
%these .dat files can be used to train the detector - see script extractFitSelectModelDemo
%if you want to run the tracker on a set of files then use script visualTrackerDemo.m

%close all figures and clear all memory
close all;clear all;


%find total number of files to be processed
filePath = 'D:/monnet/trioA1cam2/';
fileList = dir([filePath '*Image*.jpg']); nFile = length(fileList);

%create new figure
h = figure;

%initialize parameters for 3 modules
bsParams = [];
mdParams = [];
skParams = 'D:/Monnet/SkinDetTrainingDataMonnetLUT';

%for each file
for (cFile = 230:nFile)
    %create filename
    filename = [filePath sprintf('testFile2Image%d.jpg',cFile)];
    %load image
    im = imread(filename,'jpg');
    %process motion differencing
    [mdRawMap mdParams] = motionDiff(im,mdParams);
    %process background subtraction
    [bsRawMap bsParams] = backSub(im,bsParams);
    %process skin detection
    [skRawMap skParams] = skinDet(im,skParams);
    %display all raw data maps to screen
    subplot(2,2,1); image(im); axis off; title('Original Image');
    subplot(2,2,2); imagesc(mdRawMap,[0 1]); axis off; colormap(gray); title('Motion Differencing');
    subplot(2,2,3); imagesc(bsRawMap,[0 1]); axis off; colormap(gray); title('Background Subtraction');
    subplot(2,2,4); imagesc(skRawMap,[0 1]); axis off; colormap(gray); title('Skin Detection');
    set(gcf,'Name',sprintf('Frame %d',cFile));
    drawnow;
    %save data maps
    writeProbImage(mdRawMap,[filePath sprintf('MotionDiff%d.dat',cFile)]);
    writeProbImage(bsRawMap,[filePath sprintf('BackSub%d.dat',cFile)]);
    writeProbImage(skRawMap,[filePath sprintf('FaceDet%d.dat',cFile)]); 
end;

