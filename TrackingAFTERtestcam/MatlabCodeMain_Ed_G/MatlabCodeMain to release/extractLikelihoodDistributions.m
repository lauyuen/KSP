function [mdHeadDist,mdNonHeadDist,bsHeadDist,bsNonHeadDist,skHeadDist,skNonHeadDist,headSamplePosn,nonHeadSamplePosn]=...
    extractLikelihoodDistributions(fileList,headCentre,...
    bodyScales,faceScales,faceOffsets,bodyOffsets,gammaVals,facePresentFlag);
%reads in image maps of posteriors and stores values for face and non-face
%at all scales and all gammas
%used to be called extractData
%only faces flag determines if it takes into account samples where the face was not seen.
%==========================================================================

if (isempty(facePresentFlag))
    USE_ALL_HEADS = 1;
else
    USE_ALL_HEADS = 0;
end;

nNoFaceReject = 0;
nEdgeReject = 0;

%set this flag if you want to see the data that it extracts
PLOTTING_FLAG = 0;

if (PLOTTING_FLAG)
    figure;
    set(gcf,'Position',[78         690        1483         420]);
end;


%find number of scales and images and image size
nGamma = length(gammaVals);
nScaleBody = length(bodyScales);
nScaleFace = length(faceScales);
nImage = length(headCentre);
 
temp = readProbImage(fileList{1});[imY imX] = size(temp); clear temp;

%prepare cell array to store where sample points were
headSamplePosn = cell(nImage,1);
nonHeadSamplePosn = cell(nImage,1);

%define output arrays 
mdHeadDist = cell(nScaleBody,nGamma);
mdNonHeadDist = cell(nScaleBody,nGamma);
bsHeadDist = cell(nScaleBody,nGamma);
bsNonHeadDist = cell(nScaleBody,nGamma);
skHeadDist = cell(nScaleFace,nGamma);
skNonHeadDist = cell(nScaleFace,nGamma);

%find maximum and minimum body and face sizes and offsets
minXOffBody = min(bodyOffsets(:,1));  minYOffBody = min(bodyOffsets(:,2));
maxXOffBody = max(bodyOffsets(:,1));  maxYOffBody = max(bodyOffsets(:,2));
maxBodyWidth  = exp(bodyScales(nScaleBody,1));
maxBodyHeight = exp(bodyScales(nScaleBody,2));
minXOffFace = min(faceOffsets(:,1));  minYOffFace = min(faceOffsets(:,2));
maxXOffFace = max(faceOffsets(:,1));  maxYOffFace = max(faceOffsets(:,2));
maxFaceWidth  = exp(faceScales(nScaleFace,1));
maxFaceHeight = exp(faceScales(nScaleFace,2));

 
%for each image
for (cImage = 2:nImage)  %skip first frame as motion diff must be crap here. 
    disp(sprintf('Processing Image %d - %s',cImage,fileList{cImage}));  drawnow;
    
    %see how many heads there are in this image and continue if there are none
    headPosns = headCentre{cImage}; 
    nHead = size(headPosns,1);
    if (nHead==0)
        continue;
    end;
    
    %extract filenames
    bsFilename =fileList{cImage};
    mdFilename =strrep(bsFilename,'Back2Sub','MotionPost');
    skFilename =strrep(bsFilename,'Back2Sub','FaceDet');        
    
    %load skin detection data
    skImageIn = readProbImage(skFilename);
    %load background subtraction data
    bsImageIn = readProbImage(bsFilename);
    %load motion diffs and raise to power of this gamma, integrate
    mdImageIn = readProbImage(mdFilename); 
    
    %draw images if plotting flag is on
    if (PLOTTING_FLAG)
       subplot(1,3,1); hold off;
       imagesc(mdImageIn); axis off; colormap(gray); title('Motion Differencing');
       subplot(1,3,2); hold off;
       imagesc(bsImageIn); axis off; colormap(gray); title('Background Subtraction');
       subplot(1,3,3); hold off;
       imagesc(skImageIn); axis off; colormap(gray); title('Skin Detection');
    end;
    
    
    %for each exponent  
    for (cGamma = 1:nGamma)   
        %raise motion differencing to power and integrate
        mdImage = mdImageIn.^gammaVals(cGamma);
        mdImage = cumsum(cumsum(mdImage,1),2);
        
        %raise background subtraction to power and integrate
        bsImage = bsImageIn.^gammaVals(cGamma);
        bsImage = cumsum(cumsum(bsImage,1),2);
       
        %raise skin detection to power and integrate
        skImage = skImageIn.^gammaVals(cGamma);
        skImage = cumsum(cumsum(skImage,1),2);
          
        
        %FIRST EXTRACT MOTION DIFFERENCING AND BACKGROUND SUBTRACTION
        
        %for each person in the image
        for (cHead = 1:nHead)
            %check that face was seen - if implausibly small then skip out of loop
           if (~USE_ALL_HEADS&&(~facePresentFlag{cImage}(cHead)))
               fprintf('Now Rejected %d Heads without faces\n',round(nNoFaceReject/9));
               nNoFaceReject = nNoFaceReject+1;
                continue;
            end;
            
            %calculate extremal body values and reject if out of image
            bodyLeft = round(headPosns(cHead,1)+minXOffBody);
            bodyRight = round(headPosns(cHead,1)+maxXOffBody+maxBodyWidth);
            bodyTop = round(headPosns(cHead,2)+minYOffBody);
            bodyBottom = round(headPosns(cHead,2)+ maxYOffBody+maxBodyHeight);
            %check that body box at greatest scale cannot be clipped by size of image
            if ((bodyLeft<1)|(bodyRight>imX)|(bodyTop<1)|(bodyBottom>imY))
                 fprintf('Now Rejected %d Heads too near edge \n',round(nEdgeReject/9));
                 nEdgeReject = nEdgeReject+1;
                 
                continue;
            end;
            %for each scale
            for (cScale = 1:nScaleBody)            
                %extract this offset for body
                xOffBody = bodyOffsets(cScale,1);
                yOffBody = bodyOffsets(cScale,2);
                bodyWidth = exp(bodyScales(cScale,1));
                bodyHeight = exp(bodyScales(cScale,2));
                           
                %extract body position
                bodyLeft = round(headPosns(cHead,1)+xOffBody);
                bodyRight = round(headPosns(cHead,1)+xOffBody+bodyWidth);
                bodyTop = round(headPosns(cHead,2)+yOffBody);
                bodyBottom = round(headPosns(cHead,2)+ yOffBody+bodyHeight);
                headSamplePosn{cImage}(cHead,:) = [round(headPosns(cHead,1)) round(headPosns(cHead,2))];
                
                %draw boxes if plotting flag is on
                if (PLOTTING_FLAG&(cGamma==1))
                    subplot(1,3,1);hold on;
                    plot([bodyLeft bodyRight bodyRight bodyLeft bodyLeft],[bodyTop bodyTop bodyBottom bodyBottom bodyTop],'r-');
                    subplot(1,3,2);hold on;
                    plot([bodyLeft bodyRight bodyRight bodyLeft bodyLeft],[bodyTop bodyTop bodyBottom bodyBottom bodyTop],'r-');   
                end;
                
                % measure head values
                mdHead = mdImage(bodyTop,bodyLeft)+mdImage(bodyBottom,bodyRight)-mdImage(bodyTop,bodyRight)-mdImage(bodyBottom,bodyLeft);
                bsHead = bsImage(bodyTop,bodyLeft)+bsImage(bodyBottom,bodyRight)-bsImage(bodyTop,bodyRight)-bsImage(bodyBottom,bodyLeft);
                mdHead = mdHead/((bodyRight-bodyLeft)*(bodyBottom-bodyTop));
                bsHead = bsHead/((bodyRight-bodyLeft)*(bodyBottom-bodyTop));
         
                %if first scale then select non-head positions for all scales so correlated
                if (cScale==1)
                    while(1)
                        %select random position
                        randPosn = [randint(1,1,imX) randint(1,1,imY)];
                        %check not too close to heads
                        distToHeads = headPosns-repmat(randPosn,nHead,1);
                        distToHeads = sqrt(sum(distToHeads.^2,2));
                        smallestDist = min(distToHeads);
                        if (smallestDist<15)
                            continue;
                        end;
                        %check that in image
                        bodyLeft = round(randPosn(1)+minXOffBody);
                        bodyRight = round(randPosn(1)+maxXOffBody+maxBodyWidth);
                        bodyTop = round(randPosn(2)+minYOffBody);
                        bodyBottom = round(randPosn(2)+ maxYOffBody+maxBodyHeight);
                        if ((bodyLeft>0)&(bodyRight<imX)&(bodyTop>0)&(bodyBottom<imY))
                            bodyLeft = round(randPosn(1)+xOffBody);
                            bodyRight = round(randPosn(1)+xOffBody+bodyWidth);
                            bodyTop = round(randPosn(2)+yOffBody);
                            bodyBottom = round(randPosn(2)+ yOffBody+bodyHeight);
                            break;
                        end;
                    end;
                    nonHeadSamplePosn{cImage}(cHead,:) = [round(randPosn(1)) round(randPosn(2))];
                    
                    
                else
                    %if not the first scale then the non-head positions are already chosesn
                    bodyLeft = round(randPosn(1)+xOffBody);
                    bodyRight = round(randPosn(1)+xOffBody+bodyWidth);
                    bodyTop = round(randPosn(2)+yOffBody);
                    bodyBottom = round(randPosn(2)+ yOffBody+bodyHeight);
                end;                
                    
                %draw boxes if plotting flag is on
                if (PLOTTING_FLAG&(cGamma==1))
                    subplot(1,3,1);hold on;
                    plot([bodyLeft bodyRight bodyRight bodyLeft bodyLeft],[bodyTop bodyTop bodyBottom bodyBottom bodyTop],'g-');
                    subplot(1,3,2);hold on;
                    plot([bodyLeft bodyRight bodyRight bodyLeft bodyLeft],[bodyTop bodyTop bodyBottom bodyBottom bodyTop],'g-');   
                end;
                
                %extract not head areas
                mdNonHead = mdImage(bodyTop,bodyLeft)+mdImage(bodyBottom,bodyRight)-mdImage(bodyTop,bodyRight)-mdImage(bodyBottom,bodyLeft);
                bsNonHead = bsImage(bodyTop,bodyLeft)+bsImage(bodyBottom,bodyRight)-bsImage(bodyTop,bodyRight)-bsImage(bodyBottom,bodyLeft);
                bsNonHead = bsNonHead/((bodyRight-bodyLeft)*(bodyBottom-bodyTop));
                mdNonHead = mdNonHead/((bodyRight-bodyLeft)*(bodyBottom-bodyTop));
   
                %get rid of small negative values caused by integral image representation             
                bsHead = bsHead.*(bsHead>0);
                bsNonHead = bsNonHead.*(bsNonHead>0);
                mdHead = mdHead.*(mdHead>0);
                mdNonHead = mdNonHead.*(mdNonHead>0);
          
                %add to output distributions
                mdHeadDist{cScale,cGamma} = [mdHeadDist{cScale,cGamma}; mdHead];
                bsHeadDist{cScale,cGamma} = [bsHeadDist{cScale,cGamma}; bsHead];
                mdNonHeadDist{cScale,cGamma} = [mdNonHeadDist{cScale,cGamma}; mdNonHead];
                bsNonHeadDist{cScale,cGamma} = [bsNonHeadDist{cScale,cGamma}; bsNonHead];
            end;  %cScale
            
            %NOW EXTRACT SKIN DETECTION DATA
                       
            for (cScale = 1:nScaleFace)           
                %extract this offset for face
                xOffFace = faceOffsets(cScale,1);
                yOffFace = faceOffsets(cScale,2);
                faceWidth = exp(faceScales(cScale,1));
                faceHeight = exp(faceScales(cScale,2));
                
                %extract face position
                faceLeft = round(headPosns(cHead,1)+xOffFace);
                faceRight = round(headPosns(cHead,1)+xOffFace+faceWidth);
                faceTop = round(headPosns(cHead,2)+yOffFace);
                faceBottom = round(headPosns(cHead,2)+ yOffFace+faceHeight);
                
                %draw boxes if plotting flag is on
                if (PLOTTING_FLAG&(cGamma==1))
                    subplot(1,3,3);hold on;
                    plot([faceLeft faceRight faceRight faceLeft faceLeft],[faceTop faceTop faceBottom faceBottom faceTop],'r-');  
                end;
                
                % measure head values
                skHead = skImage(faceTop,faceLeft)+skImage(faceBottom,faceRight)-skImage(faceTop,faceRight)-skImage(faceBottom,faceLeft);
                skHead = skHead/((faceRight-faceLeft)*(faceBottom-faceTop));
                
                %use random position already chosen for heads and facefs
                faceLeft = round(randPosn(1)+xOffFace);
                faceRight = round(randPosn(1)+xOffFace+faceWidth);
                faceTop = round(randPosn(2)+yOffFace);
                faceBottom = round(randPosn(2)+ yOffFace+faceHeight);
                
                %draw boxes if plotting flag is on
                if (PLOTTING_FLAG&(cGamma==1))
                    subplot(1,3,3);hold on;
                    plot([faceLeft faceRight faceRight faceLeft faceLeft],[faceTop faceTop faceBottom faceBottom faceTop],'g-');  
                end;

                %extract not head areas
                skNonHead = skImage(faceTop,faceLeft)+skImage(faceBottom,faceRight)-skImage(faceTop,faceRight)-skImage(faceBottom,faceLeft);
                skNonHead = skNonHead/((faceRight-faceLeft)*(faceBottom-faceTop));
                
                %get rid of small negative values caused by integral image representation             
                skHead = skHead.*(skHead>0);
                skNonHead = skNonHead.*(skNonHead>0);
                
                %add to output distributions
                skHeadDist{cScale,cGamma} = [skHeadDist{cScale,cGamma}; skHead];
                skNonHeadDist{cScale,cGamma} = [skNonHeadDist{cScale,cGamma}; skNonHead];
            end;  %cScale
        end;  %cHead
        %pause if plotting to view picture;
        if (PLOTTING_FLAG&(cGamma==1))
            pause;    
        end;
    end; %cGamma
end %cImage
