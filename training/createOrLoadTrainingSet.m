% params = createOrLoadTrainingSet()
%
% This function launches the pixelSelectionGUI GUI dedicated to creating
% new training sets. It is some sort of wrapper to make the whole GUI act
% in a non-blocking way and extract parameters / training data once the GUI
% is exited.

function params = createOrLoadTrainingSet()
    % Start the interface and create the trainingpx structure:
    ret = pixels_selection_GUI();
    while ~(ret.finished || ret.aborted)
        pause(2)
    end

            % Clear global variables?
    if ~ret.aborted && ~isempty(ret.trainingpx)
            params.trainingpx = ret.trainingpx;
            params.rgbmap = ret.rgbmap;
            params.classnames = ret.classnames;
            params.hierarchy = ret.hierarchy;
            params.parameters = ret.training_params;
            params.parameters.frame_processing = ret.frame_processing;
        else
            params = [];
    end
        
end
