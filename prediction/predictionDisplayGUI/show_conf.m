function [I, scores] = show_conf(res, imgsize, varargin )

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