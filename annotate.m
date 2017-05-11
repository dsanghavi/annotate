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

% Last Modified by GUIDE v2.5 09-Apr-2017 23:11:28

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
global bool_control_pressed;% Boolean, indicates if CTRL is currently pressed
global bool_shift_pressed;  % Boolean, indicates if SHIFT is currently pressed
global bool_alt_pressed;    % Boolean, indicates if ALT is currently pressed
global int_mode; % maintains the mode. 1 = VIEW, 2 = ANNOTATE, 3 = REVIEW, 4 = 2-BOX REVIEW
global int_play_prev;   % For review mode, play tracklets from f_occ - int_play_prev
global int_view_only; % Ground truth tag examples to display. For review mode. 1 = any f_occ > 0. 2 = all. rest = itself.

int_mode = 1;
int_play_prev = 1;
int_view_only = 2; % default is view all.
bool_show_track_box = false;

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
global int_mode;        % 1=VIEW, 2=ANNOTATE, 3=REVIEW, 4=2-BOX REVIEW
global int_focc;        % Stores f_occ for current bbox
global int_play_prev;   % For review mode, play tracklets from f_occ - int_play_prev
global int_view_only;   % Tag examples to display during REVIEW mode.
global arr_fortracked_boxes;
global arr_revtracked_boxes;

axes(handles.axes1);

if int_curr_bbox > int_max_bboxes
    int_curr_chunk = int_curr_chunk + 1;
    load_curr_chunk(handles);
else
    bool_is_paused = true;

    int_curr_frame = int_start_frame; % default
    if int_mode == 3 % REVIEW
        % First, read int_focc
        focc_file = fopen(fullfile(str_boxdir,sprintf('%s_%03d.focc',str_curr_chunk_name,int_curr_bbox)), 'r');
        if focc_file == -1 % file does not exist
            set(handles.text_review, 'String','.focc file does not exist.');
        else
            int_focc = fscanf(focc_file,'%d');
            if int_view_only == 2 || int_focc == int_view_only || (int_view_only == 1 && int_focc>1)
                set(handles.text_review, 'String',sprintf('f_occ = %d',int_focc));
            else
                int_curr_bbox = int_curr_bbox + 1;
                load_curr_bbox(handles);
                return;
            end
        end
        % Then, seek to appropriate place - IF int_play_prev is defined.
        if int_play_prev>1 && int_focc> (int_start_frame + int_play_prev) 
            int_curr_frame = int_focc - int_play_prev;
            %disp(sprintf('%d, %d, %d',int_curr_frame, int_focc, int_play_prev));
        end
    elseif int_mode == 4 % 2-BOX REVIEW
        % First, read .fortrack and .revtrack files
        fortrackfileslist = dir(fullfile(str_boxdir, sprintf('%s_%03d_*.fortrack',str_curr_chunk_name,int_curr_bbox)));
        fortrackfiles = {fortrackfileslist.name};
        clear fortrackfileslist;

        if size(fortrackfiles) > 0
            if size(fortrackfiles) > 1
                disp('REMOVE ADDITIONAL .FORTRACK FILES');
            end
            
            fortrackfile = fortrackfiles{1};
        
            [~,fortrackfilename,~] = fileparts(fortrackfile);
            
            int_start_frame = str2num(fortrackfilename(17:21))
            int_end_frame = str2num(fortrackfilename(23:27))
            int_focc = int_end_frame
            int_curr_frame = int_start_frame

            fortrackfile_full = fullfile(str_boxdir,sprintf('%s.fortrack',fortrackfilename));
            arr_fortracked_boxes = dlmread(fortrackfile_full);
            revtrackfile_full = fullfile(str_boxdir,sprintf('%s.revtrack',fortrackfilename));
            arr_revtracked_boxes = dlmread(revtrackfile_full);
        else
            int_curr_bbox = int_curr_bbox + 1;
            load_curr_bbox(handles);
            return;
        end
    end
    
    int_max_frames = int_end_frame;

    file_track = fullfile(str_boxdir, sprintf('%s_%03d.track',str_curr_chunk_name,int_curr_bbox));
    arr_tracked_boxes = dlmread(file_track);

    display_curr_frame(handles);
    
    display_dist_plot(handles);
    
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
global int_focc;       % f_occ for the current bbox
global bool_paused_at_focc; % true if the last pause was caused by int_curr_frame == int_focc

axes(handles.axes1);

if bool_paused_at_focc
    set(handles.text_tracklet_top,'String','Playing from f_occ')
end

while ~bool_is_paused
    set(handles.text_info, 'String', 'PLAYING');
    set(handles.button_pause,'String','Pause');
    
    int_curr_frame = int_curr_frame + 1;
    if int_curr_frame > int_max_frames
        int_curr_frame = int_max_frames;
        bool_is_paused = true;
        set(handles.text_info,'String','Reached last frame in chunk!');
    end
    
    if int_curr_frame == int_focc
        bool_is_paused = true;
        set(handles.text_tracklet_top,'String','Stopped at f_occ')
        bool_paused_at_focc = true;
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
global int_mode;            % 1=VIEW, 2=ANNOTATE, 3=REVIEW, 4=2-BOX REVIEW
global int_focc;
global int_play_prev;

axes(handles.axes1);

cla;

img_curr_frame = imread(fullfile(str_imDir, list_imFiles{int_curr_frame}));

imshow(img_curr_frame);
set(handles.text_curr_frame,'String',int_curr_frame); % Show the current frame number on the GUI

display_tracklet(handles);

if bool_show_track_box || int_curr_frame == int_start_frame
    display_tracking_box(handles);
end

display_current_frame_line_in_plot(handles);

if int_mode == 3 % REVIEW Mode
    if int_curr_frame == int_focc - int_play_prev
        display_tracking_box(handles);
    end
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
global int_mode;            % 1=VIEW, 2=ANNOTATE, 3=REVIEW, 4=2-BOX REVIEW

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
            int_mode = int_mode + 1;
            if int_mode > 3
                int_mode = 1;
            end
            set(handles.listbox_mode,'Value',int_mode); % Ctrl + a will only switch to annotate mode and back.
            listbox_mode_Callback(hObject, eventdata, handles);
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
        %disp(eventdata.Key); % remove after dev.
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
global str_boxdir;          % path of directory where .box files are stored
global int_curr_bbox;       % current bounding box
global str_curr_chunk_name; % current chunk name (e.g. '00001_00500')
global int_curr_frame;      % number of the frame currently in view
global int_mode;            % 1=VIEW, 2=ANNOTATE, 3=REVIEW, 4=2-BOX REVIEW

if int_focc == 1
    int_focc = int_curr_frame;
end
if int_mode == 2 % ANNOTATE mode
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



function display_dist_plot(handles)

global str_boxdir;      % path of directory where .box files are stored
global int_curr_bbox;   % current bounding box
global str_curr_chunk_name; % current chunk name (e.g. '00001_00500')
global arr_dist_plot;   % array for L2 distances of DFs
global int_focc;        % Stores f_occ for current bbox
global int_start_frame; % first frame in the current chunk
global int_end_frame;   % last frame in the current chunk
global int_mode;
global arr_dist_plot_4box;
global dist_max;
global focc_line_handle;

axes(handles.axes3); % revert to one at the end

try
    delete(focc_line_handle);
catch
end

distFile = fullfile(str_boxdir, sprintf('%s_%03d_df.dist',str_curr_chunk_name,int_curr_bbox));
arr_dist_plot = dlmread(distFile);
arr_dist_plot = [0; arr_dist_plot]; % add a 0 in the beginning
arr_dist_plot = arr_dist_plot ./ max(arr_dist_plot);

distFile_4box = fullfile(str_boxdir, sprintf('%s_%03d.4boxdist',str_curr_chunk_name,int_curr_bbox));
arr_dist_plot_4box = dlmread(distFile_4box);
arr_dist_plot_4box = arr_dist_plot_4box ./ max(max(arr_dist_plot_4box));

x = int_start_frame:1:int_end_frame;

if int_mode == 4
    int_chunk_start = str2num(str_curr_chunk_name(1:5));
    int_chunk_end = str2num(str_curr_chunk_name(7:11));
%     arr_dist_plot = arr_dist_plot(1+int_start_frame-int_chunk_start:1+int_end_frame-int_chunk_start);
    x = int_chunk_start:1:int_chunk_end;
end

plot(x,arr_dist_plot,'y'); hold on;
plot(x,arr_dist_plot_4box(:,1),'r'); hold on;
plot(x,arr_dist_plot_4box(:,2),'g'); hold on;
plot(x,arr_dist_plot_4box(:,3),'b'); hold on;
plot(x,arr_dist_plot_4box(:,4),'k'); hold on;
plot(x,arr_dist_plot_4box(:,5),'r--'); hold on;
plot(x,arr_dist_plot_4box(:,6),'g--'); hold on;
plot(x,arr_dist_plot_4box(:,7),'b--'); hold on;
plot(x,arr_dist_plot_4box(:,8),'k--'); hold off;

dist_max = max(max(arr_dist_plot_4box));

if int_focc > 0 && int_mode ~= 1
    focc_line_handle = line([int_focc int_focc],[0 dist_max],'Color','r');
end

axes(handles.axes1);



function display_current_frame_line_in_plot(handles)

global int_curr_frame;  % number of the frame currently in view
global line_handle;     % line handle for current frame line
global dist_max;

axes(handles.axes3); % revert to one at the end

try
    delete(line_handle);
catch
end
line_handle = line([int_curr_frame int_curr_frame],[0 dist_max],'Color','k');

axes(handles.axes1);



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
global arr_tracked_boxes;
global int_mode;
global arr_fortracked_boxes;
global arr_revtracked_boxes;

trackframe = int_curr_frame-int_start_frame+1;

if int_mode==4
    rectangle('Position',arr_fortracked_boxes(trackframe,:),...
              'EdgeColor', 'r',...
              'LineStyle','-',...
              'LineWidth',3);
    rectangle('Position',arr_revtracked_boxes(trackframe,:),...
              'EdgeColor', 'g',...
              'LineStyle','-',...
              'LineWidth',3);
else
%     trackFile = fullfile(str_boxdir, sprintf('%s_%03d.track',str_curr_chunk_name,int_curr_bbox));
%     trackBoxes = dlmread(trackFile);

    redbox = arr_tracked_boxes(trackframe,:);
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
end



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
% Selects first bbox that doesnt have f_occ file.
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



% --- Executes on selection change in listbox_mode.
function listbox_mode_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global int_mode; % 1 for VIEW, 2 for ANNOTATE, 3 for REVIEW, 4 for 2-BOX REVIEW
global int_focc;        % Stores f_occ for current bbox

%contents = cellstr(get(hObject,'String')); % returns listbox_mode contents
%as cell array. Can access index-wise to get the string selected.
int_mode = get(handles.listbox_mode,'Value'); % returns selected index
if int_mode == 2
    set(handles.checkbox_rewrite_file, 'Visible','on')
    set(handles.button_continue_from, 'Visible','on')
else
    set(handles.checkbox_rewrite_file, 'Visible','off')
    set(handles.button_continue_from, 'Visible','off')
end
if int_mode == 3
    set(handles.text_review, 'Visible','on')
    set(handles.text_tracklet_top, 'Visible','on')
    set(handles.button_play_prev, 'Visible','on')
    set(handles.edit_play_prev, 'Visible','on')
    set(handles.button_view_only, 'Visible','on')
    set(handles.edit_view_only, 'Visible','on')
%    set(handles.axes3, 'Visible','on')
%    set(handles.axes1, 'OuterPosition', [-0.106 0.195 0.933 0.734])
else
    int_focc = 0;
    set(handles.text_review, 'Visible','off')
    set(handles.text_tracklet_top, 'Visible','off')
    set(handles.button_play_prev, 'Visible','off')
    set(handles.edit_play_prev, 'Visible','off')
    set(handles.button_view_only, 'Visible','off')
    set(handles.edit_view_only, 'Visible','off')
%    set(handles.axes3, 'Visible','off') % BUG - comes on for the next bbox load
%    set(handles.axes1, 'OuterPosition', [-0.106 0.195 0.933 0.824])
end
uicontrol(handles.text_status);



% --- Executes during object creation, after setting all properties.
function listbox_mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
modes = {'VIEW Mode','ANNOTATE Mode','REVIEW Mode', '2-BOX REVIEW Mode'};
set(hObject, 'String', modes);



function edit_play_prev_Callback(hObject, eventdata, handles)
% hObject    handle to edit_play_prev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global int_play_prev; % For review mode, play tracklets from f_occ - int_play_prev

int_play_prev = str2num(get(handles.edit_play_prev,'String'));
uicontrol(handles.text_status);



% --- Executes during object creation, after setting all properties.
function edit_play_prev_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_play_prev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in button_play_prev.
function button_play_prev_Callback(hObject, eventdata, handles)
% hObject    handle to button_play_prev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global int_play_prev; % For review mode, play tracklets from f_occ - int_play_prev

int_play_prev = str2num(get(handles.input,'String'));
uicontrol(handles.text_status);



function edit_view_only_Callback(hObject, eventdata, handles)
% hObject    handle to edit_view_only (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_view_only as text
%        str2double(get(hObject,'String')) returns contents of edit_view_only as a double
global int_view_only; % Ground truth tag examples to display. For review mode

text = get(handles.edit_view_only,'String');
if strcmp(text,'ALL')
    text = '2';
end
int_view_only = str2num(text);
uicontrol(handles.text_status);

% --- Executes during object creation, after setting all properties.
function edit_view_only_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_view_only (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_view_only.
function button_view_only_Callback(hObject, eventdata, handles)
% hObject    handle to button_view_only (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global int_view_only; % Ground truth tag examples to display. For review mode

text = get(handles.edit_view_only,'String');
if text=='ALL'
    text = 2;
end
int_view_only = str2num(text);
uicontrol(handles.text_status);
