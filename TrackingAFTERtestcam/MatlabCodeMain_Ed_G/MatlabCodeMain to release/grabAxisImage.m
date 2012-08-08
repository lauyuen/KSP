function im=grabAxisImage(vidobj)

if nargin == 0 
    vidobj = videoinput('winvideo', 1);
    % Configure the object for manual trigger mode.
    %triggerconfig(vidobj, 'manual');
    %start(vidobj)
end

im = getsnapshot(vidobj);
