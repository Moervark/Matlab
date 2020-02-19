% Array2DataPlot: Used by Main program DataPlot. 
%       Converting data froman Array to DataPlot format
% Written by:	J. van Zyl
% Date:			2010
% Updated:      J. van Zyl
% Last Date:  

function varargout = Array2DataPlot(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Array2DataPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @Array2DataPlot_OutputFcn, ...
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
function Array2DataPlot_OpeningFcn(hObject, eventdata, handles, varargin)
% 
% Choose default command line output for Array2DataPlot
handles.output = hObject;
guidata(hObject, handles);% Update handles structure

try
    load A2D_Config.mat
catch
    Paths.DataIn = sprintf('%s\\',pwd);
    Paths.DataOut = sprintf('%s\\',pwd);
    Points = {'65536', '0', '0'};
end
Paths.Exe = sprintf('%s\\',pwd);

set(handles.edFreq, 'Position', [2.6 16 9.8 1.2])
set(handles.txtFreq, 'Position', [2.6 17.5 20.4 1.1])
set(handles.txtHz, 'Position', [12.5 16 4.4 1.1])

setappdata(handles.Array2DataPlot, 'Paths', Paths);
setappdata(handles.Array2DataPlot, 'Points', Points);

% Get Jabberwock logo
Jabberwock = imread('Jabberwock_m.jpg');
image(Jabberwock, 'Parent', handles.axJabberwock)
set(handles.axJabberwock, 'YTickLabel',[])
set(handles.axJabberwock, 'XTickLabel',[])
set(handles.axJabberwock, 'XTick',[])
set(handles.axJabberwock, 'YTick',[])
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes when user attempts to close Array2DataPlot.
function Array2DataPlot_CloseRequestFcn(hObject, eventdata, handles)
% 
Paths =  getappdata(handles.Array2DataPlot, 'Paths');
Points = getappdata(handles.Array2DataPlot, 'Points');
save([Paths.Exe, 'A2D_Config.mat'], 'Paths', 'Points')

delete(hObject);
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = Array2DataPlot_OutputFcn(hObject, eventdata, handles)
% 
varargout{1} = handles.output;% Get default command line output from handles structure

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes on button press in pbConvert.
function pbConvert_Callback(hObject, ConversionType, handles)
% 
if strcmp(get(handles.pbConvert, 'String'), 'CANCEL')
    set(handles.pbConvert, 'String', 'CONVERT')
    drawnow;
    return
end
set(handles.Array2DataPlot, 'Pointer', 'watch')
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

if strcmp('.txt file', get(findobj(handles.rdFileType, 'Value', 1), 'String'))
    InputType = 1; % .txt file
else 
    InputType = 0; % .mat file
end

if ~get(handles.rdCreateTime,'Value')
    try
    Tmp = load([Path, '\', get(handles.edTimeFile, 'String')]);
    catch Err
        errordlg(['No such file: ',Path, '\',...
            get(handles.edTimeFile, 'String'), char(10),char(10),...
            'or no Time File specified'] , 'TIME FILE')
        ErrFlag = 1;
    end
    if ~ErrFlag
        if InputType % .txt file
            Time = Tmp;
        else
            Time = Tmp.(char(fields(Tmp)));
        end
        [row, col] = size(Time);
        if col > row 
            Time = Time'; % Transpose the array from (1,:) to (:,1)
        end
        Time = Time*str2double(get(handles.edTimeScale, 'String')); % Time must be in seconds
    end
else
    Freq = str2double(get(handles.edFreq, 'String'));
end

if ErrFlag
    set(handles.Array2DataPlot, 'Pointer', 'arrow')
    set(handles.pbConvert, 'String', 'CONVERT')
    set(handles.pbClear, 'Enable', 'On')
    return
end

PrevLen = 0;
TableData = get(handles.tblFiles, 'Data');

% Get or set the FileId parameter
FileId = get(handles.edFileId, 'String'); % Get the FileId parameter from the GUI
FileName = char(TableData(1,2));
Pos = strfind(FileName, '.');
if length(Pos) > 1 % There are more than 2 '.' implying there is a FileId
    FileId = FileName(Pos(end-1)+1:Pos(end)-1); % Change the FileId to what ever is between the '.'s
end

if strcmp(ConversionType, '.csv')
    Points = getappdata(handles.Array2DataPlot, 'Points');
    Points{2} = 0;
    setappdata(handles.Array2DataPlot, 'Points', Points);
end

for I = 1:length(TableData(:,2))
    if strcmp(get(handles.pbConvert, 'String'), 'CONVERT')
        MessageBox(handles, 'Conversion Cancelled by User', 'n')
        set(handles.Array2DataPlot, 'Pointer', 'arrow')
        set(handles.pbClear, 'Enable', 'On')
        return % User hit CANCEL
    end
    if TableData{I,1}
        if InputType % .txt file
            try
                TmpData = load([Path, '\', TableData{I,2}]);
            catch ME
                 MessageBox(handles,...
                    sprintf('Corrupt file "%s"', ParamName),'n');
                continue
            end
            Pos = strfind(TableData{I,2},'.');
            ParamName = TableData{I,2}(1:Pos(1)-1);
        else % .mat file
            try
                Tmp = load([Path, '\', TableData{I,2}]);
            catch ME
                MessageBox(handles,...
                    sprintf('Corrupt file "%s"', ParamName),'n');
                continue
            end
            TmpData = Tmp.(char(fields(Tmp)));
            ParamName = char(fields(Tmp));
        end
        [row, col] = size(TmpData);
        if col > row 
            TmpData = TmpData'; % Transpose the array from (1,:) to (:,1)
        end
        Len = length(TmpData); 
        if get(handles.rdCreateTime,'Value') % No time file specified so create one             
            if ~isvarname('Time') || Len ~= PrevLen
                Time = [0 : 1/Freq : (Len-1)/Freq]'; % Create a Time file of correct length 
                PrevLen = Len;
            end 
        end
        if length(Time) ~= Len % Check if the Time file and data file has equal lengths
            MessageBox(handles,...
                sprintf('Length of "%s" differs from "Time"', ParamName),'n');
            continue % Skip this file because of different lengths
        end
        eval([ParamName, '=  [Time TmpData];'])
        if ~strcmp(ConversionType, '.csv') % Save as .mat file
            save([get(handles.edOutputDir, 'String'), '\',...
                ParamName, '.', FileId, '.mat'], ParamName);
        else % Save as text file
            SaveExcel(ParamName, eval(ParamName), handles);
        end

        clear(ParamName)
        MessageBox(handles, '.','a') % Add a '.' to show progress
    end
end
MessageBox(handles, 'Completed converting the selected files', 'n')

set(handles.Array2DataPlot, 'Pointer', 'arrow')
set(handles.pbConvert, 'String', 'CONVERT')
set(handles.pbClear, 'Enable', 'On')

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function SaveExcel(ParamName, Data, handles)
% Break parameter up in Excel sizes and save as .csv file

Points = getappdata(handles.Array2DataPlot, 'Points');
if Points{2} == 0
    Points = inputdlg({'Maximum Number of points per file ?',...
        'Start Point ?',...
        'End Point ?'},...
        'SELECT POINTS', 1,...
        {num2str(Points{1}), '1', num2str(length(Data))}); 
    if isempty(Points)
        set(handles.pbConvert, 'String', 'CONVERT')
        return
    end
    setappdata(handles.Array2DataPlot, 'Points', Points);
end
Data = Data(str2double(Points{2}):str2double(Points{3}),:);
Cnt = 0; Flag = 1;
while Flag  
    if length(Data) > str2double(Points{1})
        SaveDat = Data(1:str2double(Points{1}),:);
        Data = Data(str2double(Points{1})+1:end,:);
    else
        SaveDat = Data;
        Flag = 0;
    end
	dlmwrite([get(handles.edOutputDir, 'String'), '\',...
        ParamName, '_', num2str(Cnt) '.csv'], SaveDat,...
        'delimiter', ',', 'precision','%0.6f');
    Cnt = Cnt + 1;
    MessageBox(handles, '-','a') % Add a '.' to show progress
end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes on button press in pbInputDir.
function pbInputDir_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.Array2DataPlot, 'Paths');
Dir = uigetdir(Paths.DataIn, 'Select the variable directory');
if isequal(Dir,0)
    return
end
Paths.DataIn = Dir;
setappdata(handles.Array2DataPlot, 'Paths', Paths);
set(handles.edInputDir, 'String', Dir);

if strcmp('.mat file', get(findobj(handles.rdFileType, 'Value', 1), 'String'))
    DirInfo = dir([Dir,'\*.mat']);
else
    DirInfo = dir([Dir,'\*.txt']);
end

if ~length(DirInfo)
    msgbox('No files in this directory', 'FILES')
    return
end

for I = 1:length(DirInfo)
    if ~strncmp(DirInfo(I).name, 'time',4)
        Data{I,1} = true;
    else
        Data{I,1} = false;
    end
    Data{I,2} = DirInfo(I).name;
end
set(handles.tblFiles, 'Data', Data)

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes on button press in pbOutputDir.
function pbOutputDir_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.Array2DataPlot, 'Paths');
Dir = uigetdir(Paths.DataOut, 'Select the variable directory');
if isequal(Dir,0)
    return
end
Paths.DataOut = Dir;
setappdata(handles.Array2DataPlot, 'Paths', Paths);
set(handles.edOutputDir, 'String', Dir);
    
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes on button press in pbTimefile.
function pbTimefile_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.Array2DataPlot, 'Paths');
if strcmp('.txt file', get(findobj(handles.rdFileType, 'Value', 1), 'String'))
    FileName = uigetfile([Paths.DataIn,'\*.txt'],'Pick a Time file');
else
    FileName = uigetfile([Paths.DataIn,'\*.mat'],'Pick a Time file');
end
if isequal(FileName,0)
    return
end

set(handles.edTimeFile, 'String', FileName);

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes on button press in rdCreateTime.
function rdCreateTime_Callback(hObject, eventdata, handles)
% 
if get(hObject,'Value')
    set([handles.edTimeFile, handles.pbTimefile, handles.txtTimeFile,...
        handles.txtTime, handles.txtS, handles.edTimeScale], 'Visible', 'Off')
    set([handles.edFreq, handles.txtFreq, handles.txtHz], 'Visible', 'On')

else
    set([handles.edTimeFile, handles.pbTimefile, handles.txtTimeFile,...
        handles.txtTime, handles.txtS, handles.edTimeScale], 'Visible', 'On')
    set([handles.edFreq, handles.txtFreq, handles.txtHz], 'Visible', 'Off')
end

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
function rdFileType_Callback(hObject, eventdata, handles)
% toggles the Input file Type radio buttons

set(handles.rdFileType, 'Value', 0)
set(hObject, 'Value', 1)

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function tblFiles_ButtonDownFcn(hObject, eventdata, handles)
% 

[Choice, Cancel] = listdlg('PromptString', 'TICK MARKS',...
    'SelectionMode','single',...
	'ListSize', [100 50],...
    'ListString', {'Mark All', 'Unmark All'});

if ~Cancel
    return
end

TableDat = get(hObject, 'Data');
if Choice == 1 % 'Mark All'
    TableDat(:,1) = {true};
else % Choice == 2 Unmark All
    TableDat(:,1) = {false};
end

set(hObject, 'Data', TableDat);


% --------------------------------------------------------------------
function mnTools_ToExcel_Callback(hObject, eventdata, handles)
% If you want to convert files to Excel .csv format -SIGH-

Answer = questdlg({'Converting to .csv format is SLOW',...
    'Do you really need to use Excel?',...
    'Surely DataPlot can do it better !'}, 'DON''T DO IT !',...
    'Continue', 'Cancel', 'Continue');
if strcmp(Answer, 'Continue')
    pbConvert_Callback(hObject, '.csv', handles)
end
