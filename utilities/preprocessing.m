function IF = preprocessing(I,feat,varargin)
% This function handles the preprocessing operations to perform on the
% frames in the stack. It takes a frame I as an input and a
% "feature/operation" structure, applies the operation described by the
% structure, and spits out an image of equal dimension.

ip = inputParser();
ip.addOptional('frame_nb',0,@(x) isnumeric(x) && isscalar(x));
ip.parse;


switch lower(feat.name)
    case 'intensity'
        IF = I;
    case 'gradient'
        if isfield(feat,'method')
            method = feat.method; % See imgradient doc page
        else
            method = 'sobel';
        end
        [IF,~] = imgradient(I,method);
    case 'average'
        h = fspecial('average',feat.hsize);
        IF = imfilter(I,h,'replicate');
    case 'disk'
        h = fspecial('disk',feat.radius);
        IF = imfilter(I,h,'replicate');
    case 'laplacian'
        h = fspecial('laplacian',feat.alpha);
        IF = imfilter(I,h,'replicate');
    case 'gaussian'
%         h = fspecial('gaussian',feat.hsize,feat.sigma);
%         IF = imfilter(I,h,'replicate');
        IF = imgaussfilt(I,feat.sigma);
    case 'log'
        h = fspecial('log',feat.hsize,feat.sigma);
        IF = imfilter(I,h,'replicate');
    case 'customfilter'
        % You can pass any convolutinal 2D filter
        h = feat.filter;
        IF = imfilter(I,h,'replicate');
    case 'customfunction'
        % You can pass any function that returns an image of equal
        % size
        switch nargin(feat.fhandle)
            case 1 % Don't pass frame number
                IF = feval(feat.fhandle,I);
            case 2 % Pass frame number
                IF = feval(feat.fhandle,I,ip.Results.frame_nb);
        end
end