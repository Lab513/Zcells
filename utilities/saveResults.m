function saveResults(path,results,varargin)

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
