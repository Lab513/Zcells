% CD to the ZStackSegmentation directory and then:
addpath(genpath('.'))
    
%% Start by creating (or loading) a (pre-existing) training set through the
% dedicated GUI:

training_set = createOrLoadTrainingSet();

%% Then run through the stack(s) to create the actual training variable that will be used with the SVM:

[data, training_set.feature_extraction] = LoadAndExtract(training_set);

%% Launch Trees training:

training_set.trainingpx = struct(); % Saves some space
% Train SVMs on that set.
SVMs = training(training_set, data);    
    
%% Save trained classifier to disk:

[save_fn, save_pn] = uiputfile('*.mat','Save trained classifier?');

% Save the trained set (or wait for parallel jobs to complete and then save
% it if using parallel training)
while(~saveTrainedSet(fullfile(save_pn,save_fn),SVMs,training_set))
    pause(60);
    disp([datestr(now) ': Waiting for parallel training to finish... (This might take a while)']);
end

disp([datestr(now) ': Done!'])