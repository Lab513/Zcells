function udapte_zpxtext(handles)
global miscgui trainingpx_local
if isfield(miscgui,'currentclass') && ~isempty(miscgui.currentclass)
    nbs = nbpixels_inclass(trainingpx_local,miscgui.currentclass);
    txt = ['#z-pixels = ' num2str(nbs) ];
else
    txt = '#z-pixels = ...';
end
handles.text_nbpx.String = txt;

