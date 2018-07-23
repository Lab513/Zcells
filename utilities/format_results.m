function y_hat = format_results(results)
% This function just reformats results into something more usable for the
% confusion matrix function

    temp = fieldnames(results);
    %assuming at least one class
    y_hat = zeros( numel(results.(temp{1}).scores) ,1 );
    y_scores = zeros( numel(results.(temp{1}).scores) ,1 );
    
    for idx = 1:numel(temp)
        idxs = find( results.(temp{idx}).scores > y_scores );
        y_hat(idxs) = idx;
        y_scores(idxs) = results.(temp{idx}).scores(idxs);
    end
    
end
