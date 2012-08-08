function Ed_MeanShift_D( X, show_figs )

% By: Eduardo Corral, May/2011
% Implementation of Mean Shift algorithm to find the modes of the pdf
% corresponding to a set of input feature vectors, in this case, points
% coordinates.
%
% Implementation based on "Mean Shift: A Robust Approach Toward Feature
% Space Analysis" (2002) by D. Comaniciu and P. Meer
% clear all
% clc
% load Salida
% [X_y, X_x] = find(Salida > 0);
% X = [X_x X_y];


Xo = X;

if show_figs
    figure(10)
    clf(10)
%     subplot(2,1,1)
%     plot(Xo(:,1), -Xo(:,2), '.')
%     axis([1 160 -120 1])
%     grid on

%    subplot(2,1,2)
    axis([1 160 -120 1])
    grid on
    hold on
end

%***********************************************************************
% We will use a Gaussian kernel exp(-0.5 * (x-xi)^2 / h )
%***********************************************************************
[N D dummy] = size(X); %Number of feature vectors

% Bandwith parameter for Gaussian kernel
%sigma = 1;
sigma = 6;
h = sigma^2;

for iter = 1:5

        % pdf estimated values:
        %f = zeros(N,1);    
        % The kernel is centered at point "n"
        
        for n = 1:N
            
            x = X(n, :).'; %<--We center the kernel at this feature vector location
            
            Xp = [ x(1)*ones(N,1)  x(2)*ones(N,1) ];            

            % Vectorized implementation to make it faster
            dist = Xo - Xp;
            diff_sqnorms =  dist(:,1).^2  + dist(:,2).^2 ;
            gs = (1/(sqrt(2*pi*h))) * exp((-0.5/h) * diff_sqnorms );
            prods = [gs gs] .* Xo;
            y_num = sum(prods).';
            Sum_g = sum(gs);
            
            % Brute force implementation:
%             Sum_g = 0;    
%             y_num = zeros(2,1);            
%             for i=1:N  % Now we compute kernel with all other vectors from data set
%                 xi = Xo(i, :).'; 
%                 g = (1/(sqrt(2*pi*h))) * exp(-0.5 * norm(x-xi)^2 / h ); %<--Kernel
%                 y_num = y_num + g*xi; % y's numerator       
%                 Sum_g = Sum_g + g;    % y's denominator
%             end

            yn = y_num/Sum_g;
            mn = yn - x; %<--Mean shift vector

            %Draw mean shift vector
            %line( [x(1) x(1)+mn(1)], [x(2) x(2)+mn(2)],   'color', 'r', 'LineWidth', 3 );

            % Estimate pdf at this location
            %f(n) = Sum_g/N;

            % Translate kernel according to meanshift vector
            X(n,:) = X(n,:) + mn.';

            dummy=1;
        end
        
end % for iter = 1:3        

%fmax = max(f);


if show_figs
    for n=1:N
        %plot(X(n,1), -X(n,2), '.', 'Color', [0 0 f(n)/fmax])
        plot(X(n,1), -X(n,2), '.')
    end
    axis([1 160 -120 1])
    hold off
    grid on
end

%toc



