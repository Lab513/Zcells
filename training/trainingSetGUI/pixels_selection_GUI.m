function varargout = pixels_selection_GUI(varargin)
% PIXELS_SELECTION_GUI MATLAB code for pixels_selection_GUI.fig
%      PIXELS_SELECTION_GUI, by itself, creates a new PIXELS_SELECTION_GUI or raises the existing
%      singleton*.
%
%      H = PIXELS_SELECTION_GUI returns the handle to a new PIXELS_SELECTION_GUI or the handle to
%      the existing singleton*.
%
%      PIXELS_SELECTION_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PIXELS_SELECTION_GUI.M with the given input arguments.
%
%      PIXELS_SELECTION_GUI('Property','Value',...) creates a new PIXELS_SELECTION_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before pixels_selection_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to pixels_selection_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help pixels_selection_GUI

% Last Modified by GUIDE v2.5 23-Jun-2018 16:54:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pixels_selection_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @pixels_selection_GUI_OutputFcn, ...
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

function pixels_selection_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pixels_selection_GUI (see VARARGIN)

warning('off','all');
addpath(genpath('../utilities'))
global trainingpx_local rgbmap_local classnames_local miscgui hierarchy frame_processing_local

% Initialize data:
trainingpx_local = struct();
rgbmap_local = [];
classnames_local = {};
miscgui = struct();
hierarchy = struct();
miscgui.selection_allowed = true;
frame_processing_local = {struct('name','Intensity')};
miscgui.currentOP = frame_processing_local{1};
miscgui.rootname = 'Zcells';


% Choose default command line output for pixels_selection_GUI
handles.output = hObject;
handles.result = struct();

% Change callback for the data cursor:
dcm_obj = datacursormode(hObject);
set(dcm_obj,'UpdateFcn',{@DataCursor_myupdatefcn})

% For debugging:
miscgui.debugging.handles = handles;
miscgui.datahandle = dirtyreference();
% Update handles structure
guidata(hObject, handles);

function varargout = pixels_selection_GUI_OutputFcn(~, ~  , handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
global miscgui

varargout{1} =  miscgui.datahandle;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STACK MANAGEMENT                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stackpopup_Callback(hObject, eventdata, handles)
global miscgui trainingpx_local

puval = get(handles.stackpopup,'Value');
pustr = get(handles.stackpopup,'String');
if iscell(pustr) % just foolproofing
    if ~strcmp(pustr{puval},miscgui.currentstack) % Only if the stack did change
        miscgui.currentstack = pustr{puval};
        currstack = trainingpx_local.(miscgui.currentstack);
        miscgui.preloadedstack = loadwholestack(currstack);
    end
end
updateGUI(handles,'updateOldies',false);

function stackpopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stackpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function addstackbtn_Callback(hObject, eventdata, handles)

global miscgui

% Get filename (TODO: make it possible to read TIF files directly)
[filename,path,findex] = uigetfile({'*.mat','Stack/Dataset files (.mat)'; '*.zip','Bundle files (.zip)'; '*.tif','TIFF images'},'Pick a stack, a training set, a TIFF file or a bundle','MultiSelect', 'on');
if findex == 0
    return;
end

if ~iscell(filename)
    filename = {filename};
end

plswt = {'Please wait... reading data on disk...'};
disp(plswt);
set(handles.expltext,'String',plswt)
drawnow

%%%%%% If TIFF files, check that they are all 1-page/multi-page:
if findex == 3
    fullpath_c = cellfun(@(x) fullfile(path,x), filename, 'UniformOutput',0);
    try
        stackfiles = tifToMatStack(fullpath_c);
    catch ME
        h = errordlg(ME.message);
        waitfor(h);
        return;
    end
    for ind0 = 1:numel(stackfiles)
        [~,fname,~] = fileparts(stackfiles{ind0});
        data = matfile(stackfiles{ind0});
        addzstack(data, stackfiles{ind0}, fname, handles);
    end   
        
%%%%% MAT files / ZIP files: (stacks, training sets, bundles)
else
    for ind0 = 1:numel(filename)
        fullpath = fullfile(path,filename{ind0});

        switch findex
            case 1 % MAT files: Stacks / training sets
                data = matfile(fullpath);
                if ~isprop(data, 'type_of_file') || strcmp(data.type_of_file, 'zstack') ...
                        || strcmp(data.type_of_file, 'stack') == 1
                    % Create the structure for this stack:
                    addzstack(data, full2relative(fullpath,miscgui.rootname), filename{ind0},handles);
                elseif strcmp(data.type_of_file, 'training_set')
                    addset(data.training_set,handles);
                end
            case 2 % ZIP files: Bundles
                fullpath = UnBundleData(fullpath);
                data = matfile(fullpath);
                addset(data.training_set,handles);
        end

    end
end

% Remove the explanatory text:
set(handles.expltext,'Visible','off')

disp('Done!');

function addzstack(data,path, fname,handles)
global trainingpx_local miscgui training_params_local

% Load general info about the stack
newstack.stackvarname = findstackvarname(data);
newstack.mfile = data;
newstack.pixel = struct();
newstack.path = path;
% Retrieve the stack:
stack = loadwholestack(newstack);
newstack.nbframes = numel(stack);
% Store the number of frames in the first stack: Only stacks w/ the same
% number of frames can be loaded from now on.
if isempty(fieldnames(trainingpx_local))
    training_params_local.nbframes = newstack.nbframes;
    initialize_training_params();
elseif (training_params_local.nbframes ~= newstack.nbframes)
    errordlg({'Cannot load stack:' 'the number of frames in this stack is not the same as in the other ones'},'Different frame numbers');
    return;
end
% Compute the display image:
newstack.currentframe_nb = round(numel(stack)/2);
newstack.currentframe = stack{1,newstack.currentframe_nb};

% Give this stack a name:
stackname = createstackname(fname);

% Put it all in the main structure
trainingpx_local.(stackname) = newstack;
miscgui.currentstack = stackname;
miscgui.preloadedstack = stack;

% Update the relevant elements in the GUI:
set(handles.axes1,{'xlim','ylim'},{[1,size(newstack.currentframe,2)],[1,size(newstack.currentframe,1)]}); % More robust
updateGUI(handles);

function addset(data,handles) % TODO: MAKE it possible to merge datasets

global trainingpx_local rgbmap_local classnames_local miscgui oldies training_params_local hierarchy frame_processing_local

stacks = fieldnames(data.trainingpx);
% Reload the matfiles for each stack:
for ind1 = 1:numel(stacks)
    disp(['Reloading stack ' stacks{ind1} ' from path: ' data.trainingpx.(stacks{ind1}).path]);
    r2f = relative2full(data.trainingpx.(stacks{ind1}).path,miscgui.rootname);
    
    if exist(r2f, 'file') == 2
        %data.trainingpx.(stacks{ind1}).mfile = matfile(r2f); % Not necessary?
    else
        choice = questdlg({['Can not find stack ' stacks{ind1} ' at the following location:']; ...
                                r2f; ...
                                ' '; ...
                                'Would you like to specify another location for this stack?'}, ...
        'Can not find stack...', ...
        'Yes...','No...','Cancel','Yes...');
    
        switch choice
            case 'Yes...'
                [fname, pname] = uigetfile('*.mat',stacks{ind1});
                r2f = fullfile(pname,fname);
                data.trainingpx.(stacks{ind1}).path = full2relative(r2f,miscgui.rootname);
                data.trainingpx.(stacks{ind1}).mfile = matfile(r2f);
            case 'No...'
                hw= warndlg('You will not be able to change the focus or compile data and train for this stack until you provide a valid Z-stack file','No file for this stack');
                waitfor(hw);
            case 'Cancel'
                return;
        end
    end
end

trainingpx_local = data.trainingpx;
rgbmap_local = data.rgbmap;
classnames_local = data.classnames;
hierarchy = data.hierarchy;
training_params_local = data.training_params;
if isfield(data,'frame_processing') && ~isempty(data.frame_processing)
    frame_processing_local = data.frame_processing;
else
    frame_processing_local = {struct('name','Intensity')}; % Backward compatibility
    miscgui.currentOP = frame_processing_local{1};
end

% Update miscgui:
miscgui.currentstack = stacks{end};
currstack = trainingpx_local.(miscgui.currentstack);
miscgui.preloadedstack = loadwholestack(currstack);
if ~isempty(classnames_local)
    miscgui.currentclass = classnames_local{1};
end



oldies = [];
newstack = trainingpx_local.(miscgui.currentstack);
% Update the relevant elements in the GUI:
updateClassesBox(handles);
updateOPbox(handles);
set(handles.axes1,{'xlim','ylim'},{[1,size(newstack.currentframe,2)],[1,size(newstack.currentframe,1)]}); % More robust
updateGUI(handles);

function namestr = findstackvarname(mfile)
% Look for the stack (can be named either 'stack' or 'imgC', otherwise just
% ask:

acceptednames = {'stack','imgC','zstack'};
vnames = whos(mfile);

for ind1 = 1:numel(vnames)
    idxs = strcmp(vnames(ind1).name,acceptednames);
    if any(idxs)
        namestr = acceptednames{find(idxs)};
        return
    end
end

% For now, we just issue an error, butwe should offer the possibility to
% give the name of the stack:
nameserrstr = '';
for ind1 = 1:numel(acceptednames)
nameserrstr = [nameserrstr '\n' acceptednames{ind1}];
end
msg = ['Error: the stack variable name in the MAT file should be one of the following: ' nameserrstr];
errordlg(sprintf(msg));
error(sprintf(msg));

function namestr = createstackname(fname)
% This function is actually bery different from the one above, it creates a
% name to use as a label in both the popup menu and in the trainingpx_local
% structure. It does not look for the VARIABLE name of the stack in hte
% matfile

global trainingpx_local
% If there is an/several extensions, remove them:
dots = find(fname=='.');
if ~isempty(dots)
    fname = fname(1:dots(1));
end

% Remove non alphanumeric characters:
fname(~ismember(fname,['A':'Z' 'a':'z' '_' '0':'9'])) = '';
fname = ['ZS_' fname]; % A Q&D way of ensuring that the first character is a letter

fields = fieldnames(trainingpx_local);

if ~any(strcmp(fname,fields));
    namestr = fname;
else
    incr = 2;
    namestr = [fname '_' num2str(incr)];
    while(any(strcmp(namestr,fields)))
        incr = incr +1;
        namestr = [fname '_' num2str(incr)];
    end
end







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FRAME MANAGEMENT                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function edit_framenb_Callback(hObject, eventdata, handles)
global miscgui trainingpx_local

currstack = trainingpx_local.(miscgui.currentstack);


nb_str = get(hObject, 'String');
if all(isstrprop(strtrim(nb_str),'digit')) % Check if input format is valid
    frnb = str2num(nb_str);
    if frnb > currstack.nbframes % If too high
        errordlg('Frame number greater than stack size')
        set(hObject,'String',num2str(currstack.currentframe_nb)); % Set the string back
        return
    elseif frnb < 1 % If too low
        errordlg('Frame number cannot be < 1')
        set(hObject,'String',num2str(currstack.currentframe_nb)); % Set the string back
        return
    end
    else % If invalid format
    errordlg('Invalid frame number')
    set(hObject,'String',num2str(currstack.currentframe_nb)); % Set the string back
    return;
end

updateFrameNumber(frnb,handles)

function edit_framenb_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function stackslider_Callback(hObject, eventdata, handles)

frnb = get(handles.stackslider, 'Value');

updateFrameNumber(frnb,handles)

function updateFrameNumber(frnb,handles)
global trainingpx_local miscgui

frnb = round(frnb);

% Update the images and frame number:
currstack = trainingpx_local.(miscgui.currentstack);
if ~isempty(currstack.mfile)
    currstack.currentframe_nb = frnb;
    % This if makes it backward compatible:
    if isfield(currstack,'preloaded_fr') 
        currstack = rmfield(currstack,'preloaded_fr');
        if isfield(currstack,'preloaded_fr_nbs')
            currstack = rmfield(currstack,'preloaded_fr_nbs');
        end
        miscgui.preloadedstack = loadwholestack(currstack);
    end
    if isempty(miscgui.preloadedstack)
        miscgui.preloadedstack = loadwholestack(currstack);
    end
    currstack.currentframe = miscgui.preloadedstack{frnb};
    trainingpx_local.(miscgui.currentstack) = currstack;
end

updateGUI(handles,'updateOldies',false);

function stackslider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function stack = loadwholestack(currstack)
global miscgui

try
    stack = currstack.mfile.(currstack.stackvarname);
catch ME
    if (strcmp(ME.identifier,'MATLAB:MatFile:NoFile'))
        warning('Matfile not found, trying reload from path...');
        currstack.mfile = matfile(relative2full(currstack.path,miscgui.rootname));
        stack = currstack.mfile.(currstack.stackvarname);
    else
        rethrow(ME)
    end
end
        




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLASSES MANAGEMENT                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function classbox_Callback(hObject, eventdata, handles)
global miscgui classnames_local

if isempty(classnames_local)
    return;
end
if strcmp(get(handles.figure1,'SelectionType'),'open') % If double click: edit the class (color, name or higher operations)
    edit_classes(handles)
else
    % If classes GUI already opened, close it:
    close_edit_class();
    cbval = get(handles.classbox,'Value');
    if numel(cbval) > 1
        cbval = cbval(1);
    end
    miscgui.currentclass = classnames_local{cbval};
    udapte_zpxtext(handles)
end

function edit_classes(handles)
global miscgui

% Switch current command to nothing:
breakoutofselection()
drawnow

% If GUI already opened, close it:
close_edit_class()
miscgui.current_editclass = miscgui.currentclass; % This is erased upon closing of the sub-GUI

% Call the dedicated GUI:
miscgui.debugging.handles.editclass = Edit_class_GUI();

function close_edit_class()
global miscgui

if isfield(miscgui.debugging.handles,'editclass')
    try
        close(miscgui.debugging.handles.editclass);
    catch
    end
end

function classbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to classbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function addclassbtn_Callback(hObject, eventdata, handles)

global rgbmap_local miscgui classnames_local

% Prepare default answers:
if isempty(classnames_local)
    classnames_local = {};
end
nbclasses = numel(classnames_local);
newclassname = ['CLASS_' num2str(nbclasses)];

newclasscolor = distinguishable_colors(1,[0 0 0; 1 1 1; rgbmap_local]);
colorstr = color2hex(newclasscolor);

ret = inputdlg({'Class name?','Color? rgbcmykw or hex (#ffffff)'},'New pixel class',1,{newclassname,colorstr});
if isempty(ret)
    return;
end

newclassname = ret{1};
if any(strcmp(newclassname,classnames_local))
    errordlg('A class by this name already exists');
    error('A class by this name already exists');
else
    classnames_local{end+1} = newclassname;
end

[newclasscolor] = hex2color(ret{2});
rgbmap_local = [rgbmap_local; newclasscolor];

miscgui.currentclass = newclassname;
% Now, add it to the listbox:
updateClassesBox(handles);

function cmdpanel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in cmdpanel 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

global miscgui trainingpx_local

if ~isfield(miscgui,'currentstack')
    errordlg('Please add at least one stack before you can use commands');
    error('Please add at least one stack before you can use commands');
end


if ~isfield(miscgui,'currentclass')
    errordlg('Please create at least one class before you can use commands');
    error('Please create at least one class before you can use commands');
end

if eventdata.NewValue ~= handles.nocmd  && (~isfield(miscgui,'selecting') || ~miscgui.selecting)
% Do the roipoly:
% Launch a new one:
    try
        miscgui.selection_allowed = true;
        while miscgui.selection_allowed % This will only break if the user changes command

            set(gcf,'CurrentAxes',handles.axes1);
            miscgui.selecting = true;
            h = impoly();
            miscgui.lastimpoly = h;
            wait(h);
            if isvalid(miscgui.lastimpoly)
                area = find(createMask(h));
                delete(h);
            else
                area = [];
            end
            actualselect = get(handles.cmdpanel,'SelectedObject');
            switch actualselect
                case handles.appdpxls_radio
                    % The field for this group already exists, we append,
                    % otherwise we create it:
                    if isfield(trainingpx_local.(miscgui.currentstack).pixel,miscgui.currentclass)
                        trainingpx_local.(miscgui.currentstack).pixel.(miscgui.currentclass) = [trainingpx_local.(miscgui.currentstack).pixel.(miscgui.currentclass); area];
                    else
                        trainingpx_local.(miscgui.currentstack).pixel.(miscgui.currentclass) = area;
                    end

                case handles.delpxls_radio
                    if isfield(trainingpx_local.(miscgui.currentstack).pixel,miscgui.currentclass)
                        [lia,locb] = ismember(area,trainingpx_local.(miscgui.currentstack).pixel.(miscgui.currentclass));
                        trainingpx_local.(miscgui.currentstack).pixel.(miscgui.currentclass) = trainingpx_local.(miscgui.currentstack).pixel.(miscgui.currentclass)(setdiff(1:numel(trainingpx_local.(miscgui.currentstack).pixel.(miscgui.currentclass)),locb(lia)));
                    end
                case handles.nocmd
                    miscgui.selecting = false;
                    break
            end
            updateGUI(handles);
        end
    catch ME % For now we just discard errors and break out of the loop
        disp('error')
        global ME_global_debug
        ME_global_debug = ME;
    end
elseif eventdata.NewValue == handles.nocmd % If we switch to nocmd (or 'Nothing'), we break out of the impoly selectionloop:
    breakoutofselection();
end

function breakoutofselection()
global miscgui

if isfield(miscgui,'selecting') && miscgui.selecting
    % This releases the impoly selection tool in case nothing was drawn
    robot = java.awt.Robot;
    robot.keyPress    (java.awt.event.KeyEvent.VK_ESCAPE);
    robot.keyRelease  (java.awt.event.KeyEvent.VK_ESCAPE);  
end

miscgui.debugging.handles.nocmd.Value = true;
miscgui.selecting = false;
miscgui.selection_allowed = false;

function visibility_check_Callback(hObject, eventdata, handles)
global miscgui classnames_local

if hObject.Value
    if isempty(hObject.UserData)
        miscgui.invisibleclasses = {};
    else
        miscgui.invisibleclasses = hObject.UserData;
    end
else
    if isfield(miscgui,'invisibleclasses')
        hObject.UserData = miscgui.invisibleclasses;
    else
        hObject.UserData = {};
    end
    miscgui.invisibleclasses = classnames_local;
end
updateGUI(handles,'updateOldies',false);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRE-PROCESSING OPERATIONS MANAGEMENT %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function preprocessing_listbox_Callback(hObject, eventdata, handles)
global miscgui frame_processing_local

pbval = get(handles.preprocessing_listbox,'Value');
if numel(pbval) > 1
    pbval = pbval(1);
end
miscgui.currentOP = frame_processing_local{pbval};
updateGUI(handles,'updateOldies',false);

function preprocessing_listbox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function addOp_btn_Callback(hObject, eventdata, handles)
global miscgui frame_processing_local trainingpx_local

if ~isfield(miscgui,'currentstack')
    warndlg('Load at least one stack before changing parameters')
else
    I0 = trainingpx_local.(miscgui.currentstack).currentframe;
    newOP =  preprocessing_ops_GUI(I0);
    if ~isempty(newOP)
        frame_processing_local{end+1} = newOP;
        updateOPbox(handles);
    end
end

function delOp_btn_Callback(hObject, eventdata, handles)
global miscgui frame_processing_local

if ~isfield(miscgui,'currentstack')
    warndlg("Load at least one stack before changing parameters")
elseif numel(frame_processing_local) == 1
    warndlg("There must be at least one preprocessing operation")
else
    pbval = get(handles.preprocessing_listbox,'Value');
    if numel(pbval) > 1
        pbval = pbval(1);
    end
    frame_processing_local(pbval) = [];
    set(handles.preprocessing_listbox,'Value',1);
    miscgui.currentOP = frame_processing_local{1};
    updateOPbox(handles);
end

function updateOPbox(handles)
global frame_processing_local

for ind1 = 1:numel(frame_processing_local)
    OP = frame_processing_local{ind1};
    str = OP.name;
    params = setdiff(fieldnames(OP),'name');
    if ~isempty(params)
        str = [str ' ('];
        for ind2 = 1:numel(params)
            str = [str params{ind2} ': '];
            pval = OP.(params{ind2});
            if isnumeric(pval)
                pval = num2str(pval);
            elseif isa(pval, 'function_handle')
                pval = func2str(pval);
            end
            str = [str pval ', '];
        end
        str = [str(1:(end-2)) ')'];
    end
    str_c{ind1} = str;
end

handles.preprocessing_listbox.String = str_c;
updateGUI(handles,'updateOldies',true);

function loadfromset_operations_Callback(hObject, eventdata, handles)
global frame_processing_local

[fname,pname] = uigetfile('*.mat','Select training set');
if fname==0 return; end

mf = matfile(fullfile(pname,fname));
set = mf.training_set;
if isfield(set,'frame_processing') && ~isempty(set.frame_processing)
    frame_processing_local = set.frame_processing;
else
    frame_processing_local = {struct('name','Intensity')};
end

handles.preprocessing_listbox.Value = 1;
updateOPbox(handles);








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TOOLBAR MANAGEMENT                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function undo_push_ClickedCallback(hObject, eventdata, handles)
global oldies
oldies.currop = oldies.currop -1;
if oldies.currop < 1
    oldies.currop = 1;
    warndlg('You have reached the last saved operation, can not undo more...');
    return;
end
updateStateVariables();

function redo_push_ClickedCallback(hObject, eventdata, handles)
global oldies
oldies.currop = oldies.currop +1;
if oldies.currop > numel(oldies.ops)
    oldies.currop = numel(oldies.ops);
    warndlg('You have reached the most recent operation, can not re-do more...');
    return;
end
updateStateVariables();

function updateStateVariables()
global  trainingpx_local rgbmap_local classnames_local oldies miscgui hierarchy frame_processing_local

OP = oldies.ops(oldies.currop);
% If the dialogbox for a class is open and the class does not exist anymore, close it:
if isfield(miscgui, 'current_editclass') && ... % Check if we have the relevant filed in the structure
        ~isempty(miscgui.current_editclass) && ... % Check if we have a valid class name (i.e. it hasn't been closed)
        (~isfield(OP.miscgui, 'current_editclass') || ~strcmp(OP.miscgui.current_editclass,miscgui.current_editclass)) && ... % Check if the new editclass field is the same as in the current state (not sure if this is possible)
        isvalid(miscgui.debugging.handles.editclass) % Check that it hasn't been deleted already
        
    try
        close(miscgui.debugging.handles.editclass); % Try closing it...
    catch
        disp('error while trying to close the edit class GUI')
    end
end
% Switch to the new state:
trainingpx_local = OP.trainingpx_local;
rgbmap_local = OP.rgbmap_local;
classnames_local = OP.classnames_local; 
miscgui = OP.miscgui;
hierarchy = OP.hierarchy;
frame_processing_local = OP.frame_processing_local;
% Update the GUI
updateGUI(miscgui.debugging.handles,'updateOldies',false);
% Update the classes box:
updateClassesBox(miscgui.debugging.handles);
% Update the operations box:
updateOPbox(miscgui.debugging.handles);

udapte_zpxtext(miscgui.debugging.handles);

function txt = DataCursor_myupdatefcn(~,event_obj)
global miscgui trainingpx_local

% Customizes text of data tips
pos = get(event_obj,'Position');
indx = get(event_obj, 'DataIndex');
% Find classes for this index:
currclass = trainingpx_local.(miscgui.currentstack);
pxl = currclass.pixel;
pos_class = fieldnames(pxl);
classes = {};
for ind1 = 1:numel(pos_class)
    if any(pxl.(pos_class{ind1}) == indx)
        classes = [classes [ '- ' pos_class{ind1}]];
    end
end
% Get gray value:
graylvl = currclass.currentframe(indx);

txt = [{['X: ',num2str(pos(1))],...
       ['Y: ',num2str(pos(2))],...
       ['index: ',num2str(indx)],...
       ['intensity: ' num2str(graylvl)],...
       '------------------------',...
       'Classes: '} classes];

function savebutton_ClickedCallback(hObject, eventdata, handles)

[fname, pname, findex] = uiputfile({'*.mat','Dataset (*.mat)'; '*.zip', 'Bundle (*.zip)'}, 'Save dataset as...',[datestr(now,29) '_trainingset']);

switch findex
    case 0 
        return
    case 1 % Dataset
        training_set = convert_to_trSet();
        type_of_file = 'training_set';
        save(fullfile(pname,fname),'training_set','type_of_file','-v7.3');
    case 2 % Bundle
        training_set = convert_to_trSet();
        BundleData(training_set, {pname,fname});
end






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HIERARCHY                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tree_button_Callback(hObject, eventdata, handles)
global miscgui hierarchy classnames_local rgbmap_local

if isfield(miscgui,'treeplot') && isvalid(miscgui.treeplot)
    cla(miscgui.treeplot);
    figure(miscgui.treeplot.Parent);
    miscgui.treeplot = plot_hierarchy_tree(hierarchy,classnames_local,rgbmap_local);
    text(0,0,'(click on ''show tree'' to update)');
else
    figure('Name','Classes Hierarchy','numbertitle','Off','menubar','none');
    miscgui.treeplot = plot_hierarchy_tree(hierarchy,classnames_local,rgbmap_local);
    text(0,0,'(click on ''show tree'' to update)');

end









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FINISHED                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function donebtn_Callback(hObject, eventdata, handles)

global miscgui trainingpx_local classnames_local

if isempty(trainingpx_local) || numel(classnames_local) < 2
    errordlg('You must have at least loaded 1 frame and created 2 classes','Nothing to train')
end

ts = convert_to_trSet();
miscgui.datahandle.trainingpx = ts.trainingpx; % datahandle is an object so I have to assign it this way...
miscgui.datahandle.rgbmap = ts.rgbmap;
miscgui.datahandle.classnames = ts.classnames;
miscgui.datahandle.hierarchy = ts.hierarchy;
miscgui.datahandle.training_params = ts.training_params;
miscgui.datahandle.frame_processing = ts.frame_processing;
miscgui.datahandle.finished = true;
close_all_GUIs();

function training_set = convert_to_trSet()

global trainingpx_local rgbmap_local classnames_local hierarchy training_params_local frame_processing_local

% Convert to training_set format:
training_set.trainingpx = trainingpx_local;
training_set.rgbmap = rgbmap_local;
training_set.classnames = classnames_local;
training_set.hierarchy = hierarchy;
training_set.training_params = training_params_local;
training_set.frame_processing = frame_processing_local;

stacks = fieldnames(trainingpx_local);
for ind1 = 1:numel(stacks) % To reduce memory size (Retro-compatibility)
    training_set.trainingpx.(stacks{1}).preloaded_fr = {};
end

function figure1_CloseRequestFcn(hObject, eventdata, handles)
global miscgui
res = questdlg('Are you sure you want to quit?','Close GUI?','Yes','No','No');
switch res
    case 'Yes'
        miscgui.datahandle.aborted = true;
        close_all_GUIs();
    case 'No'
end

function close_all_GUIs()
global miscgui

if isfield(miscgui,'current_editclass') && ~isempty(miscgui.current_editclass)
    delete(miscgui.debugging.handles.editclass);
end
if isfield(miscgui.debugging.handles, 'training_params')
    delete(miscgui.debugging.handles.training_params);
end

delete(miscgui.debugging.handles.figure1);








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETERS                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function trainingParams_Callback(hObject, eventdata, handles)
global miscgui
if ~isfield(miscgui,'currentstack')
    warndlg("Load at least one stack before changing parameters")
else
    miscgui.debugging.handles.training_params = training_params_GUI();
end
