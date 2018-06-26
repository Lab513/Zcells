function Compo = imborders(LBL, BKGD, varargin)

ip = inputParser;
ip.addOptional('thickness',3,@(x) isscalar(x) & isnumeric(x));
ip.addOptional('colormap',@cmapfun);
ip.parse(varargin{:});

overlay = double(label2rgb(LBL,ip.Results.colormap,[0 0 0]))/256;

if size(BKGD,3) == 3
    Compo = BKGD;
elseif size(BKGD,3) == 1
    Compo = grs2rgb(BKGD,gray);
end
borders = xor(LBL,imerode(LBL,strel('disk',ip.Results.thickness)));

for RGB = 1:3
    CompoL = Compo(:,:,RGB);
    overlayL = overlay(:,:,RGB);
    CompoL(borders) = overlayL(borders);
    Compo(:,:,RGB) = CompoL;
end

function cmap = cmapfun(numregions)

nbcolors = 20;

colors = distinguishable_colors(nbcolors,{'w','k'});
cats = floor(numregions/nbcolors);
ret = numregions - nbcolors*cats;

cmap = repmat(colors,cats,1);
cmap = cat(1,cmap,colors(1:ret,:));
cmap = cmap(randperm(numregions),:);