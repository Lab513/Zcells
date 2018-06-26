function [MAP] = stack2map(stackstruct,classname) 

MAP = zeros(size(stackstruct.currentframe));
if isfield(stackstruct.pixel,classname)
    MAP(stackstruct.pixel.(classname)) = true;
end