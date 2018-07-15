function BundleData(training_set, varargin)

ip = inputParser();
ip.addOptional('Filename',{},@iscellstr)
ip.parse(varargin{:});

if isempty(ip.Results.Filename)
    % Ask user for bundle filename:
    [fname, pname, f_ind] = uiputfile({'*.zip','Bundle (*.zip)'},'Where to save the bundle?',[datestr(now,29) '_trainingset.zip']);
    if f_ind == 0
        return;
    end
else
    pname = ip.Results.Filename{1};
    fname = ip.Results.Filename{2};
end


% Get all stack names
stacks = fieldnames(training_set.trainingpx);

% Retrieve all the filenames:
for ind1 = 1:numel(stacks)
    stackfiles{ind1} = relative2full(training_set.trainingpx.(stacks{ind1}).path,'Zcells');
end

% Create temporary training set mat file:
type_of_file = 'training_set';
temp_dir = mkdir_temporary(pname);
temp_file = fullfile(temp_dir,'Training_set.mat');
save(temp_file,'training_set','type_of_file','-v7.3');

% Now zip all files together:
zip(fullfile(pname,fname),[temp_file stackfiles]);

% Remove temporary file & dir:
delete(temp_file);
rmdir(temp_dir);

function dirname = mkdir_temporary(path)

ls = dir(path);
ind = 1;
while any(strcmp({ls.name},['temporary_folder_' num2str(ind)]))
    ind = ind + 1;
end
dirname = fullfile(path, ['temporary_folder_' num2str(ind)]);
mkdir(dirname);
