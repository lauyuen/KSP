function nonHeadPos = generateNonHead(actHeadPosn)

xSize = 256;
ySize = 128;
distanceThreshold = 12;

for  i=1:length(actHeadPosn)
    hc = actHeadPosn{i};
    nonHeadPos{i} = hc;
    if ~isempty(hc)
        for c = 1:size(hc(:, 1))
            xy = generateRandPair(hc, distanceThreshold, xSize, ySize);
            nonHeadPos{i}(c, :) = xy;
        end
    end
end


function xy = generateRandPair(hc, distanceThreshold, xSize, ySize)

flag = 1;
while flag
    xy = [round(rand(1)*xSize), round(rand(1)*ySize)];
    if xy(1) < 1
        xy(1) =1;
    end
    if xy(2) < 1
        xy(2) =1;
    end
    if xy(1) >xSize
        xy(1) =xSize;
    end
    if xy(2) > ySize
        xy(2) = ySize;
    end
    
    
    flag = 0;
    for i = 1:size(hc, 1)
        actHead = hc(i, :);
        distance = sqrt(sum((actHead-xy).^2));
        if distance < distanceThreshold
            flag = 1;
        end
    end
end

            



            
            
           