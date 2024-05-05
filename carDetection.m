% Read the video
vIn = VideoReader('RoadTraffic.mp4');

% Get the background of the video (average)
backgroundImg = read(vIn, 1);
backgroundImg = im2double(backgroundImg);

for idx = 2:vIn.NumFrames
    frame = read(vIn, idx);
    backgroundImg = backgroundImg + im2double(frame);
end
backgroundImg = backgroundImg / vIn.NumFrames;
backgroundImg = im2gray(enhanceImage(backgroundImg));

% Create output video writer with same frame rate as input
vOut = VideoWriter('RoadTrafficOut.mp4', 'MPEG-4');
vOut.FrameRate = vIn.FrameRate;
open(vOut);

% Loop through all video frames
for idx = 1:vIn.NumFrames
    % Enhance the current frame (optional)
    originalImg = enhanceImage(read(vIn, idx));
    grayImg = im2gray(originalImg);

    % Calculate difference between frame and background
    diff = abs(im2double(grayImg) - backgroundImg);
    
    % Segment cars in the difference image
    mask = segmentCars(diff);
    props = regionprops("table", mask, {'Area', 'BoundingBox'});
    
    % Filter detections based on area
    if sum(props.Area) > 4000 & sum(props.Area) < 400000
        % Draw bounding boxes around large objects (assumed cars)
        boudingBox= insertShape(originalImg, "rectangle", props(props.Area > 4000 & props.Area < 40000, :).BoundingBox, "LineWidth", 3, "Color", "red");
        writeVideo(vOut, boudingBox);
    else
        writeVideo(vOut, originalImg);
    end 
    
end
close(vOut);

% Function to apply median filter for noise reduction
function img = enhanceImage(img)
    img(:,:,1) = medfilt2(img(:,:,1));
    img(:,:,2) = medfilt2(img(:,:,2));
    img(:,:,3) = medfilt2(img(:,:,3));
end

% Function to perform car segmentation (uses thresholding and morphology)
function [BW, props] = segmentCars(img)
    BW = imbinarize(img);
    BW = imdilate(BW, strel('disk', 18));
    BW = imfill(BW, 'holes');
    BW = imerode(BW, strel('disk', 16));
end
