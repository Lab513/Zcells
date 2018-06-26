function tot = nbpixels_inclass(tpx,currclass)
% This function runs through the trainingpx structure to compute the number
% of pixels in a specific classname currclass

tot = 0;
if ~isempty(tpx)
    zstacks = fieldnames(tpx);
    for ind1 = 1:numel(zstacks)
        pxls = tpx.(zstacks{ind1}).pixel;
        if isfield(pxls,currclass)
            tot = tot + numel(pxls.(currclass));
        end
    end
end
    