function [eval_set] = evalparams(training_set, evaluate, iteration)


if isempty(evaluate) % Empty evaluate cell = nothing to change
    if iteration == 1
        eval_set = training_set;
    else
        eval_set = [];
    end
    return
end

eval_set = training_set;
for ind1 = 1:size(evaluate{iteration},1)
    eval_set = modifyField(eval_set, evaluate{iteration}{ind1,1}, evaluate{iteration}{ind1,2});
end

function set = modifyField(set, fieldkey, value)

eval(['set.' fieldkey ' = value;']);
    
