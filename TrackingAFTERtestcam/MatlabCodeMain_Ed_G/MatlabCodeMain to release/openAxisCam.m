function vidobj = openAxisCam

vidobj = videoinput('winvideo', 1);
% Configure the object for manual trigger mode.
triggerconfig(vidobj, 'manual');

% Now that the device is configured for manual triggering, call START.
% This will cause the device to send data back to MATLAB, but will not log
% frames to memory at this point.
%start(vidobj)
