# Clock-Recognition
The main goal for this project was to develop a model for analog clock identification, and to implement it with a program that would be able to receive an image of a clock, and return the time displayed after its analysis. I strived to write a program that would reach an acceptable success rate and would work on a broad range of images.

## Approach and Method
The approach taken in this project was to isolate the actual clock from the rest of the image, identify the clock hands, and calculate the time according to their angles.
The method for doing this consists of six steps:

I.	Isolate the clock from the rest of the image

II.	Apply edge detection to the image

III.	Use Hough transform to isolate watch hands

IV.	Calculate line angles

V.	Filter out irrelevant lines

VI.	Compute the time

![](https://github.com/ZikeiWong/Clock-Recognition/blob/master/Process%20Graph.png)
