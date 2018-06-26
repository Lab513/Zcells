% Select regular MAT files, load and then save them as v7.3 MAT files
[FileNames,PathName,~] = uigetfile('*.mat','Select regular MAT file...','MultiSelect', 'on');


for ind1 = 1:numel(FileNames)
    disp(FileNames{ind1})
    fname = fullfile(PathName,FileNames{ind1});
    mfiletoupgrade = matfile(fname);
    details = whos(mfiletoupgrade);
    variablesnames = {details(:).name};
    load(fname);
    save(fname,variablesnames{1},'-v7.3');
    clearvars(variablesnames{1});
    for ind2 = 2:numel(variablesnames)
        save(fname,variablesnames{ind2},'-append','-v7.3');
        clearvars(variablesnames{ind2});
    end
end