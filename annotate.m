% xinput set-prop 12 306 1 0

function varargout = annotate(varargin)
% ANNOTATE MATLAB code for annotate.fig
%      ANNOTATE, by itself, creates a new ANNOTATE or raises the existing
%      singleton*.
%
%      H = ANNOTATE returns the handle to a new ANNOTATE or the handle to
%      the existing singleton*.
%
%      ANNOTATE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANNOTATE.M with the given input arguments.
%
%      ANNOTATE('Property','Value',...) creates a new ANNOTATE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before annotate_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to annotate_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help annotate

% Last Modified by GUIDE v2.5 08-Apr-2017 20:51:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @annotate_OpeningFcn, ...
                   'gui_OutputFcn',  @annotate_OutputFcn, ...
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



% --- Executes just before annotate is made visible.
function annotate_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to annotate (see VARARGIN)

global int_curr_video; % current video number in the str_dir folder.
global file_prefix;    % prefix string for the image/frame files 
global str_dir;        % 'self shot' or 'from web'
global int_max_videos; % maximum number of videos folder given by str_dir
global bool_show_track_box; % Boolean, whether to display tracked boxes
global bool_mode_annotate;  % Boolean, 'ANNOTATE' mode or 'VIEW' mode
global bool_control_pressed;% Boolean, indicates if CTRL is currently pressed
global bool_shift_pressed;  % Boolean, indicates if SHIFT is currently pressed
global bool_alt_pressed;    % Boolean, indicates if ALT is currently pressed

bool_show_track_box = false;
bool_mode_annotate = false;

bool_control_pressed = false;
bool_shift_pressed = false;
bool_alt_pressed = false;

file_prefix = 'self';
str_dir = 'self shot';

int_max_videos = length(dir(fullfile(strcat('/home/is/Occlusion Video Data/',str_dir),strcat(file_prefix,'*'))));
int_curr_video = 1;

% Initialize all other variables
load_curr_video(handles);

% Choose default command line output for annotate
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);



% % BELOW PART Experimentally commented. No startup issues so far.
% This sets up the initial plot - only do when we are invisible
% so window can get raised using annotate.
%if strcmp(get(hObject,'Visible'),'off')
%    imshow(imread(fullfile(str_imDir, list_imFiles{int_curr_frame})));
%end

% UIWAIT makes annotate wait for user response (see UIRESUME)
% uiwait(handles.figure1);



% --- Outputs from this function are returned to the command line.
function varargout = annotate_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
disp('---------------------------------------------');



function load_curr_bbox(handles)
% Initializes all the variables required for a new file, and displays the
% first frame. Update the int_curr_bbox BEFORE calling this function.

global bool_is_paused;  % Boolean, indicates if the playback is paused
global int_curr_frame;  % number of the frame currently in view
global int_max_frames;  % maximum possible frame number for the current video
global str_curr_video_name; % current video name
global int_start_frame; % first frame in the current chunk
global int_end_frame;   % last frame in the current chunk
global int_curr_chunk;  % current chunk number
global int_max_chunks;  % maximum number of chunks in current video
global int_curr_bbox;   % current bounding box
global int_max_bboxes;  % maximum number of bounding boxes in current chunk
global str_curr_chunk_name; % current chunk name (e.g. '00001_00500')
global int_max_videos;  % maximum number of videos folder given by str_dir
global arr_tracked_boxes;   % array with tracked box coordinates for each frame in chunk
global str_boxdir;      % path of directory where .box files are stored

axes(handles.axes1);

if int_curr_bbox > int_max_bboxes
    int_curr_chunk = int_curr_chunk + 1;
    load_curr_chunk(handles)
else
    bool_is_paused = true;

    int_curr_frame = int_start_frame; % default
    int_max_frames = int_end_frame;

    file_track = fullfile(str_boxdir, sprintf('%s_%03d.track',str_curr_chunk_name,int_curr_bbox));
    arr_tracked_boxes = dlmread(file_track);

    display_curr_frame(handles)
    
    display_tracking_box(handles) % ONLY FOR FIRST FRAME

    % Update corresponding GUI text
    set(handles.text_curr_video, 'String', ...
        sprintf('Video: %s        Chunk: %s        BBox: %d', ...
                str_curr_video_name, str_curr_chunk_name, int_curr_bbox));
    set(handles.text_status, 'String', ...
        sprintf('Max Videos: %d        Max Chunks: %d        Max BBoxes: %d', ...
                int_max_videos, int_max_chunks, int_max_bboxes));
    set(handles.text_info, 'String', 'Ready to play.');
end



function load_curr_chunk(handles)
% Initializes all the variables required for a new file, and displays the
% first frame. Update the int_curr_chunk BEFORE calling this function.

global int_curr_video;  % current video number in the str_dir folder.
global int_start_frame; % first frame in the current chunk
global int_end_frame;   % last frame in the current chunk
global int_curr_chunk;  % current chunk number
global int_max_chunks;  % maximum number of chunks in current video
global int_curr_bbox;   % current bounding box
global int_max_bboxes;  % maximum number of bounding boxes in current chunk
global list_chunks;     % list of chunks filenames
global str_boxdir;      % path of directory where .box files are stored
global str_curr_chunk_name; % current chunk name (e.g. '00001_00500')

if int_curr_chunk > int_max_chunks
    int_curr_video = int_curr_video + 1;
    load_curr_video(handles)
else
    [~,str_curr_chunk_name,~] = fileparts(list_chunks{int_curr_chunk});
    int_start_frame = str2num(str_curr_chunk_name(1:5));
    int_end_frame = str2num(str_curr_chunk_name(7:11));

    % TODO read .box file and get list of bboxes
    list_bboxes = cell(0,1);
    fid = fopen(fullfile(str_boxdir,list_chunks{int_curr_chunk}));
    tline = fgetl(fid);
    i=1;
    while ischar(tline)
        list_bboxes{end+1,1} = tline;
        i=i+1;
        tline = fgetl(fid);
    end
    fclose(fid);

    int_max_bboxes = length(list_bboxes);

    int_curr_bbox = 1;
    load_curr_bbox(handles)
end



function load_curr_video(handles)
% Initializes all the variables required for a new file, and displays the
% first frame. Update the int_curr_video BEFORE calling this function.

global int_max_frames;  % maximum possible frame number for the current video
global str_dir;         % contains 'self shot' or 'from web'
global int_curr_video;  % current video number in the str_dir folder.
global str_imDir;       % parent dir of where the image/frame files are % the complete path of the current video folder
global list_imFiles;    % cell of all image/frame filenames (e.g. self00021_00023.jpg) % all '*.jpg' file names in the current video folder.
global file_prefix;     % prefix string for the image/frame files 
global str_curr_video_name; % current video name
global int_curr_chunk;  % current chunk number
global int_max_chunks;  % maximum number of chunks in current video
global list_chunks;     % list of chunks filenames
global str_boxdir;      % path of directory where .box files are stored
global int_max_videos;  % maximum number of videos folder given by str_dir

if int_curr_video < 1
    int_curr_video = 1;
elseif int_curr_video > int_max_videos
    int_curr_video = int_max_videos;
end

% building imDir string
str_curr_video_name = sprintf('%s%05d',file_prefix,int_curr_video); 
str_imDir = fullfile('/home/is/Occlusion Video Data', str_dir, str_curr_video_name);
imageList = dir(fullfile(str_imDir, '*.jpg'));
list_imFiles = {imageList.name};
int_max_frames = length(imageList);
clear imageList

% TODO: should use axes(handles??) here before imshow??? -- IMPORTANT when
% using multiple axes
% imshow(imread(fullfile(str_imDir, list_imFiles{int_curr_frame}))); % shifted to bbox

% read files and populate int_max_chunks
str_boxdir = fullfile(str_imDir, 'bboxes');
chunksList = dir(fullfile(str_boxdir, '*.box'));
list_chunks = {chunksList.name}; 
int_max_chunks = length(chunksList);
clear chunksList

int_curr_chunk = 1;
load_curr_chunk(handles)



% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, ~, ~)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
global bool_is_paused; % Boolean, indicates if the playback is paused

bool_is_paused = true;
pause(0.01);
% TODO: DELETE ALL OTHER VARIABLES???
delete(hObject);



% --- Executes on button press in button_pause.
function button_pause_Callback(~, ~, handles)
% hObject    handle to button_pause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global bool_is_paused; % Boolean, indicates if the playback is paused

bool_is_paused = ~bool_is_paused;
pause(0.01); % So that the thread playing the file can stop

% divert focus so that keyboard callback is only triggered on figure 1
% and not the button as well.
uicontrol(handles.text_status); 
if ~bool_is_paused
    play(handles);
else
    paused(handles);
end



function paused(handles)
global bool_is_paused; % Boolean, indicates if the playback is paused
bool_is_paused = true;
set(handles.text_info, 'String', 'PAUSED');
set(handles.button_pause,'String','Play');
pause(0.05)
display_curr_frame(handles)



function play(handles) 
% ONLY 1 thread should run this when bool_is_paused==false

global bool_is_paused; % Boolean, indicates if the playback is paused
global int_curr_frame; % number of the frame currently in view
global int_max_frames; % maximum possible frame number for the current video

axes(handles.axes1);
while ~bool_is_paused
    set(handles.text_info, 'String', 'PLAYING');
    set(handles.button_pause,'String','Pause');
    
    int_curr_frame = int_curr_frame + 1;
    if int_curr_frame > int_max_frames
        int_curr_frame = int_max_frames;
        bool_is_paused = true;
        set(handles.text_info,'String','Reached last frame in chunk!');
    end
    
    display_curr_frame(handles)
    
    pause(0.001); % some playback speed control, apparently...
end



function display_curr_frame(handles)
global int_curr_frame;  % number of the frame currently in view
global str_imDir;       % parent dir of where the image/frame files are % the complete path of the current video folder
global list_imFiles;    % cell of all image/frame filenames (e.g. self00021_00023.jpg) % all '*.jpg' file names in the current video folder.
global bool_show_track_box; % Boolean, whether to display tracked boxes
global img_curr_frame;  % image array of current frame
global int_start_frame; % first frame in the current chunk

axes(handles.axes1);

cla;

img_curr_frame = imread(fullfile(str_imDir, list_imFiles{int_curr_frame}));

imshow(img_curr_frame);
set(handles.text_curr_frame,'String',int_curr_frame); % Show the current frame on the GUI

display_tracklet(handles);

if bool_show_track_box || int_curr_frame == int_start_frame
    display_tracking_box(handles)
end

drawnow;



% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

global int_curr_frame; % number of the frame currently in view
global int_max_frames; % maximum possible frame number for the current video
global bool_is_paused; % Boolean, indicates if the playback is paused
global bool_control_pressed;% Boolean, indicates if CTRL is currently pressed
global bool_shift_pressed;  % Boolean, indicates if SHIFT is currently pressed
global bool_alt_pressed;    % Boolean, indicates if ALT is currently pressed
global int_start_frame;     % first frame in the current chunk
global bool_show_track_box; % Boolean, whether to display tracked boxes
global bool_mode_annotate;  % Boolean, 'ANNOTATE' mode or 'VIEW' mode

switch eventdata.Key
    case 'leftarrow'
        if bool_shift_pressed
            button_prev_bbox_Callback(hObject, eventdata, handles)
        elseif bool_alt_pressed
            button_prev_chunk_Callback(hObject, eventdata, handles)
        elseif bool_control_pressed
            button_prev_video_Callback(hObject, eventdata, handles);
        else
            int_curr_frame = int_curr_frame - 10;
            if int_curr_frame < int_start_frame
                int_curr_frame = int_start_frame;
                set(handles.text_info, 'String', 'Reached first frame!');
            end
            display_curr_frame(handles);
        end
    case 'rightarrow'
        if bool_shift_pressed
            button_next_bbox_Callback(hObject, eventdata, handles)
        elseif bool_alt_pressed
            button_next_chunk_Callback(hObject, eventdata, handles)
        elseif bool_control_pressed
            button_next_video_Callback(hObject, eventdata, handles);
        else
            int_curr_frame = int_curr_frame + 10;
            if int_curr_frame > int_max_frames
                int_curr_frame = int_max_frames;
                set(handles.text_info,'String','Reached last frame in chunk!');
            end
            display_curr_frame(handles);
        end
    case {'q', 'j'}
        int_curr_frame = int_curr_frame - 1;
        if int_curr_frame < int_start_frame
            int_curr_frame = int_start_frame;
            set(handles.text_info, 'String', 'Reached first frame!');
        end
        display_curr_frame(handles);
    case {'e', 'l'}
        int_curr_frame = int_curr_frame + 1;
        if int_curr_frame > int_max_frames
            int_curr_frame = int_max_frames;
            set(handles.text_info,'String','Reached last frame in chunk!');
        end
        display_curr_frame(handles);
    case 'space'
        bool_is_paused = ~bool_is_paused;
        if ~bool_is_paused
            play(handles);
        else
            paused(handles);
        end
    case 'return'
        enter_pressed(handles,1);
    case 'control'
        bool_control_pressed = true;
    case 'shift'
        bool_shift_pressed = true;
    case 'alt'
        bool_alt_pressed = true;
    case 't'
        set(handles.toggle_track_box,'Value',~bool_show_track_box);
        toggle_track_box_Callback(hObject, eventdata, handles);
    case 'a'
        if bool_control_pressed
            set(handles.toggle_mode,'Value',~bool_mode_annotate);
            toggle_mode_Callback(hObject, eventdata, handles);
        end
    case 'r'
        if bool_control_pressed
            set(handles.checkbox_rewrite_file,'Value',~get(handles.checkbox_rewrite_file, 'Value'));
            checkbox_rewrite_file_Callback(hObject, eventdata, handles);
        end
    case '0'
        enter_pressed(handles,0);
    case 'f'
        enter_pressed(handles,-1);
    case 'b'
        enter_pressed(handles,-2);
    otherwise
        disp(eventdata.Key); % remove after dev.
end
%downarrow
%uparrow
%backquote
%alt
%control



% --- Executes on key release with focus on figure1 or any of its controls.
function figure1_WindowKeyReleaseFcn(~, eventdata, ~)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)

global bool_control_pressed;% Boolean, indicates if CTRL is currently pressed
global bool_shift_pressed;  % Boolean, indicates if SHIFT is currently pressed
global bool_alt_pressed;    % Boolean, indicates if ALT is currently pressed

switch eventdata.Key
    case 'control'
        bool_control_pressed = false;
    case 'shift'
        bool_shift_pressed = false;
    case 'alt'
        bool_alt_pressed = false;
end



function enter_pressed(handles,int_focc)
global bool_mode_annotate;  % Boolean, 'ANNOTATE' mode or 'VIEW' mode
global str_boxdir;          % path of directory where .box files are stored
global int_curr_bbox;       % current bounding box
global str_curr_chunk_name; % current chunk name (e.g. '00001_00500')
global int_curr_frame;      % number of the frame currently in view

if int_focc == 1
    int_focc = int_curr_frame;
end
if bool_mode_annotate
    % Ensure no files are overwritten by mistake.
    str_fullfile = fullfile(str_boxdir, sprintf('%s_%03d.focc',str_curr_chunk_name,int_curr_bbox));
    if exist(str_fullfile,'file')==2 && ~get(handles.checkbox_rewrite_file,'Value')
        paused(handles);
        h = msgbox({'File Exists!' 'Please enable Rewrite File'},'Warning');
    else
        paused(handles);
        
        % h = myquestdlg(sprintf('Selecting frame %d as f_occ.',int_focc));
        % if strcmp(h,'Yes')
        %     fileID = fopen(str_fullfile,'w');
        %     fprintf(fileID,'%d', int_focc); % Integers.
        %     fclose(fileID);
        % end
        
        % Construct a questdlg
        if int_focc > 0
            event_desc = 'OCCLUSION';
        elseif int_focc == 0
            event_desc = 'NO OCCLUSION';
        elseif int_focc == -1
            event_desc = 'TRACKER FAILURE';
        elseif int_focc == -2
            event_desc = 'BAD BBOX';
        end
        choice = questdlg(sprintf('Selecting frame %d (%s) as f_occ.\n\nHit ESCAPE to ABORT.',int_focc,event_desc), ...
            'Confirm Action', ...
            'Continue','Continue','Continue');
        % Handle response
        switch choice
            case 'Continue'
                fileID = fopen(str_fullfile,'w');
                fprintf(fileID,'%d', int_focc); % Integers.
                fclose(fileID);
        end
    end
end



% --- Executes on button press in button_next_video.
function button_next_video_Callback(~, ~, handles)
% hObject    handle to button_next_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global int_max_videos;  % maximum number of videos folder given by str_dir
global int_curr_video;  % current video number in the str_dir folder.

if int_curr_video < int_max_videos
    int_curr_video = int_curr_video + 1;
    load_curr_video(handles); % initializes the other variables corresponding to the new video, and displays the first frame.
else
    set(handles.text_info, 'String', 'Reached last video!');
end
uicontrol(handles.text_status); % divert focus



% --- Executes on button press in button_prev_video.
function button_prev_video_Callback(~, ~, handles)
% hObject    handle to button_prev_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global int_curr_video;  % current video number in the str_dir folder.

if int_curr_video > 1
    int_curr_video = int_curr_video - 1;
    load_curr_video(handles); % initializes the other variables corresponding to the new video, and displays the first frame.
else
    set(handles.text_info, 'String', 'Reached first video!');
end
uicontrol(handles.text_status); % divert focus



% --- Executes on button press in button_next_bbox.
function button_next_bbox_Callback(hObject, eventdata, handles)
% hObject    handle to button_next_bbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global int_curr_bbox;   % current bounding box
global int_max_bboxes;  % maximum number of bounding boxes in current chunk

if int_curr_bbox < int_max_bboxes
    int_curr_bbox = int_curr_bbox + 1;
    load_curr_bbox(handles);
else
    % set(handles.text_info, 'String', 'Reached last bbox!');
    button_next_chunk_Callback(hObject, eventdata, handles);
end
uicontrol(handles.text_status); % divert focus



% --- Executes on button press in button_prev_bbox.
function button_prev_bbox_Callback(hObject, eventdata, handles)
% hObject    handle to button_prev_bbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global int_curr_bbox;   % current bounding box

if int_curr_bbox > 1
    int_curr_bbox = int_curr_bbox - 1;
    load_curr_bbox(handles);
else
    % set(handles.text_info, 'String', 'Reached first bbox!');
    button_prev_chunk_Callback(hObject, eventdata, handles);
end
uicontrol(handles.text_status); % divert focus



% --- Executes on button press in button_next_chunk.
function button_next_chunk_Callback(hObject, eventdata, handles)
% hObject    handle to button_next_chunk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global int_curr_chunk;  % current chunk number
global int_max_chunks;  % maximum number of chunks in current video

if int_curr_chunk < int_max_chunks
    int_curr_chunk = int_curr_chunk + 1;
    load_curr_chunk(handles);
else
    % set(handles.text_info, 'String', 'Reached last chunk!');
    button_next_video_Callback(hObject, eventdata, handles);
end
uicontrol(handles.text_status);



% --- Executes on button press in button_prev_chunk.
function button_prev_chunk_Callback(hObject, eventdata, handles)
% hObject    handle to button_prev_chunk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global int_curr_chunk; % current chunk number

if int_curr_chunk > 1
    int_curr_chunk = int_curr_chunk - 1;
    load_curr_chunk(handles);
else
    % set(handles.text_info, 'String', 'Reached first chunk!');
    button_prev_video_Callback(hObject, eventdata, handles);
end
uicontrol(handles.text_status);



function display_tracklet(handles)

global int_curr_frame;  % number of the frame currently in view
global int_start_frame; % first frame in the current chunk
global int_curr_bbox;   % current bounding box
global img_curr_frame;  % image array of current frame
global arr_tracked_boxes;       % array with tracked box coordinates for each frame in chunk
global int_track_box_buffer;    % the border buffer space around the bbox for tracklet

axes(handles.axes2); % revert to one at the end

trackframe = int_curr_frame-int_start_frame+1;

int_track_box_buffer = round(((arr_tracked_boxes(trackframe,3) + arr_tracked_boxes(trackframe,4)) / 2) * 0.5 + 0.49);
if int_track_box_buffer > 50
    int_track_box_buffer = 50;
end

y1 = arr_tracked_boxes(trackframe,2)-int_track_box_buffer;
y2 = arr_tracked_boxes(trackframe,2)+arr_tracked_boxes(trackframe,4)-1+int_track_box_buffer;
x1 = arr_tracked_boxes(trackframe,1)-int_track_box_buffer;
x2 = arr_tracked_boxes(trackframe,1)+arr_tracked_boxes(trackframe,3)-1+int_track_box_buffer;

if y1>0 && y2<=size(img_curr_frame,1) && x1>0 && x2<=size(img_curr_frame,2)
    set(handles.text_tracklet_info, 'String', sprintf('Tracklet for BBox %d',int_curr_bbox));
    trackedPatch = img_curr_frame(y1:y2,x1:x2,:);
    imshow(trackedPatch);
else
    set(handles.text_tracklet_info, 'String', 'Tracklet out of bounds!');
end

axes(handles.axes1);



function display_tracking_box_in_tracklet(handles)

global int_curr_frame;  % number of the frame currently in view
global int_start_frame; % first frame in the current chunk
global arr_tracked_boxes;       % array with tracked box coordinates for each frame in chunk
global int_track_box_buffer;    % the border buffer space around the bbox for tracklet

axes(handles.axes2); % revert to one at the end

trackframe = int_curr_frame-int_start_frame+1;

redbox = [int_track_box_buffer+1,int_track_box_buffer+1,arr_tracked_boxes(trackframe,3),arr_tracked_boxes(trackframe,4)];
rectangle('Position',redbox,...
          'EdgeColor', 'r',...
          'LineStyle','-',...
          'LineWidth',1);

axes(handles.axes1);



function display_tracking_box(handles)

global int_curr_frame;  % number of the frame currently in view
global int_start_frame; % first frame in the current chunk
global str_boxdir;      % path of directory where .box files are stored
global int_curr_bbox;   % current bounding box
global str_curr_chunk_name; % current chunk name (e.g. '00001_00500')

trackFile = fullfile(str_boxdir, sprintf('%s_%03d.track',str_curr_chunk_name,int_curr_bbox));
trackBoxes = dlmread(trackFile);

trackframe = int_curr_frame-int_start_frame+1;

redbox = trackBoxes(trackframe,:);
yelbox = [redbox(1)-1,redbox(2)-1,redbox(3)+2,redbox(4)+2];

rectangle('Position',yelbox,...
          'EdgeColor', 'y',...
          'LineStyle','-',...
          'LineWidth',2);
rectangle('Position',redbox,...
          'EdgeColor', 'r',...
          'LineStyle','-',...
          'LineWidth',1);

% display in tracklet also
display_tracking_box_in_tracklet(handles)



% --- Executes on button press in toggle_track_box.
function toggle_track_box_Callback(~, ~, handles)
% hObject    handle to toggle_track_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global bool_show_track_box; % Boolean, whether to display tracked boxes

bool_show_track_box = ~bool_show_track_box;

display_curr_frame(handles)

if bool_show_track_box
    set(handles.toggle_track_box,'String','SHOWING Tracked Box');
else
    set(handles.toggle_track_box,'String','NOT Showing Tracked Box');
end

uicontrol(handles.text_status);



% --- Executes on button press in toggle_mode.
function toggle_mode_Callback(~, ~, handles)
% hObject    handle to toggle_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of toggle_mode
global bool_mode_annotate;

bool_mode_annotate = get(handles.toggle_mode,'Value');
if bool_mode_annotate
    set(handles.toggle_mode,'String','Mode: ANNOTATE')
    set(handles.checkbox_rewrite_file, 'Visible','on')
else
    set(handles.toggle_mode,'String','Mode: VIEW')
    set(handles.checkbox_rewrite_file, 'Visible','off')
end
uicontrol(handles.text_status);


% --- Executes on button press in checkbox_rewrite_file.
function checkbox_rewrite_file_Callback(hObject, eventdata, handles)
% Simply remove from focus
uicontrol(handles.text_status);



function input_Callback(~, ~, handles)
% hObject    handle to input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global int_curr_video;

int_curr_video = str2num(get(handles.input,'String'));
load_curr_video(handles);
uicontrol(handles.text_status);

% --- Executes during object creation, after setting all properties.
function input_CreateFcn(hObject, ~, ~)
% hObject    handle to input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_jump_to_video.
function button_jump_to_video_Callback(~, ~, handles)
% hObject    handle to button_jump_to_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global int_curr_video;

int_curr_video = str2num(get(handles.input,'String'));
load_curr_video(handles);
uicontrol(handles.text_status);


function continue_annotation_from(int_vid,handles)
% TODO select first bbox that doesnt have f_occ file.
global int_max_videos;
global int_curr_video;
global int_curr_chunk;
global int_max_chunks;
global str_boxdir;      % path of directory where .box, .focc files are stored
global int_curr_bbox;   % current bounding box
global int_max_bboxes;  % maximum number of bounding boxes in current chunk
global str_curr_chunk_name; % current chunk name (e.g. '00001_00500')

int_curr_video = int_vid;
load_curr_video(handles);

while true
    foccFile = fullfile(str_boxdir, sprintf('%s_%03d.focc',str_curr_chunk_name,int_curr_bbox));
    fileID = fopen(foccFile,'r');
    if fileID == -1
        break;
    end
    int_curr_bbox = int_curr_bbox + 1;
    load_curr_bbox(handles);
    if int_curr_video==int_max_videos && int_curr_chunk==int_max_chunks && int_curr_bbox==int_max_bboxes 
        break;
    end
end


% --- Executes on button press in button_continue_from.
function button_continue_from_Callback(hObject, eventdata, handles)
% hObject    handle to button_continue_from (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
continue_annotation_from(str2num(get(handles.input,'String')), handles)
uicontrol(handles.text_status);