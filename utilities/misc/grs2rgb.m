function [res, varargout] = grs2rgb(img, map, varargin)

%%Convert grayscale images to RGB using specified colormap.
%	IMG is the grayscale image. Must be specified as a name of the image 
%	including the directory, or the matrix.
%	MAP is the M-by-3 matrix of colors.
%
%	RES = GRS2RGB(IMG) produces the RGB image RES from the grayscale image IMG 
%	using the colormap HOT with 64 colors.
%
%	RES = GRS2RGB(IMG,MAP) produces the RGB image RES from the grayscale image 
%	IMG using the colormap matrix MAP. MAP must contain 3 columns for Red, 
%	Green, and Blue components.  
%
%	Example 1:
%	open 'image.tif';	
%	res = grs2rgb(image);
%
%	Example 2:
%	cmap = colormap(summer);
% 	res = grs2rgb('image.tif',cmap);
%
% 	See also COLORMAP, HOT
%
%	Written by 
%	Valeriy R. Korostyshevskiy, PhD
%	Georgetown University Medical Center
%	Washington, D.C.
%	December 2006
%
% 	vrk@georgetown.edu
% 
%   Slightly modified by JB Lugagne


% Check the arguments
if nargin<1
	error('grs2rgb:missingImage','Specify the name or the matrix of the image');
end;

if ~exist('map','var') || isempty(map)
	map = hot(64);
end;

[l,w] = size(map);

if w~=3
	error('grs2rgb:wrongColormap','Colormap matrix must contain 3 columns');
end;

if ischar(img)
	a = imread(img);
elseif isnumeric(img)
	a = img;
else
	error('grs2rgb:wrongImageFormat','Image format: must be name or matrix');
end;


a = double(a);

% Get min and max to use in the heatmap:
iswhatIwant = @(x) isnumeric(x) && isscalar(x);
ip = inputParser();
ip.addOptional('HeatMin',[],iswhatIwant);
ip.addOptional('HeatMax',[],iswhatIwant);
ip.parse(varargin{:})
if isempty(ip.Results.HeatMin)
    hmin = min(a(:));
else
    hmin = ip.Results.HeatMin;
end
if isempty(ip.Results.HeatMax)
    hmax = max(a(:));
else
    hmax = ip.Results.HeatMax;
end
% Calculate the indices of the colormap matrix
ci = ceil(l*(a-hmin)/(hmax-hmin));
ci(ci > l) = l;
ci(ci < 1) = 1;


% Colors in the new image
[il,iw] = size(a);
r = zeros(il,iw); 
g = zeros(il,iw);
b = zeros(il,iw);
r(:) = map(ci,1);
g(:) = map(ci,2);
b(:) = map(ci,3);

% New image
res = zeros(il,iw,3);
res(:,:,1) = r; 
res(:,:,2) = g; 
res(:,:,3) = b;

if nargout == 2
    varargout{1} = [hmin, hmax];
end
