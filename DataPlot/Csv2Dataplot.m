% Csv2DataPlot: Used by Main program DataPlot.  
%       Converts .csv (comma seperated variables) to the DataPlot format
% Written by:	J. van Zyl
% Date:			2014
% Updated:      J. van Zyl
% Last Date:    2018-03-09


function varargout = Csv2DataPlot(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Csv2DataPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @Csv2DataPlot_OutputFcn, ...
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
function Csv2DataPlot_OpeningFcn(hObject, eventdata, handles, varargin)
% 
% Choose default command line output for csv2dataplot2
handles.output = hObject;
guidata(hObject, handles);% Update handles structure

try
    load Csv2D_Config.mat
    set(handles.edNewTxt, 'String', Fields.NewTxt)
    set(handles.edOldTxt, 'String', Fields.OldTxt)
    set(handles.edNumHeaderLines, 'String', Fields.NumHeaderLines)
    set(handles.edDelimter, 'String', Fields.Delimter)
    set(handles.edTimeCol, 'String', Fields.TimeCol)
catch
    Paths.DataIn = sprintf('%s\\',pwd);
    Paths.DataOut = sprintf('%s\\',pwd);
end
Paths.Exe = sprintf('%s\\',pwd);

setappdata(handles.Csv2DataPlot, 'Paths', Paths);

% Get Jabberwock logo
Jabberwock = imread('Jabberwock_m.jpg');
image(Jabberwock, 'Parent', handles.axJabberwock)
set(handles.axJabberwock, 'YTickLabel',[])
set(handles.axJabberwock, 'XTickLabel',[])
set(handles.axJabberwock, 'XTick',[])
set(handles.axJabberwock, 'YTick',[])
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes when user attempts to close csv2dataplot2.
function Csv2DataPlot_CloseRequestFcn(hObject, eventdata, handles)
% 
Paths =  getappdata(handles.Csv2DataPlot, 'Paths');

Fields.NewTxt = get(handles.edNewTxt, 'String');
Fields.OldTxt = get(handles.edOldTxt, 'String');
Fields.NumHeaderLines = get(handles.edNumHeaderLines, 'String');
Fields.Delimter = get(handles.edDelimter, 'String');
Fields.TimeCol = get(handles.edTimeCol, 'String');

save([Paths.Exe, 'Csv2D_Config.mat'], 'Paths', 'Fields')

delete(hObject);
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = Csv2DataPlot_OutputFcn(hObject, eventdata, handles)
% 
varargout{1} = handles.output;% Get default command line output from handles structure

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes on button press in pbConvert.
function pbConvert_Callback(hObject, ConversionType, handles)
% 

if strcmp(get(handles.pbConvert, 'String'), 'CANCEL')
    set(handles.pbConvert, 'String', 'CONVERT')
    set(handles.pbConvert, 'Visible', 'Off')
    MessageBox(handles, 'Wait while saving ', 'n')
    drawnow;
    return
end
set(handles.Csv2DataPlot, 'Pointer', 'watch')
set(handles.pbConvert, 'String', 'CANCEL')
set(handles.pbClear, 'Enable', 'Off')
drawnow;
ErrFlag = 0;
if isempty(get(handles.edInputFile, 'String'))
    errordlg('Need an Input File Name' , 'NO DIR')
    ErrFlag = 1;
end

if isempty(get(handles.edOutputDir, 'String')) || ~isdir(get(handles.edOutputDir, 'String'))
    errordlg('Need a Output directory or Output directory does not exist' , 'NO DIR')
    ErrFlag = 1;
end  

TimeCol = str2double(get(handles.edTimeCol, 'String'));
FileId = get(handles.edFileId, 'String');
OutputDir = [get(handles.edOutputDir, 'String'), '\'];
TimeFactor = eval(get(handles.edTimeFactor, 'String'));

MessageBox(handles, 'Importing the CSV file... ', 'n')
fid = fopen(get(handles.edInputFile, 'String'));
for I = 1:str2double(get(handles.edNumHeaderLines, 'String'))
    Line = fgetl(fid);
end

Pos = regexp(Line, ',');
NumPar = length(Pos)+1;

MessageBox(handles, 'Checking and fixing Parameter names... ', 'n') 
ParCnt = 1; Cnt = 0;
% Get the first parameter that is before the first ','
Parameter(1).Name = regexprep(Line(1:Pos(1)-1),...
    get(handles.edOldTxt, 'String'), get(handles.edNewTxt, 'String'));
Parameter(1).Value = [];
ParCnt = ParCnt + 1;

for I = 1:NumPar - 2 % Now for the rest of the parameters
    Parameter(ParCnt).Name = regexprep(Line(Pos(I)+1:Pos(I+1)-1),...
        get(handles.edOldTxt, 'String'), get(handles.edNewTxt, 'String'));  
    Parameter(ParCnt).Value = [];
    ParCnt = ParCnt + 1;
end
% Get the last parameter which does not have a ',' at the end
Parameter(ParCnt).Name = regexprep(Line(Pos(I+1)+1:end),...
        get(handles.edOldTxt, 'String'), get(handles.edNewTxt, 'String'));
Parameter(ParCnt).Value = [];

% Check that the variable name is valid
for I = 1:ParCnt   
    Parameter(I).Name = [get(handles.edPreamble, 'String'),Parameter(I).Name]; % Add a preamble to the variable name
    if ~isvarname(Parameter(I).Name) 
        if isvarname([regexprep(Parameter(I).Name,'[\W]+', '_')]) % If not try it with a char infront and removing all non chars
            Parameter(I).Name = [regexprep(Parameter(I).Name,'[\W]+', '_')];
        elseif isvarname(['a', regexprep(Parameter(I).Name,'[\W]+', '_')]) % If not try it with a char infront and removing all non chars
            Parameter(I).Name = ['a', regexprep(Parameter(I).Name,'[\W]+', '_')];
        else % Don't know whats wrong so give it a different name
            Cnt = Cnt + 1;
            Parameter(I).Name = ['BrokenParName_', num2str(Cnt)];
        end 
    end
end
Save2File(handles, Parameter, FileId, OutputDir, 1); % Save empty files to disk (Initialising)

Factor = round(5000000/sqrt(NumPar)); % Just to keep the data in managable chunks
for I = 0:NumPar-1
    FormatSpec(1+I*2:2+I*2) = '%f';
end

if ErrFlag
    set(handles.Csv2DataPlot, 'Pointer', 'arrow')
    set(handles.pbConvert, 'String', 'CONVERT')
    set(handles.pbClear, 'Enable', 'On')
    return
end
MessageBox(handles, 'Start Processing  ... ', 'n')
MessageBox(handles, 'Extracting data ... ', 'n')
% Actual code extracting and saving the data to your parameters
while ~feof(fid)
    if strcmp(get(handles.pbConvert, 'String'), 'CONVERT')
        MessageBox(handles, 'Data extraction Cancelled', 'n')
        break 
    end
    MessageBox(handles, 'Extracting data ... ', 'c') 
	Data = textscan(fid,FormatSpec,Factor,'delimiter',get(handles.edDelimter, 'String'), 'CollectOutput',1);   
    if isempty(Data{1}) % If Data is empty it means it can't read the next line because it is broken.
        MessageBox(handles, ['Possible corrupt data. Check for text in data at line : ', num2str(LastRecord + 1)], 'n')
        break
    else
        LastRecord = length(Data{1});
    end
    for I = 1:ParCnt 
        Parameter(I).Value = [Data{1}(:, TimeCol) Data{1}(:, I)];
    end  
    Save2File(handles, Parameter, FileId, OutputDir, 0); % Save the current data in mem to file
end
fclose(fid)
MessageBox(handles, 'Completed converting the selected files', 'n')

set(handles.Csv2DataPlot, 'Pointer', 'arrow')
set(handles.pbConvert, 'String', 'CONVERT')
set(handles.pbConvert, 'Visible', 'On')
set(handles.pbClear, 'Enable', 'On')
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function Save2File(handles, Parameter, FltNum, PathOutput, Initial)

if Initial % First save file does not exist yet
    for I = 1:length(Parameter)
        eval([Parameter(I).Name, ' = [];'])
        save(sprintf('%s%s.%s.mat', PathOutput,...
            Parameter(I).Name, char(FltNum)),...
            Parameter(I).Name);
    end
else
    for I = 1:length(Parameter)
        MessageBox(handles, ['Saving : ', Parameter(I).Name], 'c') 
        load(sprintf('%s%s.%s.mat', PathOutput,...
            Parameter(I).Name, char(FltNum)))
        eval([Parameter(I).Name,...
            ' = [', Parameter(I).Name, ' ; Parameter(I).Value];'])

        save(sprintf('%s%s.%s.mat', PathOutput,...
            Parameter(I).Name, char(FltNum)),...
            Parameter(I).Name);

        eval(['clear ', Parameter(I).Name]) % Clear variable that has been saved from memory
    end 
end
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes on button press in pbInputFile.
function pbInputFile_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.Csv2DataPlot, 'Paths');
[FileName, PathName] = uigetfile(sprintf('%s*',Paths.DataIn)); 
if isequal(FileName,0) || isequal(PathName,0)
    return
end
Paths.DataIn = PathName;
setappdata(handles.Csv2DataPlot, 'Paths', Paths);
set(handles.edInputFile, 'String', [PathName,FileName]);

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes on button press in pbOutputDir.
function pbOutputDir_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.Csv2DataPlot, 'Paths');
Dir = uigetdir(Paths.DataOut, 'Select the variable directory');
if isequal(Dir,0)
    return
end
Paths.DataOut = Dir;
setappdata(handles.Csv2DataPlot, 'Paths', Paths);
set(handles.edOutputDir, 'String', Dir);

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function MessageBox(handles, Text, Option)
CurrentText = get(handles.lbMsgBox, 'String');
switch Option
    case 'n' % New line
        CurrentText{end+1} = Text;
    case 'a' % Add to existing line
        if length(CurrentText{end}) > 70
            CurrentText{end+1} = Text;
        end
        CurrentText{end} = [CurrentText{end},Text];
    case 'c' % Change last line
        CurrentText{end} = Text;
end
set(handles.lbMsgBox, 'String', CurrentText)
set(handles.lbMsgBox, 'Value', length(get(handles.lbMsgBox, 'String')))
drawnow
refresh

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function pbClear_Callback(hObject, eventdata, handles)
% Clears the Message box on the bottom right
set(handles.lbMsgBox, 'String', '')
set(handles.pbConvert, 'Visible', 'On')
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function pbCheckHeader_Callback(hObject, eventdata, handles)
% 
pbConvert_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function edDelimter_Callback(hObject, eventdata, handles)
% 

set(handles.txtDelimeter, 'String', ['"|', get(hObject, 'String'), '|"'])
