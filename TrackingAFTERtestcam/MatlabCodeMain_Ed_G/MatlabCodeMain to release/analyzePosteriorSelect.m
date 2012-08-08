clear all
close all

showflag = 1;
minDistBWEstimates = 12;

totalEstHeads = 0; totalHits = 0; totalMisses =0; totalFPs = 0; totalBodyFPs = 0;totalActHeads=0;totalPeakHitHead = 0;totalFrames = 0;
framesWithSomeHeads =0;

load 'D:\Bob\crestechLabSelect results on Treehouse\HeadPositionsCrestechSelect.mat'
headPosCrestech = hc;

load 'D:\Bob\crestechLabSelect results on Treehouse\HeadPositionsLabSelect.mat'
headPosLab = hc;

headPos = [headPosCrestech, headPosLab];
numFrame = [821 861 1341 1381 1461];

for i = numFrame
    filename = sprintf('C:/users/yhou/sensorData1/image%d.jpg', i);
    im = imread(filename, 'jpg');
    
    headPosns = headPos{i};
    
    filename = sprintf('C:/users/yhou/sensorData1/posterior%d.mat', i);
    load (filename);
    filename = sprintf('C:/users/yhou/sensorData1/logLikeRatioAll%d.mat', i);
    load (filename);
    [estPosns,hits,misses,falsePositives,bodyFPs,peakHitHead]= analyzePosterior(posterior,headPosns, minDistBWEstimates);
    
    
    totalActHeads = totalActHeads+size(headPosns,1);
    totalEstHeads = totalEstHeads+size(estPosns,1);
    totalHits = totalHits+hits;
    totalMisses = totalMisses+misses;
    totalFPs = totalFPs+falsePositives;
    totalBodyFPs = totalBodyFPs+bodyFPs;
    totalPeakHitHead = totalPeakHitHead+peakHitHead;;
    totalFrames = totalFrames+1;
    
    if showflag
        subplot(311)
        [ySize, xSize] = size(posterior);
        bestMax =find(posterior==max(posterior(:)));
        mostLikelyHeadPosn = [floor(bestMax(1)/ySize) rem(bestMax(1),ySize)];
        
        imagesc(im); axis off; 
        
        title(['image',  num2str(i)]);
        if ~isempty(headPosns)
            hold on;
            for p = 1:size(headPosns, 1)
                plot(headPosns(p, 1), headPosns(p, 2), 'ro');
            end
            plot(mostLikelyHeadPosn(1), mostLikelyHeadPosn(2), 'c*')
            hold off;
        end
        
        subplot(312)
        imagesc(posterior); axis off; colormap(gray)
        subplot(313)
        imagesc(logLikeRatioAll); axis off; colormap(gray)
        pause;
    end
    
end


totalHits/(totalHits+totalMisses)