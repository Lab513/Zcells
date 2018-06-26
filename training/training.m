% params = training(params, nb_components (, ('settings', struct(X)), ('save', (Y))))
%
%   Take :
%       'params', the struct containing parameters needed for others
% functions.
%       'nb_components', the number of components who want to keep.
%       'X', a struture used to set the parameters of the SVM. Example :
% SVMparameters = struct('CacheSize', 15e3, 'DeltaGradientTolerance', 5e-2,
% 'ParallelTrain', true);
%       'Y', the parameter linked with save. Set it to false if you don't
% want to save
%   Return :
%       'params', the struct containing parameters needed for others
% functions.

function [RandomForest] = training(training_set, data, varargin)
    
    ip = inputParser();
    addRequired(ip,'training_set',@isstruct);
    addRequired(ip,'data',@isstruct);
    addParameter(ip, 'save',false);
    parse(ip,training_set, data, varargin{:})    
    
    cluster = [];
    
    % Process the SVM parameters a first time: (SVM optimization parameters
    % will be processed again later, class by class)
    training_set.parameters = process_SVM_params(training_set.parameters, training_set.classnames);

    % Process the classification tree:
    [siblings, children, parents] = process_SVM_tree(training_set.hierarchy,training_set.classnames);
    
    % Train SVM:
    for ind1 = 1:numel(siblings)
        curr_siblings = siblings(ind1);
        curr_siblings = curr_siblings{1};
        
        for ind2 = 1:numel(curr_siblings) % Assign children, siblings and parents into the models structure
            RandomForest.(curr_siblings{ind2}).siblings = setdiff(curr_siblings, curr_siblings{ind2});
            if isfield(training_set.hierarchy,curr_siblings{ind2})
                RandomForest.(curr_siblings{ind2}).parent = training_set.hierarchy.(curr_siblings{ind2});
            else
                RandomForest.(curr_siblings{ind2}).parent = '';
            end
            if any(strcmp(curr_siblings{ind2},parents))
                RandomForest.(curr_siblings{ind2}).children = children(strcmp(curr_siblings{ind2},parents));
            end
        end
        
        % Launch Forest training
        [Trees, cluster] = LaunchTraining(training_set,data,curr_siblings{1},curr_siblings, cluster);

        for ind2 = 1:numel(curr_siblings)
            RandomForest.(curr_siblings{ind2}).type = 'Trees';
            RandomForest.(curr_siblings{ind2}).SVM = Trees;
        end
    end
end

function [output, cluster] = LaunchTraining(training_set,data,classname,siblings, cluster)

    % Binarize the set:
    tokeep = zeros(size(data.label));

    % Reduce the data to the necessary elements:
    for ind1 = 1:numel(siblings)
            tokeep = tokeep | data.label == find(strcmp(siblings{ind1},training_set.classnames));
    end

    data.label = data.label(tokeep);
    data.components = data.components(tokeep,:);

    % Get classes' parameters:
    RF_params = training_set.parameters.SVM_params.(classname);

    
    % Launch the SVM:
    pp = training_set.parameters.parallel_processing;
    if pp.status % Parallelize
        if isempty(cluster)
            if isfield(pp,'cluster')
                cluster = pp.cluster;
            elseif isfield(pp,'cluster_profile')
                cluster = parcluster(pp.cluster_profile);
            else
                cluster = parcluster();
                cluster.NumWorkers = pp.nbWorkers;
            end
        end
        output = batch(cluster,@launchfitTrees, 1, {data,RF_params});
    else % Do not parallelize
        cluster = [];
        output = launchfitTrees(data,RF_params);
    end

end

function output = launchfitTrees(data,RF_params)

nt = find(strcmp(RF_params,'NumTrees')); % Should be the first one, but I guess this is more secure...
NumTrees = RF_params{nt+1};
RF_params(nt+1) = [];
RF_params(nt) = [];

output = TreeBagger(NumTrees,data.components,data.label,...
    'Method','classification',...
    RF_params{:});

output = compact(output);
end





%% Process parameters:
function processed = process_SVM_params(training_params, classnames)
% This function re-formats the parameters training structure to be easier
% to interface with the fitcsvm function

    processed = training_params;
    processed = rmfield(processed,'class_specific');

    % Retrieve the class specific parameters:
    def = training_params.class_specific.default;
    if isfield(training_params.class_specific,'spec')
        spec = training_params.class_specific.spec;
    else
        spec = struct();
    end
    
    % Transform the SampleWithReplacement value from boolean to
    % Matlab's 'on'/'off' bullshit:
    if def.SVM.SampleWithReplacement
        def.SVM.SampleWithReplacement = 'on';
    else
        def.SVM.SampleWithReplacement = 'off';
    end
    
    

    % Compute the parameters for each class:
    for ind1 = 1:numel(classnames)
        currclass = classnames{ind1};
        
        if isfield(spec,currclass)
            if isfield(spec.(currclass),'SVM')
                % Transform the SampleWithReplacement value from boolean to
                % Matlab's 'on'/'off' bullshit:
                if isfield(spec.(currclass).SVM,'SampleWithReplacement')
                    if spec.(currclass).SVM.SampleWithReplacement
                        spec.(currclass).SVM.SampleWithReplacement = 'on';
                    else
                        spec.(currclass).SVM.SampleWithReplacement = 'off';
                    end
                end
                SVM.(currclass) = parameters_cell(def.SVM, spec.(currclass).SVM);
            else
                SVM.(currclass) = parameters_cell(def.SVM, struct());
            end
        else
            SVM.(currclass) = parameters_cell(def.SVM, struct());
        end

    end

    processed.SVM_params = SVM;
end

function [siblings, allchildren, allparents] = process_SVM_tree(hierarchy,classnames)
% This function creates an array of cells containing all the different
% siblings groups (i.e. children of the same parent) in the hierarchy tree.

    children = fieldnames(hierarchy)';
    siblings{1} = setdiff(classnames,children);
    parents = cellfun(@(x) hierarchy.(x), children,'UniformOutput',false);
    allchildren = children;
    allparents = parents;
    while(~isempty(children))
        siblings{end+1} = children(strcmp(parents{1},parents));
        children = setdiff(children,siblings{end});
        parents = cellfun(@(x) hierarchy.(x), children,'UniformOutput',false);
    end
end

function res = parameters_cell(default, spec)

    fnames = fieldnames(spec);
    for ind1 = 1:numel(fnames)
        default.(fnames{ind1}) = spec.(fnames{ind1});
    end

    params_names = fieldnames(default);
    res = {};
    for ind1 = 1:numel(params_names)
        res{end+1} = params_names{ind1};
        res{end+1} = default.(params_names{ind1});
    end
end

function res = parameters_struct(default, spec)

    fnames = fieldnames(spec);
    for ind1 = 1:numel(fnames)
        default.(fnames{ind1}) = spec.(fnames{ind1});
    end
    res = default;
end

function yesno = compare_parameters(training_set, sib1, sib2)
yesno = isequal(training_set.parameters.SVM_params.(sib1),training_set.parameters.SVM_params.(sib2));
end