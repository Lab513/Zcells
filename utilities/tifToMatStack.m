function tifToMatStack(varargin)
% This function turns a multi-page tif stack (the kind micro-manager
% produces for example) into a MAT file of the right format for our
% algorithm. Update: It also works with image sequences now (i.e. user can
% provide a list of images)

    ip = inputParser();
    addOptional(ip,'files',{},@iscell);
    addParameter(ip,'except',[],@isnumeric);
    parse(ip, varargin{:});
    FilesCell = ip.Results.files;

    if isempty(FilesCell)
        % Ask user for file
        [FileName,PathName, ~] = uigetfile('*.tif','Select tif file','MultiSelect','on');
        % Check number of files:
        if ~iscell(FileName)
            if ischar(FileName)
                FilesCell{1} = fullfile(PathName,FileName);
            else
                return; % Abort
            end
        else
            for ind1 = 1:numel(FileName)
                FilesCell{ind1} = fullfile(PathName,FileName{ind1});
            end
        end
    end
    
    
    numfiles = numel(FilesCell);
    % Loop on files and images per file and append to the matfile:
    for ind1 = 1:numfiles
        
        ret_name = regexprep(FilesCell{ind1},'.tif','.mat');
        mfile = matfile(ret_name,'Writable',true);
        mfile.type_of_file = 'stack';
        totnumim = 0;
        
        fname = FilesCell{ind1};
        info = imfinfo(fname);
        num_images = numel(info);
        todo = setdiff(1:num_images, ip.Results.except);
        for i = todo
            img = imread(fname, i);
            totnumim = totnumim + 1;
            disp(totnumim) % We should replace that with a proper message at some point...
            mfile.stack(1,totnumim) = {img};
        end

    end
end