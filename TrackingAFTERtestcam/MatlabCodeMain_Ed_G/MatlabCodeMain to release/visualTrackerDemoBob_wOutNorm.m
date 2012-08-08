function visualTrackerDemoBob_wOutNorm
clear all;
vidobj = openAxisCam;
% Background Subtraction-based objects <people/cars> tracking used in
% GEOIDE/OCE demos 2011.
% Prepared by: Eduardo Corral on May/2011

%find total number of files to be processed
%filePath = 'D:/CrestechNewLab/';
filePath = 'C:\Eduardo\TrackingAFTERtestcam\MatlabCodeMain_Ed_G\';

%**************************************************************************
% % YORK security camera-----------------------------------------------------
% %imageStart = 0;    % Bicycle
% %imageStart = 240;  % Guy walking towards camera
% imageStart = 520; %482;  % Guy walking across image
% Nframes = 200; %30;

% %**************************************************************************
% % TrendNet camera-----------------------------------------------------
% %imageStart = 210;
% imageStart = 0;
% %imageStart = 500;
% Nframes = 1468; %500; %2000; %150;
%**************************************************************************
% % Highway 401 Liverpool
% imageStart  = 0; %40; %0;
% Nframes     = 88; %20; %88; %150;5
%**************************************************************************
% AXIS camera-----------------------------------------------------
imageStart = 0;
Nframes    = 1272;
%**************************************************************************



%##########################################################################
% SYSTEM OPTIONS:
Generate_AVI = 0; %1;         % Generate demo AVI video from figure (runs slower)
Disp_Input_and_Blobs = 0;     % Display a figure with input and blobs
Display_Output       = 1; %1; % Display final tracking results (squares overlayed)

V_Scaling = 4;              % Image downscaling factors
H_Scaling = 4;
TimeDownSampling = 4;       % Image sequence temporal downsampling  %TrendNet camera: 6, Higwhay images: 3

%Thr = 25; % WITH NORMALIZATION % Threshold for posterior differences
Thr = 0.15; % NO  NORMALIZATION % Threshold for posterior differences
Sq_H = 20; % 5; % Height of drawn squares
Sq_W = 10; % 5; % Width  of drawn squares
LocationsClosenessThr = 5; %15; % Detections merging distance

fltL = 13;%13; % 2D filter parameters (depend on image shrink factors)
fltsigmay = 9; % 7; %5;
fltsigmax = 1.5; % 7; %3;

Peak_Detection_Sensitivity = 0.9; %0.5;  %Used in the peak-searching algorithm

% Mapping between image and real-world distances: Lane marks approximate measurement/scaling
p1 = [129 212]; %<--End points of a lane mark on a 480x640 rectified 401 Liverpool image
p2 = [147 226];
LaneMLength_pxls = norm(p1 - p2);
LaneMLength_Km = 0.0010; % From real world highway: 1.0 meters = 0.0010 Km
DeltaTime_hrs = (1/60) * (1 / 3600);

% Path for output tracking results for GEOIDE demo (requested by Larry)
TargetXMLpath = 'C:\Eduardo\TrackingAFTERtestcam\SampleXML_fromLarry';
%##########################################################################


%Locations = cell(1,1); % We will store the locations in a cell array

% Make a list of file names:
nexindx = 1;
for (c1 = imageStart : imageStart + Nframes);
    %Decimate in time
    if ~(mod(c1, TimeDownSampling))%
        %fileList{nexindx} = sprintf('C:/EC/York/GEOIDEWork2011/YorkVideoDVDs/Bob1/BobCam1_%05d.bmp',c1);
        %fileList{nexindx} = sprintf('C:/EC/York/MTO/Ed_MTO_Seqs/Hwy_401Liverpool/Rect/Hwy401LiverpoolRect_%05d.bmp',c1);
        fileList{nexindx} = sprintf('C:/Eduardo/TrackingAFTERtestcam/Campus0_bmp/Campus0_%05d.bmp',c1);
        nexindx = nexindx + 1;
    end
end;

%initialize parameters for 3 modules
visTrackParams.modelBasename = [filePath, 'CrestechLabTrainingLikeDist'];           %tell visual tracker which model parameters to use



%create new figure
if Disp_Input_and_Blobs
    h = figure(1);
end

if Generate_AVI
    % Make an avi file
    mov = avifile('example.avi', 'compression', 'Cinepak', 'fps', 12, 'quality', 100);
end

%-------------------------------------------------------------------------
% 2D Filter
% fltL = 9;%13; % Parameters defined with images shrunk by a factor of 4
% fltsigmay = 5; % 7; %5;
% fltsigmax = 3; % 7; %3;
% fltL = 15;%13; % Parameters defined with images shrunk by a factor of 4
% fltsigmay = 11; % 7; %5;
% fltsigmax = 11; % 7; %3;
fltx = -(fltL-1)/2 : (fltL-1)/2;
fltG1 = exp( -(fltx.^2)./(2*fltsigmay^2) );
fltG2 = exp( -(fltx.^2)./(2*fltsigmax^2) );
flth = fltG1.' * fltG2;
flth = flth/sum(sum(flth));
%imagesc(flth)

% flth = 0*flth;
% flth(7,7) = 1;

%-------------------------------------------------------------------------

% Extract size of images
filename = fileList{1};
%im = imread(filename,'bmp');
im = grabAxisImage(vidobj);
[ROWS COLS DEPTH] = size(im);

% Initialize previous bckgnd subtr. array
Prev_BckgndSubtrResult = zeros(round(ROWS/V_Scaling), round(COLS/H_Scaling));


Centres_Prev = '';



%**************************************************************************
% Read image files from hard drive
%**************************************************************************
%for each file
%for (cFile = 1:length(fileList))
count = 0;
tic
while 1
    count = count + 1;
    %filename = fileList{cFile};
    
    %disp(cFile)
    
    %im = imread(filename,'jpg');
    %im = imread(filename,'bmp');
    im = grabAxisImage(vidobj);
    im_orig = im;
    
    % Shrink image
    im = imresize(im, round([ROWS/V_Scaling   COLS/H_Scaling])  );
    
    %main precessing
    [posterior   visTrackParams   BckgndSubtrResult] = visualTracker(im,visTrackParams);
    RunningTime_BkgndSubtr = toc;
    
    if Disp_Input_and_Blobs
        figure(1)
        %subplot(2,1,1)
        %image(im)
        %xlabel('Input')
        %subplot(2,1,2)
    end
    
    Diferencia = abs(BckgndSubtrResult - Prev_BckgndSubtrResult);
    
%     %---------------------------------------------------------
%     % Original code with normalization
%     Salida = Diferencia;
%     Salida = Salida - min(min(Salida)); %Shift down
%     Salida = 255*  (Salida / (max(max(Salida))));  %Normalize
%     Salida((Salida < Thr)) = 0;
%     
%     Salida = Salida - min(min(Salida)); %Shift down
%     Salida = imfilter(Salida, flth);
%     Salida = 255*  (Salida / (max(max(Salida))));  %Normalize
    
    %---------------------------------------------------------
    % Original code with normalization
    Salida = Diferencia;
    Salida = Salida - min(min(Salida)); %Shift down
    
    %Salida((Salida < Thr)) = 0;
    
    Salida = Salida - min(min(Salida)); %Shift down
    Salida = imfilter(Salida, flth);
    Salida((Salida < Thr)) = 0;
    %---------------------------------------------------------
    
    
    
    
    
    if Disp_Input_and_Blobs
        %image( 255* BckgndSubtrResult )
        %imagesc( Diferencia )
        imagesc( Salida )
        
        %plot( Salida.' )
        %axis([1 COLS/H_Scaling 0 0.2])
        
        
        % surf( fliplr(Salida ))
        % view(180,70)
        xlabel('Bckgnd Subtr. Posterior')
    end
    %------------------------------------------------------------------------
    % %Call Mean shift:
    % [X_y, X_x] = find(Salida > 0);
    % X = [X_x X_y];
    %
    % if (size(X,1) < 800)&(size(X,1) > 0)
    %     %
    %     Ed_MeanShift_D( X, 1 );
    %     %toc
    % end
    %------------------------------------------------------------------------
    % Direct peaks finding
    
    [Peaks, There_Are_Peaks] = PeakDet_2D(Salida, Peak_Detection_Sensitivity, round(ROWS/V_Scaling), round(COLS/H_Scaling));
    RunningTime_PeakFinding = toc;
    
    [my mx] = find(Peaks > 0);
    %Centres = [mx my];
    
%     if length(my) > 20
%         my = '';
%         mx = '';
%     end
    
    
    if isempty(mx)
        Centres = [mx my];  %Third element will be used to store speed
    else
        Centres = [H_Scaling*mx   V_Scaling*my  zeros( size(mx,1),1 )];
    end
    
    %Locations{cFile,1} = Centres;
    
    %------------------------------------------------------------------------
    % Display running times
    %disp([RunningTime_BkgndSubtr  RunningTime_PeakFinding  (RunningTime_BkgndSubtr + RunningTime_PeakFinding)])
    %disp([(RunningTime_BkgndSubtr + RunningTime_PeakFinding)]);
    
    if Display_Output
        h2 = figure(2);
        clf(2);
        %image(im);
        image(im_orig);
        hold on
    end % if Display_Output
    
    if ~isempty(mx) % ~isempty(Centres)
        %----------------------------------------------------------
        %Merge detections that are too close to eachother:
        %----------------------------------------------------------
        for i=1:size(Centres,1)-1
            for j = i+1 : size(Centres,1)
                
                dist = sqrt( sum( ( Centres(i, 1:2)-Centres(j, 1:2) ).^2 ) );
                if dist < LocationsClosenessThr
                    Centres(i, 1:2) = ( Centres(i, 1:2) + Centres(j, 1:2) )/2;
                    Centres(j, 1:2) = [999 999];
                end
                dummy=1;
                
            end
        end
        
        dummy = Centres(:,1);
        indx = find(dummy == 999);
        Centres(indx, :) = ''; %Remove entries that were merged
        
        Npts = size(Centres,1);
        NPrevpts = size(Centres_Prev,1);
        
        for m=1:Npts
            %----------------------------------------------------------
            %Associate detections with PREVIOUS surrounding detections
            %----------------------------------------------------------
            if( (~isempty(Centres_Prev)) &  (~isempty(Centres)) )
                
                This_point = Centres(m, 1:2);
                temp = repmat(This_point, NPrevpts,1);
                distances = temp - Centres_Prev(:,1:2);
                diff_sqnorms =  distances(:,1).^2  + distances(:,2).^2 ;
                diff_sqnorms = sqrt(diff_sqnorms);
                indice = find( diff_sqnorms == min( diff_sqnorms ) );
                closest_one_Prev = Centres_Prev( indice(1), : );
                
                travelled_dist_pixl = norm(This_point - closest_one_Prev(1:2));
                %speed = 80;
                travelled_dist_Km = travelled_dist_pixl * (LaneMLength_Km/LaneMLength_pxls);
                
                %speed = travelled_dist_Km / (DeltaTime_hrs/TimeDownSampling);
                speed = travelled_dist_Km / (DeltaTime_hrs*TimeDownSampling);
                %Temporal filter:
                speed = 0.5*speed + 0.5*closest_one_Prev(3);
                
            else
                speed = 0;
            end
            
            
            
            
            if Display_Output
               
                %if( (~isempty(Centres_Prev)) &  (~isempty(Centres)) & ( speed <= 50) )
                if( (~isempty(Centres_Prev)) &  (~isempty(Centres))  )
                    
                    %plot(  Centres(m,1), Centres(m,2), 'r.')
                    line( [Centres(m,1)-Sq_W Centres(m,1)-Sq_W], [Centres(m,2)-Sq_H  Centres(m,2)+Sq_H ], 'Color', 'r', 'LineWidth',2)
                    line( [Centres(m,1)+Sq_W Centres(m,1)+Sq_W], [Centres(m,2)-Sq_H  Centres(m,2)+Sq_H ], 'Color', 'r', 'LineWidth',2)
                    line( [Centres(m,1)-Sq_W Centres(m,1)+Sq_W], [Centres(m,2)-Sq_H  Centres(m,2)-Sq_H ], 'Color', 'r', 'LineWidth',2)
                    line( [Centres(m,1)-Sq_W Centres(m,1)+Sq_W], [Centres(m,2)+Sq_H  Centres(m,2)+Sq_H ], 'Color', 'r', 'LineWidth',2)
                    
                    %text( Centres(m,1), Centres(m,2), strcat( ' \leftarrow  v=', num2str(speed), 'Km/hr' )   ,'FontSize',18, 'Color', 'y')
                    %line( [Centres(m,1) closest_one_Prev(1)], [Centres(m,2)  closest_one_Prev(2) ], 'Color', 'y', 'LineWidth',3)
                    Centres(m, 3) = speed;
                else
                    Centres(m, 3) = 0;                    
                end
                
                
            end
            
        end % for m=1:Npts
        
        if Display_Output
            hold off
        end
    end
    
    Prev_BckgndSubtrResult = BckgndSubtrResult;
    
    if Generate_AVI
        %Capture figure for avi file
        %F = getframe(h);
        F = getframe(h2);
        mov = addframe(mov,F);
    end
    
    %Store detections so we can use them in the next frame to measure
    %speed.
    Centres_Prev = Centres;
    
    % Store tracking data and current image for Larry
    WriteTrackingXML( Centres, TargetXMLpath );
    %imwrite( im ,  strcat(TargetXMLpath, '\current_image', '.jpg') );
    
    dummy=1;
    
    if count == 100
        %break;
    end
    
    
    dummy = 1;
    
    
end %for (cFile = 1:length(fileList))
count/toc
%save Locations Locations  %mat file

if Generate_AVI
    % Close movie file
    mov = close(mov);
end


