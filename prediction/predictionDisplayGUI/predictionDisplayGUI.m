function varargout = predictionDisplayGUI(varargin)
% PREDICTIONDISPLAYGUI MATLAB code for predictionDisplayGUI.fig
%      PREDICTIONDISPLAYGUI, by itself, creates a new PREDICTIONDISPLAYGUI or raises the existing
%      singleton*.
%
%      H = PREDICTIONDISPLAYGUI returns the handle to a new PREDICTIONDISPLAYGUI or the handle to
%      the existing singleton*.
%
%      PREDICTIONDISPLAYGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PREDICTIONDISPLAYGUI.M with the given input arguments.
%
%      PREDICTIONDISPLAYGUI('Property','Value',...) creates a new PREDICTIONDISPLAYGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before predictionDisplayGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to predictionDisplayGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help predictionDisplayGUI

% Last Modified by GUIDE v2.5 23-Dec-2017 13:17:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @predictionDisplayGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @predictionDisplayGUI_OutputFcn, ...
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


% --- Executes just before predictionDisplayGUI is made visible.
function predictionDisplayGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to predictionDisplayGUI (see VARARGIN)

% Choose default command line output for predictionDisplayGUI
handles.output = hObject;
handles.updateResultsTimer = ...
    timer('Period',5,...
    'StartDelay',30,... % Just to be safe
    'TimerFcn',{@watchparalleljobs, handles},...
    'ExecutionMode','fixedSpacing',...
    'Name','WatchJobsTimer'...
    );
start(handles.updateResultsTimer);

% Data Cursor:
dcm = datacursormode();
set(dcm,'UpdateFcn',{@myDCMupdate, handles});

% Update handles structure
guidata(hObject, handles);



function watchparalleljobs(hObject, evt, handles)


% Autosave:
autosave = get(handles.checkbox_autosave,'Value');
if autosave
    savefolder = get(handles.edit_autosave,'String');
else
    savefolder = '';
end

% Classifier
trainedpath = get(handles.edit_trainedset,'String');

ud = get(handles.listbox_stacks, 'UserData');
for ind1 = 1:numel(ud)
    res = ud(ind1).results;
    if strcmp(ud(ind1).State, 'running') ... % If job is running...
            && ~isempty(res) ... % ... and results is not empty ...
            && (strfind(class(res),'parallel.job') == 1) ... % ... and is actually a job ...
            && strcmp(res.State,'finished') % ... and the job state is finished:
        % Fetch outputs of job:
        res = fetchOutputs(res);
        ud(ind1).results = res{1};
        ud(ind1).State = 'finished';
        % If autosave, write results to disk:
        if autosave
            saveResults( ...
                    fullfile( ...
                                savefolder, ... 
                                ['results_' ud(ind1).fname] ...
                            ), ...
                    ud(ind1).results, ...
                    'stackFile',ud(ind1).fname, ...
                    'classifier',trainedpath, ...
                    'img',ud(ind1).midimg, ...
                    'ROI',ud(ind1).ROI ...
                    );
        end
    end
end
set(handles.listbox_stacks,'UserData',ud);
updateListbox(handles);

function txt = myDCMupdate(hObject,evt,handles)

pos = get(evt,'Position');
index = get(evt, 'DataIndex');


stackUD = getStackUD(handles);
if isempty(stackUD)
    return;
end

txt = {['[X,Y]: [' num2str(pos(1)) ',' num2str(pos(2)) ']'];...
       ['index: ',num2str(index)]};

classnames = fieldnames(stackUD.results);

if strcmp(stackUD.State,'finished')
    txt = [txt; {' '; 'Confidence (%):'}];

    for ind1 = 1:numel(classnames)
        score(ind1) = stackUD.results.(classnames{ind1}).scores(index);
    end
    [~, i] = sort(score,2,'descend');
    for ind1 = i
        txt = [txt; {['  - ' classnames{ind1} ': ' num2str(100*score(ind1),'%.1f')]}];
    end
end

function varargout = predictionDisplayGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function CollectParams_LaunchPredict(handles)

%%% Collect all parameters:

% Parallel processing:
str_clusters = get(handles.popup_clusters,'String');
cluster = str_clusters{get(handles.popup_clusters,'Value')};
indpdt = get(handles.checkbox_predictionsasjobs,'Value');
useparfor = get(handles.checkbox_useparfor,'Value');
if useparfor
    parforworkers = get(handles.edit_workersparfor,'String');
    if ~all(isstrprop(parforworkers,'digit'))
        error('The parfor workers value is not an integer')
    else
        parforworkers = str2num(parforworkers);
    end
else
    parforworkers = 0;
end

% Autosave:
autosave = get(handles.checkbox_autosave,'Value');
if autosave
    savefolder = get(handles.edit_autosave,'String');
else
    savefolder = '';
end

% trained classifier:
trained = get(handles.edit_trainedset,'UserData');
trainedpath = get(handles.edit_trainedset,'String');

% Backward compatibility for frame processing:
if ~isfield(trained, 'frame_processing') || isempty(trained.frame_processing)
    trained.frame_processing = {struct('name','Intensity')};
    warndlg('The specified Trained set file uses an old format that does not specify which image operations to use on frames. Defaulted to only using single-pixel intensity (this is probably fine)')
end
% Backward compatibility for PCA normalization:
if ~isfield(trained, 'feat_mu')
    trained.feat_mu = [];
    warndlg('The specified Trained set file uses an old format that does not specify the PCA µ values for normalization. Defaulted to non-normalized PCA (this is probably fine)')
end

% Frames:
selected = get(handles.uibuttongroup_framesselection,'SelectedObject');
selectedTag = get(selected,'Tag');
switch selectedTag
    case 'radiobutton_Allframes'
        frames = 1:numel(trained.frames);
    case 'radiobutton_subselframes'
        frames = trained.frames;
    case 'radiobutton_customframes'
        frames = str2num(get(handles.edit_customframes,'String'));
end


%%% Launch:
while(true)
    
    % Look for new stacks:
    stacks = get(handles.listbox_stacks,'UserData');
    firststack = find(...
                        strcmp(...
                                {stacks(:).State}, ...
                                'queued'), ...
                        1, 'first');
    if isempty(firststack) % No more queued
        break;
    end
    % Update state:
    stacks(firststack).State = 'running';
    set(handles.listbox_stacks,'UserData',stacks);
    updateListbox(handles);
    drawnow;
    %Launch prediction:
    stacks(firststack).results = RunPrediction(stacks(firststack).path,...
        trained.feat_extr,...
        trained.feat_mu,...
        trained.SVMs, ...
        trained.classnames, ...
        'FramesSelection',frames,...
        'use_features', trained.frame_processing, ...
        'IndependentJob',indpdt,...
        'Cluster',cluster,...
        'SaveResults',savefolder,...
        'SaveName',['results_' stacks(firststack).fname],...
        'Parallelize', parforworkers, ...
        'Verbosity',0 ...
        );
    % If not launching independent jobs:
    if ~indpdt
        stacks(firststack).State = 'finished';
        if autosave
            saveResults( ...
                    fullfile( ...
                                savefolder, ... 
                                ['results_' stacks(firststack).fname] ...
                            ), ...
                    stacks(firststack).results, ...
                    'stackFile',stacks(firststack).fname, ...
                    'classifier',trainedpath, ...
                    'img',stacks(firststack).midimg, ...
                    'ROI',stacks(firststack).ROI ...
                    );
        end
    end
    set(handles.listbox_stacks,'UserData',stacks);
end
updateListbox(handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   SET BOX                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function edit_trainedset_Callback(hObject, eventdata, handles)
loadtrainedset(get(hObject,'String'),handles);

function edit_trainedset_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_trainedset_Callback(hObject, eventdata, handles)
[fname, pname]= uigetfile('*.mat','Please pick a trained classifier file');
if isnumeric(fname) && fname == 0
    return;
end
trainedpath = fullfile(pname,fname);
set(handles.edit_trainedset,'String',trainedpath);
loadtrainedset(trainedpath,handles)

function loadtrainedset(trainedpath, handles)


if isempty(trainedpath)
    errordlg('No trained classifier specified / File not valid','No classifier');
    return;
end
set(handles.loadingtext,'Visible','on')
drawnow
trained = load(trainedpath);
if ~strcmp(trained.type_of_file,'trained classifier')
    errordlg({trainedpath 'is not a valid classifier file'},'Invalid classifier')
    return;
end
dump.classnames = trained.classnames;
dump.rgbmap = trained.rgbmap;
set(handles.uibuttongroup_display,'UserData',dump);
set(handles.edit_trainedset,'UserData',trained); % This will eat up some memory but should speed up the launchprediction process...
set(handles.loadingtext,'Visible','off')
updateDisplayLists(handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   PREDICTION BOX                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%% Manual Prediction:

function listbox_stacks_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns listbox_stacks contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_stacks
if strcmp(get(handles.predict_GUI,'SelectionType'),'open')
    ud = get(hObject,'UserData');
    if ~isempty(ud)
        uiwait(msgbox(ud(get(hObject,'Value')).path,'Complete file path','modal'));
    end
end
updateDisplay(handles);

function listbox_stacks_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'UserData',...
    struct('fname',{},'path',{},'midimg',{},'results',{},'ROI',{},'State',{})... % Empty struct array
    );
set(hObject,'String',{});

function stackUD = getStackUD(handles, varargin)

if nargin == 2
    stacknb = varargin{1};
else
    stacknb = get(handles.listbox_stacks,'Value');
end
ud = get(handles.listbox_stacks,'UserData');
if ~isempty(ud)
    stackUD = ud(stacknb);
else
    stackUD = [];
end

function setStackUD(handles, stackUD, varargin)

if nargin == 3
    stacknb = varargin{1};
else
    stacknb = get(handles.listbox_stacks,'Value');
end
ud = get(handles.listbox_stacks,'UserData');
ud(stacknb) = stackUD;
set(handles.listbox_stacks,'UserData',ud);

function pushbutton_addstacks_Callback(hObject, eventdata, handles)

[fnames, pname] = uigetfile({'*.mat';'*.tif'},'Select one or more stacks','MultiSelect','On');
if isnumeric(fnames) && fnames == 0
    return;
end
if ~iscell(fnames)
    fnames = {fnames};
end

% Load stacks:
set(handles.loadingtext,'Visible','on')
drawnow
for ind1 = 1:numel(fnames)
    stacks(ind1) = newstack(pname,fnames{ind1});
end
set(handles.loadingtext,'Visible','off')
drawnow

% Update GUI and userdata
ud = get(handles.listbox_stacks,'UserData');
set(handles.listbox_stacks,'Value',1) % Safer
set(handles.listbox_stacks,'UserData',[ud,stacks])

updateListbox(handles)
updateDisplay(handles)

function stack = newstack(pname,fname)
stack.fname = fname;
stack.path = fullfile(pname,fname);
stack.midimg = loadmidimg(stack.path);
stack.results = [];
stack.ROI = [];
stack.State = 'queued';

function updateListbox(handles)
ud = get(handles.listbox_stacks,'UserData');
strings = {};
for ind1 = 1:numel(ud)
    
    switch ud(ind1).State
        case 'queued'
            color = [.5 .5 .5];
        case 'running'
            color = [.7 .5 0];
        case 'finished'
            color = [0 1 0];
    end
    strings{ind1} = pimpmystrings(ud(ind1).fname,color);
end
set(handles.listbox_stacks,'String',strings);
drawnow

function I = loadmidimg(path)
% Load the frame in the middle of the stack:

[~,~,ext] = fileparts(path);

switch ext
    case '.mat'
        mf = matfile(path);
        a = whos(mf);
        stack_ind = strcmp({a(:).name},'stack');
        if any(stack_ind)
            numframes = a(stack_ind).size;
        else
            errordlg({ path 'is not a valid stack file'},'Invalid stack');
            error([ path ' is not a valid stack file']);
        end
        I = cell2mat(mf.stack(1,round(numframes(2)/2)));
    case '.tif'
        info = imfinfo(path);
        numframes = numel(info);
        I = uint16(imread(path, round(numframes/2)));
end
I = imadjust(I);

function pushbutton_remove_Callback(hObject, eventdata, handles)

ud = get(handles.listbox_stacks,'UserData');
v = get(handles.listbox_stacks,'Value');

if isempty(ud)
    return;
end
ud(v) = [];

set(handles.listbox_stacks,'Value',1) % Safer
set(handles.listbox_stacks,'UserData',ud);

updateListbox(handles)
updateDisplay(handles)

function pushbutton_launchprediction_Callback(hObject, eventdata, handles)
watchmanual('manual',handles);
CollectParams_LaunchPredict(handles);

function radio_predictstacks_Callback(hObject, eventdata, handles)
watchmanual('manual',handles);

function watchmanual(state, handles)

switch state
    case 'manual'
        set(handles.radio_predictstacks,'Value',1);
        set(handles.radio_watch,'Value',0);
    case 'watch'
        set(handles.radio_predictstacks,'Value',0);
        set(handles.radio_watch,'Value',1);
end



%%% Watchfolder Prediction:

function radio_watch_Callback(hObject, eventdata, handles)
watchmanual('watch',handles);

function edit_watchfolder_Callback(hObject, eventdata, handles)

function edit_watchfolder_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_selectwatch_Callback(hObject, eventdata, handles)
d = uigetdir('','Please pick a folder to watch');
set(handles.edit_watchfolder,'String',d);

function pushbutton_startwatch_Callback(hObject, eventdata, handles)

watchmanual('watch',handles);
isTurningOn = get(hObject,'Value');

if ~isTurningOn
    t = get(hObject,'UserData');
    stop(t);
    delete(t);
    set(hObject,'String','Start watching');
else
    d = get(handles.edit_watchfolder,'String');
    t = timer('Period',1,'TimerFcn',{@watchfolder, d, handles},...
        'ExecutionMode','fixedSpacing',...
        'Name','WatchFolderTimer',...
        'UserData',dir(d));
    start(t);
    set(hObject,'String','Stop watching');
    set(hObject,'UserData',t);
end

function watchfolder(hObject, eventdata, d, handles)
udWatch = get(hObject,'UserData');
list = dir(d);
newfiles = setdiff({list.name},{udWatch.name});

    
% Launch predictions:
if ~isempty(newfiles)
    set(hObject,'UserData',list);
    % Update listbox:
    udList = get(handles.listbox_stacks,'UserData');
    for ind1 = 1:numel(newfiles)
        newstacks(ind1) = newstack(d,udWatch(ind1).name);
    end
    set(handles.listbox_stacks,'UserData',[udList,newstacks]);
    % Launch Predictions:
    CollectParams_LaunchPredict(handles);
end



%%% Autosave:

function checkbox_autosave_Callback(hObject, eventdata, handles)

function edit_autosave_Callback(hObject, eventdata, handles)

function edit_autosave_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_autosave_Callback(hObject, eventdata, handles)
d = uigetdir('','Please pick a save folder');
set(handles.edit_autosave,'String',d);




%%% ROI

function pushbutton_addROI_Callback(hObject, eventdata, handles)

UD = getStackUD(handles);
if isempty(UD), return; end

newROI = roipoly();
if ~isempty(UD.ROI)
    UD.ROI = newROI | UD.ROI;
else
    UD.ROI = newROI;
end
setStackUD(handles,UD);
updateDisplay(handles);

function pushbutton_deleteROI_Callback(hObject, eventdata, handles)

UD = getStackUD(handles);
if isempty(UD) return; end

newROI = roipoly();
UD.ROI = ~newROI & UD.ROI;
setStackUD(handles,UD);
updateDisplay(handles);

function checkbox_allstacksROI_Callback(hObject, eventdata, handles)




%%% Frames

function edit_customframes_Callback(hObject, eventdata, handles)
% TODO: Check if valid

function edit_customframes_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   PARALLEL BOX                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function checkbox_cluster_Callback(hObject, eventdata, handles)

function popup_clusters_Callback(hObject, eventdata, handles)

function popup_clusters_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

cls = parallel.clusterProfiles();
set(hObject,'String',cls);

function checkbox_predictionsasjobs_Callback(hObject, eventdata, handles)

function checkbox_useparfor_Callback(hObject, eventdata, handles)

function edit_workersparfor_Callback(hObject, eventdata, handles)

function edit_workersparfor_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   DISPLAY BOX                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function updateDisplayLists(handles)
ud = get(handles.uibuttongroup_display,'UserData');
strs = pimpmystrings(ud(:).classnames,ud.rgbmap);
set(handles.listbox_classif,'String',strs);
set(handles.listbox_classif,'Value',1);
drawnow

function listbox_confidence_Callback(hObject, eventdata, handles)
updateDisplay(handles)

function listbox_confidence_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function listbox_classif_Callback(hObject, eventdata, handles)
updateDisplay(handles)

function listbox_classif_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function updateDisplay(handles)

stackUD = getStackUD(handles);

% Enable / Disable radio buttons if results data is available:
if isempty(stackUD) || ~strcmp(stackUD.State,'finished')
    set(handles.uibuttongroup_display,'SelectedObject',handles.radio_orig_img);
    set(handles.radio_classif_oneclass,'enable','off');
    set(handles.radio_conf_oneclass,'enable','off');
    set(handles.listbox_classif,'enable','off');
else
    set(handles.radio_classif_oneclass,'enable','on');
    set(handles.radio_conf_oneclass,'enable','on');
    set(handles.listbox_classif,'enable','on');
end

if isempty(stackUD)
    cla(handles.axes1)
    return;
end

% Check which one is selected:
selected = get(handles.uibuttongroup_display,'SelectedObject');
selected = get(selected,'Tag');
udD = get(handles.uibuttongroup_display,'UserData');

% Apply the relevant action:
switch selected
    case 'radio_orig_img' % Show middle frame
        imshow(overlayROI(stackUD.midimg,stackUD.ROI),'Parent', handles.axes1);
        colorbar(handles.axes1,'off');
        
    case 'radio_classif_oneclass' % Show classification result on selected classes
        vals = get(handles.listbox_classif,'Value');
        whichclasses = udD.classnames(vals);
        colors = udD.rgbmap(vals,:);
        [I, ~] = show_classes( ...
                                stackUD.results, ...
                                size(stackUD.midimg), ...
                                'alpha',1,...
                                'WhichClasses',whichclasses, ...
                                'Colors',colors ...
                             );
        imshow(I,'Parent', handles.axes1);
        colorbar(handles.axes1,'off');
        
    case 'radio_conf_oneclass' % Show confidence for selected classes
        vals = get(handles.listbox_classif,'Value');
        whichclasses = udD.classnames(vals);
        colors = udD.rgbmap(vals,:);
        [I, ~] = show_conf( ...
                            stackUD.results, ...
                            size(stackUD.midimg), ...
                            'WhichClasses',whichclasses, ...
                            'Colormap',jet ...
                           );
        imshow(I,'Parent', handles.axes1);
        colormap(jet);
        c = colorbar(handles.axes1,'Location','east');
        set(c,'Color',[1 1 1]);
        set(c,'LineWidth',2);
        set(c,'FontSize',12);
end
drawnow

function RGB = overlayROI(I,ROI)

RGB = grs2rgb(I,gray());
if ~isempty(ROI)
    R = RGB(:,:,1);
    ROI = xor(ROI, imerode(ROI,strel('disk',4)));
    R(ROI) = 1;
    RGB(:,:,1) = R;
end

function uibuttongroup_display_SelectionChangedFcn(hObject, eventdata, handles)
updateDisplay(handles);





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   TOOLBAR                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function uipushtool_saveres_ClickedCallback(hObject, eventdata, handles)

[fname, pname, findx] = ...
    uiputfile( ...
        {'*.mat','Classification results (*.mat)'; ...
        '*.tif','Current image (*.tif)'; ...
        '*.png','Current image (*.png)'; ...
        '*.jpg','Current image (*.jpg)'; ...
        }, ...
        'Save as', 'results.mat' ...
    );
if isnumeric(fname) && fname == 0
    return;
end
imgfmts = {'dump', 'tif', 'png', 'jpg'};

if findx == 1
    stackUD = getStackUD(handles);
    if strcmp(stackUD.State, 'finished')
        saveResults( ...
                    fullfile(pname,fname), ...
                    stackUD.results, ...
                    'stackFile',stackUD.fname, ...
                    'classifier',get(handles.edit_trainedset,'String'), ...
                    'img',stackUD.midimg, ...
                    'ROI',stackUD.ROI ...
                    );
    else
        errordlg('Classification was not run on this stack yet','No classif');
    end
else
    img = get(handles.axes1,'Children');
    img = get(img,'CData');
    imwrite(img,fullfile(pname,fname),imgfmts{findx});
end


function uipushtool_open_ClickedCallback(hObject, eventdata, handles)

trained = get(handles.edit_trainedset,'UserData');
if isempty(trained)
    warndlg('Select a classifier first please')
    return
end

[fnames, pname] = uigetfile('*.mat','Select one or more results file','MultiSelect','On');
if isnumeric(fnames) && fnames == 0
    return;
end
if ~iscell(fnames)
    fnames = {fnames};
end

% Load stacks:
set(handles.loadingtext,'Visible','on')
drawnow
for ind1 = 1:numel(fnames)
    res = load(fullfile(pname,fnames{ind1}));
    if ~strcmp(res.type_of_file,'results')
        warndlg({fnames{ind1},' is not a valid results file. Skipping...'},'Invalid file');
    elseif ~(numel(fieldnames(res.results)) == numel(trained.classnames) ...
            && all(cellfun(@(x) any(strcmp(x,trained.classnames)),fieldnames(res.results))))
        warndlg({fnames{ind1},': mismatch between class names in classifier and results. Skipping...'},'Wrong classifier');
    else
        stacks(ind1).results = res.results;
        if isfield(res,'img')
            stacks(ind1).midimg = res.img;
        else
            img = [];
        end
        stacks(ind1).fname = fnames{ind1};
        stacks(ind1).path = fullfile(pname,fnames{ind1});
        if isfield(res,'ROI')
            stacks(ind1).ROI = res.ROI;
        else
            stacks(ind1).ROI = [];
        end
        stacks(ind1).State = 'finished';
    end   
end
set(handles.loadingtext,'Visible','off')
drawnow

% Update GUI and userdata
ud = get(handles.listbox_stacks,'UserData');
set(handles.listbox_stacks,'Value',1) % Safer
set(handles.listbox_stacks,'UserData',[ud,stacks])

updateListbox(handles)
updateDisplay(handles)


% --- Executes when user attempts to close predict_GUI.
function predict_GUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to predict_GUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
stop(handles.updateResultsTimer);
delete(handles.updateResultsTimer);
delete(hObject);
