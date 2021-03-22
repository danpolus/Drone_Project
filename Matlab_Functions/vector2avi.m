function vidObj = vector2avi(vec, FPS, ChessboardFlag, fileName)

%Defualt FPS is 30
if nargin < 2
    FPS = 30;
    ChessboardFlag = 1;
end

pixels_N = 160000; 
dimension_pixels = sqrt(pixels_N);
shift_pixels = dimension_pixels/2;
%Allocation
grayMat = zeros(10,10,length(vec));
chessMat = ones(dimension_pixels, dimension_pixels, length(vec));
chessMat = chessMat - [ones(shift_pixels),zeros(shift_pixels); zeros(shift_pixels), ones(shift_pixels)];

%Draw frame by frame and save it
% DO NOT TOUCH THE FIGURE WHILE RUNNING!
if ChessboardFlag == 0
    for i = 1:length(vec)
        grayMat(:,:,i) = vec(i);
        imshow(grayMat(:,:,i))
        vidVector(i) = getframe;
    end
else
    for i = 1:length(vec)
        if vec(i) == 1
            frame = circshift(chessMat(:,:,i),shift_pixels);
        else
            frame = chessMat(:,:,i);
        end
        imshow(frame)
        vidVector(i) = getframe;
    end
    
end

%Create video object
vidObj = VideoWriter(fileName);
vidObj.FrameRate = FPS; %set your frame rate

%Write the avi file
open(vidObj);
writeVideo(vidObj,vidVector);
close(vidObj);
