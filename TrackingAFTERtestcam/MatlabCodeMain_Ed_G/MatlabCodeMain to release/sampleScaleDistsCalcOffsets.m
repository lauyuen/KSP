function [bodyScales,faceScales,ssBodyOffset,ssFaceOffset]= sampleScaleDistsCalcOffsets(faceBodyPosnFilename,sampleNBody, sampleNFace)
%sample log height and log width at regular intervals
%Makes figure 3 from the paper 
%should order the scales by number of pixels!
%also predicts the offsets of the head at the best body positions

%load in face and body size data
load(faceBodyPosnFilename);


bodyPosnSizeList = [];
facePosnSizeList = [];
headCentreList = [];

%EXTRACT ALL VALID FACES,BODIES AND OFFSETS
for (c1 = 1:length(bodyPosnSize))
    bodyPosnSizeList = [bodyPosnSizeList; bodyPosnSize{c1}];
    facePosnSizeList = [facePosnSizeList; facePosnSize{c1}];
    headCentreList = [headCentreList; headCentre{c1}];
end;

%get rid of face positions where no face was seen - indicated by small face size 
toKeep = find((facePosnSizeList(:,3)>3)&(facePosnSizeList(:,4)>3));
facePosnSizeList = facePosnSizeList(toKeep,:);
headCentreListWithFaces = headCentreList(toKeep,:);

%SAMPLE BODY DISTRIBUTIONS

%NxN grid laid on top of sampling space
sampleN = sampleNBody;         
%get body samples
bodyScales= sampleScales(bodyPosnSizeList,sampleN);
%add labels
xlabel('Body Width (pixels)');
ylabel('Body Height (pixels)');
xlim([3 100]); ylim([3 200]);
%print to file if necessary
%print -depsc2 bodyScaleSample.eps

%SAMPLE FACE DISTRIBUTIONS

%NxN grid laid on top of sampling space
sampleN = sampleNFace;         
%get body samples
faceScales = sampleScales(facePosnSizeList,sampleN);
%add labels
xlabel('Face Width (pixels)');
ylabel('Face Height (pixels)');
xlim([3 100]); ylim([3 200]);
%print to file if necessary
%print -depsc2 faceScaleSample.eps

%FIND MOST LIKELY HEAD OFFSETS AT SCALE SAMPLES

%find body offsets in training set
bodyOffsets = bodyPosnSizeList(:,1:2)-headCentreList;
logBodySize = log(bodyPosnSizeList(:,3:4));

%find face offsets in training set
faceOffsets = facePosnSizeList(:,1:2)-headCentreListWithFaces;
logFaceSize = log(facePosnSizeList(:,3:4));

%make polynomial body offset model
ABody  = [logBodySize(:,1).*logBodySize(:,1) logBodySize(:,1).*logBodySize(:,2) logBodySize(:,2).*logBodySize(:,2) logBodySize(:,1) logBodySize(:,2) ones(length(logBodySize),1)];
ABodyInv = inv(ABody'*ABody)*ABody';
bodyOffParamsX = ABodyInv*bodyOffsets(:,1);
bodyOffParamsY = ABodyInv*bodyOffsets(:,2); 
%make polynomial face offset model
AFace  = [logFaceSize(:,1).*logFaceSize(:,1) logFaceSize(:,1).*logFaceSize(:,2) logFaceSize(:,2).*logFaceSize(:,2) logFaceSize(:,1) logFaceSize(:,2) ones(length(logFaceSize),1)];
AFaceInv = inv(AFace'*AFace)*AFace';
faceOffParamsX = AFaceInv*faceOffsets(:,1);
faceOffParamsY = AFaceInv*faceOffsets(:,2); 

%predict offset for body scale samples
AScalesBody = [bodyScales(:,1).*bodyScales(:,1) bodyScales(:,1).*bodyScales(:,2) bodyScales(:,2).*bodyScales(:,2) bodyScales(:,1) bodyScales(:,2) ones(length(bodyScales(:,1)),1)];
xOffsetBodyPred = AScalesBody*bodyOffParamsX;
yOffsetBodyPred = AScalesBody*bodyOffParamsY;
%predict offset for face scale samples
AScalesFace = [faceScales(:,1).*faceScales(:,1) faceScales(:,1).*faceScales(:,2) faceScales(:,2).*faceScales(:,2) faceScales(:,1) faceScales(:,2) ones(length(faceScales(:,1)),1)];
xOffsetFacePred = AScalesFace*faceOffParamsX;
yOffsetFacePred = AScalesFace*faceOffParamsY;

ssBodyOffset =[xOffsetBodyPred yOffsetBodyPred];
ssFaceOffset =[xOffsetFacePred yOffsetFacePred];


%SAVE CALCULATED VALUES
scalesFilename = [faceBodyPosnFilename 'Scales'];
save(scalesFilename,'bodyScales','faceScales','ssBodyOffset','ssFaceOffset');

%==============================================
%SUB ROUTINES

function samples = sampleScales(posn,sampleN)

figure;

%calculate mean and covariance of data
logPosn = log(posn);
logPosnMu  = mean(logPosn(:,3:4));
logPosnCov = cov(logPosn(:,3:4));

%plot raw data
loglog(exp(logPosn(:,3)),exp(logPosn(:,4)),'r.');
drawGaussian2DExp(logPosnMu,logPosnCov)

%find maximum and minimum values
maxY = logPosnMu(2)+2*sqrt(logPosnCov(4));
minY = logPosnMu(2)-2*sqrt(logPosnCov(4));
maxX = logPosnMu(1)+2*sqrt(logPosnCov(1));
minX = logPosnMu(1)-2*sqrt(logPosnCov(1));

%set up 4 x 4 grid on top of Gaussian
samples  = [];
for (cX = minX:(maxX-minX)/sampleN:maxX)
    for (cY = minY:(maxY-minY)/sampleN:maxY)
        if (insideGauss2SD(logPosnMu,logPosnCov,[cX cY]))
            loglog(exp(cX),exp(cY),'k+');
            %store sample position for body
            samples = [samples;[cX cY]];
        else
            loglog(exp(cX),exp(cY),'g+');
        end;
    end;
end;

%sort samples by size
nPixels = prod(exp(samples),2);
[temp index] = sort(nPixels);
samples = samples(index,:);


%modifications for figure;
set(gca,'Box','Off');
set(gca,'Position',[0.13 0.14 0.775 0.815])
set(gcf,'Position',[520   804   407   306]);
set(gcf,'PaperPosition',[0.25 2.5 4 3]);
 

%draw 2DGaussian
function r= drawGaussian2D(m,s)

hold on;
angleInc = 0.1;

for (cAngle = 0:angleInc:2*pi)
    angle1 = cAngle;
    angle2 = cAngle+angleInc;
    [x1 y1] = getGaussian2SD(m,s,angle1);
    [x2 y2] = getGaussian2SD(m,s,angle2);
    plot([x1 x2],[y1 y2],'k-','LineWidth',2);
end

%drawGaussian in LOG LOG
function r= drawGaussian2DExp(m,s)

hold on;
angleInc = 0.1;

for (cAngle = 0:angleInc:2*pi)
    angle1 = cAngle;
    angle2 = cAngle+angleInc;
    [x1 y1] = getGaussian2SD(m,s,angle1);
    [x2 y2] = getGaussian2SD(m,s,angle2);
    loglog(exp([x1 x2]),exp([y1 y2]),'k-','LineWidth',2);
end

%find position of in xy co-ordinates at 2SD out for a certain angle
function [x,y]= getGaussian2SD(m,s,angle1)

vec = [cos(angle1) sin(angle1)];
factor = 4/(vec*inv(s)*vec');

x = cos(angle1) *sqrt(factor);
y = sin(angle1) *sqrt(factor);

x = x+m(1);
y = y+m(2);

%return whether insied 2D Gaussian
function r= insideGauss2SD(m,s,x)

r= (((x-m)*inv(s)*(x-m)')<4);
