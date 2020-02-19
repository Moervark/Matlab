function varargout = printK2DataPlot(varargin)
% PRINTK2DATAPLOT M-file for printK2DataPlot.fig  
% Begin initialization code - DO NOT EDIT
% Author Cobus van Zyl
% Date Started: 2013-11-05
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @printK2DataPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @printK2DataPlot_OutputFcn, ...
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

% *************************************************************************
% *************************************************************************
% --- Executes just before printK2DataPlot is made visible.
function printK2DataPlot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
handles.output = hObject; % Choose default command line output for printK2DataPlot
guidata(hObject, handles); % Update handles structure

try
    if regexpi(pwd,'printk') % Opened directly by user inside Pass2Mat directory
        load printK2D_Config.mat; 
    else % Opened by DataPlot from DataPlot directory
        load Conversion\printk\printK2D_Config.mat; 
    end
catch
    Paths.Load   = sprintf('%s\\',pwd);
    Paths.Output = sprintf('%s\\',pwd);
    Paths.Input  = sprintf('%s\\',pwd);
    Paths.Config = sprintf('%s\\Config\\',pwd);
end
if regexpi(pwd,'printk') % Opened directly by user inside Pass2Mat directory
    Paths.Exe = sprintf('%s\\',pwd); 
else % Opened by DataPlot from DataPlot directory
    Paths.Exe = sprintf('%s\\Conversion\\printk\\',pwd); 
end
setappdata(handles.printK2DataPlot, 'Paths', Paths)
set(handles.tblParam, 'Data', [])
set(handles.tblEnumerated, 'Data', [])

% Get Jabberwock logo
try % For some reason this does not always compile well and then the whole proagram hangs up because it does not want to load the image
cd(Paths.Exe)
Jabberwock = imread('../../Jabberwock_m.jpg');
image(Jabberwock, 'Parent', handles.axJabberwock)
set(handles.axJabberwock, 'YTickLabel',[])
set(handles.axJabberwock, 'XTickLabel',[])
set(handles.axJabberwock, 'XTick',[])
set(handles.axJabberwock, 'YTick',[])
catch
end

return
% *******************************
CodeForProfiler(handles, Paths)  % Use this function when running Profiler

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = printK2DataPlot_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
varargout{1} = handles.output; % Get default command line output from handles structure

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes when user attempts to close printK2DataPlot.
function printK2DataPlot_CloseRequestFcn(hObject, eventdata, handles)
% 
Paths = getappdata(handles.printK2DataPlot, 'Paths');
SaveSize = getappdata(handles.printK2DataPlot, 'SaveSize');
save([Paths.Exe, 'printK2D_Config.mat'], 'Paths', 'SaveSize')
delete(hObject); % closes the figure

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function mnFile_New_Callback(hObject, eventdata, handles)
% 
set(handles.txtConfigFile, 'String', 'No .cfg File')
setappdata(handles.printK2DataPlot, 'ParamList', [])
set(handles.tblParam, 'Data', [])
set(handles.tblEnumerated, 'Data', [])

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function mnFile_Save_Callback(hObject, eventdata, handles)
% Saves the config file

if strcmp(get(handles.txtConfigFile, 'String'), 'No .cfg File')
    mnFile_SaveAs_Callback([], [], handles)
    return
end

Paths = getappdata(handles.printK2DataPlot, 'Paths');
ParamList = getappdata(handles.printK2DataPlot, 'ParamList');

save([Paths.Config, get(handles.txtConfigFile, 'String')],'ParamList')
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function mnFile_SaveAs_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.printK2DataPlot, 'Paths');
ParamList = getappdata(handles.printK2DataPlot, 'ParamList');

[FileName,PathName] = uiputfile(sprintf('%s*.mat',...
    Paths.Config), 'Save Config file');
if isequal(FileName,0) || isequal(PathName,0)
    return
end

save([PathName, FileName],'ParamList')

Paths.Config = sprintf('%s',PathName);
setappdata(handles.printK2DataPlot, 'Paths', Paths);
set(handles.txtConfigFile, 'String', FileName)

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function mnFile_Load_Callback(hObject, eventdata, handles)
% Loads a config file

Paths = getappdata(handles.printK2DataPlot, 'Paths');

if get(findobj('String', 'TestPoints'), 'Value')
    [FileName, PathName] = uigetfile(sprintf('%s*.txt',Paths.Config));
else
    [FileName, PathName] = uigetfile(sprintf('%s*.mat',Paths.Config));
end

if isequal(FileName,0) || isequal(PathName,0)
    return
end

if get(findobj('String', 'TestPoints'), 'Value')
% For Testpoint files
    try
        fid = fopen([PathName, FileName]);
        Paths.Config = PathName;
        setappdata(handles.printK2DataPlot, 'Paths', Paths);
     catch ME
         msgbox('Config file is broken', 'Try another one');
         return
    end
    TpDatabase = textscan(fid, '%d %s %s %d %f');
    TpDatabase = FixNames(TpDatabase); % Make sure Parameter names are valid
    if length(TpDatabase{1}) ~= (length(TpDatabase{1}) + length(TpDatabase{2}) + length(TpDatabase{3}) + length(TpDatabase{4}))/4
        msgbox({'Some of the parameters are invalid', ...
                'Make sure it is in the form:', '', ...
                '[TestPointNumber ParameterName Type Factor] eg:', '',...
                '[135316274    ParamName_1    Float          32    1.0]', ...
                '[135316276    ParamName_2    Unsigned   8     4.5]', '',...
                'ParameterName can''t contain any spaces since this file is read as space delimited'}, ...
                'CONFIG FILE ERROR')
            return
    end
    fclose(fid); 
    setappdata(handles.printK2DataPlot, 'TpDatabase', TpDatabase)
    PopulateParamBox(handles)
else
% For Printk files
    try
        load([PathName, FileName])
        Paths.Config = PathName;
        setappdata(handles.printK2DataPlot, 'Paths', Paths);
     catch ME
         msgbox('Config file is broken', 'Try another one');
         return
    end
    % Printk
    % To be removed later !!!!!!!!!!!!!!!!!!!!
    % This is to remove the unused fields from ParamList OLD CONFIG FILE
    if length(fields(ParamList)) == 8
        ParamList = rmfield(ParamList, 'TimeString');
        ParamList = rmfield(ParamList, 'TimeOffset');
        ParamList = rmfield(ParamList, 'Hex');
    end
    setappdata(handles.printK2DataPlot, 'ParamList', ParamList)
    PopulateListBox(hObject, eventdata, handles)
end

set(handles.txtConfigFile, 'String', FileName)

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function PopulateParamBox(handles)
    TpDatabase = getappdata(handles.printK2DataPlot, 'TpDatabase');
    
    Data(:,1) = num2cell(TpDatabase{1});
    Data(:,2) = TpDatabase{2};
    Data(:,3) = TpDatabase{3};
    Data(:,4) = num2cell(TpDatabase{4});
    Data(:,5) = num2cell(TpDatabase{5});
    set(handles.tblTestPoints, 'Data', Data)
    
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function pbAdd_Callback(hObject, eventdata, handles)
% Adds new parameters to Parameter list

if(isempty(get(handles.edParamName, 'String'))... % Check that all fields are filled in
    || isempty(get(handles.edSearch, 'String'))...
    || isempty(get(handles.edOffset, 'String')));%...
    
    msgbox('Fill in all the fields','ERROR')
    return
end

ParamList = getappdata(handles.printK2DataPlot, 'ParamList');
if(~isempty(ParamList)) % Only perform parameter test if the ParamList is not empty
    if ~isempty(strmatch(get(handles.edParamName, 'String'), strvcat(ParamList.Name),'exact')) % Check if the parameter name is unique
        msgbox('Parameter name already exist','ERROR')
        return
    end
end

LineNum = 1; % Set LineNum =1 before testing if there are an actual parameter list 
if(~isempty(getappdata(handles.printK2DataPlot, 'ParamList'))) % in which case the LineNum is changed
    ParamList = getappdata(handles.printK2DataPlot, 'ParamList'); % to the last parameter + 1
    LineNum = length(ParamList) + 1;
end

VarName = deblank(get(handles.edParamName, 'String'));
if ~isvarname(VarName)
    msgbox(['Not a legal Parameter name:', char(10),...
        'Must start with a letter', char(10),...
        'Can''t contain special characters', char(10),...
        'No white spaces', char(10),...
        '"_" can be used.'],'ERROR')
    return
end
ParamList(LineNum).Name         = VarName;
ParamList(LineNum).SearchString = get(handles.edSearch, 'String');
ParamList(LineNum).Offset       = str2double(get(handles.edOffset, 'String'));
ParamList(LineNum).Enum(1).Num  = NaN;
ParamList(LineNum).Enum(1).Name = '';

if(get(handles.rdFactor, 'Value') == 1) % Is Factor radio button ticked ?
    ParamList(LineNum).Factor = str2num(get(handles.edFactor, 'String'));
else
    ParamList(LineNum).Factor = 1; % Make factor = 1 
end

setappdata(handles.printK2DataPlot, 'ParamList', ParamList)
PopulateListBox(hObject, eventdata, handles)

% **** END pbAdd_Callback ****
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
%
function PopulateListBox(hObject, eventdata, handles)
ParamList = getappdata(handles.printK2DataPlot, 'ParamList');

for I = 1:length(ParamList)
    tblData{I,1} = ParamList(I).Name;
    tblData{I,2} = ParamList(I).SearchString;
    tblData{I,3} = ParamList(I).Offset;
    tblData{I,4} = ParamList(I).Factor;
end

set(handles.tblParam, 'Data', tblData)

% **** END PopulateListBox ****
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function rdTxRx_Callback(hObject, eventdata, handles)
% 
set(handles.rdTxRx, 'Value', 0)
set(hObject, 'Value', 1)

% **** END rdTxRx_Callback ****
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function tblParam_CellEditCallback(hObject, eventdata, handles)
% 

ParamList = getappdata(handles.printK2DataPlot, 'ParamList'); % Get the current Parameter listing

switch eventdata.Indices(2) % Check which which column was edited 
    case 1                  % Indices(1) identifies in which row the edited cell is
      if isempty(eventdata.NewData)
            Quest = questdlg('Do you really want to delete this parameter ?',...
                    'WARNING','Yes','No','Yes');
            if(strcmp(Quest, 'Yes')) || (isempty(Quest))
                DeleteParameter(eventdata.Indices(1), handles);
                ParamList = getappdata(handles.printK2DataPlot, 'ParamList'); % Get the new Parameter listing
            end
      else
        if ~isvarname(eventdata.NewData)
            msgbox(['Not a legal Parameter name:', char(10),...
                'Must start with a letter', char(10),...
                'Can''t contain special characters', char(10),...
                'No white spaces', char(10),...
                '"_" can be used.'],'ERROR')
            Data = get(hObject, 'Data')
            Data{eventdata.Indices(1),1} = eventdata.PreviousData;
            set(hObject, 'Data', Data)
            return
        end
          ParamList(eventdata.Indices(1)).Name   = eventdata.NewData; % Name column
      end
    case 2
        ParamList(eventdata.Indices(1)).SearchString   = eventdata.NewData; % RT column
    case 3
        ParamList(eventdata.Indices(1)).Offset   = eventdata.NewData; % SA column
    case 4
        ParamList(eventdata.Indices(1)).Factor = eventdata.NewData; % Factor column
end

setappdata(handles.printK2DataPlot, 'ParamList', ParamList); % Set the new Parameter listing
PopulateListBox(hObject, eventdata, handles) % Update the display 
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function tblParam_CellSelectionCallback(hObject, eventdata, handles)
% Remembers the last cell that was highlighted
if isempty(eventdata.Indices)
    return
end
setappdata(handles.printK2DataPlot, 'SelParamCell', eventdata.Indices);
set(handles.pbSort, 'Visible', 'On')

ParamList = getappdata(handles.printK2DataPlot, 'ParamList');

if isfield(ParamList(eventdata.Indices(1)).Enum, 'Name')...
        && ~isempty(ParamList(eventdata.Indices(1)).Enum(1).Name)...
        || length(ParamList(eventdata.Indices(1)).Enum) > 1
    for I = 1:length(ParamList(eventdata.Indices(1)).Enum)
        Data(I,:) = [{ParamList(eventdata.Indices(1)).Enum(I).Num}, {ParamList(eventdata.Indices(1)).Enum(I).Name}];
    end
    set(handles.tblEnumerated, 'Data', Data);
else
    set(handles.tblEnumerated, 'Data', []);
end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function tblEnumerated_CellEditCallback(hObject, eventdata, handles)
% 
ParamList = getappdata(handles.printK2DataPlot, 'ParamList'); % Get the current Parameter listing
Row = getappdata(handles.printK2DataPlot, 'SelParamforEnum');
switch eventdata.Indices(2) % Check which which column was edited 
    case 1
        ParamList(Row(1)).Enum(eventdata.Indices(1)).Num   = eventdata.NewData; % Number
    case 2
        ParamList(Row(1)).Enum(eventdata.Indices(1)).Name   = eventdata.NewData; % Name
end

setappdata(handles.printK2DataPlot, 'ParamList', ParamList); % Set the new Parameter listing

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function pbAddEnum_Callback(hObject, eventdata, handles)
% 

ParamList = getappdata(handles.printK2DataPlot, 'ParamList'); % Get the current Parameter listing
Row = getappdata(handles.printK2DataPlot, 'SelParamCell');

EnumData = get(handles.tblEnumerated, 'Data');
set(handles.tblEnumerated, 'Data',[EnumData; {NaN} {''}])
ParamList(Row(1)).Enum(end+1).Name = '';
ParamList(Row(1)).Enum(end).Num = NaN;
setappdata(handles.printK2DataPlot, 'ParamList', ParamList); % Set the new Parameter listing
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function tblEnumerated_CellSelectionCallback(hObject, eventdata, handles)
% Remembers the last cell that was highlighted

if isempty(eventdata.Indices)
    set(handles.pbDelEnum, 'Visible', 'Off')
    return
end
setappdata(handles.printK2DataPlot, 'SelEnumCell', eventdata.Indices);
Row = getappdata(handles.printK2DataPlot, 'SelParamCell');
setappdata(handles.printK2DataPlot, 'SelParamforEnum', Row);
set(handles.pbDelEnum, 'Visible', 'On')
uicontrol(handles.txtConfigFile) % Move focus away from previous table. 
                                   % Still need to figure out how to put focus on this table
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function pbDelEnum_Callback(hObject, eventdata, handles)
% 
RowEnum = getappdata(handles.printK2DataPlot, 'SelEnumCell');
RowParam = getappdata(handles.printK2DataPlot, 'SelParamCell');

EnumList = get(handles.tblEnumerated, 'Data');
Tmp = EnumList(1:RowEnum(1)-1,:);
EnumList = [Tmp; EnumList(RowEnum(1) + 1:end,:)];
set(handles.tblEnumerated, 'Data',EnumList);

ParamList = getappdata(handles.printK2DataPlot, 'ParamList'); % Get the current Parameter listing
ParamList(RowParam(1)).Enum = [];
if ~isempty(EnumList)
    for I = 1:length(EnumList(:,1))
        ParamList(RowParam(1)).Enum(I).Num  = cell2mat(EnumList(I,1));
        ParamList(RowParam(1)).Enum(I).Name = char(EnumList(I,2));
    end
else
    ParamList(RowParam(1)).Enum(1).Num = NaN;
    ParamList(RowParam(1)).Enum(1).Name = '';
end
setappdata(handles.printK2DataPlot, 'ParamList', ParamList); % Set the new Parameter listing

set(handles.pbDelEnum, 'Visible', 'Off')
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function DeleteParameter(RowNumber, handles)
% Delete a parameter from the list

ParamList = getappdata(handles.printK2DataPlot, 'ParamList'); % Get the current Parameter listing
NewParamlist = ParamList(1:RowNumber-1); % Copy all up to the row before the deletion
NewParamlist(RowNumber:length(ParamList)-1) = ParamList(RowNumber+1:length(ParamList)); % Copy all after the deleted row
setappdata(handles.printK2DataPlot, 'ParamList', NewParamlist); % Set the new Parameter listing

% **** END DeleteParameter ****
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function pbDataFile_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.printK2DataPlot, 'Paths');

[FileName, PathName] = uigetfile(sprintf('%s*.bin',Paths.Load), 'SELECT FILE TO PARSE');
if isequal(FileName,0) || isequal(PathName,0)
    return
end
set(handles.edDataFile, 'String', sprintf('%s%s', PathName, FileName))
Paths.Load = PathName;

setappdata(handles.printK2DataPlot, 'Paths', Paths);
% **** END pbDataFile_Callback ****
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function pbOutputDir_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.printK2DataPlot, 'Paths');
PathOutput = uigetdir(Paths.Output, 'Specify the Output Directory');
if(PathOutput == 0)
    return
end
set(handles.edOutputDir, 'String', PathOutput)
Paths.Output = PathOutput;
setappdata(handles.printK2DataPlot, 'Paths', Paths);

% **** END pbOutputDir_Callback ****
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
%
function WTF_____rdFactor_Callback(hObject, eventdata, handles)
if(get(handles.rdFactor, 'Value') == 1)
    set(handles.edFactor, 'Enable', 'On')
else
    set(handles.edFactor, 'Enable', 'Off')
end

% **** END rdFactor_Callback ****
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function [Status, fidDatFile, FltNum, PathOutput] = CheckBeforeProcess(handles, StartSeconds)
Status = 1;
fidDatFile = fopen(get(handles.edDataFile, 'String'));

FltNum = get(handles.edOutputId, 'String');
PathOutput = get(handles.edOutputDir, 'String');

setappdata(handles.printK2DataPlot, 'BreakWhile', 0); % Clear the Break variable
if(strcmp(get(handles.pbProcess, 'String'), 'CANCEL')) % If CANCEL was pressed enter 
    setappdata(handles.printK2DataPlot, 'BreakWhile', 1);
    set(handles.pbProcess, 'String', 'PROCESS');
    set([handles.edProgress, handles.edIndicator], 'Visible', 'Off')
    drawnow;
    return 
end

if(fidDatFile == -1) || isempty(PathOutput) || isempty(FltNum)
    msgbox({'Fill in fields:' ,'- Data File Name', '- Output File ID', '- Output File Directory'},'INPUT ERR')
    set(handles.printK2DataPlot, 'Pointer', 'arrow')
    return
end

if(StartSeconds > 0)
    Status = fseek(fidDatFile, StartSeconds, 'bof');
    if(Status == -1)
        msgbox('Start time too big','START TIME')
        set(handles.printK2DataPlot, 'Pointer', 'arrow')
        return
    end
end

set(handles.edProgress, 'String', ''  , 'Visible', 'On')
set(handles.edIndicator, 'String', '0', 'Visible', 'On');
set(handles.txtSeconds, 'Visible', 'On');
set(handles.pbProcess, 'String', 'CANCEL');
drawnow;
Status = 0;

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function ProgressBar(handles,PrevTime, StartTime, EndTime)
if isnan(PrevTime)
    return
end
BarLen = round(134*(PrevTime - StartTime)/(EndTime - StartTime));
if BarLen > 150
    return % Obvious time error
end
Bartxt(1:BarLen) = '|';
set(handles.edProgress, 'String', Bartxt) 
LapsedTime = (PrevTime - StartTime);
set(handles.edIndicator, 'String', num2str(round(LapsedTime)))
drawnow

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function Save2FileFdl(ParamList, FltNum, PathOutput)

for I = 1:length(ParamList)
    load(sprintf('%s\\%s.%s.mat', PathOutput,...
        ParamList(I).Name, char(FltNum)))

    eval([ParamList(I).Name,...
        ' = [', ParamList(I).Name, ' ; ParamList(I).Data];'])
    
    save(sprintf('%s\\%s.%s.mat', PathOutput,...
        ParamList(I).Name, char(FltNum)),...
        ParamList(I).Name);

    eval(['clear ', ParamList(I).Name]) % Clear variable that has been saved from memory
end 

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function Parameters = Save2FileBin(Parameters, ParamName, FltNum, PathOutput)

for I = 1:length(ParamName)
    if isempty(Parameters.(ParamName{I}))
        continue
    end
    load(sprintf('%s\\%s.%s.mat', PathOutput,...
        ParamName{I}, char(FltNum)))
    eval([ParamName{I}, ' = [', ParamName{I}, ' ; Parameters.', ParamName{I}, '];'])
    save(sprintf('%s\\%s.%s.mat', PathOutput,...
        ParamName{I}, char(FltNum)), ParamName{I});
    eval(['clear ', ParamName{I}]) % Clear variable that has been saved from memory
    Parameters.(ParamName{I}) = []; % Clear the memory in the Data struct.
end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function AddVerbose(handles,TextInput)
% Add text to the message box
CurrentText = get(handles.lbVerbose, 'String');
CurrentText{end+1} = TextInput;
set(handles.lbVerbose, 'Value', length(CurrentText), 'String', CurrentText);
drawnow

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes on button press in pbClear.
function pbClear_Callback(hObject, eventdata, handles)
% Clear the message box
set(handles.lbVerbose, 'String', '')

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% Used to sort the parameters according to user pref.
function pbSort_Callback(hObject, eventdata, handles)

ParamList = getappdata(handles.printK2DataPlot, 'ParamList');
set(handles.pbSort, 'Visible', 'Off')
Indices = getappdata(handles.printK2DataPlot, 'SelParamCell');

% First get the struct into a cell format
for I = 1:length(ParamList)
    ParamList(I).Name;
    ParamListTmp{I,1} = ParamList(I).Name;
    ParamListTmp{I,2} = ParamList(I).SearchString;
    ParamListTmp{I,3} = ParamList(I).Offset;
    ParamListTmp{I,4} = ParamList(I).Factor;
    ParamListTmp{I,5} = ParamList(I).Enum;
end

NewListTmp = sortrows(ParamListTmp,Indices(2)); % Sort the list

% Now get the cell format back to the struct format 
for I = 1:length(ParamList)
    NewParamList(I).Name         = NewListTmp{I,1};
    NewParamList(I).SearchString = NewListTmp{I,2};
    NewParamList(I).Offset       = NewListTmp{I,3};
    NewParamList(I).Factor       = NewListTmp{I,4};
    NewParamList(I).Enum         = NewListTmp{I,5};
end

setappdata(handles.printK2DataPlot, 'ParamList', NewParamList)
PopulateListBox(hObject, eventdata, handles)

% **** END pbSort_Callback ****
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes on button press in pbTest.
function pbTest_Callback(hObject, eventdata, handles)
% 
if strncmp(get(hObject, 'String'), 'Test',4)
    set(hObject, 'String', 'CANCEL')
else
    set(hObject, 'String', 'Test Search String')
    return
end

Row = getappdata(handles.printK2DataPlot, 'SelParamCell');
if isempty(Row)
    msgbox('Select a parameter in the Parameter table', 'TEST ERROR')
    return
else
    Row = Row(1);
end
ParamList = getappdata(handles.printK2DataPlot, 'ParamList');
fid = fopen(get(handles.edDataFile, 'String'));
if fid == -1
    msgbox('Select an Input File', 'TEST ERROR')
    return
end

set(handles.printK2DataPlot, 'Pointer', 'watch')
pause(0.0001); % Too give pointer time to update
StrBuff = fread(fid,100000);

TmpBuff = ''; TimeFlag = 0;
ParamList(1).Data = []; PrevTime = -1; PosRS = 0;
BuffLen = 100000;

while ~feof(fid)  
    if length(TmpBuff) < BuffLen 
        pause(0.00001)
        if strncmp(get(hObject, 'String'), 'Test',4)
            break
        end
        if ~feof(fid) % Still data in the file
            TmpBuff = [TmpBuff; fread(fid,BuffLen, 'uint8=>char')];
        elseif isempty(PosRS) ... % There is no Record Seperator (RS) left in the remaining data.
                || PosRS + 35 > length(TmpBuff) % There is not enough data for a time stamp.
            break             % Done with file exit the while loop
        end
    end
   
    % Search for the next Time stamp in file
    PosRS = regexp(TmpBuff', [char(30),char(16)],'once'); % RS DLE
    
    if ~isempty(PosRS)... % Both RS & DLE were found
            && length(TmpBuff) > PosRS + 35 ... % Enough data to contain the Timestamp
            && TimeFlag == 0 % Still searching for the next Timestamp

        TimeFlag = 1;
        if PrevTime == -1 % Exception for the first time a Timestamp is found
            PrevTime = 0;
            TimeFlag = 0;
            TmpBuff = TmpBuff(PosRS+2:end);
            continue
        end
        
        StrBuff = TmpBuff(39:PosRS)'; % get rid of header 
        TmpBuff = TmpBuff(PosRS+2:end);
    elseif TimeFlag == 0
        continue; % Could not get the Timestamp so read more bytes into TmpBuff
    end 
    
    % Search for parameters in StrBuff
    Pos = regexp(StrBuff, ParamList(Row).SearchString, 'end');
    if Pos > 0
        TmpVar = GetVarValFdl(StrBuff,Pos, ParamList(Row).Offset);
        if isfield(ParamList(Row).Enum, 'Name') && ~isnan(ParamList(Row).Enum(1).Num)
            TmpVar = DoEnum(handles, TmpVar, ParamList(Row));
        elseif isnan(TmpVar)
            continue 
        end
        ParamList(Row).Data(end + 1,:) = [PrevTime TmpVar*ParamList(Row).Factor]; 
        AddVerbose(handles, sprintf('Value ##%f##', TmpVar))
        Answer = questdlg('Verify more Values?', 'TEST SEARCH STRING','YES','NO', 'Show String','NO');
        if strcmp(Answer, 'NO')
            break
        elseif strncmp(Answer, 'Show',4)
            AddVerbose(handles, StrBuff);
        end
    end         
    TimeFlag = 0; % Time to search for next Time Stamp
end

fclose(fid);
set(hObject, 'String', 'Test Search String');
set(handles.printK2DataPlot, 'Pointer', 'arrow')

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function pbProcess_Callback(hObject, ~, handles)

if get(findobj('String', 'TestPoints'), 'Value')
    ProcessBin(handles)
else
    ProcessFdl(handles)
end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function ProcessFdl(handles)
set(handles.printK2DataPlot, 'Pointer', 'watch')
StartSeconds = round(str2double(get(handles.edStartMinutes, 'String')) * 60);
%SaveSize = getappdata(handles.printK2DataPlot, 'SaveSize');
[Status, fid, FltNum, PathOutput] = CheckBeforeProcess(handles, StartSeconds);
if Status
    return
end

ParamList = getappdata(handles.printK2DataPlot, 'ParamList');
if(length(ParamList) < 1)
    msgbox('Load a config file first','INPUT ERR')
    set(handles.printK2DataPlot, 'Pointer', 'arrow')
    return
end

for I = 1:length(ParamList) % Deleting the files & Creating first instance of files
    eval([ParamList(I).Name, ' = [];'])
    try
        save(sprintf('%s\\%s.%s.mat', PathOutput, ParamList(I).Name, char(FltNum)), ParamList(I).Name)
    catch
        msgbox(sprintf('Could not save parameter: [%s] to file: [%s\\%s.%s.mat]',...
            ParamList(I).Name, PathOutput, ParamList(I).Name, char(FltNum)), 'SAVE ERROR')
        return
    end
    eval(['clear ', ParamList(I).Name, ';'])
end

[StartTime EndTime] = FindTime(fid); % Get the first and last time stamp in the file

TmpBuff = '';  CntSave = 0; Cnt = 0;
ParamList(1).Data = [];
BuffLen = 100000;
FlagEof = 0;
FlagEod = 0;

% Get first set of values into TempBuff & search for first RS DLE
RsDle = [char(30),char(16)]; % To Speed things up - Hopefully
TmpBuff = [TmpBuff; fread(fid,BuffLen, 'uint8=>char')];
PosRS = regexp(TmpBuff(1:end)', RsDle,'once');
PackLen = TmpBuff(PosRS+2)*256+TmpBuff(PosRS+3);
if strcmp(TmpBuff(PosRS + PackLen:PosRS + PackLen + 1)', RsDle)
      TmpBuff = TmpBuff(PosRS:end);
end

GpsTime = str2double(get(handles.edHour, 'String'))*3600 ...
        + str2double(get(handles.edMin, 'String'))*60 ...
        + str2double(get(handles.edSec, 'String'));

% % Activate Insomnia so that machine doesn'r enter standby while processing
% try
%     [status, task]=dos('pslist.exe insomnia');
%     if(findstr('process insomnia was not found', task))
%         !insomnia.exe &
%     end
% catch
% end

while ~getappdata(handles.printK2DataPlot, 'BreakWhile') && FlagEod == 0 % User has NOT pressed CANCEL and there's still data
    
    if length(TmpBuff) < BuffLen && FlagEof == 0
        if ~feof(fid) % Still data in the file
            TmpBuff = [TmpBuff; fread(fid,BuffLen, 'uint8=>char')];
        else
            FlagEof = 1;
        	AddVerbose(handles, 'End Of File')
        end
    end
    
    % Healthy packet so get Time Stamp
    TimeStamp = TmpBuff(30)*7.2058e+010 +... % 256^7/1e6  = 7.2058e+010 => faster processing this way
                TmpBuff(31)*2.8147e+008 +... % 256^6/1e6 
                TmpBuff(32)*1.0995e+006 +... % 256^5/1e6 
                TmpBuff(33)*4.2950e+003 +... % 256^4/1e6 
                TmpBuff(34)*1.6777e+001 +... % 256^3/1e6 
                TmpBuff(35)*6.5536e-002 +... % 256^2/1e6 
                TmpBuff(36)*2.5600e-004 +... % 256^1/1e6 
                TmpBuff(37)*1.0000e-006;     % 256^0/1e6 

    % Search for parameters in StrBuff
    for I = 1:length(ParamList) 
        Pos = regexp(TmpBuff(41:PackLen)', ParamList(I).SearchString, 'end');
        if Pos > 0
            TmpVar = GetVarValFdl(TmpBuff(41:PackLen)',Pos, ParamList(I).Offset);
            if isfield(ParamList(I).Enum, 'Name') && ~isnan(ParamList(I).Enum(1).Num)
                TmpVar = DoEnum(handles, TmpVar, ParamList(I));
            end
            if isempty(TmpVar) || isnan(TmpVar)
              %  AddVerbose(handles, [ParamList(I).Name, ' : #_', num2str(TmpVar), '_#']);
                continue  % Ignore this entry
            end            
            ParamList(I).Data(end + 1,:) = [TimeStamp + GpsTime TmpVar*ParamList(I).Factor]; 
 %           CntSave = CntSave + 1;
        end    
    end
    Cnt = Cnt + 1;
    if(Cnt > 1000)
        ProgressBar(handles, TimeStamp, StartTime, EndTime)% Progress bar Indication
        Cnt = 0;
        
%         CheckMem = memory; % Get the current matlab memory status
%         if(0.5*CheckMem.MemAvailableAllArrays < CheckMem.MemUsedMATLAB)... % Check if there is still enough memory left
%                 || strncmp(get(handles.pbForceSave, 'String'), 'Wait',4)   % Or if User has forced a save
%             Save2FileFdl(ParamList, FltNum, PathOutput); % Save the current data in mem to file
%             for I = 1:length(ParamList)
%                 ParamList(I).Data = []; % Clear the memory in the Data struct.
%             end
%             set(handles.pbForceSave, 'String', 'Interim Save')
%         end
        
        CntSave = CntSave + 1;
        if(CntSave > 10)     % Performs a save of current data in memory when CntSave > ??
            CntSave = 0;                      
            Save2FileFdl(ParamList, FltNum, PathOutput); % Save the current data in mem to file
            for I = 1:length(ParamList)
                ParamList(I).Data = []; % Clear the memory in the Data struct.
            end
        end
    end

    TmpBuff = TmpBuff(PackLen + 1:end);
    
    if TmpBuff < 40 % Check that there are still enough data left
        break % Should be Eof as well as end of data so climb out
    end
        
    % Search for the next Time stamp in file
    PackLen = TmpBuff(3)*256+TmpBuff(4); % Get length of packet
    if PackLen > length(TmpBuff) + 1 % Check that the packet lenght is not more than the data left in the buffer
        break % Should be Eof as well as end of data so climb out
    end
    
    if strcmp(TmpBuff(PackLen + 1:PackLen + 2)', RsDle) % Check if this packet ends just infront of a RS DLE
        continue
    else % Packet is dodgy so look for next RS DLE with a healthy packet
        AddVerbose(handles, [num2str(TimeStamp),': Broken packet # ', num2str(Cnt)]);
        [FlagEof, FlagEod, TmpBuff, PackLen] = GetNextHealthyPacket(handles, FlagEof, FlagEod, BuffLen, TmpBuff, RsDle, fid);
    end  
end

Save2FileFdl(ParamList, FltNum, PathOutput); % Save the remaining data in mem to file
fclose(fid); % Close pass3200 file

set([handles.edProgress, handles.edIndicator], 'Visible', 'Off')
set(handles.pbProcess, 'String', 'PROCESS')
set(handles.edIndicator, 'Visible', 'off');
set(handles.txtSeconds, 'Visible', 'off');
set(handles.printK2DataPlot, 'Pointer', 'arrow')


% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function ProcessBin(handles)
set(handles.printK2DataPlot, 'Pointer', 'watch')
StartSeconds = round(str2double(get(handles.edStartMinutes, 'String')) * 60);
SaveSize = getappdata(handles.printK2DataPlot, 'SaveSize');
[Status, fid, FltNum, PathOutput] = CheckBeforeProcess(handles, StartSeconds);
if Status
    return
end

TpDatabase = getappdata(handles.printK2DataPlot, 'TpDatabase');
TpLen = length(TpDatabase{1});

for I = 1:TpLen % Deleting the files & Creating first instance of files
    eval([TpDatabase{2}{I}, ' = [];'])
    try
        save(sprintf('%s\\%s.%s.mat', PathOutput, TpDatabase{2}{I}, char(FltNum)), TpDatabase{2}{I})
        Parameters.(TpDatabase{2}{I}) = [];
    catch Err
        msgbox(sprintf('Could not save parameter: [%s] to file: [%s\\%s.%s.mat]',...
            TpDatabase{2}{I}, PathOutput, TpDatabase{2}{I}, char(FltNum)), 'SAVE ERROR')
        return
    end
    eval(['clear ', TpDatabase{2}{I}, ';']);
    if I == 1
        TpDatabase{6}(I) = TpDatabase{4}(I)/8; % For I == 1
    else
        TpDatabase{6}(I) = TpDatabase{6}(I-1) + TpDatabase{4}(I)/8;  % For I > 1
    end
end

GpsTime = str2double(get(handles.edHour, 'String'))*3600 ...
        + str2double(get(handles.edMin, 'String'))*60 ...
        + str2double(get(handles.edSec, 'String'));
    
CntSave = 0; Cnt = 0; BuffLen = 100000; FlagEod = 0;

RsDle = [char(30),char(16)]; % To Speed things up - Hopefully
EndTime = GetEndTime(fid, RsDle);
TmpBuff = fread(fid ,BuffLen, 'uint8=>char');
[~, FlagEod, TmpBuff] = GetNextRsDle(handles, 0, FlagEod, BuffLen, TmpBuff(513:end), RsDle, fid);

PresVect = TmpBuff(9:512)*1; % get the Presence vector
PresVectLen = find(PresVect > 0, 1, 'last'); % Only use the relevant part of the Presence vector to save time

% Test if Presence vector and database ties up
PresVectBytes = (PresVectLen-1)*8 + length(dec2bin(PresVect(PresVectLen)));
if PresVectBytes ~= TpLen
    AddVerbose(handles, ['Presence Vector = ', num2str(PresVectBytes),...
        '   Test Points = ', num2str(TpLen)])
    AddVerbose(handles, 'Possibly a Test point database error')
    setappdata(handles.printK2DataPlot, 'BreakWhile', 1)
end
%tic
while  ~getappdata(handles.printK2DataPlot, 'BreakWhile') && FlagEod == 0     
    TimeStamp = (TmpBuff(5)*16777216 + TmpBuff(6)*65536 + TmpBuff(7)*256 + TmpBuff(8))*0.02; % Time in Seconds
    PresVect = TmpBuff(9:512)*1; % get the Presence vector
    Pos = 513; % Firts bytes after the Presence vector

    for I = 1:PresVectLen       
        if PresVect(I) % If this byte is zero skip the entire byte - saves time
            for J = 1:8
                if bitget(PresVect(I), J) % BITAND is not FASTER 
                    TpPos = 8*(I-1)+J; % (8 Bits in a byte) times I bytes + current bit J                    
                    Bytes = TpDatabase{4}(TpPos)/8;
                    TmpVar = GetVarValBin(handles,TmpBuff(Pos : Pos -1 + Bytes),...
                                                [TpDatabase{3}{TpPos},num2str(TpDatabase{4}(TpPos))]);
                    Parameters.(TpDatabase{2}{TpPos})(end+1,:) = [TimeStamp + GpsTime TmpVar*TpDatabase{5}(TpPos)];
                    Pos = Pos + Bytes;
                end
            end
        end
    end

    Pos = 4*ceil((Pos+2)/4) + 1;
    if Pos ~= 4*ceil((TmpBuff(3)*256 + TmpBuff(4)*1)/4) + 1
        AddVerbose(handles, ['Packet Length = ', num2str(4*ceil((TmpBuff(3)*256 + TmpBuff(4)*1)/4)),...
            '  Data Length = ', num2str(Pos), '   Most likely a Test Point database error'])
    end
    
    [~, FlagEod, TmpBuff] = GetNextRsDle(handles, 0, FlagEod, BuffLen, TmpBuff(Pos:end), RsDle, fid); % Pos + 2 is to skip the CRC
  
    % HOUSE KEEPING Update Progress bar and save when data gets too big
    Cnt = Cnt + 1;
    if(Cnt > 500) % Random number gives a good update rate
        ProgressBar(handles, TimeStamp, 0, EndTime)% Progress bar Indication
        Cnt = 0;
        CntSave = CntSave + 1;
        
        if CntSave > 10
 %           BeforeSave = toc;
%         CheckMem = memory; % Get the current matlab memory status
%         if(0.5*CheckMem.MemAvailableAllArrays < CheckMem.MemUsedMATLAB)... % Check if there is still enough memory left
%                 || strncmp(get(handles.pbForceSave, 'String'), 'Wait',4)   % Or if User has forced a save

            Parameters = Save2FileBin(Parameters, TpDatabase{2}, FltNum, PathOutput); % Save the current data in mem to file
            set(handles.pbForceSave, 'String', 'Interim Save')
            CntSave = 0;
   %         AddVerbose(handles, ['TIME => Cycle = ', num2str(BeforeSave), '  Save = ', num2str(toc - BeforeSave)])
   %         tic
        end
    end
end

Save2FileBin(Parameters, TpDatabase{2}, FltNum, PathOutput); % Save the current data in mem to file
fclose(fid); % Close pass3200 file

set([handles.edProgress, handles.edIndicator], 'Visible', 'Off')
set(handles.pbProcess, 'String', 'PROCESS')
set(handles.edIndicator, 'Visible', 'off');
set(handles.txtSeconds, 'Visible', 'off');
set(handles.printK2DataPlot, 'Pointer', 'arrow')

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function TpDatabase = FixNames(TpDatabase)
Cnt = 0;
for I = 1:length(TpDatabase{1})
    TpDatabase{2}{I} = regexprep(TpDatabase{2}{I}, '\W','_'); % Replace any non letter or digit with "_"
    TpDatabase{2}{I} = regexprep(TpDatabase{2}{I}, '^\d', ['D', TpDatabase{2}{I}(1)]); % If it starts with a digit replace add a "D" infront  
    TpDatabase{2}{I} = ['T', num2str(TpDatabase{1}(I)), '_', TpDatabase{2}{I}];
    if length(TpDatabase{2}{I}) > 62; % Max allowable parameter name length in Matlab
        TpDatabase{2}{I} = [TpDatabase{2}{I}(1:60), '_', num2str(Cnt)]; % Assign unique Cnt in case more than one variable looks the same
        Cnt = Cnt+1;
    end
end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function TmpVar = GetVarValBin(handles,StrBuff, Type)

switch Type
    case 'Boolean8'
        TmpVar = StrBuff(1)*1;
        
    case 'Signed8'
        TmpVar = StrBuff(1)*1;
        if TmpVar >= 128 % 2^7
            TmpVar = TmpVar - 256; % 2^8 2's complement
        end
        
    case 'Signed16'
        TmpVar = StrBuff(1)*256 + StrBuff(2)*1;
        if TmpVar >= 32768 % 2^15
            TmpVar = TmpVar - 65536; % 2^16 2's complement
        end
        
    case 'Signed32'
        TmpVar = StrBuff(1)*16777216 + StrBuff(2)*65536 ...
                + StrBuff(3)*256 + StrBuff(4);
        if TmpVar >= 2147483648 % 2^31
            TmpVar = TmpVar - 4294967296; % 2^32 2's complement
        end
        
    case 'Signed64'
        TmpVar = StrBuff(1)*7.2058e+016 + StrBuff(2)*2.8147e+014 ...
                + StrBuff(3)*1.0995e+012 + StrBuff(4)*4.2950e+009 ...
                + StrBuff(5)*16777216 + StrBuff(6)*65536 ...
                + StrBuff(7)*256 + StrBuff(8)*1;
        if TmpVar >= 9.223372036854776e+018 % 2^63
            TmpVar = TmpVar - 1.844674407370955e+019; % 2^64 2's complement
        end
        
    case 'Unsigned8'
        TmpVar = StrBuff(1)*1;
        
    case 'Unsigned16'   
        TmpVar = StrBuff(1)*256 + StrBuff(2)*1;
        
    case 'Unsigned32'   
        TmpVar = StrBuff(1)*16777216 + StrBuff(2)*65536 ...
                + StrBuff(3)*256 + StrBuff(4)*1;
        
    case 'Unsigned64'   
        TmpVar = StrBuff(1)*7.2058e+016 + StrBuff(2)*2.8147e+014 ...
                + StrBuff(3)*1.0995e+012 + StrBuff(4)*4.2950e+009 ...
                + StrBuff(5)*16777216 + StrBuff(6)*65536 ...
                + StrBuff(7)*256 + StrBuff(8)*1;
            
    case 'Float32'
        TmpVar = hex2num32([MyDec2hex(StrBuff(1),2), MyDec2hex(StrBuff(2),2),...
                        MyDec2hex(StrBuff(3),2), MyDec2hex(StrBuff(4),2)]);
                    
    case 'Float64'
        TmpVar = hex2num64([MyDec2hex(StrBuff(1),2), MyDec2hex(StrBuff(2),2),...
                        MyDec2hex(StrBuff(3),2), MyDec2hex(StrBuff(4),2),...
                        MyDec2hex(StrBuff(5),2), MyDec2hex(StrBuff(6),2),...
                        MyDec2hex(StrBuff(7),2), MyDec2hex(StrBuff(8),2)])           
    otherwise
        AddVerbose(handles, ['Can''t find Type: ', Type])
        TmpVar = 0;  
end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function TmpVar = GetVarValFdl(StrBuff, Pos, Offset)
    % 256^2 = 65536         Computing is faster this way
    % 256^3 = 16777216
    % 256^4 = 4294967296
    % 256^5 = 1099511627776
    % 256^6 = 281474976710656
    % 256^7 = 72057594037927940
TmpVar = [];
PosVar = regexp(StrBuff, '%\d?\d?\.?\d?\d?[hl]*[uidfsxX]'); % Get all the variable positions
ThisVar = find(PosVar == 1+Pos+Offset); % Get the position of this variable inside PosVar
PosVarDat = regexp(StrBuff, char(0), 'once') + 1;

for J = 1:ThisVar
    if J == length(PosVar)
        VarFormat = StrBuff(PosVar(J):end); % Move to start of next % format specifier !!!!!!!!!! Should maybe limit this ?????
    else
        VarFormat = StrBuff(PosVar(J):PosVar(J+1)-1); % Move to start of next % format specifier
    end
    %------------ 16 bit Signed Integer
    if strncmp(VarFormat, '%hi',3) || strncmp(VarFormat, '%hd',3)
        if J == ThisVar
            TmpVar = StrBuff(PosVarDat)*256 + StrBuff(PosVarDat+1);
            if TmpVar >= 32768 % 2^15
                TmpVar = TmpVar - 65536; % 2^16 2's complement
            end
        else
            PosVarDat = PosVarDat + 2;
        end
        continue
    end
    %------------ 16 bit Unsigned Integer
    if strncmp(VarFormat, '%hu',3)
        if J == ThisVar
            TmpVar = StrBuff(PosVarDat)*256 + StrBuff(PosVarDat+1);
        else
            PosVarDat = PosVarDat + 2;
        end
        continue
    end
    %------------ 8 bit Unsigned Integer
    if strncmp(VarFormat, '%hhu',4)
        if J == ThisVar
            TmpVar = double(StrBuff(PosVarDat));
        else
            PosVarDat = PosVarDat + 1;
        end
        continue
    end   
    %------------ 32 bit Signed Integer
    if strncmp(VarFormat, '%d',2) || strncmp(VarFormat, '%i',2)
        if J == ThisVar
            TmpVar = StrBuff(PosVarDat)*16777216 + StrBuff(PosVarDat+1)*65536 + ... 
                     StrBuff(PosVarDat+2)*256 + StrBuff(PosVarDat+3);

            if TmpVar >= 2147483648 % 2^31
                TmpVar = TmpVar - 4294967296; % 2^32 2's complement
            end
        else
            PosVarDat = PosVarDat + 4;
        end
        continue
    end
    %------------ 64 bit Float - it seems that in the .fdl files %f (32bit) gets converted to %lf (64bit)
    if regexp(VarFormat, '%[\d\.l]*f', 'once')
        if J == ThisVar
            TmpVar = hex2num([MyDec2hex(StrBuff(PosVarDat),2), MyDec2hex(StrBuff(PosVarDat+1),2),... % STREAMLINE!!!
                            MyDec2hex(StrBuff(PosVarDat+2),2), MyDec2hex(StrBuff(PosVarDat+3),2),...
                            MyDec2hex(StrBuff(PosVarDat+4),2), MyDec2hex(StrBuff(PosVarDat+5),2),...
                            MyDec2hex(StrBuff(PosVarDat+6),2), MyDec2hex(StrBuff(PosVarDat+7),2)]);
        else
            PosVarDat = PosVarDat + 8;
        end
        continue
    end

    %------------ String made of 8 bit char, terminated by 0x00
    if strncmp(VarFormat, '%s',2)
        if J == ThisVar
            TmpVar = StrBuff(PosVarDat:PosVarDat+regexp(StrBuff(PosVarDat:end), char(0), 'once')-2);
        else
            PosVarDat = PosVarDat + regexp(StrBuff(PosVarDat:end), char(0), 'once');
        end
        continue
    end
    %------------ Hexadecimal made of 16 bit unsigned integers
    if regexp(VarFormat, '%[\d]*[xX]', 'once')
        if J == ThisVar
            TmpVar = StrBuff(PosVarDat)*16777216 + StrBuff(PosVarDat+1)*65536 ...
                   + StrBuff(PosVarDat+2)*256   + StrBuff(PosVarDat+3);
        else
            PosVarDat = PosVarDat + 4;
        end
        continue
    end
    %------------ Unsigned 32 bit
    if strncmp(VarFormat, '%u',2) 
        if J == ThisVar
            TmpVar = StrBuff(PosVarDat)*16777216 + StrBuff(PosVarDat+1)*65536 ...
                   + StrBuff(PosVarDat+2)*256   + StrBuff(PosVarDat+3);
        else
            PosVarDat = PosVarDat + 4;
        end
        continue
    end
    %------------ 64 bit Unsigned Integer
    if strncmp(VarFormat, '%lu',3)
        if J == ThisVar
            TmpVar = StrBuff(PosVarDat  )*72057594037927940 + StrBuff(PosVarDat+1)*281474976710656 ...
                   + StrBuff(PosVarDat+2)*1099511627776 + StrBuff(PosVarDat+3)*4294967296 ...
                   + StrBuff(PosVarDat+4)*16777216 + StrBuff(PosVarDat+5)*65536 ...
                   + StrBuff(PosVarDat+6)*256   + StrBuff(PosVarDat+7);
        else
            PosVarDat = PosVarDat + 8;
        end
    end  
end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function EndTime = GetEndTime(fid, RsDle)
    
% Get EndTime
fseek(fid,-2000,'eof'); % Only want to search the last 2000 characters (~30 lines) to save time
TmpBuff = fread(fid, 'uint8=>char'); 

PosRsDle = regexp(TmpBuff(1:end-10)', RsDle); % Find RS DLE (The End - 10 is to ensure that there is at least a time value after the RsDle)
Pos = PosRsDle(end);
EndTime = (TmpBuff(Pos+4)*16777216 + TmpBuff(Pos+5)*65536 ...
            + TmpBuff(Pos+6)*256 + TmpBuff(Pos+7))*0.02; % Time in Seconds    

frewind(fid); % Rewind to start of file

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function [FlagEof, FlagEod, TmpBuff] = GetNextRsDle(handles, FlagEof, FlagEod, BuffLen, TmpBuff,RsDle,fid)
    
    if TmpBuff(1:2)*1 == [30 ; 16] % This is the RsDle
        PackLen = 4*ceil((TmpBuff(3)*256 + TmpBuff(4)*1)/4); 
        if length(TmpBuff) < PackLen + 7  % At least 6 bytes => 2 Bytes for previous CRC + 2 Bytes for next RS DLE + 2 Bytes for next Packet length 
            % Make sure there's enough data in TmpBuff to work with
            if ~feof(fid) % Still data in the file
                TmpBuff = [TmpBuff; fread(fid,BuffLen, 'uint8=>char')];
            else
                FlagEod = 1;
                AddVerbose(handles, 'End Of File')
            end
        end         
    else
        [FlagEof, FlagEod, TmpBuff, PackLen] = GetNextHealthyPacket(handles, FlagEof, FlagEod, BuffLen, TmpBuff,RsDle,fid);
    end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function [FlagEof, FlagEod, TmpBuff, PackLen] = GetNextHealthyPacket(handles, FlagEof, FlagEod, BuffLen, TmpBuff,RsDle,fid)
    while 1 % Broken packet   
        % Make sure there's enough data in TmpBuff to work with
        if length(TmpBuff) < BuffLen && FlagEof == 0
            if ~feof(fid) % Still data in the file
                TmpBuff = [TmpBuff; fread(fid,BuffLen, 'uint8=>char')];
            else
                FlagEof = 1;
                AddVerbose(handles, 'End Of File')
            end
        end

        PosRS = regexp(TmpBuff(2:end)', RsDle,'once')+1; % Try and find a RS DLE in the remaining data
        if isempty(PosRS)
            if FlagEof == 1  % Could not find a RS DLE and there are no more data in the files
                FlagEod = 1; % So tell the external While loop that this is the end of the data
                break        % and break from this while loop
            else
                continue
            end
        end

        TmpBuff = TmpBuff(PosRS:end); % supposedly start of new packet
        PackLen = TmpBuff(3)*256+TmpBuff(4); % Get the length of this new packet                
        if PackLen < length(TmpBuff) + 2 % Check that the packet lenght is not more than the data left in the buffer
            if strcmp(TmpBuff(PackLen+1:PackLen + 2)', RsDle)
                TimeStamp = TmpBuff(5)*16777216 + TmpBuff(6)*65536 + TmpBuff(7)*256 + TmpBuff(8)*1;
                AddVerbose(handles, ['Broken Packet before: ', num2str(TimeStamp*0.02), 's'])
                break  % Next Packet is healthy
            else
                TmpBuff = TmpBuff(PosRS+1:end);
            end
        else                % Packet length is more than data left in Buffer
            FlagEod = 1;    % So tell the external While loop that this is the end of the data
            break;          % and break from this while loop
        end
    end
    
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function TmpVar = DoEnum(handles,TmpVar, List)
% Sub function for ProcessFdl 
EnumFlag = 0;
for J = 1:length(List.Enum)
    if strcmp(deblank(TmpVar), deblank(List.Enum(J).Name))
        TmpVar = List.Enum(J).Num;
        EnumFlag = 1;
        break
    end
end
if EnumFlag == 0
%    AddVerbose(handles, ['Value "', TmpVar,...
%        '" not defined in Enumerated types for parameter: ', List.Name])
    TmpVar = NaN; 
end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function [StartTime EndTime] = FindTime(fid)
% Sub function for ProcessFdl 
StartTime = -1;
DataBuff = '';
TmpBuff = fread(fid,1000, 'uint8=>char');
while ~feof(fid) % Get StartTime
    DataBuff = [DataBuff; TmpBuff];
    PosRS = regexp(DataBuff', [char(30),char(16)],'once'); % RS DLE
    if ~isempty(PosRS)
        TmpBuff = fread(fid,40, 'uint8=>char'); % Make sure the time is part of this DataBuff
        DataBuff = [DataBuff; TmpBuff]; % 
        
        StartTime = DataBuff(PosRS+29)*256^7 +...
                    DataBuff(PosRS+30)*256^6 +...
                    DataBuff(PosRS+31)*256^5 +...
                    DataBuff(PosRS+32)*256^4 +...
                    DataBuff(PosRS+33)*256^3 +...
                    DataBuff(PosRS+34)*256^2 +...
                    DataBuff(PosRS+35)*256   +...
                    DataBuff(PosRS+36);        
                       
        StartTime = StartTime/1e6;
        break
    else
        TmpBuff = fread(fid,1000, 'uint8=>char');
        continue
    end
end

% Get EndTime
fseek(fid,-50000,'eof'); % Only want to search the last 2000 characters (~30 lines) to save time
DataBuff = fread(fid, 'uint8=>char'); 
TmpTime = 0;
while 1
    PosRS = regexp(DataBuff', [char(30),char(16)],'once'); % RS DLE
    if ~isempty(PosRS) && length(DataBuff)-PosRS > 35
        
        EndTime = TmpTime; % In case the final package is broken giving weird answers
        TmpTime = DataBuff(PosRS+29)*256^7 +...
                    DataBuff(PosRS+30)*256^6 +...
                    DataBuff(PosRS+31)*256^5 +...
                    DataBuff(PosRS+32)*256^4 +...
                    DataBuff(PosRS+33)*256^3 +...
                    DataBuff(PosRS+34)*256^2 +...
                    DataBuff(PosRS+35)*256   +...
                    DataBuff(PosRS+36);                         
        TmpTime = TmpTime/1e6;
        DataBuff = DataBuff(PosRS + 36:end);
    else
        break
    end
end
frewind(fid);

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------    
function x = hex2num32(s)
% Converts a hexadecimal 8-byte character string into the equivalent 32-bit floating
% point number. 
d = abs(s);
d=(d-48).*(d<58)+(d-55).*(d>58);
s=(-1).^(d(:,1)>7);
e=32*d(:,1)-256*(d(:,1)>7)+2*d(:,2)+(d(:,3)>7);
f=[2*d(:,3:7)-16*(d(:,3:7)>7)+(d(:,4:8)>7), 2*d(:,8)-16*(d(:,8)>7)];
f=f*[6.250000000000000e-002;3.906250000000000e-003;2.441406250000000e-004;...
   1.525878906250000e-005;9.536743164062500e-007;5.960464477539063e-008];

i1=find(e<255&e>0); % valid number
i2=find(e==255&f); % NaN
i3=find(e==255&~f); % Inf's
i4=find(e==0); % denormalized

x=zeros(1,1);
if i1,x(i1)=pow2(1+f(i1),e(i1)-127).*s(i1);end
if i2,x(i2)=nan;end
if i3,x(i3)=s(i3).*inf;end
if i4,x(i4)=pow2(f(i4),e(i4)-126).*s(i4);end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------    
function x = hex2num64(s)

d = abs(s);
d=(d-48).*(d<58)+(d-55).*(d>58);
neg = d(1) > 7;

%The leading character being greater than 7 implies a negative number.
d(1) = d(1)-8*neg;

% Floating point exponent.
e = 256*d(1) + 16*d(2) + d(3) - 1023;

% Floating point fraction.
sixteens = [16;256;4096;65536;1048576;16777216;268435456];
sixteens2 = 268435456*sixteens(1:6);
multiplier = 1./[sixteens;sixteens2];
f = d(4:16)*multiplier;

x = zeros(1,1);
% Scale the fraction by 2 to the exponent.
overinf = find((e>1023) & (f==0));
if ~isempty(overinf)
    x(overinf) = inf;
end

overNaN = find((e>1023) & (f~=0));
if ~isempty(overNaN)
    x(overNaN) = NaN;
end

underflow = find(e<-1022);
if ~isempty(underflow)
    x(underflow) = pow2(f(underflow),-1022);
end

allothers = find((e<=1023) & (e>=-1022));
if ~isempty(allothers)
    x(allothers) = pow2(1+f(allothers),e(allothers));
end

negatives = find(neg);
if ~isempty(negatives)
    x(negatives) = -x(negatives);
end
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------    
function rdInputType_Callback(hObject, eventdata, handles)
% 
set(handles.rdInputType, 'Value', 0)
set(hObject, 'Value', 1)

if get(findobj('String', 'TestPoints'), 'Value')
    set(handles.tblTestPoints , 'Visible', 'On')
    set(handles.tblParam , 'Visible', 'Off')
    set(handles.tblEnumerated , 'Visible', 'Off')
    set(handles.pbAddEnum , 'Visible', 'Off')
    set(handles.pbDelEnum , 'Visible', 'Off')
    set(handles.pbTest , 'Visible', 'Off')
    set(handles.pnAddPrintk , 'Visible', 'Off')
else
    set(handles.tblTestPoints , 'Visible', 'Off')
    set(handles.tblParam , 'Visible', 'On')
    set(handles.tblEnumerated , 'Visible', 'On')
    set(handles.pbAddEnum , 'Visible', 'On')
    set(handles.pbDelEnum , 'Visible', 'On')
    set(handles.pbTest , 'Visible', 'On')
    set(handles.pnAddPrintk , 'Visible', 'On')
end
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function d = MyHex2Dec(h)

h = char(h);
if(length(h)~= 4) % Should take care of most anomalies in data such  
    d = 99999;    % as the "GAP" or "  " problems 
    return
end

d = h <= 64; % For the numbers subtrack 48
h(d) = h(d) - 48; 
 
d =  h > 64; % For the letters subtrack 55
h(d) = h(d) - 55; 

d = sum(h.*[4096 256 16 1],2); 

% -------------------------------------------------------------------------
% ------------------------------------------------------------------------- 
function h = MyDec2hex(d,n)

bits32 = 4294967296;       % 2^32



if nargin==1,
    n = 1; % Need at least one digit even for 0.
end

[~,e] = log2(double(max(d)));
n = max(n,ceil(e/4));

%For small enough numbers, we can do this the fast way.
if all(d<bits32),
    h = sprintf('%0*X',[n,d]');
else
    %Division acts differently for integers
    d = double(d);
    d1 = floor(d/bits32);
    d2 = rem(d,bits32);
    h = sprintf('%0*X%08X',[n-8,d1,d2]');
end

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function CodeForProfiler(handles, Paths) 
% Use this function when running Profiler. 

load([Paths.Config, 'Ciu.mat'])
set(handles.edDataFile, 'String', 'C:\WORK\Data\printk\ciu\CIU_6_NOV\N249_F842.txt')
set(handles.edOutputDir, 'String', 'C:\WORK\Data\printk\ciu\CIU_6_NOV\N249_F849')
setappdata(handles.printK2DataPlot, 'ParamList', ParamList)
set(handles.edOutputId, 'String', '849');
refresh
ProcessFdl(handles)

set(handles.edDataFile, 'String', 'Y:\Data\RunwayTests\20131127-RunwayTest2\uavc_303_613\data.bin')
set(handles.edOutputDir, 'String', 'C:\WORK\Data\tmp')
set(handles.edOutputId, 'String', '000');
fid = fopen([Paths.Config, 'TestPoints.txt']);
TpDatabase = textscan(fid, '%d %s %s %d %f');
TpDatabase = FixNames(TpDatabase); % Make sure Parameter names are valid
fclose(fid); 
setappdata(handles.printK2DataPlot, 'TpDatabase', TpDatabase)
PopulateParamBox(handles)
refresh
ProcessBin(handles)

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function pbForceSave_Callback(hObject, eventdata, handles)
%
    set(hObject, 'String', 'Wait...')

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function mnHelp_Help_Callback(hObject, eventdata, handles)
% 

Paths = getappdata(handles.printK2DataPlot, 'Paths');
web(sprintf('%s\\HelpFiles\\printK2DataPlot.html', Paths.Exe))

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
function mnFile_Properties_Callback(hObject, eventdata, handles)
% 
try
    SaveSize = getappdata(handles.printK2DataPlot, 'SaveSize');
catch
    SaveSize = 5;
end
SaveSize = str2double(inputdlg('This is experimental! Select a Size between 1 and 100, 5 is default, This determines how often the data in memory is saved to hard disk, bigger chunks is better but you can run out of memory', 'MEMORY / FILE SIZE'));
setappdata(handles.printK2DataPlot, 'SaveSize', SaveSize);

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function mnHelp_About_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.printK2DataPlot, 'Paths');

eval(['!"', Paths.Exe, '..\..\md5.exe" -n -o"', Paths.Exe, 'CRC_tmp.txt" "',...
    Paths.Exe, mfilename, '.exe"']); % Get CRC for exe
a = textread([Paths.Exe, 'CRC_tmp.txt'],'%s'); % Read checksum from txt file
delete([Paths.Exe, 'CRC_tmp.txt']);
s = char(a); % Convert string from cell to char format
W1 = 0; W2 = 0; 
for I = 1:16
    W1 = W1 + s(I); % Add first 16 characters
    W2 = W2 + s(I+16); % Add second set of 16 characters
end
CRC = MyDec2hex(W1*W2); % Multiply 2 sets for own unique checksum

Version={'printK2DataPlot - Version 5.1';...
         'Date: 2014-08-11';...
        ['CRC: ', CRC, '']; char(10);...
        'Developer: Cobus van Zyl'};
Handle=helpdlg(Version,'printK2DataPlot');

% *************************************************************************
% *************************************************************************
% *************************************************************************
% *************************************************************************
% *************************************************************************
% *************************************************************************

% % -------------------------------------------------------------------------
% % -------------------------------------------------------------------------
% function crc_val = CalcCrc(TmpBuff)
% 
% crc_table = hex2dec(['0000';'1189';'2312';'329b';'4624';'57ad';'6536';'74bf';
%                      '8c48';'9dc1';'af5a';'bed3';'ca6c';'dbe5';'e97e';'f8f7';
%                      '1081';'0108';'3393';'221a';'56a5';'472c';'75b7';'643e';
%                      '9cc9';'8d40';'bfdb';'ae52';'daed';'cb64';'f9ff';'e876';
%                      '2102';'308b';'0210';'1399';'6726';'76af';'4434';'55bd';
%                      'ad4a';'bcc3';'8e58';'9fd1';'eb6e';'fae7';'c87c';'d9f5';
%                      '3183';'200a';'1291';'0318';'77a7';'662e';'54b5';'453c';
%                      'bdcb';'ac42';'9ed9';'8f50';'fbef';'ea66';'d8fd';'c974';
%                      '4204';'538d';'6116';'709f';'0420';'15a9';'2732';'36bb';
%                      'ce4c';'dfc5';'ed5e';'fcd7';'8868';'99e1';'ab7a';'baf3';
%                      '5285';'430c';'7197';'601e';'14a1';'0528';'37b3';'263a';
%                      'decd';'cf44';'fddf';'ec56';'98e9';'8960';'bbfb';'aa72';
%                      '6306';'728f';'4014';'519d';'2522';'34ab';'0630';'17b9';
%                      'ef4e';'fec7';'cc5c';'ddd5';'a96a';'b8e3';'8a78';'9bf1';
%                      '7387';'620e';'5095';'411c';'35a3';'242a';'16b1';'0738';
%                      'ffcf';'ee46';'dcdd';'cd54';'b9eb';'a862';'9af9';'8b70';
%                      '8408';'9581';'a71a';'b693';'c22c';'d3a5';'e13e';'f0b7';
%                      '0840';'19c9';'2b52';'3adb';'4e64';'5fed';'6d76';'7cff';
%                      '9489';'8500';'b79b';'a612';'d2ad';'c324';'f1bf';'e036';
%                      '18c1';'0948';'3bd3';'2a5a';'5ee5';'4f6c';'7df7';'6c7e';
%                      'a50a';'b483';'8618';'9791';'e32e';'f2a7';'c03c';'d1b5';
%                      '2942';'38cb';'0a50';'1bd9';'6f66';'7eef';'4c74';'5dfd';
%                      'b58b';'a402';'9699';'8710';'f3af';'e226';'d0bd';'c134';
%                      '39c3';'284a';'1ad1';'0b58';'7fe7';'6e6e';'5cf5';'4d7c';
%                      'c60c';'d785';'e51e';'f497';'8028';'91a1';'a33a';'b2b3';
%                      '4a44';'5bcd';'6956';'78df';'0c60';'1de9';'2f72';'3efb';
%                      'd68d';'c704';'f59f';'e416';'90a9';'8120';'b3bb';'a232';
%                      '5ac5';'4b4c';'79d7';'685e';'1ce1';'0d68';'3ff3';'2e7a';
%                      'e70e';'f687';'c41c';'d595';'a12a';'b0a3';'8238';'93b1';
%                      '6b46';'7acf';'4854';'59dd';'2d62';'3ceb';'0e70';'1ff9';
%                      'f78f';'e606';'d49d';'c514';'b1ab';'a022';'92b9';'8330';
%                      '7bc7';'6a4e';'58d5';'495c';'3de3';'2c6a';'1ef1';'0f78']);
% 
% 
% crc = hex2dec('ffff');
% %crc = hex2dec('0000');
% for n = 1:length(TmpBuff)
%     crc = bitxor(crc,TmpBuff(n));
%     lowByte  = bitand(crc,hex2dec('00ff'));
%     highByte = bitshift(bitand(crc,hex2dec('ff00')),-8);
%     
%     crc = crc_table(lowByte+1);
%     crc = bitxor(crc,highByte); 
% end
% 
% crc = bitxor(crc,hex2dec('ffff'));
% lowByte  = bitand(crc,hex2dec('ff'));
% highByte = bitshift(bitand(crc,hex2dec('ff00')),-8);
% 
% crc_val = dec2hex([lowByte highByte])
% 
% 
% %------------------------------------------------
%      crc = uint16(hex2dec('FFFF')); % 0x1DOF non-augmented initial value equivalent to augmented initial value 0xFFFF
% % 8408 1021 
% 
% 
%     for i = 1:length(TmpBuff)
%         crc = bitxor(crc,bitshift(TmpBuff(i),8));
% 
%         for j = 1:8
%             if (bitand(crc, hex2dec('8000')) > 0)
%                 crc = bitxor(bitshift(crc, 1), hex2dec('1021'));
%             else
%                 crc = bitshift(crc, 1);
%             end
%         end
%     end
%     crc_bin = dec2bin(crc);
% 
%     dec2hex(bin2dec(crc_bin(1:8)))
%     dec2hex(bin2dec(crc_bin(9:16)))
%     disp('')
%     

  
%   
%   
%   /**************************************************************************//**
% CRC CCITT16 1201 calculation
% 
% Calculates the 16 bit CRC-CCITT. Data length is restricted to 64k bytes.
% The seed value by default should be 0. If the CRC for a piece of data can't
% calculated in on go subsequent calls to this function may be seeded with
% the previousely calculated crc. This will ensure correct calculation of crc
% for message with multiple data sctions.
% 
% @param[in]  pBuff    Pointer to buffer containing data
% @param[in]  length   Length of data
% @param[in]  seed     16 bit CRC (start value)
% @return     Calculated CRC value
% 
% @note Hamming distance, Hamming weight and data error properties need to
%       be considered before using this CRC routine on large messages
% INLINE uint16_t CRC_CCITT16_1201_Calculate  (uint8_t*  pBuff,
%                                              uint16_t  length,
%                                              uint16_t  seed)
% {
%   err_t     errCode = E_OK;
%   uint16_t   crc    = seed;
%   uint16_t  index   = 0;
%                                                          __BR(CRC_C161201C, 0);
%   for (index = 0; index < length; index++)
%   {                                                      __BR(CRC_C161201C, 1);
%     crc = CRC_CCITT16_1021_Table [(crc ^ pBuff[index]) & 0xFF] ^ (crc >> 8);
%   }
%   
%   ERR_SET(CRC_C16A, errCode);
%   return (crc);
% }


% 01:02     -> RS DLE
% 03:04     -> Data Size
% 05:08     -> Cycle counter
% 09:end-2  -> Data
% end-2:end -> CRC
% 01:04     -> Test Point Val5 = 6 bits; Val4 = 6 bits; Val3 = 6 bits; Val2 = 6 bits; Val1 = 8 bits (32 bits in total)
% Val1 = bitand(bitshift(TPNum,-26),63); % bin2dec('111111') = 63
% Val2 = bitand(bitshift(TPNum,-20),63);
% Val3 = bitand(bitshift(TPNum,-14),63);;
% Val4 = bitand(bitshift(TPNum,-8),63);
% Val5 = bitand(TPNum,255); % bin2dec('11111111') = 255

% function x = hex2num32(s)
% % Converts a hexadecimal 8-byte character string into the equivalent 32-bit floating
% % point number. The input can be a cell array of strings, the strings are
% % padded to the right with '0' if need be.
% % The rules obey the IEEE-754 standard, although +/- 0 is not supported.
% if iscellstr(s)
%     s = char(s)
% end
% if ~isstr(s)
%     error('Input to hex2float must be a string.')
% end
% if isempty(s)
%     x = []
%     return
% end
% 
% [row,col] = size(s);
% 
% blanks = find(s==' ');
% % zero pad the blanks
% if blanks
%     s(blanks) = '0'
% end
% 
% d=48*ones(1,8);
% i=find(s);
% d(i)=abs(lower(s));
% if ~(all((d<58&d>47)|(d<103&d>96)))
%  error('Input should only contain 0-9, a-f, A-F')
% end
% 
% d=(d-48).*(d<58)+(d-87).*(d>58);
% s=(-1).^(d(:,1)>7);
% e=32*d(:,1)-256*(d(:,1)>7)+2*d(:,2)+(d(:,3)>7);
% f=[2*d(:,3:7)-16*(d(:,3:7)>7)+(d(:,4:8)>7), 2*d(:,8)-16*(d(:,8)>7)];
% % f=f./16.^[1:6]
% f=f*[6.250000000000000e-002;3.906250000000000e-003;2.441406250000000e-004;...
%    1.525878906250000e-005;9.536743164062500e-007;5.960464477539063e-008];
% 
% i1=find(e<255&e>0); % valid number
% i2=find(e==255&f); % NaN
% i3=find(e==255&~f); % Inf's
% i4=find(e==0); % denormalized
% 
% x=zeros(1,1);
% if i1,x(i1)=pow2(1+f(i1),e(i1)-127).*s(i1);end
% if i2,x(i2)=nan;end
% if i3,x(i3)=s(i3).*inf;end
% if i4,x(i4)=pow2(f(i4),e(i4)-126).*s(i4);end

% *************************************************************************
% *************************************************************************
% *************************************************************************

% --------------------------------------
% TEST POINT DATA structure  2013 - 2014
% --------------------------------------
% 1  - 1E            => Record Seperator (RS)
% 2  - 10            => Data Link Escape (DLE)
% 3  - 00 EC         => tpsize
% 5  - 00 00 00 4C   => Cycle cnt
% 9  - 08 0F C0 32   => Test Point Number
% 13 - 00 00         => Padding size
% 15 - 07 95         => CRC for header
% 17 - 12 00 C2      => ??
% 20 - 9D 08  => Port (40200)
% 22 - EB 28 00 01 
% 26 - 0C 05 00 2D 
% 30 - 00 00 00 00 00 08 0D 2E => Time Stamp (527662) => Not sure about the size think its 64 bits
% 38 - 01 01 13     
% Last 2 bytes => Total CRC


% function ProcessBin(handles)
% set(handles.printK2DataPlot, 'Pointer', 'watch')
% StartSeconds = round(str2double(get(handles.edStartMinutes, 'String')) * 60);
% 
% [Status, fid, FltNum, PathOutput] = CheckBeforeProcess(handles, StartSeconds);
% if Status
%     return
% end
% 
% TpDatabase = getappdata(handles.printK2DataPlot, 'TpDatabase');
% 
% for I = 1:length(TpDatabase{1}) % Deleting the files & Creating first instance of files
%     eval([TpDatabase{2}{I}, ' = [];'])
%     try
%         save(sprintf('%s\\%s.%s.mat', PathOutput, TpDatabase{2}{I}, char(FltNum)), TpDatabase{2}{I})
%         Parameters.(TpDatabase{2}{I}) = [];
%     catch
%         msgbox(sprintf('Could not save parameter: [%s] to file: [%s\\%s.%s.mat]',...
%             TpDatabase{2}{I}, PathOutput, TpDatabase{2}{I}, char(FltNum)), 'SAVE ERROR')
%         return
%     end
%     eval(['clear ', TpDatabase{2}{I}, ';']);
% end
% 
% GpsTime = str2double(get(handles.edHour, 'String'))*3600 ...
%         + str2double(get(handles.edMin, 'String'))*60 ...
%         + str2double(get(handles.edSec, 'String'));
%     
% TmpBuff = '';  CntSave = 0; Cnt = 0;
% BuffLen = 100000;
% FlagEof = 0;
% FlagEod = 0;
% 
% % DATA
% % 1E 10                     RS DLE
% % 00 00                     Buffer size
% % 00 00 00 00               Cycle count / Time Stamp
% % 504 Bytes                 Presence vector
% % Test Point Data
% % 00 00                     CRC
% 
% 
% % Get first set of values into TempBuff & search for first RS DLE
% RsDle = [char(30),char(16)]; % To Speed things up - Hopefully
% [StartTime, EndTime, TmpBuff, PackLen] = GetStartBin(TmpBuff, fid, RsDle);
% while ~getappdata(handles.printK2DataPlot, 'BreakWhile') && FlagEod == 0 % User has NOT pressed CANCEL and there's still data
%     % PackLen still gives the length of the data from this RsDle to the
%     % next so that hasn't broken. Seems like the GetStartBin function still
%     % works as advertised
%     if length(TmpBuff) < BuffLen && FlagEof == 0
%         if ~feof(fid) % Still data in the file
%             TmpBuff = [TmpBuff; fread(fid,BuffLen, 'uint8=>char')];
%         else
%             FlagEof = 1;
%         	AddVerbose(handles, 'End Of File')
%         end
%     end
%   
%     BuffSize = TmpBuff(3)*16+TmpBuff(4)*1;
%     % Healthy packet so get Time Stamp & Test Point number
%     TimeStamp = (TmpBuff(5)*16777216 + TmpBuff(6)*65536 + TmpBuff(7)*256 + TmpBuff(8))*0.02; % Time in Seconds
%     Pos = 9; % Start of first Test Point Number
%     while Pos < PackLen - 4 % The -4 is for the Test Point Values 
%         TPNum = TmpBuff(Pos)*16777216 + TmpBuff(Pos+1)*65536 + TmpBuff(Pos+2)*256 + TmpBuff(Pos+3)*1;
%         Index = find(TpDatabase{1} == TPNum);
%         if isempty(Index)
%             AddVerbose(handles, ['No Test Point number: ', num2str(TPNum), ' in Config file'])
%             break
%         else
% 
%            TmpVar = GetVarValBin(handles,TmpBuff(Pos+4:PackLen)', [TpDatabase{3}{Index},num2str(TpDatabase{4}(Index))]);
%        %    disp([num2str(TPNum), ' ', TpDatabase{2}{Index}, ' ', num2str(TmpVar), ' ', num2str(Pos)])
%            Parameters.(TpDatabase{2}{Index})(end+1,:) = [TimeStamp + GpsTime TmpVar*TpDatabase{5}(Index)]; 
%         end
%         Pos = Pos + TpDatabase{4}(Index)/8 + 4;
%     end
% 
%     Cnt = Cnt + 1;
%     if(Cnt > 300) % Random number gives a good update rate
%         ProgressBar(handles, TimeStamp, StartTime, EndTime)% Progress bar Indication
%         Cnt = 0;
%         CntSave = CntSave + 1;
%         if(CntSave > 10)     % Performs a save of current data in memory when CntSave > 10
%             CntSave = 0;                      
%             Parameters = Save2FileBin(Parameters, TpDatabase{2}, FltNum, PathOutput); % Save the current data in mem to file
%         end
%     end
%     
%     TmpBuff = TmpBuff(PackLen + 1:end);
%     if TmpBuff < 5 % Check that there are still enough data left for Packet length
%         break % Should be Eof as well as end of data so climb out
%     end
%         
%     % Search for the next Time stamp in file
%     PackLen = 4*ceil((TmpBuff(3)*256 + TmpBuff(4)*1)/4); % Get length of packet
%     if PackLen > length(TmpBuff) + 1 % Check that the packet lenght is not more than the data left in the buffer
%         break % Should be Eof as well as end of data so climb out
%     end
%     
%     if regexp(TmpBuff(PackLen+1:end)', RsDle,'once') == 1 % Check if this packet ends just infront of a RS DLE                      
%         continue
%     else % Packet is dodgy so look for next RS DLE with a healthy packet     
%         AddVerbose(handles, [num2str(TimeStamp),': Broken packet # ', num2str(Cnt)]);
%         [FlagEof, FlagEod, TmpBuff, PackLen] = GetNextHealthyPacket(handles, FlagEof, FlagEod, BuffLen, TmpBuff, RsDle, fid);
%     end  
% end
% 
% Save2FileBin(Parameters, TpDatabase{2}, FltNum, PathOutput); % Save the current data in mem to file
% fclose(fid); % Close pass3200 file
% 
% set([handles.edProgress, handles.edIndicator], 'Visible', 'Off')
% set(handles.pbProcess, 'String', 'PROCESS')
% set(handles.edIndicator, 'Visible', 'off');
% set(handles.txtSeconds, 'Visible', 'off');
% set(handles.printK2DataPlot, 'Pointer', 'arrow')
