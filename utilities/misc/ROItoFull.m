function output = ROItoFull(input,ROI,imgsize)
% This function changes input coordinates from their ROI basis to the
% coordinates in the full picture;

[s1,s2] = ind2sub(ROI(3:4),input);
s1 = s1 + ROI(2) - 1;
s2 = s2 + ROI(1) - 1;
output = sub2ind(imgsize,s1,s2);