% CD to the ZStackSegmentation directory and then:
addpath(genpath('.'))

%% Run prediction on stacks from cmd line:

% Load set:
[class_fn, class_pn] = uigetfile('*.mat','select a trained classifier to use...');
load(fullfile(class_pn,class_fn));
% Load stacks:
[fname_c, pname] = uigetfile('MultiSelect','on');
if ~iscell(fname_c)
    fname_c = {fname_c};
end
% Backward compatibility for frame processing:
if ~exist('frame_processing') || isempty(frame_processing)
    frame_processing = {struct('name','Intensity')};
end
% Backward compatibility for PCA normalization:
if ~exist('feat_mu')
    feat_mu = [];
end

%%
% Launch prediction:
for ind1 = 1:numel(fname_c)
    clearvars res I S% To save some space
    
    % Load stack
    fname = fname_c{ind1};
    disp(fname)
    stack = matfile(fullfile(pname,fname));
    

    % Predict
    res = RunPrediction(stack, ...
                        feat_extr, ...
                        feat_mu, ...
                        SVMs, ...
                        'use_features', frame_processing, ...
                        'Parallelize', 8, ...
                        'FramesSelection',frames ... % Either use the frames subselection from the saved classifier or a custom subselection...
                        );
    
    % Display prediction results:
    firstframe = stack.stack(1,1);
    firstframe = firstframe{1};
    [I, ~] = show_classes(res, size(firstframe),'Colors',rgbmap);
    figure(1);
    imshow(I);
    title(['Prediction results for stack ' fname])
    
    % Display prediction overall confidence:
    [S, ~] = show_conf(res, size(firstframe));
    figure(2)
    imshow(S);
    title(['Prediction confidence for stack ' fname])
    
end

%% You can do about the same thing using this GUI:

predictionDisplayGUI;


