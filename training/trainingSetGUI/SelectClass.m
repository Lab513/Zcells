function [selected,allstacks] = SelectClass(txt,classes)

   global miscgui
   miscgui.boolops.selected = '';
   miscgui.boolops.allstacks = false;
   
   
   %  Create and then hide the UI as it is being constructed.
    f = figure('Visible','off','Position',[360,500,300,95],'menubar','none','Name',txt,'NumberTitle','off');
   
   
   %  Construct the components.
%    htext = uicontrol('Style','text','String',txt,...
%            'Position',[125,65,60,15]);
   

    h.allstacks = uicontrol('Style','checkbox',...
       'String','apply to all stacks',...
       'Position',[10,38,285,35]);
    h.popup = uicontrol('Style','popupmenu',...
       'String',classes,...
       'Position',[10,58,285,35]);
    h.Done = uicontrol('Style','pushbutton','String','Done',...
        'Position',[160,10,120,35],'Callback',@Done_Callback);
    h.Cancel = uicontrol('Style','pushbutton','String','Cancel',...
        'Position',[20,10,120,35],'Callback',@Cancel_Callback); 
    align([h.popup],'Center','None');
   
      
    % Move the window to the center of the screen.
    movegui(f,'center')
    f.UserData = h;
    
   % Make the UI visible.
    f.Visible = 'on';
   
    waitfor(f)
    
    selected = miscgui.boolops.selected;
    allstacks = miscgui.boolops.allstacks;
end

function Done_Callback(source,eventdata)
    global miscgui
    Higher = get(source,'Parent');
    h = get(Higher,'UserData');
    classes = get(h.popup,'String');
    selected = get(h.popup,'Value');
    miscgui.boolops.selected = classes{selected};
    miscgui.boolops.allstacks = get(h.allstacks,'Value');
    close(Higher)
end

function Cancel_Callback(source,eventdata)
    Higher = get(source,'Parent');
    close(Higher);
end