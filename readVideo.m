clear all;close all;
vidObj = VideoReader('C:\Users\ofera\Studies\drone_proj\vid.mp4');

th = 180;
i = 1;

%display frame by frame (play video)
currAxes = axes;
while hasFrame(vidObj)
    vidFrame = readFrame(vidObj); %read next frame
    r = vidFrame(:,:,1);
    maxVal(i) = max(max(r(355:365,635:645)));
    %   image(vidFrame, 'Parent',currAxes);
    imshow(vidFrame, 'Parent',currAxes);
    currAxes.Visible = 'off';
    pause(1/vidObj.FrameRate);
    i = i + 1;
end
bwVec = maxVal > th;
changesVec = diff(bwVec);
framePerChange = diff(find(changesVec ~= 0);

allFrames = re(vidObj); %read all frames
size(allFrames)

r = vidFrame(:,:,1);
g = vidFrame(:,:,2);
b = vidFrame(:,:,3);
I = rgb2gray(vidFrame);