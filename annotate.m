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

% Last Modified by GUIDE v2.5 18-Mar-2017 22:07:52

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
global is_paused;
global curr_frame;
global imDir;
global imFiles;
global curr_file;
global max_frames;
global seq_str;
global dir_str;
seq_str = strcat('web','%05d');
dir_str = 'from web';
curr_file = 3;
new_file();

% Choose default command line output for annotate
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% % BELOW PART Experimentally commented. No startup issues so far.
% This sets up the initial plot - only do when we are invisible
% so window can get raised using annotate.
%if strcmp(get(hObject,'Visible'),'off')
%    imshow(imread(fullfile(imDir, imFiles{curr_frame})));
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


function new_file()
% Update the curr_file BEFORE calling this function.
global is_paused;
global curr_frame;
global max_frames;
global seq_str;
global dir_str;
global curr_file;
global imFiles;
global imDir;
is_paused = true;
curr_frame = 1;
seq_name = sprintf(seq_str,curr_file); 
imDir = sprintf(strcat('/home/darpan/sem2/is/Occlusion Video Data/',dir_str,'/%s'), seq_name);
imageList = dir(fullfile(imDir, '*.jpg'));
imFiles = {imageList.name};    
max_frames = length(imageList);
clear imageList
imshow(imread(fullfile(imDir, imFiles{curr_frame})));


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
global is_paused;
is_paused = true;
pause(0.01);
% DELETE ALL OTHER VARIABLES??
delete(hObject);


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global is_paused;
is_paused = ~is_paused;
pause(0.01);
uicontrol(handles.text1); % divert focus
% so that keyboard callback is only triggered on figure 1 and not the button as well.
play(handles);


function play(handles) 
% ONLY 1 thread should run this when is_paused==false
global is_paused;
global curr_frame;
global max_frames;
global imDir;
global imFiles;
axes(handles.axes1);
while ~is_paused
    cla;
    imshow(imread(fullfile(imDir, imFiles{curr_frame})));
    set(handles.curr_frame,'String',curr_frame); % Show the current frame on the GUI
    drawnow;
    pause(0.01); % approx 33 fps in original dim
    curr_frame = curr_frame + 1;
    if curr_frame > (max_frames-1)
        is_paused = true;
        set(handles.text1,'String','max frames exceeded');
    end
end


function display_curr_frame(handles)
global curr_frame;
global imDir;
global imFiles;
axes(handles.axes1);
cla;
im = imread(fullfile(imDir, imFiles{curr_frame}));
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
global curr_frame;
global max_frames;
global is_paused;
switch eventdata.Key
    case 'leftarrow'
        curr_frame = curr_frame - 10;
        is_paused = true;
        if curr_frame < 1
            curr_frame = 1;
            set(handles.text1,'String','curr_frame underflow');
        end
        display_curr_frame(handles);
        set(handles.curr_frame, 'String', num2str(curr_frame));
    case 'rightarrow'
        curr_frame = curr_frame + 10;
        is_paused = true;
        if curr_frame > (max_frames-1)
            curr_frame = max_frames-1;
            set(handles.text1,'String','max frames exceeded');
        end
        display_curr_frame(handles);
        set(handles.curr_frame, 'String',num2str(curr_frame));
    case 'space'
        h = gco; % get the UIControl currently in focus.
        x = strcmp(get(h,'String'),'Pause');
        if ~x
            is_paused = ~is_paused; 
            play(handles);
        end
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
