% Background Subtraction-based objects <people/cars> tracking used in
% GEOIDE/OCE demos 2011.
% By: Eduardo Corral on May/2011
function visualTrackerDemoBobwNormTmpFlt2_Bob

twm = ftp('130.63.82.70');

%##########################################################################
% SYSTEM OPTIONS:
%##########################################################################
ImageSourceMode = 1;  % 1=Live Camera, 2=bmp files (hard drive)

% AXIS camera bmp files:
imageStart = 0;
Nframes    = 450; %1272;

Generate_AVI = 0; %1;         % Generate demo AVI video from figure (runs slower)
Disp_Input_and_Blobs = 0;     % Display a figure with input and blobs
Display_Output       = 1; %1; % Display final tracking results (squares overlayed)

V_Scaling = 4;              % Image downscaling factors
H_Scaling = 4;
TimeDownSampling = 4;       % Image sequence temporal downsampling  %TrendNet camera: 6, Higwhay images: 3

%Thr = 25; %55; %65; % Threshold for posterior differences
Thr = 0.4; %0.5;  %0.3; %55; %65; % Threshold for posterior differences
Sq_H = 20; % 5; % Height of drawn squares
Sq_W = 10; % 5; % Width  of drawn squares
LocationsClosenessThr = 5; %15; % Detections merging distance

% fltL = 13;%13; % 2D filter parameters (depend on image shrink factors)
% fltsigmay = 9; % 7; %5;
% fltsigmax = 1.5; % 7; %3;

fltL = 17;%13; % 2D filter parameters (depend on image shrink factors)
fltsigmay = 11; % 7; %5;
fltsigmax = 3; % 7; %3;


Peak_Detection_Sensitivity = 0.1; %0.9; %0.5;  %Used in the peak-searching algorithm

% Mapping between image and real-world distances: Lane marks approximate measurement/scaling
p1 = [129 212]; %<--End points of a lane mark on a 480x640 rectified 401 Liverpool image
p2 = [147 226];
LaneMLength_pxls = norm(p1 - p2);
LaneMLength_Km = 0.0010; % From real world highway: 1.0 meters = 0.0010 Km
DeltaTime_hrs = (1/60) * (1 / 3600);

% Path for output tracking results for GEOIDE demo (requested by Larry)
%TargetXMLpath = 'C:\Eduardo\TrackingAFTERtestcam\SampleXML_fromLarry';
TargetXMLpath = 'C:\users\geoide';
MaxPeopleAllowedThr =  20;

INITIAL_SPEED = 75;
SPEED_THR = 110;
%##########################################################################

if ImageSourceMode==1
    vidobj = openAxisCam;   %<<<----REAL TIME
end

%find total number of files to be processed
%filePath = 'D:/CrestechNewLab/';
filePath = 'C:\users\Eduardo\TrackingAFTERtestcam\MatlabCodeMain_Ed_G\';

% Make a list of file names:
nexindx = 1;
for (c1 = imageStart : imageStart + Nframes);
    %Decimate in time
    if ~(mod(c1, TimeDownSampling))%
        fileList{nexindx} = sprintf('C:/users/Eduardo/TrackingAFTERtestcam/Campus0_bmp/Campus0_%05d.bmp',c1);
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
fltx = -(fltL-1)/2 : (fltL-1)/2;
fltG1 = exp( -(fltx.^2)./(2*fltsigmay^2) );
fltG2 = exp( -(fltx.^2)./(2*fltsigmax^2) );
flth = fltG1.' * fltG2;
flth = flth/sum(sum(flth));
%-------------------------------------------------------------------------

% Extract size of images
if ImageSourceMode==1
    im = grabAxisImage(vidobj);   %<<<----REAL TIME
else
    filename = fileList{1};
    im = imread(filename,'bmp');
end
[ROWS COLS DEPTH] = size(im);

% Initialize previous bckgnd subtr. array
Prev_BckgndSubtrResult = zeros(round(ROWS/V_Scaling), round(COLS/H_Scaling));


Centres_Prev = '';
Centres_Prev2 = '';
Centres_Prev3 = '';
Centres_Prev4 = '';
speedCurrent = INITIAL_SPEED;

%**************************************************************************
% Read image files from hard drive
%**************************************************************************
count = 0;

countImage = 0;

while 1
    %tic
    countImage = 1+countImage;
    if ImageSourceMode==1
        im = grabAxisImage(vidobj);   %<<<----REAL TIME
    else
        count = count + 1;
        cFile = count;
        filename = fileList{cFile};
        disp(cFile)
        im = imread(filename,'bmp');
    end
    
    im_orig = im; %Back up original image
    imBoxOn = im_orig;
    % Shrink image
    im = imresize(im, round([ROWS/V_Scaling   COLS/H_Scaling])  );
    
    %Background subtraction
    [posterior   visTrackParams   BckgndSubtrResult] = visualTracker(im,visTrackParams);
    
    
    if Disp_Input_and_Blobs
        figure(1)
        %subplot(2,1,1)
        %image(im)
        %xlabel('Input')
        %subplot(2,1,2)
    end
    
    Diferencia = abs(BckgndSubtrResult - Prev_BckgndSubtrResult);
    
    %     Salida = Diferencia;
    %     Salida = Salida - min(min(Salida)); %Shift down
    %     Salida = 255*  (Salida / (max(max(Salida))));  %Normalize
    %     Salida((Salida < Thr)) = 0;
    %
    %     Salida = Salida - min(min(Salida)); %Shift down
    %     Salida = imfilter(Salida, flth);
    %     Salida = 255*  (Salida / (max(max(Salida))));  %Normalize
    
    
    Salida = Diferencia;
    %Salida = Salida - min(min(Salida)); %Shift down
    %Salida = 255*  (Salida / (max(max(Salida))));  %Normalize
    Salida((Salida < Thr)) = 0;
    
    Salida = Salida - min(min(Salida)); %Shift down
    Salida = imfilter(Salida, flth);
    Salida = 255*  (Salida / (max(max(Salida))));  %Normalize
    
    if Disp_Input_and_Blobs
        %image( Salida )
        plot( Diferencia.' )
        axis([1 180 0 1])
        % surf( fliplr(Salida ))
        % view(180,70)
        xlabel('Bckgnd Subtr. Posterior')
    end
    
    % Direct peaks finding
    [Peaks, There_Are_Peaks] = PeakDet_2D(Salida, Peak_Detection_Sensitivity, round(ROWS/V_Scaling), round(COLS/H_Scaling));
    %RunningTime_PeakFinding = toc;
    
    [my mx] = find(Peaks > 0);
    
    if isempty(mx)
        Centres = [mx my];  %Third element will be used to store speed
    else
        Centres = [H_Scaling*mx   V_Scaling*my  zeros( size(mx,1),1 )];
    end
    
    
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
        NPrev2pts = size(Centres_Prev2,1);
        NPrev3pts = size(Centres_Prev3,1);
        NPrev4pts = size(Centres_Prev4,1);
        
        for m=1:Npts
            %----------------------------------------------------------
            %Associate detections with PREVIOUS surrounding detections
            %----------------------------------------------------------
            %if(  (~isempty(Centres_Prev)) &  (~isempty(Centres)) )
            %if( (~isempty(Centres_Prev2)) & (~isempty(Centres_Prev)) &  (~isempty(Centres)) )
            %if( (~isempty(Centres_Prev3)) & (~isempty(Centres_Prev2)) & (~isempty(Centres_Prev)) &  (~isempty(Centres)) )
            if( (~isempty(Centres_Prev4)) & (~isempty(Centres_Prev3)) & (~isempty(Centres_Prev2)) & (~isempty(Centres_Prev)) &  (~isempty(Centres)) )
                
                ThisSinglePoint = Centres(m, 1:2);
                
                %--------------------------------------------------
                % Current v/s prev:
                %--------------------------------------------------
                AListOfPoints = Centres_Prev;
                NPtsList = NPrevpts;
                NearestPointPrev = Find_Nearest_Point( ThisSinglePoint, AListOfPoints, NPtsList );
                travelled_dist_pixlCurr = norm(ThisSinglePoint - NearestPointPrev(1:2));
                %travelled_dist_Km = travelled_dist_pixl * (LaneMLength_Km/LaneMLength_pxls);
                %SpeedCurrPrev = travelled_dist_Km / (DeltaTime_hrs*TimeDownSampling);
                %SpeedCurrPrev = 0.6*NearestPointPrev(3) + 0.4*SpeedCurrPrev;
                %line( [ThisSinglePoint(1)  NearestPointPrev(1)], [ThisSinglePoint(2)  NearestPointPrev(2)], 'Color', 'y', 'LineWidth',3)
                
                %--------------------------------------------------
                % prev v/s prev2:
                %--------------------------------------------------
                AListOfPoints = Centres_Prev2;
                NPtsList = NPrev2pts;
                NearestPointPrev2 = Find_Nearest_Point( NearestPointPrev, AListOfPoints, NPtsList );
                travelled_dist_pixlPrev = norm(NearestPointPrev - NearestPointPrev2(1:2));
                %travelled_dist_Km = travelled_dist_pixl * (LaneMLength_Km/LaneMLength_pxls);
                %SpeedPrevPrev2 = travelled_dist_Km / (DeltaTime_hrs*TimeDownSampling);
                %SpeedPrevPrev2 = 0.6*NearestPointPrev(3) + 0.4*SpeedPrevPrev2;
                %line( [NearestPointPrev(1)  NearestPointPrev2(1)], [NearestPointPrev(2)  NearestPointPrev2(2)], 'Color', 'r', 'LineWidth',3)
                
                %--------------------------------------------------
                % prev2 v/s prev3:
                %--------------------------------------------------
                AListOfPoints = Centres_Prev3;
                NPtsList = NPrev3pts;
                NearestPointPrev3 = Find_Nearest_Point( NearestPointPrev2, AListOfPoints, NPtsList );
                travelled_dist_pixlPrev2 = norm(NearestPointPrev2 - NearestPointPrev3(1:2));
                %travelled_dist_Km = travelled_dist_pixl * (LaneMLength_Km/LaneMLength_pxls);
                %SpeedPrev2Prev3 = travelled_dist_Km / (DeltaTime_hrs*TimeDownSampling);
                %SpeedPrevPrev2 = 0.6*NearestPointPrev(3) + 0.4*SpeedPrevPrev2;
                %line( [NearestPointPrev2(1)  NearestPointPrev3(1)], [NearestPointPrev2(2)  NearestPointPrev3(2)], 'Color', 'b', 'LineWidth',3)
                
                %--------------------------------------------------
                % prev3 v/s prev4:
                %--------------------------------------------------
                AListOfPoints = Centres_Prev4;
                NPtsList = NPrev4pts;
                NearestPointPrev4 = Find_Nearest_Point( NearestPointPrev3, AListOfPoints, NPtsList );
                travelled_dist_pixlPrev3 = norm(NearestPointPrev3 - NearestPointPrev4(1:2));
                %travelled_dist_Km = travelled_dist_pixl * (LaneMLength_Km/LaneMLength_pxls);
                %SpeedPrev3Prev4 = travelled_dist_Km / (DeltaTime_hrs*TimeDownSampling);
                %SpeedPrevPrev2 = 0.6*NearestPointPrev(3) + 0.4*SpeedPrevPrev2;
                %line( [NearestPointPrev2(1)  NearestPointPrev3(1)], [NearestPointPrev2(2)  NearestPointPrev3(2)], 'Color', 'b', 'LineWidth',3)
                
                ObjLocs = [ ThisSinglePoint;  NearestPointPrev; NearestPointPrev2; NearestPointPrev3; ];
                TravDists = [ travelled_dist_pixlCurr   travelled_dist_pixlPrev   travelled_dist_pixlPrev2   travelled_dist_pixlPrev3 ];
                
                %                         % Compute angles of all these vectors:
                %                         v1 = ThisSinglePoint - NearestPointPrev;
                %                         if(v1(1)==0)
                %                             den = 1;
                %                         else
                %                             den = v1(1);
                %                         end
                %                         angle1 = atan( v1(2) / den ) * 180/pi;
                %
                %                         v2 = NearestPointPrev - NearestPointPrev2;
                %                         if(v2(1)==0)
                %                             den = 1;
                %                         else
                %                             den = v2(1);
                %                         end
                %                         angle2 = atan( v2(2) / den ) * 180/pi;
                %
                %                         v3 = NearestPointPrev2 - NearestPointPrev3;
                %                         if(v3(1)==0)
                %                             den = 1;
                %                         else
                %                             den = v3(1);
                %                         end
                %                         angle3 = atan( v3(2) / den ) * 180/pi;
                %
                %                         v4 = NearestPointPrev3 - NearestPointPrev4;
                %                         if(v4(1)==0)
                %                             den = 1;
                %                         else
                %                             den = v4(1);
                %                         end
                %                         angle4 = atan( v4(2) / den ) * 180/pi;
                
                %                         ANGLES = [angle1 angle2 angle3 angle4];
                %                         ANGLES_VAR = var(ANGLES);
                ca_VAR = var(ObjLocs(:,1));
                co_VAR = var(ObjLocs(:,2)); %<--MJPEG artifacts!!!
                
                
                TRAVELDISTS_VAR = var(TravDists);
                
                
                
                
                
                
                %                         Speeds = [ SpeedCurrPrev  SpeedPrevPrev2  SpeedPrev2Prev3 SpeedPrev3Prev4];
                %
                %                         speedIndexes = find( Speeds < SPEED_THR);
                %                         Nspeeds = length( speedIndexes );
                %
                %                         for L=1:Nspeeds
                %                             ind = speedIndexes(L);
                %                             if ind == 1
                %                                 line( [ThisSinglePoint(1)  NearestPointPrev(1)], [ThisSinglePoint(2)  NearestPointPrev(2)], 'Color', 'y', 'LineWidth',3);
                %                             end
                %                             if ind == 2
                %                                 line( [NearestPointPrev(1)  NearestPointPrev2(1)], [NearestPointPrev(2)  NearestPointPrev2(2)], 'Color', 'r', 'LineWidth',3)
                %                             end
                %                             if ind == 3
                %                                 line( [NearestPointPrev2(1)  NearestPointPrev3(1)], [NearestPointPrev2(2)  NearestPointPrev3(2)], 'Color', 'b', 'LineWidth',3)
                %                             end
                %                             if ind == 4
                %                                 line( [NearestPointPrev3(1)  NearestPointPrev4(1)], [NearestPointPrev3(2)  NearestPointPrev4(2)], 'Color', 'g', 'LineWidth',3)
                %                             end
                %                         end
                %
                %                         Reasonable_Speeeds = Speeds( speedIndexes );
                %                         speedCurrent = 0.9*speedPrev + 0.1*( sum(Reasonable_Speeeds)/Nspeeds );
                %
                %                         DisplayedSpeed = round(speedCurrent);
                %                         DisplayedSpeed = round(DisplayedSpeed/10);
                %                         DisplayedSpeed = DisplayedSpeed*10;
                
                
                %text( Centres(m,1), Centres(m,2), strcat( ' \leftarrow  v=', num2str( DisplayedSpeed  ), 'Km/hr' )   ,'FontSize',18, 'Color', 'y')
                
                
                %if (TRAVELDISTS_VAR < 150^2)&(co_VAR < 150^2)&(ca_VAR < 150^2)&(co_VAR > 0)&(ca_VAR > 0)
                %if (TRAVELDISTS_VAR < 200^2)&(co_VAR < 200^2)&(ca_VAR < 200^2)&(co_VAR > 0)&(ca_VAR > 0)
                if (TRAVELDISTS_VAR < 250^2)&(co_VAR < 250^2)&(ca_VAR < 250^2)&(co_VAR > 0)&(ca_VAR > 0)
                    
                    
                    line( [Centres(m,1)-Sq_W Centres(m,1)-Sq_W], [Centres(m,2)-Sq_H  Centres(m,2)+Sq_H ], 'Color', 'b', 'LineWidth',5)
                    line( [Centres(m,1)+Sq_W Centres(m,1)+Sq_W], [Centres(m,2)-Sq_H  Centres(m,2)+Sq_H ], 'Color', 'b', 'LineWidth',5)
                    line( [Centres(m,1)-Sq_W Centres(m,1)+Sq_W], [Centres(m,2)-Sq_H  Centres(m,2)-Sq_H ], 'Color', 'b', 'LineWidth',5)
                    line( [Centres(m,1)-Sq_W Centres(m,1)+Sq_W], [Centres(m,2)+Sq_H  Centres(m,2)+Sq_H ], 'Color', 'b', 'LineWidth',5)
                    Centres(m, 3) = speedCurrent;
                    
                    
                else
                    Centres(m, 3) = 999;
                    Centres(m,:) = 0*Centres(m,:);
                    Centres(m,:) = 999+Centres(m,:);
                end
                dummy = 1;
            else
                ThisSinglePoint = Centres(m, 1:2);
                NearestPointPrev = ThisSinglePoint;
                speedCurrent = INITIAL_SPEED;
                Centres(m, 3) = speedCurrent;
            end
            
            
        end % for m=1:Npts
        
        dummy = Centres(:,1);
        indx = find(dummy == 999);
        Centres(indx, :) = ''; %Remove entries that were merged
        
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
    Centres_Prev4 = Centres_Prev3;
    Centres_Prev3 = Centres_Prev2;
    Centres_Prev2 = Centres_Prev;
    Centres_Prev = Centres;
    
    speedPrev = speedCurrent;
    
    % Store tracking data and current image for Larry
    %WriteTrackingXML( Centres, TargetXMLpath );
    filename=[TargetXMLpath, '\currentimage', num2str(mod(countImage, 10000)),  '.jpg'];
    %filename=[TargetXMLpath, '\currentimage', num2str(countImage),  '.jpg'];
    
    if(~isempty(Centres))
        %load('C:\users\geoide\rotations.mat');
        a = mget(twm,'rotations.mat');
        load (a{1});
        imBoxOn = drawBox(imBoxOn, Centres);
        [ron_rows, ron_columns] = size(Centres);
        UTM_Centres = zeros(ron_rows, 2);
        for ron_i = 1:ron_rows
            %             Centres(ron_i, :)
            Pos3D = comproadvecs3(RM2UTM,T', RM2UTM, Centres(ron_i, 1:2), focal, pp);
            UTM_Centres(ron_i, :) = Pos3D(1:2);
        end
        [Lat,Lon] = utm2deg(UTM_Centres(:,1)',UTM_Centres(:,2)',repmat(['17 N'], ron_rows, 1));
        
        
        %imwrite(imBoxOn ,  strcat(TargetXMLpath, '\currentimage', '.jpg') );
        %imwrite( im ,  strcat(TargetXMLpath, '\current_image', '.jpg') );
        %         pause;
        Ron = [Lat Lon];
        %         ( Ron, TargetXMLpath );
        
        [framexmlfile, xmlFileName] = WriteTrackingXML( Ron, TargetXMLpath, countImage);
    else
        Lat=0;
        Lon=0;
        Ron = [Lat Lon];
        %         ( Ron, TargetXMLpath );
        
        [framexmlfile, xmlFileName] = WriteTrackingXML( Ron, TargetXMLpath, countImage);
        
        
    end
    
    imwrite(imBoxOn ,  filename);
    mput(twm, filename);
    
    mput(twm, xmlFileName);
    mput(twm, framexmlfile);
    %filename=strcat(Targetpath, '\currentimage', '.jpg');
    
    
    %im(1:30, 1:30, : ) = 0;
    
    
    
    dummy=1;
    
    %toc
end %for (cFile = 1:length(fileList))



if Generate_AVI
    % Close movie file
    mov = close(mov);
end

return



function [NearestPointPrev] = Find_Nearest_Point(ThisSinglePoint, AListOfPoints, NPtsList)
SinglePointVect = repmat(ThisSinglePoint, NPtsList,1);
distances = SinglePointVect - AListOfPoints(:,1:2);
diff_norms =  distances(:,1).^2  + distances(:,2).^2 ;
diff_norms = sqrt(diff_norms);
indice = find( diff_norms == min( diff_norms ) );
NearestPointPrev = AListOfPoints( indice(1), 1:2 );
return




