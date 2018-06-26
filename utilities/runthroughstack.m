% This function runs through a zstack file (mfile or actual stack (cell form or matrix form)) and loads the pixel-observations
% into the trainingMat output. \
% It is possible to provide a pixel list to limit the number of 
% observations per z-frame to a subset. (see 'groupspxl' below)
% It is possible to specify which subset of frames in the Z-Stack should be
% use, (see 'offset' below)
% It is also possible to provide a set of PCA coefficients to apply to
% frames on the fly to reduce the memory footprint. (see 'pca_coeffs' and
% 'pca_mu' parameters below)
% It is now also possible to provide a list of "features", or
% image pre-processing operations to perform on each frame of the stack.
% This may or may not help achieve better performance. (see 'use_features'
% below)

function [trainingMat] = runthroughstack(inputstack, varargin)

    %% inputs
    
    % inputstack
    ip = inputParser();
    addRequired(ip, 'inputstack'); % Will be processed after the parsing
    addParameter(ip, 'stackVarName', 'stack', @ischar);
    addParameter(ip, 'groupspxl',[],@isnumeric);
    addParameter(ip, 'offset', [], @isnumeric);
    addParameter(ip, 'use_features', {struct('name','Intensity')}, @iscell);
    addParameter(ip, 'pca_coeffs', []);
    addParameter(ip, 'pca_mu', []);
    addParameter(ip, 'Verbosity', 1,@isscalar);
    parse(ip,inputstack,varargin{:});
    
    stackvarname = ip.Results.stackVarName;
    groupspxl = ip.Results.groupspxl;
    offset = ip.Results.offset;
    use_features = ip.Results.use_features;
    pca_coeff = ip.Results.pca_coeffs;
    pca_mu = ip.Results.pca_mu;
    verbosity = ip.Results.Verbosity;
    
    % inputstack processing
    switch class(inputstack)
        case 'char'
            if isfile(inputstack) 
                [~,~,ext] = fileparts(inputstack);
                switch ext
                    case '.mat'
                        inputstack = matfile(inputstack);
                        stack = uint16(reshape(cell2mat(inputstack.(stackvarname)),[size(cell2mat(inputstack.(stackvarname)(1,1))) numel(inputstack.(stackvarname))]));
                    case '.tif'
                        info = imfinfo(inputstack);
                        num_images = numel(info);
                        for i = 1:num_images
                            stack(:,:,i) = imread(inputstack, i);
                        end
                        stack = uint16(stack);
                end
            else
                error(['file ' inputstack ' does not exist']);
            end
        case 'matlab.io.MatFile'
            stack = uint16(reshape(cell2mat(inputstack.(stackvarname)),[size(cell2mat(inputstack.(stackvarname)(1,1))) numel(inputstack.(stackvarname))]));
        case 'cell'
            stack = uint16(reshape(cell2mat(inputstack),[size(inputstack{1}) numel(inputstack)]));
        otherwise
            if isnumeric(inputstack)
                stack = inputstack;
            else
                error(['Unknown input type: ' class(inputstack)]);
            end
    end
    
    % groupspxl processing:
    if isempty(groupspxl)
        groupspxl = 1:numel(stack(:,:,1));
    end
    
    % "offset" processing:
    if isempty(offset)
        offset = 1:size(stack,3);
    end

    %% function
    if verbosity >= 1
        fprintf(['Running through stack, retrieving ' num2str(numel(groupspxl)) ' signatures\n']);
    end
    
    % Get values for histogram equalization:
    value_in = get_adjust_parameters(stack,offset);
    % Extract the signatures:
    trainingMat = extract_signatures(stack, groupspxl, offset, value_in, use_features, pca_coeff, pca_mu, verbosity);
end


%% Utilities
function [compiled] = extract_signatures(stack, groupspxl, offset, value_in, use_features, pca_coeff, pca_mu, verbosity)
    
    % Init variables:
    msg = '';
    numObs = numel(offset);
    num_features = numel(use_features);
    if ~isempty(pca_coeff)
        compiled = zeros(numel(groupspxl), size(pca_coeff,2));
    else
        compiled = zeros(numel(groupspxl), numObs*num_features);
    end
    
    % Calculate which frames will be used in stack according to offset:
    if numel(offset) == 1
        error('RTS:Only1Frame','Only one frame specified for offset');
    end
    
    frame_nbs = offset;
    % Some protection:
    frame_nbs(frame_nbs < 1) = 1;
    frame_nbs(frame_nbs > size(stack,3)) = size(stack,3);

    % Unfortunately, to extract the features we have to run a for loop (we
    % should look into 3D convolution though)
    for ind0 = 1:numel(frame_nbs)
        ind1 = frame_nbs(ind0);

        % Display
        if verbosity>=1
            bkspces = repmat('\b',1,numel(sprintf(msg)));
            ratio = ind0/numObs;
            msg = [ '[' repmat('#',1,round(40*ratio)) repmat('-',1,round(40-(40*ratio))) '] ' num2str(ind0) '/' num2str(numObs) '\n\n'];
            fprintf([bkspces msg]);
        end
        % /Display

        % Get image:
        im = stack(:,:,ind1);
        im = imadjust(im, [value_in(1);value_in(2)]);
        % Extract features:
        imfeatures = extract_features(im,groupspxl,use_features);
        
        % Store in matrices
        % If using PCA coefficients for compression on-the-fly:
        pca_indexes = (ind0-1)*num_features + (1:num_features);
        if ~isempty(pca_coeff)
            if ~isempty(pca_mu)
                compiled = compiled + ... 
                    (imfeatures-repmat(pca_mu(pca_indexes),size(imfeatures,1),1)) * ...
                    pca_coeff(pca_indexes,:); % Compute pca on the fly %
            else
                compiled = compiled + ... 
                    imfeatures * ...
                    pca_coeff(pca_indexes,:); % Compute pca on the fly %
            end
        else
            compiled(:,pca_indexes) = imfeatures; % normal image
        end
        
    end
        
end

function extracted = extract_features(I,groupspxl,feats)
% Given a frame and the indexes of the pixels of interest, this function
% extracts the features specified in feats and returns a compiles set
% of observcations in extracted

    extracted = zeros(numel(groupspxl), numel(feats));
    for ind1 = 1:numel(feats)
%         feats{ind1}
        IF = preprocessing(I,feats{ind1});
        extracted(:,ind1) = double(IF(groupspxl));
    end
end

function parameters = get_adjust_parameters(stack, offset)

    % Thresh: ratio of pixels that will be saturated. Realthresh: ratio
    % over all frames
    thresh = 1/100;
    
    if numel(offset) > 1
       ref_img = stack(:,:,offset(round(numel(offset)/2)));
    else
       ref_img = stack(:,:,round(size(stack, 3) / 2) - offset);
    end
    
    [counts, bin_location] = imhist(ref_img);
    sat_min = find(cumsum(counts) >= (thresh/2) * max(cumsum(counts)), 1, 'first');
    sat_max = find(cumsum(counts) >= (1-thresh/2) * max(cumsum(counts)), 1, 'first');
    mvuint16 = double(intmax('uint16')); 
    parameters = [double(bin_location(sat_min)/mvuint16), double(bin_location(sat_max))/mvuint16];
end
