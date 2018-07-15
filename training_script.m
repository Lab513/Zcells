% CD to the ZStackSegmentation directory and then:
addpath(genpath('.'))
    
%% Start by creating (or loading) a (pre-existing) training set through the
% dedicated GUI:

training_set = createOrLoadTrainingSet();

%% And train:

% Where to save the classifier once trained:
[save_fn, save_pn] = uiputfile('*.mat','Save trained classifier?');

% Extract data from stacks:
[data, training_set.feature_extraction] = LoadAndExtract(training_set);

% Launch Classifier training:
training_set.trainingpx = struct(); % Saves some space (make sure you save your training set!)
SVMs = training(training_set, data);    


% Save the trained set (or wait for parallel jobs to complete and then save
% it if using parallel training)
while(~saveTrainedSet(fullfile(save_pn,save_fn),SVMs,training_set))
    pause(60);
    disp([datestr(now) ': Waiting for parallel training to finish... (This might take a while)']);
end

disp([datestr(now) ': Training one!'])