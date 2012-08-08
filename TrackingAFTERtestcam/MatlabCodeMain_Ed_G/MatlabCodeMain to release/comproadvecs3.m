function Pos3D = comproadvecs3(RM2UTM,T, RC2M, X, focal, pp)
% Pos3D = comproadvecs3(RM2UTM,T, RM2UTM, POINT, focal, pp)
% X -> any point on the image to be backprojected
% P -> any point in UTM to be projected
pixelsize =0.0090;
x = (X(1) - pp(1))*pixelsize;
y = (X(2) - pp(2))*pixelsize; %switch y to positive up in the image
%I think this makes sense if z is positive out of the page (right-hand
%system)
% T = [620538    239  4847268]'; %Location of optical centre, in UTM coords
YA =  196; % Height of ground surface
n = [0 0 1]; %Ground plane normal
p_0 = [ 0 0 YA]'; %Arbitrary point on ground plane
l_0 = T; %Location of optical centre, in UTM coords
%Are we sure this is supposed to be -focal and not +focal?
% RC2M(:,3) = -RC2M(:,3);
l = RM2UTM*RC2M*[x;y; focal]; % Vector in direction of pixel from optical centre

% n
% p_0
% l_0
% l
% T

d = dot((p_0' - l_0'), n)/dot(l, n); %Distance of intersection from optical centre



Pos3D = T + d*l; %Location of intersection in UTM coords



 
