function handle = plot_hierarchy_tree(hierarchy,classnames,rgbmap)

nodes = nodes_from_hierarchy(hierarchy);
nodes = [0 nodes+1];
mygrey = [.2 .2 .2];
bkgrey = [0.94 0.94 0.94];

[x,y,~,~] = treelayout(nodes);
linespec.lineWidth = 3;
linespec.Color = mygrey;
treeplot(nodes,'',linespec);
% get(gca,'
hold on
axis off

plot(x(1),y(1),' o','MarkerFaceColor','k','MarkerEdgeColor',bkgrey,'MarkerSize',15,'LineWidth',3)
for ind1 = 1:numel(classnames)
    plot(x(ind1+1),y(ind1+1),' o','MarkerFaceColor',rgbmap(ind1,:),'MarkerEdgeColor',mygrey,'MarkerSize',15,'LineWidth',3)
    text(x(ind1+1),y(ind1+1),classnames{ind1},'Color','w','FontSize',8,'Interpreter','none')
end

title('Tree representation of the hierarchy between the classes')

handle = gca;