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

function [SVMmodels] = training(training_set, data, varargin)
    
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
            SVMmodels.(curr_siblings{ind2}).siblings = setdiff(curr_siblings, curr_siblings{ind2});
            if isfield(training_set.hierarchy,curr_siblings{ind2})
                SVMmodels.(curr_siblings{ind2}).parent = training_set.hierarchy.(curr_siblings{ind2});
            else
                SVMmodels.(curr_siblings{ind2}).parent = '';
            end
            if any(strcmp(curr_siblings{ind2},parents))
                SVMmodels.(curr_siblings{ind2}).children = children(strcmp(curr_siblings{ind2},parents));
            end
        end
        
        % Launch SVM training
        if numel(curr_siblings) == 2 ... % If there are only 2 classes...
               && compare_parameters(training_set, curr_siblings{:}) % .. and the parameters for the two are the same --> Binary SVM
            SVMmodels.(curr_siblings{1}).type = 'binary';
            SVMmodels.(curr_siblings{2}).type = 'binary';
            SVMmodels.(curr_siblings{2}).SVM = [];
            [SVMmodels.(curr_siblings{1}).SVM, cluster] = LaunchTraining(training_set,data,curr_siblings{1},curr_siblings, cluster);
        else
            for ind2 = 1:numel(curr_siblings)
                SVMmodels.(curr_siblings{ind2}).type = 'WTA';
                [SVMmodels.(curr_siblings{ind2}).SVM, cluster] = LaunchTraining(training_set,data,curr_siblings{ind2},curr_siblings, cluster);
            end
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

    data.label = data.label(tokeep) == find(strcmp(training_set.classnames,classname));
    data.components = data.components(tokeep,:);

    SVM_params = training_set.parameters.SVM_params.(classname);
    SVM_optim = process_SVM_optim(training_set.parameters.SVM_optim.(classname),data);

    
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
        output = batch(cluster,@launchfitcsvm, 1, {data,SVM_params,SVM_optim,training_set.parameters.maxmemUse/cluster.NumWorkers});
    else % Do not parallelize
        cluster = [];
        output = launchfitcsvm(data,SVM_params,SVM_optim, training_set.parameters.maxmemUse);
    end

end

function output = launchfitcsvm(data,SVM_params,SVM_optim, cachesize)

% strlabels = repmat({'a'},1,numel(data.label));
% strlabels{data.label} = 'z';

if ~isempty(SVM_optim)
    output = fitcsvm(data.components,data.label,'Verbose',1,'CacheSize',cachesize*1000, ...
                                                        SVM_params{:},...
                                                        'OptimizeHyperparameters',SVM_optim);
else
    output = fitcsvm(data.components,data.label,'Verbose',1,'CacheSize',cachesize*1000, ...
                                                        SVM_params{:});
end

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

    % Compute the parameters for each class:
    for ind1 = 1:numel(classnames)
        currclass = classnames{ind1};
        if isfield(spec,currclass)
            if isfield(spec.(currclass),'SVM')
                SVM.(currclass) = parameters_cell(def.SVM, spec.(currclass).SVM);
            else
                SVM.(currclass) = parameters_cell(def.SVM, struct());
            end
            if isfield(spec.(currclass),'OptimizeSVM')
                OptimizeSVM.(currclass) = parameters_struct(def.OptimizeSVM, spec.(currclass).OptimizeSVM);
            else
                OptimizeSVM.(currclass) = parameters_struct(def.OptimizeSVM, struct());
            end
        else
            SVM.(currclass) = parameters_cell(def.SVM, struct());
            OptimizeSVM.(currclass) = parameters_struct(def.OptimizeSVM, struct());
            subsample.(currclass) = def.subsample;
        end
        if numel(OptimizeSVM.(currclass).KernelFunction) < 2
            OptimizeSVM.(currclass).KernelFunction = struct('Optimize',false);
        else
            OptimizeSVM.(currclass).KernelFunction = struct('Optimize',true,'Range',OptimizeSVM.(currclass).KernelFunction);
        end
    end

    processed.SVM_params = SVM;
    processed.SVM_optim = OptimizeSVM;
end

function SVM_optim = process_SVM_optim(s,d)
    SVM_optim = hyperparameters('fitcsvm',d.components,d.label);

    options = fieldnames(s);
    optim_all = false;
    for ind1 = 1:numel(options)
        values = fieldnames(s.(options{ind1}));
        optim = logical(s.(options{ind1}).Optimize);
        s.(options{ind1}).Optimize = optim;
        optim_all = optim_all || optim;
        for ind2 = 1:numel(values)
            theone = arrayfun(@(x) strcmp(x.Name,options{ind1}),SVM_optim);
            SVM_optim(theone).(values{ind2}) = s.(options{ind1}).(values{ind2});
        end
    end
    if ~optim_all
        SVM_optim = [];
    end
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

    if ~strcmp(default.KernelFunction,'Polynomial')
        default = rmfield(default,'PolynomialOrder');
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
yesno = isequal(training_set.parameters.SVM_params.(sib1),training_set.parameters.SVM_params.(sib2)) && ...
    isequal(training_set.parameters.SVM_optim.(sib1),training_set.parameters.SVM_optim.(sib2));
end