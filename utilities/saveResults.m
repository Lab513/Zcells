function saveResults(path,results,varargin)
% This saves prediction results to disk in a specific format so that they
% can reloaded into the predictionDisplay GUI.
% Note: There is currently some problem which I can't elucidate, and the
% results are saved twice into the MAT file: once as 'results' and once as
% 'Results'. I can't understand why yet

ip = inputParser();
ip.addOptional('stackFile','',@isstr)
ip.addOptional('classifier','',@isstr)
ip.addOptional('img',[])
ip.addOptional('ROI',[])
ip.parse(varargin{:})

mf = matfile(fullfile(path),'Writable',true);
mf.results = results;
mf.type_of_file = 'results';

if ~isempty(ip.Results.stackFile)
    mf.stackfile = ip.Results.stackFile;
end
if ~isempty(ip.Results.classifier)
    mf.classifier = ip.Results.classifier;
end
if ~isempty(ip.Results.img)
    mf.img = ip.Results.img;
end
if ~isempty(ip.Results.ROI)
    mf.ROI = ip.Results.ROI;
end
