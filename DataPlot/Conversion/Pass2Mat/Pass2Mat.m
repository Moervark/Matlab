function varargout = Pass2Mat(varargin)
% PASS2MAT M-file for Pass2Mat.fig  
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Pass2Mat_OpeningFcn, ...
                   'gui_OutputFcn',  @Pass2Mat_OutputFcn, ...
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
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes just before Pass2Mat is made visible.
function Pass2Mat_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
handles.output = hObject; % Choose default command line output for Pass2Mat
guidata(hObject, handles); % Update handles structure

try
    if regexpi(pwd,'Pass2Mat') % Opened directly by user inside Pass2Mat directory
        load P2M_Config.mat; 
    else % Opened by DataPlot from DataPlot directory
        load Conversion\Pass2Mat\P2M_Config.mat; 
    end
catch
    Paths.Load   = sprintf('%s\\',pwd);
    Paths.Output = sprintf('%s\\',pwd);
    Paths.Input  = sprintf('%s\\',pwd);
    Paths.Config = sprintf('%s\\Config\\',pwd);
end
if regexpi(pwd,'Pass2Mat') % Opened directly by user inside Pass2Mat directory
    Paths.Exe = sprintf('%s\\',pwd); 
else % Opened by DataPlot from DataPlot directory
    Paths.Exe = sprintf('%s\\Conversion\\Pass2Mat\\',pwd); 
end
setappdata(handles.Pass2Mat, 'Paths', Paths)

% Get Jabberwock logo
cd(Paths.Exe)
Jabberwock = imread('..\..\Jabberwock_m.jpg');
image(Jabberwock, 'Parent', handles.axJabberwock)
set(handles.axJabberwock, 'YTickLabel',[])
set(handles.axJabberwock, 'XTickLabel',[])
set(handles.axJabberwock, 'XTick',[])
set(handles.axJabberwock, 'YTick',[])
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = Pass2Mat_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
varargout{1} = handles.output; % Get default command line output from handles structure
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% --- Executes when user attempts to close Pass2Mat.
function Pass2Mat_CloseRequestFcn(hObject, eventdata, handles)
% 
Paths = getappdata(handles.Pass2Mat, 'Paths');
save([Paths.Exe, 'P2M_Config.mat'], 'Paths')
delete(hObject); % closes the figure

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function pbSave_Callback(hObject, eventdata, handles)
% Saves the config file
Paths = getappdata(handles.Pass2Mat, 'Paths');
ParamList = getappdata(handles.Pass2Mat, 'ParamList');

ParameterVal = '';
for I = 1:length(ParamList)
    ParameterVal = sprintf('%s%s %s %s %d %d %e %d\r\n',...
        ParameterVal,...
        ParamList(I).Name,...   % Type char
        ParamList(I).RT,...     % Type char
        ParamList(I).SA,...     % Type char
        ParamList(I).Word,...   % Type double
        ParamList(I).TxRx,...   % Type logical
        ParamList(I).Factor,... % Type float
        ParamList(I).TwosComp); % Type logical
end

[FileName,PathName] = uiputfile(sprintf('%s*.cfg',...
    Paths.Config), 'Save Config file');
if isequal(FileName,0) || isequal(PathName,0)
    return
end

Paths.Config = sprintf('%s\\',PathName);
setappdata(handles.Pass2Mat, 'Paths', Paths);
set(handles.txtConfigFile, 'String', FileName)

eval(['fid = fopen(''', PathName, FileName, ''',''w'');'])
if(fid == -1)
     msgbox('Error accessing file', 'FILE ERROR');
    return
end
fprintf(fid,'%s', ParameterVal);
fclose(fid);

% **** END pbSave_Callback ****
% *************************************************************************
% *************************************************************************
function pbLoad_Callback(hObject, eventdata, handles)
%  Loads a config file
Paths = getappdata(handles.Pass2Mat, 'Paths');
[FileName, PathName] = uigetfile(sprintf('%s*.cfg',Paths.Config)); 
if isequal(FileName,0) || isequal(PathName,0)
    return
end

try
    eval(['fid = fopen(''',PathName, FileName, ''');'])

    Paths.Config = PathName;
    setappdata(handles.Pass2Mat, 'Paths', Paths);
    Data = textscan(fid,'%s %s %s %d %d %f %d');
    fclose(fid);
    ParamList(length(Data{1})) = struct('Name', 'char', 'RT', 'char', ...  % Create struct
        'SA', 'char', 'Word', 'double', 'TxRx', 'logical', 'Factor', 'double', 'TwosComp', 'logical');    
    for I = 1:length(Data{1})
        ParamList(I).Name     = char(Data{1}(I)); % Type char
        ParamList(I).RT       = char(Data{2}(I)); % Type char
        ParamList(I).SA       = char(Data{3}(I)); % Type char
        ParamList(I).Word     = double(Data{4}(I)); % Type double
        ParamList(I).TxRx     = logical(Data{5}(I)); % Type logical
        ParamList(I).Factor   = double(Data{6}(I)); % Type double
        ParamList(I).TwosComp = logical(Data{7}(I)); % Type logical
    end
 catch ME
     msgbox('Config file is broken', 'Try another one');
     return
 end

set(handles.txtConfigFile, 'String', FileName)
setappdata(handles.Pass2Mat, 'ParamList', ParamList)
PopulateListBox(hObject, eventdata, handles)

% **** END mnFile_Load_Callback ****
% *************************************************************************
% *************************************************************************
function pbAdd_Callback(hObject, eventdata, handles)
% Adds new parameters to Parameter list

if(isempty(get(handles.edParamName, 'String'))... % Check that all fields are filled in
        || isempty(get(handles.edRT, 'String'))...
        || isempty(get(handles.edSA, 'String'))...
        || isempty(get(handles.edWord, 'String')));
    msgbox('Fill in all the fields','ERROR')
    return
end

ParamList = getappdata(handles.Pass2Mat, 'ParamList');
if(~isempty(ParamList)) % Only perform parameter test if the ParamList is not empty
    if ~isempty(strmatch(get(handles.edParamName, 'String'), strvcat(ParamList.Name),'exact')) % Check if the parameter name is unique
        msgbox('Parameter name already exist','ERROR')
        return
    end
end

LineNum = 1; % Set LineNum =1 before testing if there are an actual parameter list 
if(~isempty(getappdata(handles.Pass2Mat, 'ParamList'))) % in which case the LineNum is changed
    ParamList = getappdata(handles.Pass2Mat, 'ParamList'); % to the last parameter + 1
    LineNum = length(ParamList) + 1;
end

ParamList(LineNum).Name = get(handles.edParamName, 'String');
ParamList(LineNum).RT   = get(handles.edRT, 'String');
ParamList(LineNum).SA   = get(handles.edSA, 'String');
ParamList(LineNum).Word = str2double(get(handles.edWord, 'String'));
TxRx = get(findobj(handles.rdTxRx, 'String', 'Transmit'), 'Value');
if(TxRx == 1) %Is Tx or Rx selected ?
    ParamList(LineNum).TxRx = logical(1); %#ok<LOGL> % Tx selected
else
    ParamList(LineNum).TxRx = logical(0); %#ok<LOGL> % Rx selected
end
if(get(handles.rdFactor, 'Value') == 1) % Is Factor radio button ticked ?
    ParamList(LineNum).Factor = str2num(get(handles.edFactor, 'String'));
else
    ParamList(LineNum).Factor = 1; % Make factor = 1
end
if(get(handles.rdTwosComp, 'Value') == 1) % Is 2's complement radio button ticked ?
    ParamList(LineNum).TwosComp = logical(1);
else
    ParamList(LineNum).TwosComp = logical(0);  
end
setappdata(handles.Pass2Mat, 'ParamList', ParamList)
PopulateListBox(hObject, eventdata, handles)

% **** END pbAdd_Callback ****
% *************************************************************************
% *************************************************************************
%
function PopulateListBox(hObject, eventdata, handles)
ParamList = getappdata(handles.Pass2Mat, 'ParamList');

for I = 1:length(ParamList)
    tblData{I,1} = ParamList(I).Name;
    tblData{I,2} = ParamList(I).RT;
    tblData{I,3} = ParamList(I).SA;
    tblData{I,4} = ParamList(I).Word;
    tblData{I,5} = ParamList(I).TxRx;
    tblData{I,6} = ParamList(I).Factor;
    tblData{I,7} = ParamList(I).TwosComp;
end

set(handles.tblParam, 'Data', tblData)

% **** END PopulateListBox ****
% *************************************************************************
% *************************************************************************
function rdTxRx_Callback(hObject, eventdata, handles)
% 
set(handles.rdTxRx, 'Value', 0)
set(hObject, 'Value', 1)

% **** END rdTxRx_Callback ****
% *************************************************************************
% *************************************************************************
function tblParam_CellEditCallback(hObject, eventdata, handles)
% 

ParamList = getappdata(handles.Pass2Mat, 'ParamList'); % Get the current Parameter listing

switch eventdata.Indices(2) % Check which which column was edited 
    case 1                  % Indices(1) identifies in which row the edited cell is
      if isempty(eventdata.NewData)
            Quest = questdlg('Do you really want to delete this parameter ?',...
                    'WARNING','Yes','No','Yes');
            if(strcmp(Quest, 'Yes')) || (isempty(Quest))
                DeleteParameter(eventdata.Indices(1), handles);
                ParamList = getappdata(handles.Pass2Mat, 'ParamList'); % Get the new Parameter listing
            end
      else
          ParamList(eventdata.Indices(1)).Name   = eventdata.NewData; % Name column
      end
    case 2
        ParamList(eventdata.Indices(1)).RT   = eventdata.NewData; % RT column
    case 3
        ParamList(eventdata.Indices(1)).SA   = eventdata.NewData; % SA column
    case 4
        ParamList(eventdata.Indices(1)).Word = eventdata.NewData; % Word column
    case 5
        ParamList(eventdata.Indices(1)).TxRx = eventdata.EditData; % TxRx (Logical)
    case 6
        ParamList(eventdata.Indices(1)).Factor = eventdata.NewData; % Factor column
    case 7
        ParamList(eventdata.Indices(1)).TwosComp = eventdata.EditData; % TwosComp (Logical)
end

setappdata(handles.Pass2Mat, 'ParamList', ParamList); % Set the new Parameter listing
PopulateListBox(hObject, eventdata, handles) % Update the display 

% **** END tblParam_CellEditCallback ****
% *************************************************************************
% *************************************************************************
function DeleteParameter(RowNumber, handles)
% Delete a parameter from the list

ParamList = getappdata(handles.Pass2Mat, 'ParamList'); % Get the current Parameter listing
NewParamlist = ParamList(1:RowNumber-1); % Copy all up to the row before the deletion
NewParamlist(RowNumber:length(ParamList)-1) = ParamList(RowNumber+1:length(ParamList)); % Copy all after the deleted row
setappdata(handles.Pass2Mat, 'ParamList', NewParamlist); % Set the new Parameter listing

% **** END DeleteParameter ****
% *************************************************************************
% *************************************************************************
function pbDataFile_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.Pass2Mat, 'Paths');

if(strcmp(get(handles.txtInputDat, 'String'), 'Input File:'))
    [FileName, PathName] = uigetfile(sprintf('%s*.txt',Paths.Load), 'SELECT FILE TO PARSE');
    if isequal(FileName,0) || isequal(PathName,0)
        return
    end
    set(handles.edDataFile, 'String', sprintf('%s%s', PathName, FileName))
    Paths.Load = PathName;
else
    PathInput = uigetdir(Paths.Input, 'Specify the Input Directory');
    if(PathInput == 0)
        return
    end
    set(handles.edDataFile, 'String', PathInput)
    Paths.Input = PathInput;  
end
setappdata(handles.Pass2Mat, 'Paths', Paths);
% **** END pbDataFile_Callback ****
% *************************************************************************
% *************************************************************************
function pbOutputDir_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.Pass2Mat, 'Paths');
PathOutput = uigetdir(Paths.Output, 'Specify the Output Directory');
if(PathOutput == 0)
    return
end
set(handles.edOutputDir, 'String', PathOutput)
Paths.Output = PathOutput;
setappdata(handles.Pass2Mat, 'Paths', Paths);

% **** END pbOutputDir_Callback ****
% *************************************************************************
% *************************************************************************
%
function rdFactor_Callback(hObject, eventdata, handles)
if(get(handles.rdFactor, 'Value') == 1)
    set(handles.edFactor, 'Enable', 'On')
else
    set(handles.edFactor, 'Enable', 'Off')
end

% **** END rdFactor_Callback ****
% *************************************************************************
% *************************************************************************
function pbProcess_Callback(hObject, ~, handles)
% 
set(handles.Pass2Mat, 'Pointer', 'watch')

setappdata(handles.Pass2Mat, 'BreakWhile', 0); % Clear the Break variable
if(strcmp(get(hObject, 'String'), 'CANCEL')) % If CANCEL was pressed enter 
    setappdata(handles.Pass2Mat, 'BreakWhile', 1);
    set(handles.pbProcess, 'String', 'PROCESS');
    set([handles.edProgress, handles.edIndicator], 'Visible', 'Off')
    drawnow;
    return
end

fidDatFile = fopen(get(handles.edDataFile, 'String'));
FltNum = get(handles.edOutputId, 'String');
PathOutput = get(handles.edOutputDir, 'String');
if(fidDatFile == -1) || isempty(PathOutput) || isempty(FltNum)
    msgbox({'Fill in fields:' ,'- Data File Name', '- Output File ID', '- Output File Directory'},'INPUT ERR')
    set(handles.Pass2Mat, 'Pointer', 'arrow')
    return
end

ParamList = getappdata(handles.Pass2Mat, 'ParamList');
if(length(ParamList) < 1)
    msgbox('Load a config file first','INPUT ERR')
    set(handles.Pass2Mat, 'Pointer', 'arrow')
    return
end

StartSeconds = round(str2double(get(handles.edStartMinutes, 'String')) * 60);
if(StartSeconds > 0)
    Status = fseek(fidDatFile, StartSeconds*632000, 'bof');
    if(Status == -1)
        msgbox('Start time too big','START TIME')
        set(handles.Pass2Mat, 'Pointer', 'arrow')
        return
    end
end
SaveAsType = get(findobj(handles.rdMatTxt, 'Value', 1), 'String');
for I = 1:length(ParamList) % Deleting the files & Creating first instance of files
    switch SaveAsType % Type of file .mat or .txt files ?
        case '.txt files'    
            fid = fopen(sprintf('%s\\%s.%s.txt', PathOutput, ParamList(I).Name, char(FltNum)), 'wt+');
            fclose(fid);
        case '.mat struct'
            delete(sprintf('%s\\%s.%s.mat', get(handles.edOutputDir, 'String'),...
            get(handles.edStructName, 'String'), get(handles.edOutputId, 'String')));
            break;
        case '.mat files' % Deleting the files & Creating first instance of files
            eval([ParamList(I).Name, ' = [];'])
            save(sprintf('%s\\%s.%s.mat', PathOutput, ParamList(I).Name, char(FltNum)), ParamList(I).Name)
            eval(['clear ', ParamList(I).Name, ';'])
    end      
end
StructName = get(handles.edStructName, 'String');
Cnt = 0;
RtTxRxSa.Address = '';
RtTxRxSaAddress{1} = '';
FindCmnd = cell(length(ParamList));
for I = 1:length(ParamList) % In order to effectively parse the Pass file, the ParamList must be massaged into this format
    if(ParamList(I).TxRx == 1) % Quickly massage the TxRx logical to char
        TxRx = 'T';
    else
        TxRx = 'R';
    end
  
    switch SaveAsType % Type of file .mat or .txt files ?
        case '.txt files'    
            ParamList(I).Data = ''; % In the case of .txt use the Data variable for the text string
        case '.mat struct'
            ParamList(I).Data = 0; % In the case of a struct use the Data variable as a counter
        case '.mat files'
            ParamList(I).Data = [];% In the case of .mat use the Data variable as a struct
    end       
   
    FindCmnd{I} = sprintf('%s-%s-%s',... % RT-RxTx-SA => eg. 31-T-6
        ParamList(I).RT,... % RT adress
        TxRx,...            % Transmit / Recieve
        ParamList(I).SA);   % Sub adress

    if (isempty(strmatch(FindCmnd{I},RtTxRxSaAddress, 'exact')))    % Specific RT Sub Adress not in list yet
        Cnt = Cnt+1;                                                % So add the new RT Sub Adress to end of list
        RtTxRxSaAddress(Cnt)= FindCmnd(I);                          % And add first parameter for RT Sub Adress
        RtTxRxSa(Cnt).ParamList(1) = ParamList(I);  
        if(strcmp(SaveAsType, '.mat struct'))
            eval(['Data.', RtTxRxSa(Cnt).ParamList(1).Name, ' = [];'])
        end
    else        % Specific RT Sub Adress already in list
        Pos = strmatch(FindCmnd{I},RtTxRxSaAddress, 'exact'); % Find specific  address in RtTxRxSa
        RtTxRxSa(Pos).ParamList(end + 1) = ParamList(I); % Add this parameter to this list
        if(strcmp(SaveAsType, '.mat struct'))
            eval(['Data.', RtTxRxSa(Pos).ParamList(end).Name, ' = [];'])
        end
    end    
end

set(handles.edProgress, 'String', ''  , 'Visible', 'On')
set(handles.edIndicator, 'String', '0', 'Visible', 'On');
set(handles.txtSeconds, 'Visible', 'On');
set(handles.pbProcess, 'String', 'CANCEL');
drawnow;

% Get the file length info to guess a Progress bar length
FileInfo = dir(get(handles.edDataFile, 'String'));
InputFilelen = FileInfo.bytes/3050;
BarLen = round(FileInfo.bytes/2950 - StartSeconds*210);

FlagLine1 = 0; FlagLine2 = 0; FlagLine3 = 0; FlagLine4 = 0; 
Cnt = 0; CntDraw = 0; Time = 0;
CmndR = ''; CmndT = ''; 
StartTime = -1; 

% ****** Start Parsing ****** RtTxRxSa = '6-T-3'  ParamList = 'mss_ella'
while ~feof(fidDatFile) && ~getappdata(handles.Pass2Mat, 'BreakWhile')     
    Words = textscan(fidDatFile, '%s%s%s%s%s%s%s%s',1); % Scan the next line from the input file
    Cnt = Cnt + 1; % Increment Bar length counter

    % Ignore all these lines
    if(     strcmp(char(Words{1}), 'File/Msg') ||...
            strcmp(char(Words{1}), 'Bus'      ) ||...
            strcmp(char(Words{1}), 'IMGap'    ) ||...
            strcmp(char(Words{1}), 'Response' ) ||...                
            strcmp(char(Words{1}), 'Status:'  ))
        continue
    end   

    % Write out the values and reset
    if(strcmp(char(Words{1}), 'Time:'))     
        TimeCell = textscan(char(Words{2}), '%f', 'delimiter', ':');   
        NTime = TimeCell{1}(2)*3600 ... % hours 2 Sec
            + TimeCell{1}(3)*60 ... % Minutes 2 Sec
            + TimeCell{1}(4) ... % Sec
            + TimeCell{1}(5)/1000; % mSec 2 Sec
        
        if(StartTime == -1)
            StartTime = NTime;
        end
        if(FlagLine1 == 0) 
            CmndR = ''; CmndT = '';
            Time = NTime;
            continue
        end
       % Search for Receive                                             % Find first occurence of the specific word   
        Position =  find(strcmp(CmndR, RtTxRxSaAddress), 1, 'first');   % (eg. '5-T-6') in the array
        if (Position)                                                   % RtTxRxSaAddress contains the list of all used RT subadresses
            for J = 1:length(RtTxRxSa(Position).ParamList)              % The RtTxRxSa struct will therefore be built according to the list in RtTxRxSaAddress
                DecimalValue = MyHex2Dec(DataWords{RtTxRxSa(Position).ParamList(J).Word});
                if(DecimalValue == 99999)
                    continue;
                end
                if(RtTxRxSa(Position).ParamList(J).TwosComp == 1) % Is this a 2's complement value
                    if(DecimalValue > 2^15-1) % Perform 2's complement conversion
                        DecimalValue = DecimalValue - 2^16;
                    end
                end % if(RtTxRxSa(I).ParamList(J).TwosComp == 1)

                switch SaveAsType % Must this be saved as .mat or .txt files ?
                    case '.txt files'
                        RtTxRxSa(Position).ParamList(J).Data = sprintf('%s%0.3f %d\n',...
                            RtTxRxSa(Position).ParamList(J).Data,...
                            Time,...            % Create entry in form: TIME DECIMALVALUE
                            DecimalValue*RtTxRxSa(Position).ParamList(J).Factor);
                    case '.mat struct'
                        Data.(RtTxRxSa(Position).ParamList(J).Name)(end+1,:)...
                            = [Time DecimalValue*RtTxRxSa(Position).ParamList(J).Factor];   
                    case '.mat files'
                        RtTxRxSa(Position).ParamList(J).Data(end + 1,:)...
                            = [Time DecimalValue*RtTxRxSa(Position).ParamList(J).Factor];
                end                
            end
        end
        % Search for Transmit
        Position =  find(strcmp(CmndT, RtTxRxSaAddress), 1, 'first');
        if (Position)
            for J = 1:length(RtTxRxSa(Position).ParamList)
                DecimalValue = MyHex2Dec(DataWords{RtTxRxSa(Position).ParamList(J).Word});
                if(DecimalValue == 99999)
                    continue;
                end
                if(RtTxRxSa(Position).ParamList(J).TwosComp == 1) % Is this a 2's complement value
                    if(DecimalValue > 2^15-1) % Perform 2's complement conversion
                        DecimalValue = DecimalValue - 2^16;
                    end
                end
                
                switch SaveAsType % Must this be saved as .mat or .txt files ?
                    case '.txt files'
                        RtTxRxSa(Position).ParamList(J).Data = sprintf('%s%0.3f %d\n',...
                            RtTxRxSa(Position).ParamList(J).Data,...
                            Time,...            % Create entry in form: TIME DECIMALVALUE
                            DecimalValue*RtTxRxSa(Position).ParamList(J).Factor);
                    case '.mat struct'
                        Data.(RtTxRxSa(Position).ParamList(J).Name)(end+1,:)...
                            = [Time DecimalValue*RtTxRxSa(Position).ParamList(J).Factor];                       
                    case '.mat files'
                          RtTxRxSa(Position).ParamList(J).Data(end + 1,:)...
                            = [Time DecimalValue*RtTxRxSa(Position).ParamList(J).Factor];
                end
            end
        end              
        
        FlagLine1 = 0; FlagLine2 = 0; FlagLine3 = 0; FlagLine4 = 0;
        clear Time;
        DataWords(1:32) = {''};
        CmndR = ''; CmndT = '';
        Time = NTime;
        continue
    end % if(strcmp(char(Words{1}), 'Time:'))

    % Get the command details
    if(strcmp(char(Words{1}), 'Cmnd:'))
        Commmand = char(Words{3});
        Position = strfind(Commmand, '-');
        if(strncmp(Commmand(Position(1)+1), 'T',1))
            CmndT = Commmand(2:Position(end)-1);
        else
            CmndR = Commmand(2:Position(end)-1);
        end
        continue
    end

    if(FlagLine1 == 0  && length(char(Words{1})) == 4)
        FlagLine1 = 1; % 1st line of 8 datawords (1-8)
        DataWords(1) = Words(1); % DON'T USE FOR LOOPS
        DataWords(2) = Words(2); % It Makes the code too SLOW
        DataWords(3) = Words(3);
        DataWords(4) = Words(4);
        DataWords(5) = Words(5);
        DataWords(6) = Words(6);
        DataWords(7) = Words(7);
        DataWords(8) = Words(8);
        continue
    end
    if(FlagLine2 == 0  && length(char(Words{1})) == 4)
        FlagLine2 = 1; % 2nd line of 8 datawords (9-16)
        DataWords(9)  = Words(1); % DON'T USE FOR LOOPS
        DataWords(10) = Words(2); % It Makes the code too SLOW
        DataWords(11) = Words(3);
        DataWords(12) = Words(4);
        DataWords(13) = Words(5);
        DataWords(14) = Words(6);
        DataWords(15) = Words(7);
        DataWords(16) = Words(8);        
        continue
    end
    if(FlagLine3 == 0  && length(char(Words{1})) == 4)
        FlagLine3 = 1; % 3rd line of 8 datawords (17-14)         
        DataWords(17) = Words(1); % DON'T USE FOR LOOPS
        DataWords(18) = Words(2); % It Makes the code too SLOW
        DataWords(19) = Words(3);
        DataWords(20) = Words(4);         
        DataWords(21) = Words(5);
        DataWords(22) = Words(6);        
        DataWords(23) = Words(7);
        DataWords(24) = Words(8);
        continue
    end
    if(FlagLine4 == 0  && length(char(Words{1})) == 4)
        FlagLine4 = 1; % 4th line of 8 datawords (25-32)
        DataWords(25) = Words(1);  % DON'T USE FOR LOOPS
        DataWords(26) = Words(2); % It Makes the code too SLOW
        DataWords(27) = Words(3);
        DataWords(28) = Words(4);
        DataWords(29) = Words(5);
        DataWords(30) = Words(6);
        DataWords(31) = Words(7);
        DataWords(32) = Words(8);
    end

    % Progress bar Indication
    if(Cnt > BarLen)
        set(handles.edProgress, 'String', sprintf('%s|',...
        get(handles.edProgress, 'String')))
        Cnt = 0;
        drawnow
    end
    CntDraw = CntDraw + 1;                      % Progress Time indication, also help to ensure a faster CANCEL
    if(CntDraw > 5000)                          % Performs a save of current data in memory when CntDraw > ??
        LapsedTime = (Time - StartTime);   % Keeping the memory in use low
        set(handles.edIndicator, 'String', num2str(round(LapsedTime)))
        drawnow
        CntDraw = 0;
                 
        % Save the current data in mem to file
        if(strcmp(SaveAsType, '.mat struct'))
           continue;
        elseif(strcmp(SaveAsType, '.txt files'))
            for I = 1:length(RtTxRxSa)
                for J = 1:length(RtTxRxSa(I).ParamList)
                    fid = fopen(sprintf('%s\\%s.%s.txt', PathOutput,...
                        RtTxRxSa(I).ParamList(J).Name, char(FltNum)), 'at');           
                    fprintf(fid,'%s', RtTxRxSa(I).ParamList(J).Data); % Print value to file   
                    RtTxRxSa(I).ParamList(J).Data = '';
                    fclose(fid);
                end
            end
        else % SaveAsType = '.mat files'
            for I = 1:length(RtTxRxSa)
                for J = 1:length(RtTxRxSa(I).ParamList)
                    load(sprintf('%s\\%s.%s.mat', PathOutput,...
                        RtTxRxSa(I).ParamList(J).Name, char(FltNum)))

                    eval([RtTxRxSa(I).ParamList(J).Name,...
                        ' = [', RtTxRxSa(I).ParamList(J).Name, ' ; RtTxRxSa(I).ParamList(J).Data];'])
                    
                    save(sprintf('%s\\%s.%s.mat', PathOutput,...
                        RtTxRxSa(I).ParamList(J).Name, char(FltNum)),...
                        RtTxRxSa(I).ParamList(J).Name);
                    
                    eval(['clear ', RtTxRxSa(I).ParamList(J).Name]) % Clear variable that has been saved from memory
                    RtTxRxSa(I).ParamList(J).Data = []; % Clear the memory in the Data struct.
                end 
            end 
        end 

    end % if(CntDraw > 5000)
end %  ~feof(fidDatFile)

% Save all data in memory to file      
switch SaveAsType % Must this be saved as .mat or .txt files ?
    case '.txt files'     
        for I = 1:length(RtTxRxSa)
            for J = 1:length(RtTxRxSa(I).ParamList)
                fid = fopen(sprintf('%s\\%s.%s.txt', PathOutput, RtTxRxSa(I).ParamList(J).Name, char(FltNum)), 'at');           
                fprintf(fid,'%s', RtTxRxSa(I).ParamList(J).Data); % Print value to file   
                fclose(fid);
                RtTxRxSa(I).ParamList(J).Data = '';                
            end
        end
    case '.mat struct'
        eval([get(handles.edStructName, 'String'), '.Data = Data']) % Build proper struct for saving
        save(sprintf('%s\\%s.%s.mat', get(handles.edOutputDir, 'String'),...
            get(handles.edStructName, 'String'), get(handles.edOutputId, 'String')),...
            get(handles.edStructName, 'String'));

    case '.mat files'
        for I = 1:length(RtTxRxSa)
            for J = 1:length(RtTxRxSa(I).ParamList)
                load(sprintf('%s\\%s.%s.mat', PathOutput,...
                    RtTxRxSa(I).ParamList(J).Name, char(FltNum)))

                eval([RtTxRxSa(I).ParamList(J).Name,...
                    ' = [', RtTxRxSa(I).ParamList(J).Name, ' ; RtTxRxSa(I).ParamList(J).Data];'])

                save(sprintf('%s\\%s.%s.mat', PathOutput,...
                    RtTxRxSa(I).ParamList(J).Name, char(FltNum)),...
                    RtTxRxSa(I).ParamList(J).Name); 
            end
        end
end

fclose(fidDatFile); % Close pass3200 file

set([handles.edProgress, handles.edIndicator], 'Visible', 'Off')
set(handles.pbProcess, 'String', 'PROCESS')
set(handles.edIndicator, 'Visible', 'off');
set(handles.txtSeconds, 'Visible', 'off');
set(handles.Pass2Mat, 'Pointer', 'arrow')

% **** END pbProcess_Callback ****
% *************************************************************************
% *************************************************************************
function mnFile_ConvertFTData_Callback(hObject, eventdata, handles)
 
set(handles.txtInputDat, 'String', 'Input Directory:')
set([handles.pnDataWords, handles.pbProcess,...
    handles.edStartMinutes, handles.txtApproxtime], 'Visible', 'Off')
set([handles.pbConvert, handles.lbVerbose], 'Visible', 'On')
set(handles.lbVerbose, 'Position', [3 1 113 14])
% **** END mnFile_ConvertFTData_Callback ****
% *************************************************************************
% *************************************************************************
function mnFile_Process_Pass3200_Callback(hObject, eventdata, handles)

set(handles.txtInputDat, 'String', 'Input File:')
set([handles.pnDataWords, handles.pbProcess,...
    handles.edStartMinutes, handles.txtApproxtime], 'Visible', 'On')
set([handles.pbConvert, handles.lbVerbose], 'Visible', 'Off')

% **** END mnFile_Process_Pass3200_Callback ****
% *************************************************************************
% *************************************************************************
% Converts the matlab data from the Flight test department to the same
% format as used by program DataPlot
function pbConvert_Callback(hObject, eventdata, handles)
set(handles.Pass2Mat, 'Pointer', 'watch')

Paths = getappdata(handles.Pass2Mat, 'Paths');

setappdata(handles.Pass2Mat, 'BreakWhile', 0); % Clear the Break variable
if(strcmp(get(hObject, 'String'), 'CANCEL')) % If CANCEL was pressed enter 
    setappdata(handles.Pass2Mat, 'BreakWhile', 1);
    set(handles.pbConvert, 'String', 'CONVERT');
    drawnow;
    set(handles.Pass2Mat, 'Pointer', 'arrow')
    return
end
set(handles.edProgress, 'String', ''  , 'Visible', 'On')

set(handles.lbVerbose, 'Value', 1, 'String', '');
[FileName, PathName] = uigetfile(sprintf('%sFlighttest.cfg',Paths.Config)); 
if isequal(FileName,0) || isequal(PathName,0)
    set(handles.Pass2Mat, 'Pointer', 'arrow')
    return
end
Paths.Config = sprintf('%s\\',PathName);
setappdata(handles.Pass2Mat, 'Paths', Paths);

try
    eval(['fid = fopen(''',PathName, FileName, ''');'])

    Data = textscan(fid,'%s %s %s %s');
    fclose(fid);
    ParamList(length(Data{1})) = struct('ParFileName', 'char',... 
        'ParameterName', 'char', 'TimeFile', 'char', 'NewFileName', 'char');    % Create struct
    for I = 1:length(Data{1})
        ParamList(I).ParFileName   = char(Data{1}(I)); % Type char
        ParamList(I).ParameterName = char(Data{2}(I)); % Type char
        ParamList(I).TimeFile      = char(Data{3}(I)); % Type char
        ParamList(I).NewFileName   = char(Data{4}(I)); % Type char
        ParamList(I).TimeFile
    end
 catch ME
     msgbox('Config file is broken', 'Try another one');
     set(handles.pbConvert, 'String', 'CONVERT');
     set(handles.Pass2Mat, 'Pointer', 'arrow')
     return
end

Cnt = 0;
for I = 1:length(ParamList) % Loads all the time00?? files needed 
    if (I > 1) && (strcmp(TimeFile(Cnt), ParamList(I).TimeFile))
        continue;
    end
    Cnt = Cnt + 1;
    TimeFile{Cnt} = ParamList(I).TimeFile;
    try
        load (sprintf('%s\\%s.%s.mat', get(handles.edDataFile, 'String'),...
            ParamList(I).TimeFile, get(handles.edOutputId, 'String')))
    catch ME
        AddVerbose(handles,sprintf('Can''t load time file %s', ParamList(I).TimeFile));
        set(handles.Pass2Mat, 'Pointer', 'arrow')
        return
    end
end

set(handles.pbConvert, 'String', 'CANCEL');

for I = 1:length(ParamList)
    if(getappdata(handles.Pass2Mat, 'BreakWhile') == 1) % Test if user hit CANCEL
        return; % Exit for loop
    end
   
    try 
        load (sprintf('%s\\%s.%s.mat', get(handles.edDataFile, 'String'),...
            ParamList(I).ParFileName, get(handles.edOutputId, 'String')))
    catch ME
        AddVerbose(handles,sprintf('Can''t load file %s', ParamList(I).ParFileName));
        continue;
    end
    whos
    eval([ParamList(I).NewFileName, ' = transpose([',...
        ParamList(I).TimeFile, ' ; ',...
        ParamList(I).ParameterName, ']);'])
    
    SaveAsType = get(findobj(handles.rdMatTxt, 'Value', 1), 'String');
    
    switch SaveAsType
        case '.txt files'    
            save(sprintf('%s\\%s.%s.txt', get(handles.edOutputDir, 'String'),...
                ParamList(I).NewFileName, get(handles.edOutputId, 'String')),...
                ParamList(I).NewFileName, '-ascii');
        case '.mat struct'
            eval(['TmpStruct.', ParamList(I).NewFileName, ' = ',...
                ParamList(I).NewFileName, ';']) 
            
        case '.mat files'
            
    end
    clear(ParamList(I).ParameterName, ParamList(I).NewFileName)
    AddVerbose(handles,sprintf('Saved %s', ParamList(I).ParFileName));
    
end

if (strcmp(SaveAsType, '.mat struct'))
    save(sprintf('%s\\%s.%s.mat', get(handles.edOutputDir, 'String'),...
        'Rvlk', get(handles.edOutputId, 'String')),...
        'TmpStruct');
end
set(handles.pbConvert, 'String', 'CONVERT');
set(handles.Pass2Mat, 'Pointer', 'arrow')

% **** END ConvertFTData ****
% *************************************************************************
% *************************************************************************
function AddVerbose(handles,TextInput)

CurrentText = get(handles.lbVerbose, 'String');
CurrentText{end+1} = TextInput;
set(handles.lbVerbose, 'Value', length(CurrentText), 'String', CurrentText);
drawnow
% **** END AddVerbose ****
% *************************************************************************
% *************************************************************************
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

% **** END MyHex2Dec(h) ****
% *************************************************************************
% *************************************************************************
% Used to sort the parameters according to user pref.
function pbSort_Callback(hObject, eventdata, handles)

ParamList = getappdata(handles.Pass2Mat, 'ParamList');
set(handles.pbSort, 'Visible', 'Off')
Indices = getappdata(handles.Pass2Mat, 'SelectedCell');

% First get the struct into a cell format
for I = 1:length(ParamList)
    ParamList(I).Name;
    ParamListTmp{I,1} = ParamList(I).Name;
    ParamListTmp{I,2} = ParamList(I).RT;
    ParamListTmp{I,3} = ParamList(I).SA;
    ParamListTmp{I,4} = ParamList(I).Word;
    ParamListTmp{I,5} = ParamList(I).TxRx;
    ParamListTmp{I,6} = ParamList(I).Factor;
    ParamListTmp{I,7} = ParamList(I).TwosComp;
end

NewListTmp = sortrows(ParamListTmp,Indices(2)); % Sort the list

% Now get the cell format back to the struct format 
for I = 1:length(ParamList)
    NewParamList(I).Name     = NewListTmp{I,1};
    NewParamList(I).RT       = NewListTmp{I,2};
    NewParamList(I).SA       = NewListTmp{I,3};
    NewParamList(I).Word     = NewListTmp{I,4};
    NewParamList(I).TxRx     = NewListTmp{I,5};
    NewParamList(I).Factor   = NewListTmp{I,6};
    NewParamList(I).TwosComp = NewListTmp{I,7};
end

setappdata(handles.Pass2Mat, 'ParamList', NewParamList)
PopulateListBox(hObject, eventdata, handles)


% **** END pbSort_Callback ****
% --------------------------------------------------------------------
function mnHelp_Help_Callback(hObject, eventdata, handles)
% 

Paths = getappdata(handles.Pass2Mat, 'Paths');
web(sprintf('%s\\HelpFiles\\Pass2Mat.html', Paths.Exe))


% --------------------------------------------------------------------
function mnFile_MakeConfig_Callback(hObject, eventdata, handles)
% I think this makes the Flighttest.cfg file used by CONVERT FLIGHT TEST DATA
DirName = uigetdir;
DirList = dir(DirName);
[FileName, PathName] = uiputfile('*.cfg', 'Config File name', '*.cfg');
hFile = fopen(sprintf('%s%s', PathName, FileName), 'wt')

for I = 3:length(DirList)
    try
        TmpLoad = load(sprintf('%s\\%s', DirName, DirList(I).name));
    catch Me
        disp('err')
        continue;
    end
    TmpName = fieldnames(TmpLoad);
    if(strfind(char(TmpName), '0003'))
        TimeVal = '0003';
    elseif(strfind(char(TmpName), '0004'))
        TimeVal = '0004';
    elseif(strfind(char(TmpName), '0006'))
        TimeVal = '0006';
    elseif(strfind(char(TmpName), '0012'))
        TimeVal = '0012';
    elseif(strfind(char(TmpName), '0025'))
        TimeVal = '0025';
    elseif(strfind(char(TmpName), '0050'))
        TimeVal = '0050';
    else
        TimeVal = '????';
    end
    Name = char(TmpName);
    NameLen = length(Name);
    fwrite(hFile, sprintf('%s   %s   time%s   %s\n', Name(1:NameLen-4), Name, TimeVal, lower(Name(1:NameLen-8))));
end
fclose(hFile);


% **** END mnFile_MakeConfig_Callback ****
% *************************************************************************
% *************************************************************************
% Setting the Radio buttons for the file type
function rdMatTxt_Callback(hObject, eventdata, handles)
% 
set(handles.rdMatTxt, 'Value', 0)
set(hObject, 'Value', 1)
if(strcmp(get(hObject, 'String'), '.mat struct'))
    set([handles.edStructName, handles.txtStructName], 'Visible', 'On')
else
    set([handles.edStructName, handles.txtStructName], 'Visible', 'Off')
end

% **** END rdMatTxt_Callback ****
% --------------------------------------------------------------------
function mnHelp_About_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.Pass2Mat, 'Paths');
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
CRC = dec2hex(W1*W2); % Multiply 2 sets for own unique checksum

Version = {'Pass2Mat - Version 3.3';...
         'Date: 2013-11-08';...
        ['CRC: ', CRC, '']};
Handle = helpdlg(Version,'Pass2Mat');

% --- Executes when selected cell(s) is changed in tblParam.
function tblParam_CellSelectionCallback(hObject, eventdata, handles)
% Remembers the last cell that was highlighted

setappdata(handles.Pass2Mat, 'SelectedCell', eventdata.Indices);
set(handles.pbSort, 'Visible', 'On')

% *************************************************************************
% *************************************************************************
% *************************************************************************
% *************************************************************************
