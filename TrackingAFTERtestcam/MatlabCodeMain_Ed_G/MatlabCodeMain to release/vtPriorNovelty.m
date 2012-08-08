function priorNovelty= vtPriorNovelty(lastPosn,prevPosterior,kernel);
%implements novelty prior for visual tracker

%KERNEL SIZE
[kernY kernX] = size(kernel);
[imY imX] = size(prevPosterior);
largeOutImage = ones(3*imY,3*imX);
lastPosn = lastPosn+[imX imY];
lastPosn = lastPosn-[(kernY-1)/2 (kernX-1)/2];
largeOutImage(lastPosn(2)+1:lastPosn(2)+kernY,lastPosn(1)+1:lastPosn(1)+kernX) = kernel;
priorNovelty = largeOutImage(imY+1:2*imY,imX+1:2*imX);


%verySmallNumber = 0.0000000001;
%priorNovelty = normalization(priorNovelty, [verySmallNumber 1-verySmallNumber]);
