function localMaxima = findLocalMaxima(posterior, posteriorThresh)

    
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

if nargin == 2
%find local maxima where above threshold
localMaxima = localMaxima.*posterior;
localMaxima = localMaxima.*(localMaxima>posteriorThresh);
localMaxima(:,1) = 0; localMaxima(:,end) = 0; localMaxima(1,:) = 0; localMaxima(end,:) = 0;
end

