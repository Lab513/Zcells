function nodes = nodes_from_hierarchy(hierarchy)
global classnames_local

nodes = zeros(size(classnames_local));

children = fieldnames(hierarchy);

for ind1 = 1:numel(children)
    nodes(strcmp(children{ind1},classnames_local)) = find(strcmp(hierarchy.(children{ind1}),classnames_local));
end