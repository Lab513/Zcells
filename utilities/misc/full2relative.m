function relpath = full2relative(fullpath,rootfoldername)
%relative2full Transform a gloabl path in a path relative to an
%arbitrary root
%
% relpath = full2relative(fullpath,rootfoldername) returns relative path
% relpath relative to the root rootfoldername.
%
%
% example: 
% >>pwd
% 
% ans =
% 
% /home/jeanbaptiste/phd/imageanalysis/ZstackSegmentation/training_set_construction
%
% >> relpath = full2relative('/home/jeanbaptiste/phd/imageanalysis/ZstackSegmentation/google_drive/zstacks','ZstackSegmentation')
% 
% ans = 
% 
% /google_drive/zstacks
% 
%
% Of course, if the working directory is not under the transposed root
% directory (here ZstackSegmentation) this does not work



% if fullpath(1) ~= '/'
%     error('The full path must start with ''\''')
% end

pos = strfind(fullpath,rootfoldername);
if isempty(pos)
    error('fullpath must be under the rootfoldername directory  or one of its subdirectories to run this function');
end

relpath = fullpath((pos+numel(rootfoldername)):end);