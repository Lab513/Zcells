function allchildren = hierarchy_checkup(hierarchy,currclass)

if isempty(hierarchy)
    allchildren = {};
    return;
end
% Find all direct children of current class: (recursive tree descent)
possible_children = fieldnames(hierarchy);
allchildren = {};
for ind1 = 1:numel(possible_children)
    if strcmp(hierarchy.(possible_children{ind1}),currclass)
        allchildren = [allchildren {possible_children{ind1}} hierarchy_checkup(hierarchy,possible_children{ind1})]; 
    end
end
    
