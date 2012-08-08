function params = fit3Gauss(distribution,plotFlag)
%fit mixture of three Gaussians to a distribution

%make sure distribution is a column vector
if (size(distribution,2)>size(distribution,1))
    distribution = distribution';
end;

%analyze distribution
minDist = min(distribution)
maxDist = max(distribution)
nData = length(distribution);
range = maxDist-minDist;


meanVal = mean(distribution)
stdVal = std(distribution)

%initialize parameters
mu =  zeros(1,3);
sig = (1/6)*range*ones(1,3);
pi =  (1/3)*ones(1,3);
mu(1) = minDist+range*1/4;
mu(2) = minDist+range*2/4;
mu(3) = minDist+range*3/4;
%mu(1) = meanVal-stdVal;
%mu(2) = meanVal;
%mu(3) = meanVal+stdVal;

pFromModel = zeros(nData,3);


if (plotFlag==1)
    figure;
end;


nIter = 0;
maxIter = 200;
while(1)
    %E-step
    
    pFromModel(:,1) = (1/(sqrt(2*3.1413*sig(1)*sig(1))))*exp(-0.5*(distribution-mu(1)).*(distribution-mu(1))/(sig(1)*sig(1)));
    pFromModel(:,2) = (1/(sqrt(2*3.1413*sig(2)*sig(2))))*exp(-0.5*(distribution-mu(2)).*(distribution-mu(2))/(sig(2)*sig(2)));
    pFromModel(:,3) = (1/(sqrt(2*3.1413*sig(3)*sig(3))))*exp(-0.5*(distribution-mu(3)).*(distribution-mu(3))/(sig(3)*sig(3)));
    pFromModel = pFromModel./repmat(sum(pFromModel,2),1,3);
    
    %M-step
    pi = sum(pFromModel); pi = pi/sum(pi);
    newMu = sum(pFromModel.*repmat(distribution,1,3))./sum(pFromModel);
    muMatrix = repmat(newMu,nData,1);
    newSig = sum(pFromModel.*((muMatrix-repmat(distribution,1,3)).^2))./sum(pFromModel);
    newSig = sqrt(newSig);
    
    %see if parameters have changed enough to be worth doing
    change = sum((newMu-mu).^2)+sum((newSig-sig).^2);
    if (nIter>maxIter)
        break;
    end;
    nIter= nIter+1;
    mu = newMu;
    sig = newSig;
    
    if (plotFlag)
        hold off;
        X = minDist:(maxDist-minDist)/150:maxDist;
        N = hist(distribution,X);
        %normalize values so we can plot CDF
        N = N/length(distribution);
        N = N/(X(2)-X(1));
        bar(X,N);hold on;
        xlim([minDist maxDist]);
        
        %plot gaussians
        X = minDist:(maxDist-minDist)/1000:maxDist;
        p1 =   pi(1)*(1/(sqrt(2*3.1413*sig(1)*sig(1))))*exp(-0.5*(X-mu(1)).*(X-mu(1))/(sig(1)*sig(1)));
        p2 =   pi(2)*(1/(sqrt(2*3.1413*sig(2)*sig(2))))*exp(-0.5*(X-mu(2)).*(X-mu(2))/(sig(2)*sig(2)));
        p3 =   pi(3)*(1/(sqrt(2*3.1413*sig(3)*sig(3))))*exp(-0.5*(X-mu(3)).*(X-mu(3))/(sig(3)*sig(3)));
        plot(X,p1+p2+p3,'r-');
        plot(X,p1,'b--');
        plot(X,p2,'g--');
        plot(X,p3,'m--');
        drawnow;
    end;
end;
params = [pi;mu;sig];