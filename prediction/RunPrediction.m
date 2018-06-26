% params = makePrediction(params, auto_focus, radius)
%
% Make prediction on the selected stack. The score calculated by the
% prediction is stocked into the structure params.
%
%   Take :
%       'params', the struct containing parameters needed for others
% functions.
%
%   Return :
%       'params', the struct containing parameters needed for others
% functions.

function Results = RunPrediction(stack, feat_extr, feat_mu, SVMs, varargin)
    %% Inputs
    ip = inputParser;
    addParameter(ip,'ROI',[]);
    addParameter(ip,'FramesSelection',[]);
    addParameter(ip,'Parallelize',0, @isnumeric);
    addParameter(ip,'IndependentJob',false);
    addParameter(ip,'Cluster',parallel.defaultClusterProfile);
    addParameter(ip,'use_features', {struct('name','Intensity')}, @iscell);
    addParameter(ip,'SaveResults','');
    addParameter(ip,'SaveName','results');
    addParameter(ip,'Verbosity',1,@isscalar);
    addParameter(ip,'isProcessed',0,@isscalar);
    addParameter(ip,'processedMat',[]);
    parse(ip,varargin{:});
    
    % Extract data and features on-the-fly:
    if ip.Results.isProcessed
        data = ip.Results.processedMat;
        disp('Will predict on already processed dataset')
    else
        data = runthroughstack(stack, ...
            'offset', ip.Results.FramesSelection, ...
            'groupspxl', ip.Results.ROI, ...
             'pca_coeffs', feat_extr, ...
             'pca_mu', feat_mu, ...
             'Verbosity', ip.Results.Verbosity, ...
             'use_features', ip.Results.use_features ...
            );    
    end
    % Launch the prediction:
    if ip.Results.IndependentJob % Independent job on a cluster:
%             parallelpool = ip.Results.Parallelize-1;
%             parallelpool(parallelpool < 0) = 0;
        parallelpool = ip.Results.Parallelize;

        Results = batch( @RunPredictionSubroutine,1, ...
            {SVMs, data,  ip.Results.Parallelize, ip.Results.SaveResults, ip.Results.SaveName, ip.Results.Verbosity}, ...
            'Profile', ip.Results.Cluster, ...
            'Pool', parallelpool);

    else
        Results = RunPredictionSubroutine(SVMs, data, ip.Results.Parallelize, ip.Results.SaveResults, ip.Results.SaveName, ip.Results.Verbosity);
    end
        

    
function Results = RunPredictionSubroutine(SVMs, data, parallelize,autosave,savename,verbosity)
    
% Reprocess the SVMs tree into an ordered list:
    childrenlist = recursive_listing(SVMs,'');
     % Go down the tree: (non-recursive to reduce overhead)
    for ind1 = 1:size(childrenlist,2)
        siblings = setdiff(childrenlist{ind1},'');
        % Keep only necessary data:
        curr_parent = SVMs.(siblings{1}).parent;
        if isempty(curr_parent)
            sub_sel = true(size(data,1),1);
        else
            sub_sel = Results.(curr_parent).isa;
        end
        data_to_classify = data(sub_sel,:);

        % Run the prediction:
        Scores = predict_siblings(SVMs,data_to_classify,siblings,parallelize,verbosity);
        Scores = mysoftmax(Scores);
        [~, tmp_dump] = max(Scores, [], 2);

        % Tidy-up results:
        for ind2 = 1:numel(siblings)
            Results.(siblings{ind2}).scores = ones(size(data,1),1)*NaN;
            Results.(siblings{ind2}).scores(sub_sel) = Scores(:,ind2);
            Results.(siblings{ind2}).isa = false(size(data,1),1);
            Results.(siblings{ind2}).isa(sub_sel) = tmp_dump == ind2;
            Results.(siblings{ind2}).parent = SVMs.(siblings{ind2}).parent;
            if isfield(SVMs.(siblings{ind2}),'children')
                Results.(siblings{ind2}).children = SVMs.(siblings{ind2}).children;
            end
            Results.(siblings{ind2}).siblings = SVMs.(siblings{ind2}).siblings;
        end
    end
    
    if ~isempty(autosave)
        save(fullfile(autosave,savename),'Results');
    end

function Scores = predict_siblings(SVMs,data,siblings,Parallelize,verbosity)
% Predicts the scores for all siblings, whether we are in binary or
% winner-takes-all configuration

    for ind1 = 1:numel(siblings)
        s = SVMs.(siblings{ind1});
        switch s.type
            case 'binary'
                if ~isempty(s.SVM)
                    Scores = script_predict({s.SVM}, data, {[ siblings{ind1} ' & ' s.siblings{1}]}, Parallelize,verbosity);
                    Scores(:,ind1) = Scores(:,1);
                    Scores(:,setdiff(1:2,ind1)) = -Scores(:,1);
                    return
                end
            case 'WTA'
                SVM_models{ind1} = s.SVM;
        end
    end
    Scores = script_predict(SVM_models, data, siblings, Parallelize,verbosity);


function list = recursive_listing(SVMs,parentname)
% Recursively creates a list of siblings, in an order that allows for
% non-recursive tree descent.
    classnames = fieldnames(SVMs);
    list = classnames(structfun(@(x) strcmp(x.parent,parentname), SVMs));
    if ~isempty(list)
        list = {list};
        for ind1 = 1:numel(list{1})
            list = [list recursive_listing(SVMs,list{1}{ind1})];
        end
    end
    
function Scores = script_predict(SVM_models, mat, classnames, Parallelize, verbosity)
% This function runs the perdiction for all the SVM models given and for
% the data given.

    Scores = zeros(size(mat, 1), numel(SVM_models));
    for j = 1:numel(SVM_models)
        if verbosity >= 1
            disp(['Launching prediction for class: ' classnames{j}]);
        end
        if Parallelize % PARALLELIZE
            matsize = floor(size(mat,1)/Parallelize);
            remainder = mod(size(mat,1),Parallelize);
            parfor ind1 = 1:Parallelize
                % Split mat into sub mats
                if ind1 == Parallelize
                    indexes = ((ind1-1)*matsize+1):(ind1*matsize + remainder)
                else
                    indexes = ((ind1-1)*matsize+1):(ind1*matsize);
                end
                % Run on each
                [~,scoreSVMpar{ind1}] = predict(SVM_models{j}, mat(indexes,:));
            end
            % Concatenate them all
            scoreSVM = [];
            for ind1 = 1:Parallelize
                scoreSVM = cat(1,scoreSVM,scoreSVMpar{ind1});
            end
            clearvars scoreSVMpar
        else % DON'T PARALLELIZE
            [~,scoreSVM] = predict(SVM_models{j}, mat);
        end
        Scores(:,j) = scoreSVM(:,2);
    end
