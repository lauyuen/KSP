function priorSpatial= vtPriorSpatial(imX, imY)
%returns spatial prior for visual tracker

PRIOR_MEAN = 0.4588;      %proportion down screen
PRIOR_SD   = 0.09202;     %proportion of height
PRIOR_BASE = 0.0000000001;        %minimum value anywhere (prior never less than this)
PRIOR_AREA  = 0.002452;   %integrates to probability of face appearing in image 

PRIOR_MAX = PRIOR_AREA*1/(256*2*pi*PRIOR_SD);  


heightMap = repmat((1:imY)',1,imX);
heightMap = heightMap - PRIOR_MEAN*imY;

priorSpatial = PRIOR_MAX*exp(-0.5*(heightMap.^2)/((PRIOR_SD.*imY)^2));
priorSpatial = priorSpatial*0.00252/sum(priorSpatial(:));  %quick hack as amplitude calculation above seems to be wrong
priorSpatial = max(priorSpatial,PRIOR_BASE);

%verySmallNumber = 0.0000000001;
%priorSpatial = normalization(priorSpatial, [verySmallNumber 1-verySmallNumber]);
