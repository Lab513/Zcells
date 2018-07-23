% CD to the Zcells directory and then:
addpath(genpath('.'))

%% Start by creating (or loading) a (pre-existing) training set with the GUI:
training_set = createOrLoadTrainingSet();

training_set.parameters.parallel_processing.status = false; % Parallel training in evaluations not supported for now
%% Parameters for evaluation:

% General parameters:
test_percent = 1;
displayConfMat = false;
displayStackPred = true;

% Parameters to evaluate against:
evaluate = {}; % Leave empty if you just want to evaluate the current training_set

% evaluate(1) = {
%                {'parameters.feature_extraction.nbcomponents', 30}   
%                };

           
evaluate(1) = {
               {}   
               };
evaluate(2) = {   {'parameters.frame_processing' ,...
                        {struct('name','Intensity')}
                   }
               };
evaluate(3) = {   
                {'parameters.class_specific.default.SVM.MinLeafSize', 3}
               };
           
evaluate(4) = {   
                {'parameters.class_specific.default.SVM.NumTrees', 100}
               };
evaluate(5) = {   
                {'parameters.class_specific.default.SVM.NumTrees', 30}
               };
evaluate(6) = {   
                {'parameters.focus_shifting.radius', 3}
               };
evaluate(7) = {   
                {'parameters.feature_extraction.nbcomponents', 5}
               };
evaluate(8) = {   
                {'parameters.feature_extraction.nbcomponents', 8}
               };
evaluate(9) = {   
                {'parameters.feature_extraction.nbcomponents', 30}
               };
evaluate(10) = {   
                {'parameters.frames_subselection.type', 'log';
                'parameters.frames_subselection.nbframes_linlog', 40;
                'parameters.feature_extraction.nbcomponents', 20}
               };
evaluate(11) = {   
                {'parameters.class_specific.default.SVM.MinLeafSize', 5}
               };
evaluate(12) = {   
                {'parameters.class_specific.default.SVM.NumTrees', 50}
               };
evaluate(13) = {   
                {'parameters.class_specific.default.SVM.NumTrees', 75}
                };
evaluate(14) = {   
                {'parameters.class_specific.default.SVM.NumTrees', 75}
                };

% Run each evaluation against specific stacks:
predstack = {
                '/home/jeanbaptiste/data/Zcells/google_drive/CuratedSets/Mammalian/Stacks/Stack_13.mat', ...
                '/home/jeanbaptiste/data/Zcells/google_drive/CuratedSets/Mammalian/Stacks/Stack_14.mat', ...
                '/home/jeanbaptiste/data/Zcells/google_drive/CuratedSets/Mammalian/Stacks/Stack_15.mat'};


%% Run evalutation:

for ind1 = 1:numel(evaluate)
    
    fprintf("%s: Starting evaluation for parameters set #%d\n",datestr(now),ind1)
    eval_set = evalparams(training_set,evaluate,ind1);
    
    [data, eval_set.feature_extraction, eval_data] = LoadAndExtract(eval_set,'test_percent',test_percent);
    eval_labels{ind1} = eval_data.label;
    
    fprintf("%s: Launching training\n",datestr(now))
    Classifier = training(eval_set, data);
    
    fprintf("%s: Launching prediction\n",datestr(now))
    tic
    eval_results{ind1} = RunPrediction([], ...
		        eval_set.feature_extraction.coeff, ...
                eval_set.feature_extraction.mu, ...
		        Classifier, ...
		        'isProcessed', 1, ...
		        'processedMat', eval_data.components ...
		        );
	prediction_time(ind1) = toc;
    
    if displayConfMat
        eval_y_hat = format_results(eval_results{ind1}); % Only reliable for non-hierarchical cases
        eval_cm = confusionmat(eval_data.label, eval_y_hat);
        figure('Name', sprintf('Confusion Matrix #%d', ind1));
        plotConfMat(eval_cm, eval_set.classnames);
    end
    
    if displayStackPred
        tic
        for ind2 = 1:numel(predstack)
            tmp = matfile(predstack{ind2});
            midframe = tmp.stack(1,1);
            midframe = midframe{round(numel(midframe)/2)};
            stack_results = RunPrediction(tmp, ...
                eval_set.feature_extraction.coeff, ...
                eval_set.feature_extraction.mu, ...
                Classifier, ...
                'use_features', eval_set.parameters.frame_processing, ...
                'FramesSelection', eval_set.parameters.frames_subselection.frames...
                );
            [I, ~] = show_classes(stack_results, size(midframe),'Colors',eval_set.rgbmap);
            figure('Name', sprintf('Stack #%d, Prediction #%d', ind2, ind1));
            imshow(I);
        end
        stacks_time(ind1) = toc;
    end
    
    fprintf("%s: Done!\n\n",datestr(now))
    drawnow
end