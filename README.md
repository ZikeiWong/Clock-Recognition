# Clock-Recognition
Analog clock and watch reader 

## Approach and Method
The approach taken in this project was to isolate the actual clock from the rest of the image, identify the clock hands, and calculate the time according to their angles.
The method for doing this consists of six steps:
I.	Isolate the clock from the rest of the image
II.	Apply edge detection to the image
III.	Use Hough transform to isolate watch hands
IV.	Calculate line angles
V.	Filter out irrelevant lines
VI.	Compute the time
