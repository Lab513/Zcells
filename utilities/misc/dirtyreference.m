classdef dirtyreference < handle
    properties 
        trainingpx = struct();
        rgbmap = [];
        classnames = {};
        training_params = struct();
        hierarchy = [];
    end
    properties (SetObservable)
        finished = false;
        aborted = false;
    end
end