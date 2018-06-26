function [imcomp, layers] = show_classes(res, imgsize, varargin )

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

