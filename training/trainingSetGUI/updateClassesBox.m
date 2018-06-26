function updateClassesBox(handles)
global rgbmap_local classnames_local miscgui

class_strings_pimped = pimpmystrings(classnames_local,rgbmap_local);
set(handles.classbox,'String',class_strings_pimped);
if ~isempty(classnames_local) && isfield(miscgui,'currentclass') && ~isempty(miscgui.currentclass)
    set(handles.classbox,'Value',find(strcmp(classnames_local,miscgui.currentclass)));
end
udapte_zpxtext(handles);


