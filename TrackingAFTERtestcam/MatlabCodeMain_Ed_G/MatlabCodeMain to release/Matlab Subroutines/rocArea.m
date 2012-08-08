function [area] = rocArea(f)
%============ find the area under ROC curve==============

[total dim] = size(f);
    if dim ~= 2
        fprintf('Everything is wrong!\n');
    end
k = 2:total;
%force ends to have correct values - 
f = [[1 1];f;[0 0]];
areaTable(k) = 0.5*(f(k,1) + f(k-1,1)).*(f(k-1,2) - f(k,2));
area = sum(areaTable);
