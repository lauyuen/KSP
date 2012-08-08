function [rocData] = buildRoc(bestLikeRatioHead, bestLikeRatioNonHead)
 
%convert to columns if in rows
if (size(bestLikeRatioHead,2)>size(bestLikeRatioHead,1))
    bestLikeRatioHead = bestLikeRatioHead';
    bestLikeRatioNonHead = bestLikeRatioNonHead';
end;


%append zeros and ones to data
bestLikeRatioHead = [bestLikeRatioHead ones(length(bestLikeRatioHead),1)];
bestLikeRatioNonHead = [bestLikeRatioNonHead zeros(length(bestLikeRatioNonHead),1)];

%put data all in one matrix
dataAll = [bestLikeRatioHead; bestLikeRatioNonHead];
%sort
dataAll = sortrows(dataAll,1);
%extract sorted ones and zeros
pointOrder = dataAll(:,2);

%measure total length of each data set
nHeadPts = length(bestLikeRatioHead);
nNonHeadPts = length(bestLikeRatioNonHead);

%initalize with total headPts
totalHeadAfterHere=nHeadPts;
totalNonHeadAfterHere = nNonHeadPts;

for (c1 = 1:nHeadPts+nNonHeadPts)
    if(pointOrder(c1))
        totalHeadAfterHere = totalHeadAfterHere-1;
    else
        totalNonHeadAfterHere = totalNonHeadAfterHere-1;
    end;
    rocData(c1,1) = totalHeadAfterHere/nHeadPts;
    rocData(c1,2) = totalNonHeadAfterHere/nNonHeadPts;
end;

rocData = [[1 1];rocData;[0 0]];



%points = -50:0.1:50;
%rocData = zeros(length(points), 2);
%norm1 = length(bestLikeRatioHead);
%norm2 = length(bestLikeRatioNonHead);
%for k = 1:length(points)
%    mask = bestLikeRatioHead >= points(k);
%    rocData(k, 1) = sum(mask)/norm1;
%    mask = bestLikeRatioNonHead >= points(k);
%    rocData(k, 2) = sum(mask)/norm2;
%end