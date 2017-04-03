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

% Last Modified by GUIDE v2.5 03-Apr-2017 18:00:33

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
function annotate_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to annotate (see VARARGIN)
global bool_is_paused; % Boolean, indicates if the playback is paused
global int_curr_frame; % number of the frame currently in view
global str_imDir;      % parent dir of where the image/frame files are
global list_imFiles;   % cell of all image/frame filenames (e.g. self00021_00023.jpg)
global int_curr_video; % number of the video currently
global int_max_frames; % maximum possible frame number for the current video
global str_seq;
global file_prefix;    % prefix string for the image/frame files 
global str_dir;        % 'self shot' or 'from web'
global int_max_videos;

file_prefix = 'self';
str_seq = strcat(file_prefix,'%05d');
str_dir = 'self shot';

int_max_videos = length(dir(fullfile(strcat('/home/is/Occlusion Video Data/',str_dir),'self*')));
int_curr_video = 1;

% Initialize all other variables
load_curr_video();

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
function varargout = annotate_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
disp('---------------------------------------------');


function load_curr_video()
% Initializes all the variables required for a new file, and displays the
% first frame. Update the int_curr_video BEFORE calling this function.

global bool_is_paused; % Boolean, indicates if the playback is paused
global int_curr_frame; % number of the frame currently in view
global int_max_frames; % maximum possible frame number for the current video
global str_seq;        % contains 'self%05d' or 'web%05d' REMOVE TODO
global str_dir;        % contains 'self shot' or 'from web'
global int_curr_video; % current video number in the str_dir folder.
global str_imDir;      % parent dir of where the image/frame files are % the complete path of the current video folder
global list_imFiles;   % cell of all image/frame filenames (e.g. self00021_00023.jpg) % all '*.jpg' file names in the current video folder.
global file_prefix; % prefix string for the image/frame files 

% initial settings
bool_is_paused = true; % default
int_curr_frame = 1; % default

% building imDir string
seq_name = sprintf('%s%05d',file_prefix,int_curr_video); 
str_imDir = fullfile('/home/is/Occlusion Video Data', str_dir, seq_name);

imageList = dir(fullfile(str_imDir, '*.jpg'));
list_imFiles = {imageList.name};    
int_max_frames = length(imageList);
clear imageList
% TODO: should use axes(handles??) here before imshow???
imshow(imread(fullfile(str_imDir, list_imFiles{int_curr_frame})));

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
global bool_is_paused;
bool_is_paused = true;
pause(0.01);
% TODO: DELETE ALL OTHER VARIABLES???
delete(hObject);


% --- Executes on button press in button_pause.
function button_pause_Callback(hObject, eventdata, handles)
% hObject    handle to button_pause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global bool_is_paused;

bool_is_paused = ~bool_is_paused;
pause(0.01);

% divert focus so that keyboard callback is only triggered on figure 1
% and not the button as well.
uicontrol(handles.text_status); 

play(handles);


function play(handles) 
% ONLY 1 thread should run this when bool_is_paused==false
global bool_is_paused;
global int_curr_frame;
global int_max_frames;
global str_imDir;
global list_imFiles;

axes(handles.axes1);
while ~bool_is_paused
    cla;
    imshow(imread(fullfile(str_imDir, list_imFiles{int_curr_frame})));
    set(handles.curr_frame,'String',int_curr_frame); % Show the current frame on the GUI
    drawnow;
    pause(0.01); % approx 33 fps in original dim
    int_curr_frame = int_curr_frame + 1;
    if int_curr_frame > (int_max_frames-1)
        bool_is_paused = true;
        set(handles.text_status,'String','max frames exceeded');
    end
end


function display_curr_frame(handles)
global int_curr_frame;
global str_imDir;
global list_imFiles;

axes(handles.axes1);
cla;
im = imread(fullfile(str_imDir, list_imFiles{int_curr_frame}));
imshow(im);
%drawnow;

% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
global int_curr_frame;
global int_max_frames;
global bool_is_paused;

switch eventdata.Key
    case 'leftarrow'
        int_curr_frame = int_curr_frame - 10;
        bool_is_paused = true;
        if int_curr_frame < 1
            int_curr_frame = 1;
            set(handles.text_status,'String','curr_frame underflow');
        end
        display_curr_frame(handles);
        set(handles.curr_frame, 'String', num2str(int_curr_frame));
    case 'rightarrow'
        int_curr_frame = int_curr_frame + 10;
        bool_is_paused = true;
        if int_curr_frame > (int_max_frames-1)
            int_curr_frame = int_max_frames-1;
            set(handles.text_status,'String','max frames exceeded');
        end
        display_curr_frame(handles);
        set(handles.curr_frame, 'String',num2str(int_curr_frame));
    case 'space'
        bool_is_paused = ~bool_is_paused;
        play(handles);
        % h = gco; % get the UIControl currently in focus.
        %try
        %    x = strcmp(get(h,'String'),'Pause');
        %catch
        %    x = false;
        %end
        %if ~x
        %    bool_is_paused = ~bool_is_paused; 
        %    play(handles);
        %end
        % Above part not needed anymore as we are diverting focus as soon
        % as the button is pressed anyway!
    case 'return'
        enter_pressed(handles);
    otherwise
        disp(eventdata.Key); % remove after dev.
end
%downarrow
%uparrow
%backquote
%alt
%control

function enter_pressed(handles)
disp('Enter pressed');


% --- Executes on button press in button_next_file.
function button_next_file_Callback(hObject, eventdata, handles)
% hObject    handle to button_next_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global int_max_videos;
global int_curr_video;
if int_curr_video<int_max_videos
    int_curr_video = int_curr_video + 1;
    load_curr_video(); % initializes the other variables corresponding to the new video, and displays the first frame.
else
    disp('Reached maximum video limit. Display this in status bar.');
end
uicontrol(handles.text_status); % divert focus
