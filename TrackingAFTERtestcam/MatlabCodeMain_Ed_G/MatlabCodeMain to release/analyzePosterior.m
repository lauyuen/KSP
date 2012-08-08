function [estHeadPosns,hits,misses,falsePositives,bodyFPs,peakHitHead]= analyzePosterior(posterior,actualHeadPosns, minDistBWEstimates);
%plot the posterior map with the likelihood ratios, peaks in map and real head positions
%=======================================================================================

%DEFINITIONS

maxPost = max(posterior(:))

%minDistBWEstimates = 12;             % minimum distance between the estimated head positions
posteriorThresh = 0.01;               % must be above this value to be considered a potential head


%ESTIMATE FINAL POINT POSITIONS

%find local maxima
[ySize xSize] = size(posterior);
leftImage = [posterior(:,2:end) ones(ySize,1)];
rightImage = [ones(ySize,1) posterior(:,1:end-1)];
topImage = [posterior(2:end,:);ones(1,xSize)];
bottomImage = [ones(1,xSize) ; posterior(1:end-1,:)];
topLeftImage = [topImage(:,2:end) ones(ySize,1)];
bottomLeftImage = [ones(1,xSize); leftImage(1:end-1,:)];
topRightImage = [rightImage(2:end,:);ones(1,xSize)];
bottomRightImage = [ones(1,xSize); rightImage(1:end-1,:)];
localMaxima = (posterior>leftImage)&(posterior>rightImage)&(posterior>topImage)&(posterior>bottomImage)&(posterior>topLeftImage)&(posterior>topRightImage)&(posterior>bottomLeftImage)&(posterior>bottomRightImage);


%find local maxima where above threshold
localMaxima = localMaxima.*posterior;
localMaxima = localMaxima.*(localMaxima>posteriorThresh);
localMaxima(:,1) = 0; localMaxima(:,end) = 0; localMaxima(1,:) = 0; localMaxima(end,:) = 0;
    
%extract estimated positions of head and best overall position
estHeadPosns= find(localMaxima);
estHeadStrength = localMaxima(estHeadPosns);
estHeadPosns = [floor(estHeadPosns/ySize) rem(estHeadPosns,ySize)];

%sort estimated head positions - needed for when we eliminate close points
[trash index] = sort(estHeadStrength);
estHeadPosns = flipud(estHeadPosns(index,:));
%eliminate weaker point where points are close
estHeadPosns = eliminateTooClose(estHeadPosns,minDistBWEstimates);

%extract best head posn
if (length(estHeadPosns>0))
    mostLikelyHeadPosn = estHeadPosns(1,:);
else
    %set to highest point in map
    bestMax =find(posterior==max(posterior(:)));
    mostLikelyHeadPosn = [floor(bestMax(1)/ySize) rem(bestMax(1),ySize)];
end;

%calculate statistics for all estimated positions
hitsMisses= getHeadHits(estHeadPosns,actualHeadPosns);
hits = sum(sum(hitsMisses,1)>0);
misses = sum(sum(hitsMisses,1)==0);
falsePositives = sum(sum(hitsMisses,2)==0);

if (length(estHeadPosns)>2)
%    keyboard;
end;

%calculate false positives that were probably on bodies
fpIndex = find(sum(hitsMisses,2)==0);
bodyFPs = 0;
if (~isempty(fpIndex)&~isempty(actualHeadPosns))
 %   keyboard;
    for (cIndex = fpIndex)
        estPoint = estHeadPosns(cIndex,:);
        closeHorz = find(abs(estPoint(1)-actualHeadPosns(:,1))<30);
        if(length(closeHorz)>0)
            %test if below 
            belowVert = find(((actualHeadPosns(closeHorz,2)-estPoint(2))>-60)&((actualHeadPosns(closeHorz,2)-estPoint(2))<0));
            if (length(belowVert)>0)
                bodyFPs = bodyFPs+1;
            end;
        end;
    end;
end;

%disp(sprintf('Heads = %d, Hits = %d, Misses = %d, FalsePositives = %d',size(actualHeadPosns,1),hits,misses,falsePositives));

%calculate statistics for best maxima
hitsMisses = getHeadHits(mostLikelyHeadPosn,actualHeadPosns);
if (sum(hitsMisses(:))>0)
%    disp('Overall Maximum Hit Head!');
    peakHitHead = 1;
else;
%    disp('Overall Maximum Missed Head!');
    peakHitHead = 0;
end;    

%now plot the overall posterior with all points
%plot posterior;
%imagesc(posterior); axis off; colormap(gray); hold on;
%plot estimated positions
plot(estHeadPosns(:,1),estHeadPosns(:,2),'r+');
%plot best position
plot(mostLikelyHeadPosn(1),mostLikelyHeadPosn(2),'g+');
%plot actual positions
if (length(actualHeadPosns)>0)
    plot(actualHeadPosns(:,1),actualHeadPosns(:,2),'mo');
end;
hold off;

%==========================================================

function r= getHeadHits(h1,h2)

n1 = size(h1,1);
n2 = size(h2,1);

headHits = zeros(n1,n2);
for (c1 = 1:n1)
    for (c2= 1:n2)
        distance =(h1(c1,:)-h2(c2,:)).^2;
        distance = sqrt(sum(distance(:)));
        if (distance<12)
            headHits(c1,c2) =1;
        end;
    end;
end;
r = headHits;

%==========================================================

function r= eliminateTooClose(X,thresh)
index = 1;
X(:,2)=X(:,2)/2; %weight vert distance less 
while(index<=size(X,1))
    distances = repmat(X(index,:),size(X,1),1)-X;
    distances = sqrt(sum(distances.^2,2));
    X = X(find(distances>thresh|distances==0),:);
    index = index+1;
end;
r = X;
r(:,2) = r(:,2)*2;
%==========================================================





%Frames 3535, Actual Heads 6706, Estimated Heads 6124, Hits 3521, Misses 3185, False Pos 2740, FP Bodys 454, PeaksHitHead 1963