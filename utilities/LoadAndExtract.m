function [data, pcavals,varargout] = LoadAndExtract(training_set, varargin)
%
% [data, pcavals] = LoadAndExtract(training_set)
% [data, pcavals, test_data] = LoadAndExtract(training_set, test_set)
% 
% LoadAndExtract runs through the stack in the training_set.trainingpx
% structure and applies the image pre-processing, focussing radius, and PCA
% operations specified in training_set.parameters to the data.
% 
% [data, pcavals] = LoadAndExtract(training_set)
% returns a structure, data, that contains two matrices: The first N
% principal components of the observations specified in the training_set
% variable. It also returns the PCA parameters useful for applying the same
% operations later on, for prediction.
% 
% [data, pcavals, test_data] = LoadAndExtract(training_set,'test_set', test_set)
% If the user specifies another set that was produced by the training set
% construction GUI, it will be used as a test set, and a structure 
% (test_data) of the same format as data. The PCA coefficients from the
% initial training_set will be applied (no matter what is specified in the
% test_set parameters structure), as well as the image preprocessing 
% operations from the trainingset. However, the focusing radius from
% test_set will be used.
% 
% [data, pcavals, test_data] = LoadAndExtract(training_set,'test_set', test_set)
% If the user specifies a test "percentage" (>0 and <100), then the
% training data from the training_set structure will be partitioned into
% data (for training) and test_data (for evaluation purposes).

    % Parse inputs
    ispercent = @(x) isscalar(x) && isnumeric(x) &&  x >= 0 && x < 100;
    ip = inputParser();
    addParameter(ip, 'test_set', [], @isstruct);
    addParameter(ip, 'test_percent', 0, ispercent);
    ip.parse(varargin{:});
    if ~isempty(ip.Results.test_set) && ip.Results.test_percent > 0
        error("You can not both specify a test_set and require a test_percent >0")
    end
        
    % Backward compatibility for frame processing:
    if ~isfield(training_set.parameters,'frame_processing') || isempty(training_set.parameters.frame_processing)
        training_set.parameters.frame_processing = {struct('name','Intensity')};
    end

    % Process the subsampling rates
    training_set.parameters.subsampling = process_subsampling(training_set.parameters, training_set.classnames);
    nb_components = training_set.parameters.feature_extraction.nbcomponents;

    % Loading data:
    if training_set.parameters.feature_extraction.subsampling < 100
        % Load up a subset of the data to compute PCA coefficients:
        disp(['Loading up ' num2str(training_set.parameters.feature_extraction.subsampling) '% of data to estimate the PCA'])
        dummy = training_set;
        for ind1 = 1:numel(training_set.classnames) % Change the subsampling rate:
            dummy.parameters.subsampling.(training_set.classnames{ind1}) = dummy.parameters.subsampling.(training_set.classnames{ind1}) * (training_set.parameters.feature_extraction.subsampling/100);
        end
        [data.components, data.label] = compile_data(dummy,'use_features',training_set.parameters.frame_processing);
    else
        [data.components, data.label] = compile_data(training_set,'use_features',training_set.parameters.frame_processing);
    end
        
    % Principal Component Analysis
    [pcavals.coeff, ~, pcavals.latent, ~, ~, pcavals.mu] = pca( ...
        data.components, ... 
        'NumComponents', nb_components ...
        );
    percVar = sum(pcavals.latent(1:nb_components))/sum(pcavals.latent);
    disp(['Variance accounted for by the first ' num2str(nb_components) ' components: ' num2str(100*percVar,'%02.1f') '%'])
    
    % Now get the full datasets (both training and test, if applicable):
    if training_set.parameters.feature_extraction.subsampling < 100
        disp('Now loading up all training data and extracting features on-the-fly...')
        % Load up all data and extract features on-the-fly:
        [data.components, data.label] = compile_data(training_set, ...
            'pca_coeffs',pcavals.coeff, ...
            'pca_mu',pcavals.mu, ...
            'use_features',training_set.parameters.frame_processing ...
            );
    else
        data.components = (data.components - repmat(pcavals.mu,size(data.components,1),1)) * pcavals.coeff;
    end
    testdata = struct();
    if ~isempty(ip.Results.test_set)
        disp('Now loading up all test data and extracting features on-the-fly...')
        % Load up all data and extract features on-the-fly:
        [testdata.components, testdata.label] = compile_data(ip.Results.test_set, ...
            'pca_coeffs',pcavals.coeff, ...
            'pca_mu',pcavals.mu, ...
            'use_features',training_set.parameters.frame_processing ...
            );
    elseif ip.Results.test_percent > 0
        disp('Partitioning training and test data...')
        nsamples = size(data.components,1);
        test_part = randsample(nsamples,round(nsamples*ip.Results.test_percent/100));
        testdata.components = data.components(test_part,:);
        testdata.label = data.label(test_part);
        data.components(test_part,:) = [];
        data.label(test_part) = [];
    end
    if nargout == 3
        varargout{1} = testdata;
    end
    disp('Done!')
    

  
function subsample = process_subsampling(training_params, classnames)
% This function computes the subsampling to apply to each class to feed it
% into the compile_data function

% Retrieve the class specific parameters:
def = training_params.class_specific.default;
if isfield(training_params.class_specific,'spec')
    spec = training_params.class_specific.spec;
else
    spec = struct();
end

for ind1 = 1:numel(classnames)
    currclass = classnames{ind1};
    if isfield(spec,currclass) && isfield(spec.(currclass),'subsample')
        subsample.(currclass) = spec.(currclass).subsample;
    else
        subsample.(currclass) = def.subsample;
    end
end
