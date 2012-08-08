function r= cumGauss(X)

if (X>0)
    X = 0.5+erf(X/sqrt(2))/2;
else
    X = 0.5-erf(-1*X/sqrt(2))/2;
end;

r = X;