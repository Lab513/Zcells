function successFlag = saveTrainedSet(path,SVMs,training_set)

successFlag = false;

% Check if SVMs have finished training:
SVMsNames = fieldnames(SVMs);
for ind1 = 1:numel(SVMsNames)
    res = SVMs.(SVMsNames{ind1}).SVM;
    if any(strfind(class(res),'ClassificationSVM')) || isempty(res)
        % Do nothing
    elseif any(strfind(class(res),'parallel.job')) && strcmp(res.State,'finished')
        % If finished, fetch job outputs
        res = fetchOutputs(res);
        SVMs.(SVMsNames{ind1}).SVM = res{1};
    else
        % Return without saving, send a false successFlag...
        return;
    end
end


% Save only parts relevant for prediction and results display:
rgbmap = training_set.rgbmap;
classnames = training_set.classnames;
frames = training_set.parameters.frames_subselection.frames;
feat_extr = training_set.feature_extraction.coeff;
feat_mu = training_set.feature_extraction.mu;
% Backward compatibility for frame processing:
if ~isfield(training_set.parameters,'frame_processing') || isempty(training_set.parameters.frame_processing)
    frame_processing = {struct('name','Intensity')};
else
    frame_processing = training_set.parameters.frame_processing;
end
type_of_file = 'trained classifier';

save(path,'SVMs','rgbmap','classnames','frames','feat_extr','feat_mu','frame_processing','type_of_file','-v7.3')
successFlag = true;
return;

