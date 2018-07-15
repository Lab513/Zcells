% Feature extraction and svm training require the pixels, or observations
% to be in a certain format: It has to be an "n-by-p data matrix X. Rows 
% of X correspond to observations and columns correspond to variables."
% THis is what this function does, and the formatted data is in
% trainingMat.
% Also for SVM training the "classes" of each observation (in our case
% pixels) must be provided, in an n-by-1 vector specifying the group of
% each observation. The numbers are based on the order of the groupsnames
% cell of strings.
%
% [trainingMat, vec] = compile_dataset(trainingpx, groupsnames, radius)
%
%   Take :
%       'trainingpx', the pixel you selected during the construction of the
% data set.
%       'groupsnames', the class you created for selecting pixels in your
% during the creation of the data set.
%       'radius', this parameter set the radius you want for making extra 
% data by concataining different operation on different stack. It actually
% shift the offset used in runthroustack and permit to train on way more
% data that what you have. Radius must not exceed <number_of_stack / 2>.
%
%   Return :
%       'trainingMat', the matrix created with the runthroughstack
% function.
%       'class_vec', a vector containing every class for every pixel in
% your matrix. 

function [trainingMat, class_vec] = compile_data(training_set, varargin)
% Run through the fields, load up the zstacks, get the observations for each
% group and concatenate it all:

    %% inputs

    % Parsing
    ip = inputParser();
    addRequired(ip, 'training_set', @validatetrainingset)
    addParameter(ip, 'use_features', {struct('name','Intensity')}, @iscell);
    addParameter(ip, 'pca_coeffs', []);
    addParameter(ip, 'pca_mu', []);
    parse(ip,training_set, varargin{:});

    % Re-label
    trainingpx = training_set.trainingpx;
    classnames = training_set.classnames;
    params = training_set.parameters;
    
    frames_subselection = params.frames_subselection.frames;
    
    if params.focus_shifting.status
        radius = params.focus_shifting.radius;
    else
        radius = 0;
    end
    
    
    %Misc
    rootname = 'Zcells';

    % Initialize formatted training matrix and class vector:
    trainingMat = [];
    class_vec = [];

    
    %% function

    % Run through all stacks:
    zstacks = fieldnames(trainingpx);
    for ind0 = 1:numel(zstacks)
        
        zstackstr = zstacks{ind0};
        disp('---------------------------------------------------------');
        disp(['Dataset formatting on zstack : ' zstackstr ' (' num2str(ind0) '/' num2str(numel(zstacks)) ')']);
        % reconstruct the path to the zstack:
        disp(trainingpx.(zstackstr).path)
        fullpath = relative2full(trainingpx.(zstackstr).path,rootname);

        % Identify which pixels to exctract from the stack, and update group vector:
        groupspxl = [];
        group = [];
        for ind1 = 1:numel(classnames)
            classname = classnames{ind1};
            if isfield(trainingpx.(zstackstr).pixel,classname) % If there are pixels for this group in this zstack:
                group = [group; ind1.*ones(numel(trainingpx.(zstackstr).pixel.(classname)),1)];
                groupspxl = cat(2,groupspxl,trainingpx.(zstackstr).pixel.(classname)');
            end
        end
        if isempty(groupspxl)
            disp('No labels on zstack, nothing to do...');
            disp('');
        else

            % Extract subsampling ratio (if specified):
            if isfield(params,'subsampling') && isfield(params.subsampling,classname)
                randSub = (params.subsampling.(classname) / 100);
            else
                randSub = 1;
            end

            % Load up the stack once for all offsets:
            disp('Reading data on file...');
            mfile = matfile(fullpath);
            zstack = mfile.(trainingpx.(zstackstr).stackvarname);

            % Then run through the stack:
            for i = -radius:radius

                % Specify which frames will be used to extract the signatures:
                framestorun = frames_subselection + i;
                disp(['Retrieving for focus shift = ' num2str(i) ' frame (radius = ' num2str(radius) ' frames)']);

                % Subsample the signatures if specified
                if randSub < 1 % The random subsample is different for each focussing offset
                    [subpxl, idxs] = datasample(groupspxl,round(numel(groupspxl)*randSub),'Replace',false);
                    subgrp = group(idxs);
                else
                    subpxl = groupspxl;
                    subgrp = group;
                end

                % Run through the stack and concatenate the training matrix and class vector on
                % the fly:
                trainingMat = cat(1, trainingMat, runthroughstack(...
                    zstack, ...
                    'offset', framestorun, ...
                    'groupspxl', subpxl, ...
                    'pca_coeffs', ip.Results.pca_coeffs, ...
                    'pca_mu', ip.Results.pca_mu, ...
                    'use_features', ip.Results.use_features ...
                    ));
                class_vec = cat(1, class_vec, subgrp);
            end
        end

    end
end




%% Utilities
function [subpxl, subgrp] = subsamplesignatures(groupspxl,group,randSub)
% This function subsamples the different signatures dpending on each class
% subsampling ratio

    subpxl = [];
    subgrp = [];
    for ind1 = 1:numel(randSub)
        nbsamples = round(nnz(group==ind1)*randSub(ind1));
        subpxl = cat(2, subpxl, randsample(groupspxl(group == ind1),nbsamples,0));
        subgrp = cat(1, subgrp, ones(nbsamples,1)*ind1);
    end

end

function isvalid = validatetrainingset(t_s)
    % this function summarily validates the structure of the training set.
    isvalid = isstruct(t_s) && isfield(t_s,'trainingpx') && isfield(t_s,'classnames') && isfield(t_s,'parameters');
    if ~isfield(t_s,'rgbmap')
        warning('TS:NoRGBmap','The training set provided contains no RGB map for the different classes.');
    end
end

