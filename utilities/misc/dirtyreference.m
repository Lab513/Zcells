classdef dirtyreference < handle
    properties 
        trainingpx = struct();
        rgbmap = [];
        classnames = {};
        training_params = struct();
        hierarchy = [];
        frame_processing = {};
    end
    properties (SetObservable)
        finished = false;
        aborted = false;
    end
end