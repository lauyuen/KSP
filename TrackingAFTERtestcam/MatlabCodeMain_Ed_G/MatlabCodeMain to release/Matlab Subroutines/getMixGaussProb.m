function p = getMixGaussProb(params,X)
prop = params(1,:);
mu = params(2,:);
sig = params(3,:);
p1 =   prop(1)*(1/(sqrt(2*3.1413*sig(1)*sig(1))))*exp(-0.5*(X-mu(1)).*(X-mu(1))/(sig(1)*sig(1)));
p2 =   prop(2)*(1/(sqrt(2*3.1413*sig(2)*sig(2))))*exp(-0.5*(X-mu(2)).*(X-mu(2))/(sig(2)*sig(2)));
p3 =   prop(3)*(1/(sqrt(2*3.1413*sig(3)*sig(3))))*exp(-0.5*(X-mu(3)).*(X-mu(3))/(sig(3)*sig(3)));
p = p1+p2+p3;
