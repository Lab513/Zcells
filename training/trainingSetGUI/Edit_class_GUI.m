function varargout = Edit_class_GUI(varargin)
    % EDIT_CLASS_GUI MATLAB code for Edit_class_GUI.fig
    %      EDIT_CLASS_GUI, by itself, creates a new EDIT_CLASS_GUI or raises the existing
    %      singleton*.
    %
    %      H = EDIT_CLASS_GUI returns the handle to a new EDIT_CLASS_GUI or the handle to
    %      the existing singleton*.
    %
    %      EDIT_CLASS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in EDIT_CLASS_GUI.M with the given input arguments.
    %
    %      EDIT_CLASS_GUI('Property','Value',...) creates a new EDIT_CLASS_GUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before Edit_class_GUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to Edit_class_GUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help Edit_class_GUI

    % Last Modified by GUIDE v2.5 21-Apr-2017 17:50:44

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @Edit_class_GUI_OpeningFcn, ...
                       'gui_OutputFcn',  @Edit_class_GUI_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT


% --- Executes just before Edit_class_GUI is made visible.
function Edit_class_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    % Update handles structure
    guidata(hObject, handles);




% --- Outputs from this function are returned to the command line.
function varargout = Edit_class_GUI_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;




function pushbutton_done_Callback(hObject, eventdata, handles)
% Just close the figure:
close(get(hObject,'Parent'));


function figure1_DeleteFcn(hObject, eventdata, handles)
global miscgui
miscgui.current_editclass = '';



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NAME & COLOR                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function classnametext_Callback(hObject, eventdata, handles)

    global miscgui trainingpx_local classnames_local training_params_local hierarchy
    oldname = miscgui.currentclass;
    newname = get(hObject,'String');

    if strcmp(oldname,newname)
        return;
    end

    % Check if available:
    if any(strcmp(newname, classnames_local))
        warndlg(['A class named ' newname ' already exists'])
        get(hObject,'String',oldname);
        return;
    end

    % Replace in the classnames variable:
    classnames_local(strcmp(oldname, classnames_local)) = {newname};

    % replace the old name in the trainingpx tree:
    zstks = fieldnames(trainingpx_local);
    for ind1 = 1:numel(zstks)
        cls = fieldnames(trainingpx_local.(zstks{ind1}).pixel);
        if any(strcmp(oldname,cls))
            trainingpx_local.(zstks{ind1}).pixel.(newname) = trainingpx_local.(zstks{ind1}).pixel.(oldname);
            trainingpx_local.(zstks{ind1}).pixel = rmfield(trainingpx_local.(zstks{ind1}).pixel,oldname);
        end
    end
    
    % replace it in the hierarchy:
    if isfield(hierarchy,'oldname')
        hierarchy.(newname) = hierarchy.(oldname);
        hierarchy = rmfield(hierarchy,'oldname');
    end
    
    %replace it in the training parameters: (if applicable)
    if ~isempty(training_params_local) && isfield(training_params_local.class_specific.spec,'oldname')
        training_params_local.class_specific.spec.(newname) = training_params_local.class_specific.spec.(oldname);
        training_params_local.class_specific.spec = rmfield(training_params_local.class_specific.spec,'oldname');
    end

    % uPDATE the current class:
     miscgui.currentclass = newname;
     updateClassesBox(miscgui.debugging.handles);
     updateGUI(miscgui.debugging.handles,'updateOldies',false);

% --- Executes during object creation, after setting all properties.
function classnametext_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    global miscgui
    set(hObject,'String',miscgui.currentclass);



function colortext_Callback(hObject, eventdata, handles)

    global miscgui rgbmap_local classnames_local
    % Get current color index in the colormap:
    indC = find(strcmp(miscgui.currentclass,classnames_local));
    oldcol = rgbmap_local(indC,:);
    % Find current color:
    newcol = hex2color(get(hObject,'String'));

    % If nothing changed, change nothing...
    if all(oldcol == newcol)
        return;
    end

    % Check if available:
    for ind1 = size(rgbmap_local,1)
        if all(newcol == rgbmap_local(ind1,:));
            warndlg(['A class with this color already exists (' classnames_local{ind1} ')'])
            set(hObject,'String',color2hex(oldcol));
            return;
        end
    end

    % Update
    rgbmap_local(indC,:) = newcol;
    updateClassesBox(miscgui.debugging.handles);
    updateGUI(miscgui.debugging.handles,'updateOldies',false);


% --- Executes during object creation, after setting all properties.
function colortext_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

    global miscgui rgbmap_local classnames_local
    % Get current color index in the colormap:
    indC = find(strcmp(miscgui.currentclass,classnames_local));
    % Write it:
    set(hObject,'String',color2hex(rgbmap_local(indC,:)));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BOOLEAN OPERATIONS, 2 Classes %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoubleClassMods_boolops_2MAPS(expltext,logical_operation_handle)
    global classnames_local trainingpx_local miscgui
    
    % Get the other glass with GUI
    [otherclass,allstacks] = SelectClass(expltext,setdiff(classnames_local,miscgui.currentclass));
    if isempty(otherclass) % User clicked cancel or closed the window
        return;
    end

    if allstacks % If the boolean operation is to be applied on all stacks
        stacknames = fieldnames(trainingpx_local);
        for ind1 = 1:numel(stacknames)
            MAP_curr = stack2map(trainingpx_local.(stacknames{ind1}),miscgui.currentclass);
            MAP_other = stack2map(trainingpx_local.(stacknames{ind1}),otherclass);
            result = feval(logical_operation_handle,MAP_curr,MAP_other);
            trainingpx_local.(stacknames{ind1}).pixel.(miscgui.currentclass) = find(result);
        end
    else % If the boolean operation is to be applied on this stack only
        if isfield(miscgui,'currentstack')
            MAP_curr = stack2map(trainingpx_local.(miscgui.currentstack),miscgui.currentclass);
            MAP_other = stack2map(trainingpx_local.(miscgui.currentstack),otherclass);
        else
            return;
        end
        result = feval(logical_operation_handle,MAP_curr,MAP_other);
        trainingpx_local.(miscgui.currentstack).pixel.(miscgui.currentclass) = find(result);
    end
    
    updateGUI(miscgui.debugging.handles);

function output = diffop(M1,M2)
    output = xor(M1,M2);
    output = output&M1;

function pushbutton_union_Callback(hObject, eventdata, handles)
    DoubleClassMods_boolops_2MAPS('Unite with...', @or);


function pushbutton_difference_Callback(hObject, eventdata, handles)
    DoubleClassMods_boolops_2MAPS('Differ from...', @diffop);

function pushbutton_intersection_Callback(hObject, eventdata, handles)
    DoubleClassMods_boolops_2MAPS('Intersect with...', @and);

    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BOOLEAN & MORPHO OPERATIONS, 1 Class %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function flag = singleClassMods(res, fhandle, class)
global trainingpx_local miscgui

flag = 0;

    switch lower(res)
        case 'all stacks' % Apply to all stacks
            stacknames = fieldnames(trainingpx_local);
            for ind1 = 1:numel(stacknames)
                trainingpx_local.(stacknames{ind1}).pixel.(class) = fhandle(trainingpx_local.(stacknames{ind1}));
                flag = 2;
            end
        case 'only this one' % Apply only to current stack (if it exists)
            if isfield(miscgui,'currentstack')
                trainingpx_local.(miscgui.currentstack).pixel.(class) = fhandle(trainingpx_local.(miscgui.currentstack));
                flag = 1;
            else
                return;
            end
        case 'cancel'
            return;
    end
    
function pushbutton_duplicate_Callback(hObject, eventdata, handles)
global  miscgui classnames_local rgbmap_local

newclass = ['copy_of_' miscgui.currentclass];
if any(strcmp(classnames_local,newclass)) % If there is already a class by this name:
    newnewclass = [newclass '_nb2'];
    iter = 2;
    while(strcmp(classnames_local,newnewclass))
        newnewclass = [newclass '_nb' num2str(iter)];
    end
    newclass = newnewclass;
end

newclasscolor = distinguishable_colors(1,[0 0 0; 1 1 1; rgbmap_local]);

res = questdlg('Duplicate this class on all stacks or only the current stack?', ...
    'Apply to all stacks?', 'Only this one', 'All stacks', 'Only this one');
if strcmpi(res,'cancel')
    return;
end

classnames_local{end+1} = newclass;
rgbmap_local = [rgbmap_local; newclasscolor];

fh = @duplicate;

if(singleClassMods(res, fh, newclass)) % If it succeeds...
    updateClassesBox(miscgui.debugging.handles);
    updateGUI(miscgui.debugging.handles);
end

function output = duplicate(stack) % Duplicate current class in class
global miscgui

if isfield(stack.pixel,miscgui.currentclass) 
    output = stack.pixel.(miscgui.currentclass);
else
    output = [] ;
end

function pushbutton_inversion_Callback(hObject, eventdata, handles)
global miscgui

res = questdlg('Apply boolean inversion on this class to all stacks or only the current stack?', ...
    'Apply to all stacks?', 'Only this one', 'All stacks', 'Only this one');

fh = @(stack) find(~stack2map(stack)); % Invert the map and find elements...

if(singleClassMods(res, fh, miscgui.currentclass)) % If it succeeds...
    updateGUI(miscgui.debugging.handles);
end

function pushbutton_delete_Callback(hObject, eventdata, handles)
global  miscgui


res = questdlg('Delete this class from all stacks or only the current stack?', ...
    'Apply to all stacks?', 'Only this one', 'All stacks', 'Only this one');

fh = @erasepixels;

if(singleClassMods(res, fh, miscgui.currentclass)) % If it succeeds...
    if (nomoreelementsinclass(miscgui.currentclass)) % Check if anything remains
            deleteclass(miscgui.currentclass,hObject); % Delete if necessary
    end
    updateClassesBox(miscgui.debugging.handles);
    updateGUI(miscgui.debugging.handles);
end

function output = erasepixels(stack)
% This just returns an empty array
    output = [];

function deleteclass(classname,hObject)
% This function completely deletes a class.
global classnames_local rgbmap_local miscgui hierarchy

    close(get(hObject,'Parent'));
    indXclass = strcmp(classnames_local, classname);
    classnames_local = setdiff(classnames_local, classname,'stable');
    rgbmap_local(indXclass,:) = [];
    
    if numel( classnames_local) >= 1
        miscgui.currentclass = classnames_local{1};
    else
        miscgui.currentclass = '';
    end
    
    if isfield(hierarchy,classname)
        hierarchy = rmfield(hierarchy,classname);
    end
    
function yesno = nomoreelementsinclass(classname)
% This function checks if some elements remain in the class. If there are empty
% arrays in some of the stacks, they will be removed...
global trainingpx_local

yesno = true;
stacknames = fieldnames(trainingpx_local);
for ind1 = 1:numel(stacknames)
    if isfield(trainingpx_local.(stacknames{ind1}).pixel, classname)
            if(~isempty(trainingpx_local.(stacknames{ind1}).pixel.(classname))) % Flag false
                yesno = false;
            else % Do some clean-up:
                trainingpx_local.(stacknames{ind1}).pixel = ...
                    rmfield(trainingpx_local.(stacknames{ind1}).pixel,classname);
            end
    end
end

function pushbutton_erode_Callback(hObject, eventdata, handles)
global miscgui

res = questdlg('Apply morphological dilation on this class to all stacks or only the current stack?', ...
    'Apply to all stacks?', 'Only this one', 'All stacks', 'Only this one');

strelsize = inputdlg({'Size (in pixels)?'},'Size of the structuring element',1,{'5'});
if isempty(strelsize)
    return;
end
strelsize = str2double(strelsize{1});

fh = @(stack) find(imerode(stack2map(stack,miscgui.currentclass),strel('disk',strelsize))); % Erode the map and find elements...

if(singleClassMods(res, fh, miscgui.currentclass)) % If it succeeds...
    updateGUI(miscgui.debugging.handles);
end

function pushbutton_dilate_Callback(hObject, eventdata, handles)
global miscgui

res = questdlg('Apply morphological dilation on this class to all stacks or only the current stack?', ...
    'Apply to all stacks?', 'Only this one', 'All stacks', 'Only this one');

strelsize = inputdlg({'Size (in pixels)?'},'Size of the structuring element',1,{'5'});
if isempty(strelsize)
    return;
end
strelsize = str2double(strelsize{1});

fh = @(stack) find(imdilate(stack2map(stack,miscgui.currentclass),strel('disk',strelsize))); % Erode the map and find elements...

if(singleClassMods(res, fh, miscgui.currentclass)) % If it succeeds...
    updateGUI(miscgui.debugging.handles);
end

function Contour_button_Callback(hObject, eventdata, handles)
global miscgui

res = questdlg('Apply contour on this class to all stacks or only the current stack?', ...
    'Apply to all stacks?', 'Only this one', 'All stacks', 'Only this one');

strelsize = inputdlg({'Size (in pixels)?'},'Size of the structuring element',1,{'5'});
if isempty(strelsize)
    return;
end
strelsize = str2double(strelsize{1});

fh = @(stack) find(...
                    xor(...
                        stack2map(stack,miscgui.currentclass),...
                        imerode(stack2map(stack,miscgui.currentclass),strel('disk',strelsize))...
                    )...
                  ); % Contour operation

if(singleClassMods(res, fh, miscgui.currentclass)) % If it succeeds...
    updateGUI(miscgui.debugging.handles);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MASK IMPORT, 1 Class                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function importmask_Callback(hObject, eventdata, handles)
    global miscgui trainingpx_local
    
    [fname, pname, fidx] = uigetfile({'*.tif; *.tiff', 'TIFF images'; '*.mat', 'MAT-files'},'Pick a mask file');
    fname = fullfile(pname,fname);
    switch fidx
        case 0
            return;
        case 2
            BW = load(fname);
            if isfield(BW,'mask')
                BW = BW.mask;
            else
               errordlg('The selected MAT file does not contain a variable called ''mask''','No mask variable');
               return;
            end
        case 1
            BW = logical(imread(fname));
    end
    
    % Compare mask size:
    ims = size(miscgui.imcomp);
    ims = ims(1:2);
    bws = size(BW);
    if all(bws == ims)
        % Apply:
        if isfield(miscgui,'currentstack')
            trainingpx_local.(miscgui.currentstack).pixel.(miscgui.currentclass) = find(BW);
        else
            return;
        end
    else
        errordlg(['The selected mask is not the same size as the stack''s frame size. (' num2str(bws(1)) 'x' num2str(bws(2)) 'px instead of '  num2str(ims(1)) 'x' num2str(ims(2)) 'px)' ], 'Wrong mask size');
        return;
    end
    
    updateGUI(miscgui.debugging.handles,'updateOldies',true);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HIERARCHY MANAGEMENT                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function checkbox_ischild_Callback(hObject, eventdata, handles)
global hierarchy miscgui

if strcmp(getParentClass(handles),'Cannot be child of any class');
    set(handles.checkbox_ischild,'Value',false)
    return;
end

if get(handles.checkbox_ischild,'Value') 
    hierarchy.(miscgui.currentclass) = getParentClass(handles);
else
    hierarchy = rmfield(hierarchy,miscgui.currentclass);
end

function checkbox_ischild_CreateFcn(hObject, eventdata, handles)
    global hierarchy miscgui
    
    if isfield(hierarchy, miscgui.currentclass) && ~isempty(hierarchy.(miscgui.currentclass))
        set(hObject,'Value',true);
    end

function popupmenu_parentclass_Callback(hObject, eventdata, handles)
global hierarchy miscgui

if get(handles.checkbox_ischild,'Value') 
    hierarchy.(miscgui.currentclass) = getParentClass(handles);
end

function parent = getParentClass(handles)

strs = get(handles.popupmenu_parentclass,'String');
parent = strs{get(handles.popupmenu_parentclass,'Value')};


function popupmenu_parentclass_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global miscgui classnames_local hierarchy

% Add all the class strings, except those that are its childrena
% and itself.
possible_parents = setdiff(classnames_local,[hierarchy_checkup(hierarchy,miscgui.currentclass),miscgui.currentclass]);
if isempty(possible_parents)
    possible_parents = {'Cannot be child of any class'};
%     set(handles.checkbox_ischild,'Visible',false);
end
set(hObject,'String',possible_parents);
if ~isempty(possible_parents) && isfield(hierarchy, miscgui.currentclass) && ~isempty(hierarchy.(miscgui.currentclass))
    set(hObject,'Value',find(strcmp(hierarchy.(miscgui.currentclass),possible_parents)));
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VISIBILITY                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function visiblebox_Callback(hObject, eventdata, handles)
    global miscgui
    visible = hObject.Value;
    if isfield(miscgui,'invisibleclasses') && ~isempty(miscgui.invisibleclasses)
        if visible
            miscgui.invisibleclasses = setdiff(miscgui.invisibleclasses,miscgui.currentclass);
        else
           miscgui.invisibleclasses{end+1} = miscgui.currentclass;
        end
    else
        if ~visible
            miscgui.invisibleclasses = {miscgui.currentclass};
        end
    end
    updateGUI(miscgui.debugging.handles,'updateOldies',false);
    


% --- Executes during object creation, after setting all properties.
function visiblebox_CreateFcn(hObject, eventdata, handles)
    global miscgui
    if isfield(miscgui,'invisibleclasses')
        hObject.Value = ~any(strcmp(miscgui.invisibleclasses,miscgui.currentclass));
    else
        hObject.Value = true;
    end

        

