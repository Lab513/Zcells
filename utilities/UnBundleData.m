function datafile = UnBundleData(path)

unzip(path,path(1:(end-4)));
path = path(1:(end-4));


datafile = fullfile(path,'Training_set.mat');
load(datafile);

stacks = fieldnames(training_set.trainingpx);

% Re-assign the paths for the Zstacks to the new directory:
for ind1 = 1:numel(stacks)
    oldpath = training_set.trainingpx.(stacks{ind1}).path;
    parts = strsplit(oldpath, filesep);
    stackname = parts{end};
    training_set.trainingpx.(stacks{ind1}).path = full2relative(fullfile(path, stackname),'Zcells');
end

save(datafile,'training_set','type_of_file','-v7.3');
