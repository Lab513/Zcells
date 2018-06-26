function output = FulltoROI(input,ROI,imgsize)
% This function changes input coordinates from their original value in the original basis to the
% coordinates in the ROI;

[s1,s2] = ind2sub(imgsize,input);
s1 = s1 - ROI(2) + 1;
s2 = s2 - ROI(1) + 1;
output = sub2ind(ROI(3:4),s1,s2);