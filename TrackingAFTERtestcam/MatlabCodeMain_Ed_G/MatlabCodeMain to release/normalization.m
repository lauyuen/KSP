function x = normalization(x, range1);
%
% linear tranform x such that x falls between range1(1) and range1(2)
%
x = (x-min(x(:)))./(max(x(:))-min(x(:)));
x = (x+range1(1))*(range1(2) - range1(1));
