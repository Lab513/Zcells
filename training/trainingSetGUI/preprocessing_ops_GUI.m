function varargout = preprocessing_ops_GUI(varargin)
% PREPROCESSING_OPS_GUI MATLAB code for preprocessing_ops_GUI.fig
%      PREPROCESSING_OPS_GUI, by itself, creates a new PREPROCESSING_OPS_GUI or raises the existing
%      singleton*.
%
%      H = PREPROCESSING_OPS_GUI returns the handle to a new PREPROCESSING_OPS_GUI or the handle to
%      the existing singleton*.
%
%      PREPROCESSING_OPS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PREPROCESSING_OPS_GUI.M with the given input arguments.
%
%      PREPROCESSING_OPS_GUI('Property','Value',...) creates a new PREPROCESSING_OPS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before preprocessing_ops_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to preprocessing_ops_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help preprocessing_ops_GUI

% Last Modified by GUIDE v2.5 18-Jun-2018 19:03:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @preprocessing_ops_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @preprocessing_ops_GUI_OutputFcn, ...
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

function preprocessing_ops_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to preprocessing_ops_GUI (see VARARGIN)

% Choose default command line output for preprocessing_ops_GUI
handles.I0 = varargin{1};
handles.IOP = varargin{1};
handles.OP = struct('name','intensity');

% Update handles structure
guidata(hObject, handles);

update_preview(handles);

uiwait(hObject)


function varargout = preprocessing_ops_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isfield(handles,'output')
    varargout{1} = handles.output.value;
else
    varargout{1} = [];
end

delete(hObject);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN BUTTON GROUP                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
function operations_btngrp_SelectionChangedFcn(hObject, eventdata, handles)

update_preview(handles);

function update_preview(handles)

h=get(handles.operations_btngrp,'SelectedObject');
operation = get(h,'Tag');


switch operation
    case 'intensity'
        OP.name = operation;
        IOP = preprocessing(handles.I0,OP);
    case 'gradient'
        OP.name = operation;
        methods = handles.method_popup.String;
        OP.method = methods{handles.method_popup.Value};
        IOP = preprocessing(handles.I0,OP);
    case 'average'
        OP.name = operation;
        OP.hsize = str2num(handles.average_hsize_edit.String);
        try
            IOP = preprocessing(handles.I0,OP);
        catch
            errordlg('hsize must be a scalar or 2-element vector of integer values')
            return
        end
    case 'disk'
        OP.name = operation;
        OP.radius = str2num(handles.disk_radius_edit.String);
        try
            IOP = preprocessing(handles.I0,OP);
        catch
            errordlg('radius must be an integer')
            return
        end
    case 'laplacian'
        OP.name = operation;
        OP.alpha = str2num(handles.laplacian_alpha_edit.String);
        try
            IOP = preprocessing(handles.I0,OP);
        catch
            errordlg('alpha must be a scalar in the range [0.0 1.0]')
            return
        end
    case 'gaussian'
        OP.name = operation;
        OP.sigma = str2num(handles.gaussian_sigma_edit.String);
        try
            IOP = preprocessing(handles.I0,OP);
        catch
            errordlg('sigma must be a scalar or 2-element vector of positive values')
            return
        end
    case 'LoG'
        OP.name = operation;
        OP.sigma = str2num(handles.LoG_sigma_edit.String);
        OP.hsize = str2num(handles.LoG_hsize_edit.String);
        try
            IOP = preprocessing(handles.I0,OP);
        catch
            errordlg('alpha must be a scalar in the range [0.0 1.0]')
            return
        end
    case 'customfunction'
        OP.name = operation;
        str = handles.customfile_edit.String;
        if isempty(str)
            return;
        end
        if isfile(str)
            OP.fhandle = evalfile(str);
        else
            OP.fhandle = str2func(str);
        end
        try
            IOP = preprocessing(handles.I0,OP);
        catch
            errordlg('Function handle is invalid')
            return
        end
        if ~(isnumeric(IOP) && isequal(size(IOP),size(handles.I0)))
            errordlg('Custom function must return an image of the same dimensions as the input')
            return
        end
end
handles.OP = OP;
handles.IOP = IOP;
imagesc(handles.IOP);
colormap('gray');
guidata(handles.preprocessing_gui, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TERMINATION                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function add_btn_Callback(hObject, eventdata, handles)
try
    dump = preprocessing(handles.I0,handles.OP);
catch
    errordlg('Sorry, something went wrong with the current operation. Can not add to the list');
    return;
end
handles.output = dirtypointer(handles.OP);
guidata(handles.preprocessing_gui, handles);
close(handles.preprocessing_gui);

function cancel_btn_Callback(hObject, eventdata, handles)
close(handles.preprocessing_gui);

function preprocessing_gui_CloseRequestFcn(hObject, eventdata, handles)

handles = rmfield(handles,'I0'); % I have to remove those because for some reason gui_mainfcn.m has a problem with non-handle fields in the handles structure on close request.
handles = rmfield(handles,'IOP');
handles = rmfield(handles,'OP');
guidata(hObject, handles);

if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPERATION PARAMETERS                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-------------IMGRADIENT----------------------%
function method_popup_Callback(hObject, eventdata, handles)
update_preview(handles)

function method_popup_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%-------------AVERAGE----------------------%
function average_hsize_edit_Callback(hObject, eventdata, handles)
update_preview(handles)

function average_hsize_edit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%-------------DISK AVERAGE----------------------%
function disk_radius_edit_Callback(hObject, eventdata, handles)
update_preview(handles)

function disk_radius_edit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%-------------LAPLACIAN----------------------%
function laplacian_alpha_edit_Callback(hObject, eventdata, handles)
update_preview(handles)

function laplacian_alpha_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to laplacian_alpha_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%-------------GAUSSIAN----------------------%
function gaussian_sigma_edit_Callback(hObject, eventdata, handles)
update_preview(handles)

function gaussian_sigma_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gaussian_sigma_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%-------------LAPLACIAN OF GAUSSIAN----------------------%
function LoG_hsize_edit_Callback(hObject, eventdata, handles)
update_preview(handles)

function LoG_hsize_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LoG_hsize_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function LoG_sigma_edit_Callback(hObject, eventdata, handles)
update_preview(handles)

function LoG_sigma_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LoG_sigma_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%-------------CUSTOM FUNCTION----------------------%
function customfile_edit_Callback(hObject, eventdata, handles)
update_preview(handles)

function customfile_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to customfile_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function customfile_btn_Callback(hObject, eventdata, handles)
[fn,pn] = uigetfile('*.m');
str = fullfile(pn,fn);
handles.customfile_edit.String = str;
update_preview(handles);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UTILITIES                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function func = evalfile(str)
oldDir = pwd;
fseps = strfind(str,filesep);
if ~isempty(fseps)
    dirname = str(1:fseps(end));
    name = str((fseps(end)+1):end);
    cd(dirname);
else
    name = str;
end
func = str2func(name(1:(end-2))); % Removing the '.m'
cd(oldDir);
