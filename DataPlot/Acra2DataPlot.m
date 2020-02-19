% Acra2DataPlot: Used by Main program DataPlot. This is to convert data
%       from the Acra recorder used by the Flight test department to 
%       DataPlot format
% Written by:	J. van Zyl
% Date:			2018
% Updated:      J. van Zyl
% Last Date:    2018-03-09

function varargout = Acra2DataPlot(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Acra2DataPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @Acra2DataPlot_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function Acra2DataPlot_OpeningFcn(hObject, eventdata, handles, varargin)
% 
% Choose default command line output for Acra2DataPlot
handles.output = hObject;
guidata(hObject, handles);% Update handles structure

try
    load Acra2D_Config.mat
catch
    Paths.DataIn = sprintf('%s\\',pwd);
    Paths.DataOut = sprintf('%s\\',pwd);
    Paths.Config = sprintf('%s\\',pwd);

end
Paths.Exe = sprintf('%s\\',pwd);

setappdata(handles.Acra2DataPlot, 'Paths', Paths);

% Get Jabberwock logo
Jabberwock = imread('Jabberwock_m.jpg');
image(Jabberwock, 'Parent', handles.axJabberwock)
set(handles.axJabberwock, 'YTickLabel',[])
set(handles.axJabberwock, 'XTickLabel',[])
set(handles.axJabberwock, 'XTick',[])
set(handles.axJabberwock, 'YTick',[])
Load_ParameterList(handles)
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes when user attempts to close Acra2DataPlot.
function Acra2DataPlot_CloseRequestFcn(hObject, eventdata, handles)
% 
Paths =  getappdata(handles.Acra2DataPlot, 'Paths');
save([Paths.Exe, 'Acra2D_Config.mat'], 'Paths')

delete(hObject);
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = Acra2DataPlot_OutputFcn(hObject, eventdata, handles)
% 
varargout{1} = handles.output;% Get default command line output from handles structure

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes on button press in pbConvert.
function pbConvert_Callback(hObject, ConversionType, handles)
% 
global Words
if strcmp(get(handles.pbConvert, 'String'), 'CANCEL')
    set(handles.pbConvert, 'String', 'CONVERT')
    drawnow;
    return
end

set(handles.Acra2DataPlot, 'Pointer', 'watch')
set(handles.pbConvert, 'String', 'CANCEL')
set(handles.pbClear, 'Enable', 'Off')
drawnow;
MessageBox(handles, 'Converting the selected files ', 'n')

ErrFlag = 0;
if isempty(get(handles.edInputDir, 'String')) || ~isdir(get(handles.edInputDir, 'String'))
    errordlg('Need a Input directory or Input directory does not exist' , 'NO DIR')
    ErrFlag = 1;
end

if isempty(get(handles.edOutputDir, 'String')) || ~isdir(get(handles.edOutputDir, 'String'))
    errordlg('Need a Output directory or Output directory does not exist' , 'NO DIR')
    ErrFlag = 1;
end   

Path = get(handles.edInputDir, 'String');
FileId = get(handles.edFileId, 'String'); % Get the FileId parameter from the GUI

% Load config file
%Words = Acra2DataPlot_Config();

SubAddNames = fieldnames(Words);
for I = 1:length(SubAddNames)
    try
        TimeHi = load([Path, '\', SubAddNames{I}, '_thi.', FileId, '.mat']);
        TimeLo = load([Path, '\', SubAddNames{I}, '_tlo.', FileId, '.mat']);
        TimeU = load([Path, '\', SubAddNames{I}, '_tu.', FileId, '.mat']);
        Inf = load([Path, '\', SubAddNames{I}, '_inf.', FileId, '.mat']);
    catch ME
        if strcmp(ME.identifier, 'MATLAB:load:notBinaryFile')
            MessageBox(handles,...
                sprintf('Corrupt file "%s"', SubAddNames{I}),'n');
        elseif strcmp(ME.identifier, 'MATLAB:load:couldNotReadFile')
            MessageBox(handles,...
                sprintf('Missing file "%s"', SubAddNames{I}),'n');
        end
        continue
    end
    TimeHi = TimeHi.(char(fields(TimeHi)));
    TimeLo = TimeLo.(char(fields(TimeLo)));
    TimeU = TimeU.(char(fields(TimeU)));
    Inf = Inf.(char(fields(Inf)));
    
    % Create a Timefile in seconds from the 3 Acra time words
    % TimeHi word
    TimeSec = bitand(bitshift(TimeHi,-11),3)*36000 ... % Hour Tens digit
            + bitand(bitshift(TimeHi,-7),15)*3600 ... % Hour digit
            + bitand(bitshift(TimeHi,-4),7)*600 ... % Minute Tens digit
            + bitand(bitshift(TimeHi,0),15)*60 ... % Minute digit
    ... % TimeLo word
            + bitand(bitshift(TimeLo,-12),15)*10 ... % Seconds Tens digit
            + bitand(bitshift(TimeLo,-8),15) ... % Seconds digit
            + bitand(bitshift(TimeLo,-4),15)/ 10 ... % 1st decimal
            + bitand(bitshift(TimeLo,0),15) / 100 ... % 2nd decimal
    ... % TimeMicro word
            + bitand(bitshift(TimeU,-12),15)/ 1000 ... % 3rd decimal
            + bitand(bitshift(TimeU,-8),15) / 10000 ... % 4th decimal
            + bitand(bitshift(TimeU,-4),15) / 100000 ... % 5th decimal
            + bitand(bitshift(TimeU,0),15)  / 1000000; % 6th decimal
    
    ParamNames = eval(['Words.', SubAddNames{I}, '.Old']);

    for J = 1:length(ParamNames)     
        try
            TmpVar = load([Path, '\', ParamNames{J}, '.', FileId, '.mat']);
        catch ME
            if strcmp(ME.identifier, 'MATLAB:load:notBinaryFile')
                MessageBox(handles,...
                    sprintf('Corrupt file "%s"', ParamNames{J}),'n');
            elseif strcmp(ME.identifier, 'MATLAB:load:couldNotReadFile')
                MessageBox(handles,...
                    sprintf('Missing file "%s"', ParamNames{J}),'n');
            end
            continue
        end
        TmpVal = TmpVar.(char(fields(TmpVar)));

        Cnt = 0;
        clear FixedVar;
        for K = 1:length(TmpVal)
            if bitand(bitshift(Inf(K),-14),3) == 0 %bitget(Inf(K),15) == 0 && bitget(Inf(K),16) == 0
                Cnt = Cnt + 1;
                FixedVar(Cnt,:) = [TimeSec(K) TmpVal(K)];
            end
        end
 
        TmpVar = eval(['Words.', SubAddNames{I}, '.New{J};']);
        eval([TmpVar, ' = FixedVar;'])
        save([get(handles.edOutputDir, 'String'), '\',...
                TmpVar, '.', FileId, '.mat'], TmpVar);         
        MessageBox(handles, '.', 'a')
        eval(['clear ', TmpVar]) % Keep the memory clean
    end
    pause(0.00001)
    if strcmp(get(handles.pbConvert, 'String'), 'CONVERT')
        set(handles.Acra2DataPlot, 'Pointer', 'arrow')
        set(handles.pbClear, 'Enable', 'On')
        MessageBox(handles, '** User CANCELLED conversion **', 'n')
        return
    end
end

MessageBox(handles, '** Completed converting the selected files **', 'n')

set(handles.Acra2DataPlot, 'Pointer', 'arrow')
set(handles.pbConvert, 'String', 'CONVERT')
set(handles.pbClear, 'Enable', 'On')

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes on button press in pbInputDir.
function pbInputDir_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.Acra2DataPlot, 'Paths');
Dir = uigetdir(Paths.DataIn, 'Select the variable directory');
if isequal(Dir,0)
    return
end
Paths.DataIn = Dir;
setappdata(handles.Acra2DataPlot, 'Paths', Paths);
set(handles.edInputDir, 'String', Dir);

DirInfo = dir([Dir,'\*.mat']);


if ~length(DirInfo)
    msgbox('No files in this directory', 'FILES')
    return
end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes on button press in pbOutputDir.
function pbOutputDir_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.Acra2DataPlot, 'Paths');
Dir = uigetdir(Paths.DataOut, 'Select the variable directory');
if isequal(Dir,0)
    return
end
Paths.DataOut = Dir;
setappdata(handles.Acra2DataPlot, 'Paths', Paths);
set(handles.edOutputDir, 'String', Dir);
    
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function MessageBox(handles, Text, Option)
CurrentText = get(handles.lbMsgBox, 'String');
switch Option
    case 'n' % New line
        CurrentText{end+1} = Text;
    case 'a' % Add to existing line
        if length(CurrentText{end}) > 50
            CurrentText{end+1} = Text;
        end
        CurrentText{end} = [CurrentText{end},Text];
    case 'c' % Change last line
        CurrentText{end} = Text;
end
set(handles.lbMsgBox, 'String', CurrentText)
set(handles.lbMsgBox, 'Value', length(get(handles.lbMsgBox, 'String')))
drawnow
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function pbClear_Callback(hObject, eventdata, handles)
% Clears the Message box on the bottom right
set(handles.lbMsgBox, 'String', '')
set(handles.pbConvert, 'Visible', 'On')
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function Load_ParameterList(handles)
%  Loads a config file with all the parameters
global Words
Paths = getappdata(handles.Acra2DataPlot, 'Paths');
[FileName, PathName] = uigetfile(sprintf('%s*.cfg',Paths.Config)); 
if isequal(FileName,0) || isequal(PathName,0)
    return
end

try
    eval(['fid = fopen(''',PathName, FileName, ''');'])

    Paths.Config = PathName;
    setappdata(handles.Acra2DataPlot, 'Paths', Paths);
    Data = textscan(fid,'%s %s %s');
    fclose(fid);

    SubAdd = 'xxx000xxx000';
    for I = 1:length(Data{1})
        if not(strcmp(SubAdd, char(Data{1}(I))))
            CntSub = 0;
            SubAdd = char(Data{1}(I));
        end
        CntSub = CntSub + 1;
        eval(['Words.', char(Data{1}(I)),'.Old{', num2str(CntSub), '} =''', char(Data{2}(I)), ''';']) 
        eval(['Words.', char(Data{1}(I)),'.New{', num2str(CntSub), '} =''', char(Data{3}(I)), ''';'])
    end
 catch ME
     msgbox('Config file is broken', 'Try another one');
     return
 end
