function[center radius] = ipl_find_circle(I)

% NOTE: I is assumed to be a grayscale image
if (size(I) == 3)
    I = rgb2gray(I);
end
% Step 1: Segment image using Otsu´s method
t = graythresh(I); 
BW = im2bw(I, t); 

% Step 2: Leave just "big" components on binary image
[L, num] = bwlabel(BW); 
stats = regionprops(L, 'Area', 'PixelIdxList');
area_vector = [stats(:).Area];
area_vector = sort(area_vector);
threshold_pos = floor(num * 0.98);
threshold = area_vector(threshold_pos);

for i=1:num
    if(stats(i).Area < threshold)
        BW(stats(i).PixelIdxList) = false;
    end
end

% Step 3: Dilate image with a circle of small radius
str = strel('disk', 5); 
BW = imdilate(BW, str); 

% Step 4: Take component with biggest area as the circle
L = bwlabel(BW); 
stats = regionprops(L, 'Area', 'BoundingBox', 'Centroid', 'EquivDiameter');
area_vector = [stats(:).Area];
[max_value, max_idx] = max(area_vector);
soi = stats(max_idx);

% Set output variable
circle = imcrop(I, soi.BoundingBox);

% Display results
radius = soi.EquivDiameter/2;
N = 1000;
theta = linspace(0, 2*pi, N);
rho = ones(1, N) * radius;
[X,Y] = pol2cart(theta, rho);
X = soi.Centroid(1) - X;
Y = soi.Centroid(2) - Y;

figure; 
subplot(1,2,1);
imshow(I);
hold on;
plot(X, Y, '-r', 'LineWidth', 2);
title('Original graycale image + circle', 'FontSize', 12)

subplot(1,2,2);
imshow(circle);
title('Circle region', 'FontSize', 12);
center = soi.Centroid;
end