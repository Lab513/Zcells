function [imcomp, layers] = show_classes(res, imgsize, varargin )
%
% [imcomp, layers] = show_classes(res, imgsize)
% 
% [imcomp, layers] = show_classes(res, imgsize, 'Name', Value)
%
% Classification Results display function.
% You must provide a results structure 'res' as produced by the function
% RunPrediction(), and the size of one frame, 'imgsize'. 'imcomp' is an RGB image
% displaying the predicted classes in different colors. 'layers' is an 
% N-dimensinal boolean image, where N is the number of classes to display. This is
% useful for downstream segmentation.
%
% You can provide the following Name-Value pair arguments:
% * 'WhichClasses', cell-of-class-names: A cell containing the names of the
%   classes you want to display. You may prefer to display only a
%   subselection of the classes. All classes are shown by default.
% * 'Colors', N-by-3 matrix: contains rgb values (0 to 1) tu use for each
%   class.
% * 'Background', image matrix: An image that you want to display the
%   classes over. Typically the middle frame of your stack. Default: [].
% * 'alpha', 0-to-1 scalar: Transparency of the classes if doing an
%   background overlay. Default: 1.

% Parameters and inputs parsingP:
ip = inputParser();
ip.addOptional('WhichClasses',{});
ip.addOptional('Colors',[]);
ip.addOptional('Background',[]);
ip.addOptional('alpha',1);
ip.parse(varargin{:})

imcomp = ip.Results.Background;
if isempty(imcomp)
    imcomp = ones(imgsize(1),imgsize(2),3);
end
if isempty(ip.Results.WhichClasses)
    WhichClasses = fieldnames(res);
else
    WhichClasses = ip.Results.WhichClasses;
end
if isempty(ip.Results.Colors)
    Colors = distinguishable_colors(numel(WhichClasses),[0 0 0; 1 1 1]);
else
    Colors = ip.Results.Colors; % I should check the orientation here...
end

% Plotting:
for ind1 = 1:numel(WhichClasses)
    currclass = WhichClasses{ind1};
    currRes = res.(currclass);
    layers(:,:,ind1) = reshape(currRes.isa,imgsize);
    
    imcomp = coloroverlay(imcomp,layers(:,:,ind1),Colors(ind1,:),ip.Results.alpha);
end


function Icomp = coloroverlay(I0,ROI,color,alpha)

Icomp = I0;
for RGB = 1:3
    IcompL = Icomp(:,:,RGB);
    overlay  = repmat(color(RGB),size(ROI));
    IcompL(ROI) = (1-alpha)*IcompL(ROI) + alpha*overlay(ROI);
    Icomp(:,:,RGB) = IcompL;
end

