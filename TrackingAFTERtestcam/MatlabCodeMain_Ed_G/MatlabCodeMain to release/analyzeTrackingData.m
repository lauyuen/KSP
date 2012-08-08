function r=analyzeTrackingData(used,occluded,x,y);
%analyzes training label data to extract statistics about frequency of people in scene etc.


%label matrix can be loaded using
% load ('D:/CrestechNewLab/labelTraining');
% [nFrames nPeople] = size(labels);
% used = zeros(nFrames,nPeople); occluded = zeros(nFrames,nPeople); x = zeros(nFrames,nPeople); y = zeros(nFrames,nPeople);
% for (cFrame = 1:nFrames)
%    for (cPeople = 1:nPeople)
%       used(cFrame,cPeople) = labels(cFrame,cPeople).used;
%       x(cFrame,cPeople) = labels(cFrame,cPeople).x;
%       y(cFrame,cPeople) = labels(cFrame,cPeople).y;
%       occluded(cFrame,cPeople) = labels(cFrame,cPeople).occluded;
%    end;
% end

%number of frames skipped over
nFrameSkip = 10;
%count number of frames and people
[nFrames nPeople] = size(occluded);

%=================================================
%1.  Calculate mean number of frames stay in image
%=================================================

meanFramesInImage = mean(sum(used))*nFrameSkip

%==================================================
%2.  Calculate probability a new person will appear
%==================================================

probabilityAppear = nPeople/(nFrames*nFrameSkip)

%==================================================
%3.  Calculate mean number of people per image
%==================================================

meanNumberPerImage = mean(sum(used,2))

%==================================================
%4.  Calculate prob remains in scene
%==================================================

probRemainsInScene = mean(((sum(used)*10)-1)./(sum(used)*10))

%==================================================
%5.  Calculate motion vector
%==================================================

motionVecs = [];
for (cPeople = 1:nPeople)
    inImageIndices = find(used(:,cPeople));
    firstFrame = min(inImageIndices);
    lastFrame = max(inImageIndices);
    if (firstFrame<lastFrame)
        theseMotionVecs = [x(firstFrame+1:lastFrame,cPeople)-x(firstFrame:lastFrame-1,cPeople) y(firstFrame+1:lastFrame,cPeople)-y(firstFrame:lastFrame-1,cPeople)];
        motionVecs = [motionVecs; theseMotionVecs];
    end;
end;

motionVecs = motionVecs/nFrameSkip;

xHist = hist(abs(motionVecs(:,1)),[1:15])
yHist = hist(abs(motionVecs(:,2)),[1:15])

figure;
subplot(1,2,1);
bar(xHist); xlabel('X Movement'); ylabel('Frequency');
subplot(1,2,2);
bar(yHist);xlabel('Y Movement'); ylabel('Frequency');


mean(motionVecs)
std(motionVecs)

%==================================================
%6.  Calculate mean and SD height
%==================================================

yPosns = [];
for (cPeople = 1:nPeople)
    inImageIndices = find(used(:,cPeople));
    firstFrame = min(inImageIndices);
    lastFrame = max(inImageIndices);
    if (firstFrame<=lastFrame)
        yPosns = [yPosns; y(firstFrame:lastFrame,cPeople)];
    end;
end;
meanYPosn = mean(yPosns)
stdYPosn = std(yPosns)

break;
%==================================================
%6.  Calculate distances between people
%==================================================

distVecs =[];
for (cFrame = 1:nFrames)
     peopleInFrame = find(used(cFrame,:));
     for (cFirstPerson = [peopleInFrame])
         for (cSecondPerson = [peopleInFrame])
            if (cFirstPerson~=cSecondPerson)
                distVecs = [distVecs; x(cFrame,cFirstPerson)-x(cFrame,cSecondPerson) y(cFrame,cFirstPerson)-y(cFrame,cSecondPerson)];
            end;
         end;
     end;
end;


distVecs1D = sum(distVecs.^2,2);
N = hist(distVecs1D,100);
figure;
bar(N);
xlabel('Distance Between People')
ylabel('Frequency')