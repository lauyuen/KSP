function priorTracking= vtPriorTracking(prevPosterior)
 


kernelX =1000* [ 6.7680    1.6035    0.4955    0.2225    0.1405    0.0870    0.0650    0.0430    0.0320 0.0265    0.0170    0.0120    0.0130    0.0075    0.0045    0.0030    0.0045    0.0040 ];
kernelY =1000* [    8.0250    1.6750    0.3615    0.0675    0.0260    0.0090    0.0025    0.0030    0.0040 0.0030    0.0010         0    0.0015    0.0010         0    0.0005    0.0010    0.0020 ];
 

%create kernels
kernelX = [fliplr(kernelX(2:end)) kernelX];  
kernelY = [fliplr(kernelY(2:end)) kernelY]; 

%normalize kernel to represent probability of a given head remaining in scene
kernelXY = kernelY'*kernelX;
kernelX = kernelX*sqrt(0.95948/sum(kernelXY(:)));
kernelY = kernelY*sqrt(0.95948/sum(kernelXY(:)));         %0.95948 is probability that a given head remains in the scene

priorTracking = conv2(kernelX,kernelY,prevPosterior,'same');

%verySmallNumber = 0.0000000001;
%priorTracking = normalization(priorTracking, [verySmallNumber 1-verySmallNumber]);
