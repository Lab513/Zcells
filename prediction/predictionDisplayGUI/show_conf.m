function [I, scores] = show_conf(res, imgsize, varargin )
%
% [imconf, scores] = show_conf(res, imgsize)
% 
% [imconf, scores] = show_conf(res, imgsize, 'Name', Value)
%
% Classification confidence display function.
% You must provide a results structure 'res' as produced by the function
% RunPrediction(), and the size of one frame, 'imgsize'. 'imconf' is an RGB image
% displaying the classification confidence . 'scores' is an N-dimensinal
% image, where N is the number of classes to display. Each 1-dimensional
% image contains the confidence scores for 1 class, values between [0 1].
% This is useful for downstream segmentation.
%
% You can provide the following Name-Value pair arguments:
% * 'Colormap', colormap matrix: A colormap matrix to specify how to
%   display scores. Default: jet();
% * 'ZeroColor', 1-by-3 vector: The color to use for parts that are not
%   classified as any of the classes.
% * 'WhichClasses', cell-of-class-names: A cell containing the names of the
%   classes you want to display. You may prefer to display only a
%   subselection of the classes. All classes are shown by default.


% Parameters and inputs parsingP:
ip = inputParser();
ip.addOptional('Colormap',jet());
ip.addOptional('ZeroColor',[1 1 1]);
ip.addOptional('WhichClasses',{});
ip.parse(varargin{:})

if isempty(ip.Results.WhichClasses)
    WhichClasses = fieldnames(res);
else
    WhichClasses = ip.Results.WhichClasses;
end

% Run through the classes scores and keep best results:
compiled = zeros(size(res.(WhichClasses{1}).scores)).*NaN;
for ind1 = 1:numel(WhichClasses)
    compiled = max(res.(WhichClasses{ind1}).scores,compiled);
end

% Format into image size:
scores = reshape(compiled,imgsize);

% Create RGB image with the input colormap:
I = repmat(reshape(ip.Results.ZeroColor,1,1,3),imgsize(1),imgsize(2),1);
I(repmat(~isnan(compiled),3,1)) = ...
    reshape(...
                grs2rgb( ...
                            compiled(~isnan(compiled)), ...
                            ip.Results.Colormap, ...
                            'HeatMin',0, ...
                            'HeatMax',1 ...
                        ), ...
                sum(~isnan(compiled))*3, ...
                1 ...
            );