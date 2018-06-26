% Main update function: 
function updateGUI(handles,varargin)

global trainingpx_local miscgui
% Process inputs:
ip = inputParser();
ip.addParameter('updateOldies',true);
ip.parse(varargin{:});

% Update the GUI
stacksnames = fieldnames(trainingpx_local);
if isfield(miscgui,'currentstack')
    stacknb = find(strcmp(miscgui.currentstack,stacksnames));
    currstack = trainingpx_local.(miscgui.currentstack);
    % Update the popup menu:
    set(handles.stackpopup,'String',stacksnames);
    set(handles.stackpopup,'Value',stacknb);
    % Computed the labeled frame:
    miscgui.imcomp = displayimage(currstack);
    % Display it:
    if ~isfield(miscgui, 'H_im') || ~isvalid(miscgui.H_im)
        miscgui.H_im = imshow(miscgui.imcomp);
    else
        set(miscgui.H_im ,'CData',miscgui.imcomp);
    end

    % Update the slider and its text:
    set(handles.stackslider, 'Min', 1);
    set(handles.stackslider, 'Max', currstack.nbframes);
    set(handles.stackslider, 'SliderStep', [1/currstack.nbframes , 10/currstack.nbframes ]);
    set(handles.stackslider, 'Value', currstack.currentframe_nb);
    set(handles.stacknbtext, 'String', ['/     ' num2str(currstack.nbframes)]);
    set(handles.edit_framenb, 'String', num2str(currstack.currentframe_nb));
    
    udapte_zpxtext(handles);
end

% Update the history of operations:
if ip.Results.updateOldies
    updateOldies();
end


% Image manippulation function
function imcomp = displayimage(stack)

global rgbmap_local classnames_local miscgui

alpharatio = .2;
stack.currentframe = preprocessing(stack.currentframe, miscgui.currentOP);
stack.currentframeRGB = grs2rgb(stack.currentframe,colormap('gray'));
imcomp = stack.currentframeRGB;
for indStr = 1:numel(classnames_local)
    if isclassvisible(classnames_local{indStr}) && isfield(stack.pixel,classnames_local{indStr}) && ~isempty(stack.pixel.(classnames_local{indStr}))
        overlay  = repmat(rgbmap_local(indStr,:)',numel(stack.pixel.(classnames_local{indStr})),1);
        [indx,indy] = ind2sub(size(stack.currentframe),stack.pixel.(classnames_local{indStr}));
        indx3 = repmat(indx',3,1);
        indy3 = repmat(indy',3,1);
        subs = [reshape(indx3,numel(indx3),1),reshape(indy3,numel(indy3),1),repmat((1:3)',numel(indx),1)];
        indcomp = sub2ind(size(stack.currentframeRGB),subs(:,1),subs(:,2),subs(:,3));
        imcomp(indcomp) = ...
            (1-alpharatio)*imcomp(indcomp) ...
            + alpharatio*overlay;
    end
end

function yesno = isclassvisible(classname)
global miscgui
if isfield(miscgui,'invisibleclasses')
    yesno = ~any(strcmp(miscgui.invisibleclasses,classname));
else
    yesno = true;
end

function updateOldies

    global trainingpx_local rgbmap_local classnames_local oldies miscgui hierarchy frame_processing_local
    
    new_oldie.trainingpx_local = trainingpx_local;
    new_oldie.rgbmap_local = rgbmap_local;
    new_oldie.classnames_local = classnames_local;
    new_oldie.miscgui = miscgui;
    new_oldie.miscgui.preloadedstack = {};
    new_oldie.hierarchy = hierarchy;
    new_oldie.frame_processing_local = frame_processing_local;
    
    % If we've had an "Undo" before, erase the following operations:
    if ~isempty(oldies) && oldies.currop < numel(oldies.ops)
        oldies((oldies.currop+ 1):end) = [];
    end
    
    if isempty(oldies) % First time this function is fired...
        oldies.currop = 1;
        oldies.ops = [new_oldie];
    elseif numel(oldies) < 20 % Until we have 20 operations saved 
        oldies.currop = oldies.currop + 1;
        oldies.ops(oldies.currop) = new_oldie;
    else % Otherwise, circshift and overwrite the oldest operation.
        oldies = circshift(oldies,-1);
        oldies(end) = new_oldie;
    end