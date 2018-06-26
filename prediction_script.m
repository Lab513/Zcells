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
    clearvars res I S % To save some space
    
    % Load stack
    fname = fname_c{ind1};
    disp(fname)
    stack = matfile(fullfile(pname,fname));
    
%     tic
    % Predict
    res{ind1} = RunPrediction(stack, ...
                        feat_extr, ...
                        feat_mu, ...
                        SVMs, ...
                        'use_features', frame_processing, ...
                        'IndependentJob', false, ...
                        'Parallelize', 3, ...
                        'FramesSelection',frames ... % Either use the frames subselection from the saved classifier or a custom subselection...
                        );
%     toc
    
    % Display prediction results:
    firstframe = stack.stack(1,1);
    firstframe = firstframe{1};
    [I, ~] = show_classes(res{ind1}, size(firstframe),'Colors',rgbmap);
    figure(ind1);
    imshow(I);
    title(['Prediction results for stack ' fname])
    
%     Display prediction overall confidence:
    [S, ~] = show_conf(res{ind1}, size(firstframe));
    figure(10+ind1)
    imshow(S);
    title(['Prediction confidence for stack ' fname])
    
    midframe = stack.stack(1,50);
    figure(20+ind1)
    imshow(imadjust(midframe{1}))
    title(['Prediction confidence for stack ' fname])
    drawnow
    
end

%% You can do about the same thing using this GUI:

predictionDisplayGUI;


