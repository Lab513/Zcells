function varargout = training_params_GUI(varargin)
% TRAINING_PARAMS_GUI MATLAB code for training_params_GUI.fig
%      TRAINING_PARAMS_GUI, by itself, creates a new TRAINING_PARAMS_GUI or raises the existing
%      singleton*.
%
%      H = TRAINING_PARAMS_GUI returns the handle to a new TRAINING_PARAMS_GUI or the handle to
%      the existing singleton*.
%
%      TRAINING_PARAMS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRAINING_PARAMS_GUI.M with the given input arguments.
%
%      TRAINING_PARAMS_GUI('Property','Value',...) creates a new TRAINING_PARAMS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before training_params_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to training_params_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help training_params_GUI

% Last Modified by GUIDE v2.5 21-Jun-2018 17:53:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @training_params_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @training_params_GUI_OutputFcn, ...
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


% --- Executes just before training_params_GUI is made visible.
function training_params_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to training_params_GUI (see VARARGIN)

% Choose default command line output for training_params_GUI
handles.output = hObject;

global classnames_local rgbmap_local training_params_local

if isempty(training_params_local) % If for some reason it has not been initialized...
    initialize_training_params();
end

% Update the UI elements:
setv(handles.maxmemUse,training_params_local.maxmemUse);
switch training_params_local.frames_subselection.type
    case 'all'
        setv(handles.allframes,true);
    case 'linear'
        setv(handles.linearbtn, true);
        set(handles.editUseFrames,'ForegroundColor',[0 0 0]);
    case 'log'
        setv(handles.logbtn, true); 
        set(handles.editUseFrames,'ForegroundColor',[0 0 0]);
    case 'custom'
        setv(handles.custombtn, true);
        set(handles.customframe,'ForegroundColor',[0 0 0]);
end
setv(handles.editUseFrames,training_params_local.frames_subselection.nbframes_linlog);
setv(handles.customframe ,training_params_local.frames_subselection.custom_set );
setv(handles.nbcomponents_edit ,training_params_local.feature_extraction.nbcomponents  );
setv(handles.featextr_subsampling_edit ,training_params_local.feature_extraction.subsampling  );
setv(handles.focusshift_check ,training_params_local.focus_shifting.status );
setv(handles.radius_edit ,training_params_local.focus_shifting.radius );
setv(handles.parallel_check ,training_params_local.parallel_processing.status );
if ~isempty(training_params_local.parallel_processing.cluster_profile)
    if any(strcmp(training_params_local.parallel_processing.cluster_profile,parallel.clusterProfiles()))
        setv(handles.clusters_popup ,training_params_local.parallel_processing.cluster_profile );
    else
        clp = parallel.clusterProfiles();
        warndlg(['Cluster profile ' training_params_local.parallel_processing.cluster_profile ' not valid, defaulting to first profile: ' clp{1}]);
    end
end

% Class-specific:
set(handles.againstclasses, 'Min', 0, 'Max', 2);
set(handles.class_popup,'String',pimpmystrings(['__default__' classnames_local],[1 1 1; rgbmap_local]));
if isfield(training_params_local.class_specific.default.SVM,'DeltaGradientTolerance')
    res = questdlg('It looks like the training parameters for this dataset were established for SVM calssification. Would you like to switch to switch to Random Forest parameters?','SVM parameters detected','Yes','Cancel','Yes');
    if strcmp(res,'Yes')
        training_params_local.class_specific.default.SVM = struct();
        training_params_local.class_specific.spec = struct();
        training_params_local.class_specific.default = rmfield(training_params_local.class_specific.default, 'OptimizeSVM');
        % That's pretty dirty:
        training_params_local.class_specific.default.SVM.NumTrees = 50;
        training_params_local.class_specific.default.SVM.InBagFraction = 1;
        training_params_local.class_specific.default.SVM.MinLeafSize = 1;
        training_params_local.class_specific.default.SVM.SampleWithReplacement = 1;
        writeClassParameters('__default__',handles);
    else
        handles.closefigure = 1;
    end
else
    writeClassParameters('__default__',handles);
end

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = training_params_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% This function is executed right after OpeningFcn: If the user cancelled
% after the SVM-->RF parameters questdlg box, we close the figure:
if (isfield(handles,'closefigure') && handles.closefigure)

      figure1_CloseRequestFcn(hObject, eventdata, handles)

end


function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   UTILITIES                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% A generic function to retrieve data from the various UI elements:
function data = retr(handle, varargin)

ip = inputParser();
ip.addRequired('handle',@(x) isa(x,'matlab.ui.control.UIControl'));
ip.addParameter('validation_fcn',@(x) ~isempty(x), @(x) isa(x,'function_handle'));
ip.addParameter('additional_errorinfo','',@isstr);
ip.parse(handle, varargin{:})

switch handle.Style
    case 'edit'
        str = get(handle,'String');
        data = str2num(str);
        if ~ip.Results.validation_fcn(data)
            errordlg({'The value you just entered:' str 'is not valid.' ip.Results.additional_errorinfo})
            error(['The value you just entered: ' str ' is not valid. ' ip.Results.additional_errorinfo]);
        end

    case 'radiobutton'
        data = get(handle,'Value');
        
    case 'checkbox'
        data = get(handle,'Value');
        
    case 'popupmenu'
        str = get(handle, 'String');
        data = str{get(handle,'Value')};
end

% A generic function to set data in the various UI elements:
function data = setv(handle, value)

ip = inputParser();
ip.addRequired('handle',@(x) isa(x,'matlab.ui.control.UIControl'));
ip.addRequired('value',@(x) ~isempty(x));
ip.parse(handle, value)

switch handle.Style
    case 'edit'
        set(handle,'String',num2str(value,'%g '));
    case 'radiobutton'
        set(handle,'Value',value);
        
    case 'checkbox'
        set(handle,'Value',value);
        
    case 'popupmenu'
        if ischar(value)
            str = get(handle, 'String');
            val = find(strcmp(value,str));
            set(handle,'Value',val);
        elseif isnum(value)
            set(handle,'Value',value);
        end
        
end

% Check whether handle is of UIControl class:
function isit = isuicontrol(handle)
if strcmp(class(handle),'matlab.ui.control.UIControl')
    isit = true;
else
    isit = false;
end

function cd = getCurrentClassData(class)
global  trainingpx_local hierarchy classnames_local

if strcmp(class,'__default__')
    cd.nbpxls = 0;
    for ind1 = 1:numel(classnames_local)
        cd.nbpxls = cd.nbpxls + nbpixels_inclass(trainingpx_local,classnames_local{ind1});
    end
    cd.parentclass_nb = [];
    cd.parentclass = 'N/A';
    cd.againstclasses = {'N/A'};
    cd.otherclasses = classnames_local;
else
    cd.nbpxls = nbpixels_inclass(trainingpx_local,class);
    nodes_H = nodes_from_hierarchy(hierarchy);
    cd.parentclass_nb = nodes_H(strcmp(classnames_local, class));
    if cd.parentclass_nb > 0
        cd.parentclass = classnames_local{cd.parentclass_nb};
    else
        cd.parentclass = '';
    end
    cd.againstclasses = setdiff(classnames_local(nodes_H == cd.parentclass_nb),class);
    cd.otherclasses = ['__default__' setdiff(classnames_local,class)];
end

function cc = getCurrentClass(handles)
global classnames_local
val = get(handles.class_popup,'Value');
str = ['__default__' classnames_local];
cc = str{val};

function assign_to_field(handles,x,varargin)
% This function assigns the value in 'x' to the correct field depending on
% the current selected class and the field name in field1. Up to 4 additional
% field can be added for deeper structures assignments
global training_params_local

ip = inputParser();
ip.addRequired('x');
ip.addRequired('fields',@iscellstr);
ip.parse(x, varargin);

fields = ip.Results.fields;

cc = getCurrentClass(handles);

switch cc
    case '__default__'
        training_params_local.class_specific.default = setfield(training_params_local.class_specific.default,fields{:},x);
    otherwise
        if ~isfield(training_params_local.class_specific,'spec')
            training_params_local.class_specific.spec = struct();
        end
        if ~isfield(training_params_local.class_specific.spec,cc)
            training_params_local.class_specific.spec.(cc) = struct();
        end
        training_params_local.class_specific.spec.(cc) = setfield(training_params_local.class_specific.spec.(cc),fields{:},x);
end

function x = retrieve_field(handles,varargin)
% This function reads the value in 'x' to the correct field depending on
% the current selected class and the field name in field1. Up to 4 additional
% field can be added for deeper structures assignments
global training_params_local

ip = inputParser();
ip.addRequired('handles',@isstruct);
ip.addRequired('fields',@iscellstr);
ip.parse(handles,varargin);

cc = getCurrentClass(ip.Results.handles);

try 
    switch cc
        case '__default__'
            x = getfield(training_params_local.class_specific.default,ip.Results.fields{:});
        otherwise
            x = getfield(training_params_local.class_specific.spec.(cc),ip.Results.fields{:});
    end
catch 
    x = [];
end

function x = retrieve_field_default(handles, varargin)
% This function assigns the value in 'x' to the correct field depending on
% the current selected class and the field name in field1. Up to 4 additional
% field can be added for deeper structures assignments
global training_params_local

fields = varargin;
x = retrieve_field(handles,fields{:});
if isempty(x)
    x = getfield(training_params_local.class_specific.default,fields{:});
elseif strcmp(fields{end},'Range') % Check if the range has been entirely set, otherwise set the corresponding value to default
    x2 = getfield(training_params_local.class_specific.default,fields{:});
    if numel(x) == 1
        x(2) = x2(2);
    elseif any(x == 0)
        x(x == 0) = x2(x==0);
    end
end

function writeClassParameters(class,handles)
% This function updates all the UI elements in the class-specific panel
% depending on the input class 'class'
global classnames_local rgbmap_local

cd = getCurrentClassData(class);

% Explanatory text:
expltext = {'Number of z-pixels:' num2str(cd.nbpxls) 'Child of class: ' cd.parentclass};
set(handles.expltext,'String',expltext);

% Trained against classes:
if ~strcmp(class, '__default__')
    against_indexes = cellfun(@(x) any(strcmp(x,cd.againstclasses)), classnames_local);
    set(handles.againstclasses, 'String', pimpmystrings(cd.againstclasses,rgbmap_local(against_indexes,:)));
else
    set(handles.againstclasses, 'String','N/A')
end
set(handles.againstclasses, 'Value', []);

% Copy popup:
others_indexes = cellfun(@(x) any(strcmp(x,cd.otherclasses)), classnames_local);
if any(strcmp('__default__',cd.otherclasses))
    set(handles.copy_popup,'String',pimpmystrings(cd.otherclasses, [1 1 1; rgbmap_local(others_indexes,:)]));
else
    set(handles.copy_popup,'String',pimpmystrings(cd.otherclasses, rgbmap_local(others_indexes,:)));
end
set(handles.copy_popup,'Value',1);

% Subsampling:
res = retrieve_field_default(handles,'subsample');
set(handles.subsample_editpc,'String',num2str(res,'% 3.2f'));
set(handles.subsample_editpxls,'String',num2str(round(cd.nbpxls*res/100),'%.4g'));

% Random Forest:
res = retrieve_field_default(handles,'SVM','NumTrees');
setv(handles.NumTrees_edit,res);
res = retrieve_field_default(handles,'SVM','InBagFraction');
setv(handles.InBagFraction_edit, res);
res = retrieve_field_default(handles,'SVM','MinLeafSize');
setv(handles.MinLeafSize_edit,res);
res = retrieve_field_default(handles,'SVM','SampleWithReplacement');
setv(handles.SampleWithReplacement,res);











%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   MEMORY USAGE                                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function maxmemUse_Callback(hObject, eventdata, handles)
global training_params_local

training_params_local.maxmemUse = retr(hObject);

function maxmemUse_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end











%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   FRAMES SUBSELECTION                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function allframes_Callback(hObject, eventdata, handles)
global training_params_local

if retr(hObject)
    training_params_local.frames_subselection.type = 'all';
    training_params_local.frames_subselection.frames = process_framessubselection(training_params_local.frames_subselection,training_params_local.nbframes);
    set(handles.customframe,'ForegroundColor',[.5 .5 .5]);
    set(handles.editUseFrames,'ForegroundColor',[.5 .5 .5]);
end

function linearbtn_Callback(hObject, eventdata, handles)
global training_params_local

if retr(hObject)
    training_params_local.frames_subselection.type = 'lin';
    training_params_local.frames_subselection.frames = process_framessubselection(training_params_local.frames_subselection,training_params_local.nbframes);
    set(handles.customframe,'ForegroundColor',[.5 .5 .5]);
    set(handles.editUseFrames,'ForegroundColor',[0 0 0]);
end

function logbtn_Callback(hObject, eventdata, handles)
global training_params_local

if retr(hObject)
    training_params_local.frames_subselection.type = 'log';
    training_params_local.frames_subselection.frames = process_framessubselection(training_params_local.frames_subselection,training_params_local.nbframes);
    set(handles.customframe,'ForegroundColor',[.5 .5 .5]);
    set(handles.editUseFrames,'ForegroundColor',[0 0 0]);
end

function custombtn_Callback(hObject, eventdata, handles)
global training_params_local

if retr(hObject)
    training_params_local.frames_subselection.type = 'custom';
    training_params_local.frames_subselection.frames = process_framessubselection(training_params_local.frames_subselection,training_params_local.nbframes);
    set(handles.customframe,'ForegroundColor',[0 0 0]);
    set(handles.editUseFrames,'ForegroundColor',[.5 .5 .5]);
end

function customframe_Callback(hObject, eventdata, handles)
global training_params_local

training_params_local.frames_subselection.custom_set = retr(hObject,...
    'additional_errorinfo','Please provide all chosen frames'' numbers. (something like: 30 35 38 39 40 41 45 50)', ...
    'validation_fcn', @(x) (~isempty(x) && all((mod(x,1) == 0)))); % is not empty and all are integer values
training_params_local.frames_subselection.frames = process_framessubselection(training_params_local.frames_subselection,training_params_local.nbframes);

function editUseFrames_Callback(hObject, eventdata, handles)
global training_params_local

training_params_local.frames_subselection.nbframes_linlog = retr(hObject,...
    'additional_errorinfo','Please provide only an integral number of frames', ...
    'validation_fcn', @(x) (~isempty(x) && isscalar(x) && all((mod(x,1) == 0)))); % is not empty and value is integer
training_params_local.frames_subselection.frames = process_framessubselection(training_params_local.frames_subselection,training_params_local.nbframes);

function editUseFrames_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function customframe_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Feature extraction                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function nbcomponents_edit_Callback(hObject, eventdata, handles)
global training_params_local

training_params_local.feature_extraction.nbcomponents = retr(hObject,...
    'additional_errorinfo','Please provide only an integral number of components', ...
    'validation_fcn', @(x) (~isempty(x) && isscalar(x) && all((mod(x,1) == 0)))); % is not empty and value is integer

function nbcomponents_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function featextr_subsampling_edit_Callback(hObject, eventdata, handles)
global training_params_local

training_params_local.feature_extraction.subsampling = retr(hObject,...
    'additional_errorinfo','Please provide a percentage', ...
    'validation_fcn', @(x) (~isempty(x) && isscalar(x) && x > 0 && x <= 100)); % is not empty and value is integer

function featextr_subsampling_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Focus shifting                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function focusshift_check_Callback(hObject, eventdata, handles)
global training_params_local

training_params_local.focus_shifting.status = retr(hObject);

function radius_edit_Callback(hObject, eventdata, handles)
global training_params_local

training_params_local.focus_shifting.radius = retr(hObject,...
    'additional_errorinfo','Please provide only an integral focussing radius', ...
    'validation_fcn', @(x) (~isempty(x) && isscalar(x) && all((mod(x,1) == 0)))); % is not empty and value is integer

function radius_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Parallel processing                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function parallel_check_Callback(hObject, eventdata, handles)
global training_params_local

training_params_local.parallel_processing.status = retr(hObject);

function clusters_popup_Callback(hObject, eventdata, handles)
global training_params_local

training_params_local.parallel_processing.cluster_profile = retr(hObject);

function clusters_popup_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

cls = parallel.clusterProfiles();
set(hObject,'String',cls);








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Class-specific - GENERAL                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function class_popup_Callback(hObject, eventdata, handles)

cc = getCurrentClass(handles);
writeClassParameters(cc, handles);

function class_popup_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function againstclasses_Callback(hObject, eventdata, handles)
% Deselect:
set(hObject,'Value',[]);

function againstclasses_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Class-specific - COPY                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function copy_btn_Callback(hObject, eventdata, handles)
global training_params_local

cc = getCurrentClass(handles);
cd = getCurrentClassData(cc);
copyclass = cd.otherclasses{get(handles.copy_popup,'Value')};

if isfield(training_params_local.class_specific.spec,copyclass)
    training_params_local.class_specific.spec.(cc) = training_params_local.class_specific.spec.(copyclass);
elseif strcmp(copyclass,'__default__')
    training_params_local.class_specific.spec.(cc) = training_params_local.class_specific.default;
end

writeClassParameters(cc,handles)

function copy_popup_Callback(hObject, eventdata, handles)

function copy_popup_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Class-specific - SUBSAMPLE                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function subsample_editpxls_Callback(hObject, eventdata, handles)

% Get current class and class data:
cc = getCurrentClass(handles);
cd = getCurrentClassData(cc);

% Retrieve UI element data:
res = retr(hObject,...
    'additional_errorinfo',['Number of z-pixels must be an integer between 0 and ' num2str(cd.nbpxls) ], ...
    'validation_fcn', @(x) (~isempty(x) && isscalar(x) && all((mod(x,1) == 0))) && x <= cd.nbpxls && x >= 0); % is not empty and value is integer between 0 and nb of pixels in class

% Update the global variable:
pc = 100*res/cd.nbpxls;
assign_to_field(handles,pc,'subsample')

% Update the other edit element:
set(handles.subsample_editpc,'String',num2str(pc,'% 3.2f'))

function subsample_editpxls_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function subsample_editpc_Callback(hObject, eventdata, handles)

% Get current class and class data:
cc = getCurrentClass(handles);
cd = getCurrentClassData(cc);

% Retrieve UI element data:
res = retr(hObject,...
    'additional_errorinfo','Percentage of z-pixels must be a real number between 0 and 100' , ...
    'validation_fcn', @(x) (~isempty(x) && isscalar(x) && x <= 100 && x >= 0)); % is not empty and value is between 0 and 100

% Update the global variable:
assign_to_field(handles,res,'subsample')
    
% Update the other edit element:
set(handles.subsample_editpxls,'String',num2str(round(res*cd.nbpxls/100),'%.4g'))

function subsample_editpc_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end











%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Class-specific - Random Forest                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Number of Trees -----------------------------------------------------
function NumTrees_edit_Callback(hObject, eventdata, handles)

% Retrieve UI element data:
res = retr(hObject,...
    'additional_errorinfo','Number of trees must be a positive integer (> 0)' , ...
    'validation_fcn', @(x) (~isempty(x) && isscalar(x) && x > 0 && all((mod(x,1) == 0)))); % is not empty and value is integer

% Update the global variable:
assign_to_field(handles,res,'SVM','NumTrees')

function NumTrees_edit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% IN BAG FRACTION -----------------------------------------------------
function InBagFraction_edit_Callback(hObject, eventdata, handles)

% Retrieve UI element data:
res = retr(hObject,...
    'additional_errorinfo','Interation limit must be a positive positive scalar fraction (> 0 & <=1)' , ...
    'validation_fcn', @(x) (~isempty(x) && isscalar(x) && x <=1 && x > 0)); % is not empty and value ]0;1]

% Update the global variable:
assign_to_field(handles,res,'SVM','InBagFraction')

function InBagFraction_edit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% MIN LEAF SIZE -----------------------------------------------------
function MinLeafSize_edit_Callback(hObject, eventdata, handles)

% Retrieve UI element data:
res = retr(hObject,...
    'additional_errorinfo','Min leaf size must be a positive integer (> 0)' , ...
    'validation_fcn', @(x) (~isempty(x) && isscalar(x) && all((mod(x,1) == 0)) && x > 0)); % is not empty and value is integer

% Update the global variable:
assign_to_field(handles,res,'SVM','MinLeafSize')

function MinLeafSize_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% SAMPLE WITH REPLACEMBT -----------------------------------------------------
function SampleWithReplacement_Callback(hObject, eventdata, handles)
% Retrieve UI element data:
res = retr(hObject,...
    'additional_errorinfo','Set In Bag Fraction < 1 first' , ...
    'validation_fcn', @(x) x == 1 || (x == 0 && retr(handles.InBagFraction_edit) < 1)); % Check if In Bag Fraction is <1

% Update the global variable:
assign_to_field(handles,res,'SVM','SampleWithReplacement')






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   LOADING                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function load_button_Callback(hObject, eventdata, handles)

global training_params_local classnames_local miscgui

[fname,pname] = uigetfile('*.mat','Select training set');
if fname==0 return; end

mf = matfile(fullfile(pname,fname));
set = mf.training_set;
if isfield(set,'training_params') && ~isempty(set.training_params) 
    training_params_local = set.training_params;
    % Check conflicts in the class specific parameters:
    flds = fieldnames(training_params_local.class_specific.spec);
    for ind1 = 1:numel(flds)
        if ~any(strcmp(flds{ind1},classnames_local))
            h = warndlg(['Unknow class ' flds{ind1} ', removing related parameters']);
            waitfor(h);
        end
    end
else 
    h = warndlg('You selected a training set with empty parameters, using defaults...');
    waitfor(h);
    training_params_local = [];
end

% For simplicity, just reload the whole figure:
miscgui.debugging.handles.training_params = training_params_GUI();

