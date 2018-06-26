function fullpath = relative2full(relativepath,rootfoldername)
%relative2full Transform a relative path in a full path relative to an
%arbitrary root
%
% fullpath = relative2full(relativepath,rootfoldername) returns global path
% of relative path relativepath. relativepath must start with a '/' symbol, 
% the path is relative to transposed root rootfoldername, and
% is transformed by this function into the 'actual' global path.
%
% example :
% >>pwd
% 
% ans =
% 
% /home/jeanbaptiste/phd/imageanalysis/ZstackSegmentation/training_set_construction
%
% >> fullpath = relative2full('/google_drive/zstacks/','ZstackSegmentation')
% 
% ans = 
% 
% /home/jeanbaptiste/phd/imageanalysis/ZstackSegmentation/google_drive/zstacks/
% 
%
% Of course, if the working directory is not under the transposed root
% directory (here ZstackSegmentation) this does not work.

% if relativepath(1) ~= '/'
%     error('The relative path must start with ''\''')
% end

pwdstr = pwd();
pos = strfind(pwdstr,rootfoldername);
if isempty(pos)
    error('You must be under the rootfoldername directory  or one of its subdirectories to run this function');
end

fullpath = fullfile(pwdstr(1:(pos+numel(rootfoldername)-1)),relativepath(2:end));

end

