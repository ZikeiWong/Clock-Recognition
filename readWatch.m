%% step 1:LOAD IMAGE
img = imread('./images/watch11.jpg');
subplot(2,3,1);
imshow(img,'initialmagnification','fit' ); hold on;
title('input image','fontsize',12);
%% step 2: FIND AND ISOLATE THE CLOCK

[rows, cols, dim] = size(img);

% if the image is too big to process, minimize it.
if (max(rows,cols)>1000)
    scale = 1/((max(rows,cols))/1000);
    img = imresize(img,scale);
    [rows, cols, dim] = size(img);
end

% generate minMax radius sizes
Rmin = round(min(rows,cols)*0.1); % 10% of smaller dimenstion
Rmax = round(max(rows,cols)*0.5); % 50% of max dimension - largest possible
RRange = [Rmin Rmax];

isEmptyFlag = 1;
attempts = 0;
while isEmptyFlag
    attempts = attempts + 1;
    %Find bright background circles in the image
    [centersBright, radiiBright] = imfindcircles(img,RRange,'ObjectPolarity','bright');
    %Plot bright circles in blue
    viscircles(centersBright, radiiBright,'EdgeColor','b');
        
    %Find dark background circles in the range
    [centersDark, radiiDark] = imfindcircles(img,RRange,'ObjectPolarity','dark');
    %Plot dark circles in dashed red boundaries
    viscircles(centersDark, radiiDark,'LineStyle','--');
        
    centersBright = vertcat(centersBright,centersDark);
    radiiBright = vertcat(radiiBright,radiiDark);
    
    if ~isempty(centersBright)
        'Found Circle';
        isEmptyFlag = 0;
    else
        if attempts > 5
            %use function ipl_find_circle
            [centersBright,radiiBright] = ipl_find_circle(img);
            isEmptyFlag = 0;
        else
            %Try again by reducing Rmin
            'Found Nothing. Try again';
            
            Rmin = round(Rmin*0.7);%Reduce Rmin
            RRange = [Rmin Rmax];
        end
    end
end

%grayscale the image
if length(size(img)) == 3
    img = rgb2gray(img);
end

%Find biggest circle
[maxRadBright,maxIndex] = max(radiiBright);
centerMax = centersBright(maxIndex,:);
imageSize = size(img);

% center and radius of circle
ci = [centerMax(1,2), centerMax(1,1), maxRadBright];    
[xx,yy] = ndgrid((1:imageSize(1))-ci(1),(1:imageSize(2))-ci(2));
mask = uint8((xx.^2 + yy.^2)<ci(3)^2);

% show the area of the watch
croppedImage = uint8(zeros(size(img)));
croppedImage(:,:) = img(:,:).*mask;
% figure;
% imshow(croppedImage);
% title('Maskedimage','fontsize',12);

% create rectangle that only includes circle.
recX = centerMax(1,1) - maxRadBright;
recY = centerMax(1,2) - maxRadBright;
WHrect = maxRadBright*2;
rectImg = [recX,recY,WHrect,WHrect];

% Crop out the circle
croppedImage = imcrop(croppedImage,rectImg);

subplot(2,3,2);
imshow(croppedImage, 'initialmagnification','fit');
title('cropped image','fontsize',12);

%% step 3: EDGE DETECTION
%canny edge detection
edges = edge(croppedImage,'canny',[0.1 0.2], 1);

subplot(2,3,3);
imshow(edges,'initialmagnification','fit'); hold on
title('canny edge detector','fontsize',12) 

%% step 4: FIND WATCH HANDS BY HOUGH TRANSFORM

BW=edges;
% Compute the Hough transform of the image using the hough function.
[H,theta,rho] = hough(BW);

% Display the transform 
subplot(2,3,4)
imshow(imadjust(mat2gray(H)),[],'XData',theta,'YData',rho, 'initialmagnification','fit');
xlabel('\theta (degrees)'), ylabel('\rho');
axis on, axis normal, hold on;
colormap(hot);

% Find the peaks in the Hough transform matrix, H, using the houghpeaks function.
P = houghpeaks(H,10,'threshold',ceil(0.2*max(H(:))));

x = theta(P(:,2));
y = rho(P(:,1));

plot(x,y,'s','color','black');
title('Hough Transform with Suspected Line Positions','fontsize',12) 

% Find lines in the image using the houghlines function.

% lines = houghlines(BW,theta,rho,P,'FillGap',5,'MinLength',30);
 lines = houghlines(BW,theta,rho,P,'FillGap',15);

% subplot(2,3,5);
% imshow(croppedImage, 'initialmagnification','fit'),hold on;
% title('clock with detected lines','fontsize',12);

max_len = 0;
% image center is exactly clock center
croppedCenter = [maxRadBright, maxRadBright];

%  Calculate each lines min. distance (from both ends) to center.

for k=1:length(lines)
   xy = [lines(k).point1; lines(k).point2];
   dist1 = pdist2(xy(1,:),croppedCenter,'euclidean');
   dist2 = pdist2(xy(2,:),croppedCenter,'euclidean');
   dist = min(dist1,dist2);
   
  % Filter unwanted lines by distance from center of circle
    if dist<(maxRadBright*0.2)
%        plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
%        % Plot beginnings and ends of lines
%        plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
%        plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
       
       % Determine the endpoints of the longest line segment
       len = norm(lines(k).point1 - lines(k).point2);
       if (len> max_len)
          max_len = len;
          xy_long = xy;
       end
    else
       %mark for future deletion
       lines(k).theta = 999;
   end
end

%remove lines marked as irrelevant
lines([lines.theta]==999) = [];


% Merge closer one with origin
newLines= zeros(length(lines),3);
lineAngles = zeros(length(lines),2);

 subplot(2,3,5);
 imshow(croppedImage, 'initialmagnification','fit'),hold on;
 title('clock with detected lines','fontsize',12);
% calculate newLines' points
for i=1:length(lines)
    %convert points relative to CENTER of circle, not top left corner
    P1 = [lines(i).point1(1,1)-maxRadBright,maxRadBright-lines(i).point1(1,2)];
    P2 = [lines(i).point2(1,1)-maxRadBright,maxRadBright-lines(i).point2(1,2)];
    
    %add ORIGINAL length between points
    newLines(i,3) = pdist([P1;P2],'euclidean');
    
    % save the farthest out line, and convert closer line to 0.
    % (adds a slight inaccuracy to time telling.)
    max1 = max(abs(P1(1,1)),abs(P1(1,2)));
    max2 = max(abs(P2(1,1)),abs(P2(1,2)));
    
    % merge close point to origin (0,0)
    if max1>max2
        newLines(i,1:2) = [P1(1,1),P1(1,2)];
    else
        newLines(i,1:2) = [P2(1,1),P2(1,2)];
    end
    

    point1 = [newLines(i,1)+maxRadBright,-(newLines(i,2)-maxRadBright)];
    point2 = [maxRadBright,maxRadBright];
    xy = [point1 ; point2];
 
    plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
    plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
    plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
    
end

% in case we get a 0 coordinate, move it a bit as not to mess up atan2
newLines(newLines==0) = 0.001;

%% step 5: CALCULATE LINE ANGLES

for i=1:size(newLines,1)
    diffX = newLines(i,1);
    diffY = newLines(i,2);
    lineAngles(i,1) = radtodeg(atan2(diffY,diffX));
    
   
    lineAngles(i,2) = norm([diffX diffY]);
    % get correct angle according to which quarter the line is in :
    switch ((diffX>0) + 2*(diffY>0))
        
        % 1st quarter: (true,true) - (diffX>0 && diffY>0)
        case 3
            lineAngles(i,1) = 90-lineAngles(i,1);
   
        % 2d quarter: (true,false) - (diffX>0 && diffY<0)          
        case 1
            lineAngles(i,1) = abs(lineAngles(i,1))+90;
            
        % 3d quarter: (false,false) - (diffX<0 && diffY<0)
        case 0
            lineAngles(i,1) = abs(lineAngles(i,1))+90;
            
        % 4th quarter: (false,true) - (diffX<0 && diffY>0)
        case 2
            lineAngles(i,1) = 450-lineAngles(i,1);
   end
end

%% step 6: FILTER OUT ADJACENT LINES

% define 5 degree offset as same line to merge
degOffset = 5;

% sort angles and compare adjacent lines to find duplicates (if lines>3)
lineAnglesSorted = sort(lineAngles);
% iterations counter
rounds = 0;
while (size(lineAngles,1) > 3)%More than three lines
    rounds=rounds+1;
     
    % safety precaution if no lines meet condition, possible infinite loop
    if rounds>30
        % something is wrong, delete shortest line until cond. is met
        if (degOffset > 15)
            minLine = min(lineAngles(:,2));
            index = find(lineAngles(:,2) == minLine);
            lineAngles(index,:) = [];
            newLines(index,:) = [];       
            continue
        end
        degOffset = degOffset + 1;
        rounds = 0;
    end
    
    lineAnglesSorted = sortrows(lineAngles,1);
% traverse sorted list and merge lines with degree offset< degOffset(5)
    for i=2:size(lineAnglesSorted,1)
        
        line1Angle = lineAnglesSorted(i,1);
        line1Len = lineAnglesSorted(i,2);
        
        line2Angle = lineAnglesSorted(i-1,1);
        line2Len = lineAnglesSorted(i-1,2);
        
        if ((abs(line1Angle-line2Angle)) < degOffset)
            % if found, take the longer one and delete the other

%           Whether Max or min is better?
%           Average?
            minLine = min(line1Len,line2Len);
            maxLine = max(line1Len,line2Len);
%             avgLine = (line1Len + line2Len) / 2;
            index = find(lineAngles(:,2) == minLine);
            index2 = find(lineAngles(:,2) == maxLine);
%             lineAngles(index2,2) = avgLine; 
            lineAngles(index,:) = [];
            newLines(index,:) = [];
            break            
        end   
    end
end

% end case - less than 3 lines
% 1) one line. failed to identify all lines
if (size(lineAnglesSorted,1)) == 1  
    msg = 'Could not identify all lines correctly.';
    baseException = MException(msgID,msg);
    throw(baseException)
end

% 2) two lines. assume there is no seconds hand.
twoLinesOnly = 0;
if (size(lineAnglesSorted,1) == 2)
   twoLinesOnly = 1;      
end

% display new image with fixed filtered lines
subplot(2,3,6)
% final image with hour displayed
imshow(croppedImage, 'initialmagnification','fit');hold on;

for k=1:size(newLines,1)
   %calculate each lines min. distance (from both edges) to center.
   point1 = [newLines(k,1)+maxRadBright,-(newLines(k,2)-maxRadBright)];
   point2 = [maxRadBright,maxRadBright];
   xy = [point1 ; point2];

   plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
   % Plot beginnings and ends of lines
   plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
   plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');

       % Determine the endpoints of the longest line segment
       len = norm(lines(k).point1 - lines(k).point2);
       if ( len > max_len)
          max_len = len;
          xy_long = xy;
       end
end

%% step 7: TELL TIME
% According to longest-shortest: seconds - minutes - hours

% LAST MINUTE CALCULATIONS
% we need background type for our calculation of minute/seconds hands width later on.
% if its a dark background we sum light pixels. if its a light one, dark pixels.
% calculate sum of pixels around center and determine background type.
centerCenter = floor(maxRadBright);
% size of square around center
distance = floor(centerCenter/5);

localCenterArea = croppedImage(centerCenter-distance:centerCenter+distance,...
                                centerCenter-distance:centerCenter+distance);
% make sure we have the right area
% figure,imshow(localCenterArea);
%compare avg. pixel value to middle. if > middle => bright, <middle => dark.
avg = sum(localCenterArea(:))/(size(localCenterArea,1)^2);
if avg>130
    backgroundType = 0; %bright
else
    backgroundType = 1; %dark
end

% sort line lengths. then we can match line to indication by length,
% and turn them from angles to values
lineLen2 = sort(lineAngles(:,2));

% for each line: get the index in original array ,get angle, and turn into
% value.

% shortest line is the hours
hoursLength = lineLen2(1,1);
hoursIndex = find(lineAngles(:,2) == hoursLength);
hoursAngle = lineAngles(hoursIndex,1);
hoursValue = floor((hoursAngle/360)*12);
if hoursValue == 0
    hoursValue = 12;
end

% middle line is the minutes
minutesLength = lineLen2(2,1);
minutesIndex = find(lineAngles(:,2) == minutesLength);
minutesAngle = lineAngles(minutesIndex,1);
minutesValue = floor((minutesAngle/360)*60);

% check only if we got 3 lines. else we assume there is no seconds hand
if ~twoLinesOnly
    % longest line is the seconds
    secondsLength = lineLen2(3,1);
    secondsIndex = find(lineAngles(:,2) == secondsLength);
    secondsAngle = lineAngles(secondsIndex,1);
    secondsValue = floor((secondsAngle/360)*60);
else
   secondsValue = 0; 
end

%optional variables if the hands are close in length:
hoursValue2 = floor((minutesAngle/360)*12);
minutesValue2 = floor((hoursAngle/360)*60);

%if the clock's ticks are close in length, give us all options:
hoursOrMinutesFlag = 0;
minutesOrSecondsFlag = 0;
switchMinutesSecondsFlag = 0;
% if (minutesLength-hoursLength)<15
%     hoursOrMinutesFlag = 1;
% end
if  ~twoLinesOnly
%     not sure if to check only if diff<30 or always
%     && (secondsLength-minutesLength)<30) 
%     minutesOrSecondsFlag = 1;
    
    % get ACTUAL position in image relative to image (0,0)
    minutesPos = [newLines(minutesIndex,1)+maxRadBright,-(newLines(minutesIndex,2)-maxRadBright)];
    secondsPos = [newLines(secondsIndex,1)+maxRadBright,-(newLines(secondsIndex,2)-maxRadBright)];
    
    % compute middle of line
    minutesMiddle = [(minutesPos(1,1) - (newLines(minutesIndex,1)/2)) (minutesPos(1,2) + (newLines(minutesIndex,2)/2))];
    secondsMiddle = [(secondsPos(1,1) - (newLines(secondsIndex,1)/2)) (secondsPos(1,2) + (newLines(secondsIndex,2)/2))];
    minutesMiddle = floor(minutesMiddle);
    secondsMiddle = floor(secondsMiddle);
    
%     show line middles to validate we have the correct pixel
%     figure,imshow(croppedImage), hold on
%     plot(minutesMiddle(1,1),minutesMiddle(1,2), 'x','lineWidth',3,'Color','green'); hold on
%     plot(secondsMiddle(1,1),secondsMiddle(1,2), 'x','lineWidth',3,'Color','green'); hold on
    
    % compute pixel sum in neighboring area. More black pixel will have a
    % LOWER sum value (and vice versa with bright background).
    % if minutes have an incorrect value, switch them!
    minutesArea = croppedImage((minutesMiddle(1,2)-7):(minutesMiddle(1,2)+7),(minutesMiddle(1,1)-7):(minutesMiddle(1,1)+7));
    secondsArea = croppedImage((secondsMiddle(1,2)-7):(secondsMiddle(1,2)+7),(secondsMiddle(1,1)-7):(secondsMiddle(1,1)+7));
%     figure(7),imshow(minutesArea,'initialMagnification','fit')
%     figure(8),imshow(secondsArea,'initialMagnification','fit')
    minutesPixelValues = sum(minutesArea(:));
    secondsPixelValues = sum(secondsArea(:));
    
    %if we need to switch, clear the 2 option flag and replace them
    needToSwitch = (minutesPixelValues > secondsPixelValues)
    % if we have a dark background, minutes hand should have more white
    % pixels meaning HIGHER sum value.
    if backgroundType == 1
        needToSwitch = ~needToSwitch;
    end
    
    if needToSwitch
%         switchMinutesSecondsFlag = 1;
%         minutesOrSecondsFlag = 0;
        tmp = minutesValue;
        minutesValue = secondsValue;
        secondsValue = tmp;
    end    
end

%finalize texts
hoursText = int2str(hoursValue);
minutesText = int2str(minutesValue);
secondsText = int2str(secondsValue);

hoursText2 = int2str(hoursValue2);
minutesText2 = int2str(minutesValue2);

if minutesValue < 10
    minutesText = strcat('0',minutesText);
end
if minutesValue2 < 10
    minutesText2 = strcat('0',minutesText2);
end
if secondsValue < 10
    secondsText = strcat('0',secondsText);
end

%create strings for GUI
I = sprintf('TIME: %s:%s:%s',hoursText,minutesText,secondsText);
% I2 = sprintf(' OR  %s:%s:%s',hoursText2,minutesText2,secondsText);
% I3 = sprintf(' OR  %s:%s:%s',hoursText,secondsText,minutesText);

if hoursOrMinutesFlag
    I = sprintf('%s %s',I,I2);
end
if minutesOrSecondsFlag
    I = sprintf('%s %s',I,I3);
end

%all done! display the time visually
title(I,'fontsize',12);