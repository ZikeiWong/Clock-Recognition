function varargout = ReadWatchGUI(varargin)
% READWATCHGUI MATLAB code for ReadWatchGUI.fig
%      READWATCHGUI, by itself, creates a new READWATCHGUI or raises the existing
%      singleton*.
%
%      H = READWATCHGUI returns the handle to a new READWATCHGUI or the handle to
%      the existing singleton*.
%
%      READWATCHGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in READWATCHGUI.M with the given input arguments.
%
%      READWATCHGUI('Property','Value',...) creates a new READWATCHGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ReadWatchGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ReadWatchGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ReadWatchGUI

% Last Modified by GUIDE v2.5 22-Apr-2019 15:03:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ReadWatchGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ReadWatchGUI_OutputFcn, ...
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


% --- Executes just before ReadWatchGUI is made visible.
function ReadWatchGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ReadWatchGUI (see VARARGIN)

% Choose default command line output for ReadWatchGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ReadWatchGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ReadWatchGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in loadImageButton.
function loadImageButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadImageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
image=uigetimagefile;
imshow(image);
set(handles.imagePath,'visible','on','String',image);


% --- Executes on button press in tellTimebutton.
function tellTimebutton_Callback(hObject, eventdata, handles)
% hObject    handle to tellTimebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1, 'HandleVisibility', 'off');
set(handles.axes1, 'HandleVisibility', 'off');
close all;
set(handles.figure1, 'HandleVisibility', 'on');
set(handles.axes1, 'HandleVisibility', 'on');

try
    img = get(handles.imagePath,'String');
    set(handles.figure1, 'HandleVisibility', 'off');
    set(handles.axes1, 'HandleVisibility', 'off');
    watchTime = watchread(img);
    set(handles.figure1, 'HandleVisibility', 'on');
    set(handles.axes1, 'HandleVisibility', 'on');
    
    set(handles.time,'visible','on','String',watchTime,'ForegroundColor',[0.0,0.0,0.0]);
catch e
    if ~exist(img,'file')
        errMessage = 'No image loaded!';
    else
        errMessage = 'Unable to detect time.';
    end
    set(handles.figure1, 'HandleVisibility', 'on');
    set(handles.axes1, 'HandleVisibility', 'on');
    set(handles.time,'visible','on','String',errMessage,'ForegroundColor',[1.0,0.0,0.0]);
end


function time_Callback(hObject, eventdata, handles)
% hObject    handle to time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of time as text
%        str2double(get(hObject,'String')) returns contents of time as a double


% --- Executes during object creation, after setting all properties.
function time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function imagePath_Callback(hObject, eventdata, handles)
% hObject    handle to imagePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of imagePath as text
%        str2double(get(hObject,'String')) returns contents of imagePath as a double


% --- Executes during object creation, after setting all properties.
function imagePath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to imagePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
