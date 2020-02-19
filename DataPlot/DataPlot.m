% DataPlot: A tool for creating complex graphs of big data. 
%           It was specifically developed to plot data from software parameters 
%           on a typical data bus and therefore it has the unique ability 
%           to plot individual bits of a paramter.
% Written by:	J. van Zyl
% Date:			2008
% Updated:      J. van Zyl
% Last Date:    2018-03-09

function varargout = DataPlot(varargin)
% DATAPLOT M-file for DataPlot.fig
% DATAPLOT, by itself, creates a new DATAPLOT or raises the existing
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DataPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @DataPlot_OutputFcn, ...
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
% --- Executes just before DataPlot is made visible.
function DataPlot_OpeningFcn(hObject, ~, handles, varargin)
%
handles.output = hObject; % Choose default command line output for DataPlot
guidata(hObject, handles); % Update handles structure
AddVerbose(handles,sprintf('Current working dir: %s', pwd));

% Check for OS
    if isunix
        DirSym = '/'
    else
        DirSym = '\\'
    end

try % See if a Config file exists
    load DataPlotConfig.mat
catch ME % If no Config file exist set paths to default values
    Paths.Data = sprintf('%s\\',pwd);
    Paths.Config = sprintf('%s\\Projects\\',pwd);    
end
Paths.Sym = DirSym;
Paths.Exe = sprintf('%s\\',pwd);
setappdata(handles.DataPlot, 'Paths', Paths);

GP.TitleFontSize = 12; 
GP.AxesFontSize = 10;
GP.LineWidth = 1;
GP.MarkerSize = 5;
GP.DataTipDecX = 6;
GP.DataTipDecY = 3;

setappdata(handles.DataPlot, 'GraphProperties', GP);
setappdata(handles.DataPlot, 'UpdateStartTime', 'True') % StartTime must be re-calculated

% Get Jabberwock logo
Jabberwock = imread('Jabberwock_m.jpg');
image(Jabberwock, 'Parent', handles.axJabberwock)
set(handles.axJabberwock, 'YTickLabel',[])
set(handles.axJabberwock, 'XTickLabel',[])
set(handles.axJabberwock, 'XTick',[])
set(handles.axJabberwock, 'YTick',[])

mnFile_NewProject_Callback([],[],handles)
% -------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = DataPlot_OutputFcn(~, ~, handles) 
% 
varargout{1} = handles.output;

% -------------------------------------------------------------------------
% --- Executes on closing of program
function DataPlot_CloseRequestFcn(hObject, ~, handles)
%
Paths = getappdata(handles.DataPlot, 'Paths');
save('DataPlotConfig', 'Paths');
for I = 1:200
    if(ishandle(I))
        close(I)
    end
end
delete(hObject);

% *************************************************************************
% *************************************************************************
% *************************************************************************
function pbDataDir_Callback(~, ~, handles)
% For .mat or .txt files set the data directory. For a struct set the filename
set(handles.DataPlot, 'Pointer', 'watch')

Paths = getappdata(handles.DataPlot, 'Paths');

Paths.Data = uigetdir(Paths.Data, 'Select the variable directory');
if isequal(Paths.Data,0)
    set(handles.DataPlot, 'Pointer', 'arrow')
    return
end
set(handles.edDataDir, 'String', Paths.Data);

DirFileNames = dir(Paths.Data);
Len = length(DirFileNames);
if(Len > 10)
    Len = 10; % Just want to list 8 files
end

FileNames = DirFileNames(3).name;
for I = 4:Len
    FileNames = [FileNames, char(10), DirFileNames(I).name];
end
Pos = strfind(FileNames,'.');
FileID = FileNames(Pos(1)+1:Pos(2)-1);
if ~strcmp(get(handles.edFileId, 'String'), FileID)
    Ans = questdlg(['It looks like the File ID should be: ', FileID, char(10),...
        'Change File ID for you, or not ?', char(10), char(10), FileNames], 'FILE ID CHECK',...
        'Change', 'Ignore', 'Change');
    if strcmp(Ans, 'Change')
        if isempty(strfind(FileID, 10)) % carriage return in fileId - can't be right, so ignore
            set(handles.edFileId, 'String', FileID)
        end
    end
end
setappdata(handles.DataPlot, 'Paths', Paths);
setappdata(handles.DataPlot, 'UpdateStartTime', 'True') % StartTime must be re-calculated
set(handles.edTestDescription, 'BackgroundColor', [1;0;0]) % Warn that tile must change
set(handles.DataPlot, 'Pointer', 'arrow')
% **** END pbWord_Callback ****
% *************************************************************************
% *************************************************************************	
function SetStartTime(handles)
Paths = getappdata(handles.DataPlot, 'Paths');

Names = dir([Paths.Data,'\*.mat']);
Len  = length(Names);

StartTime = (23*3600 + 59*60 + 59)*365; % Biggest time possible 
try
    for I=1:Len
        GetDot = strfind(Names(I).name,'.');
        VarName = Names(I).name(1:GetDot(1)-1);
        load([Paths.Data,'\',Names(I).name])
        if ~eval(['isempty(', VarName, ')'])
            eval(['FileStartTime = ', VarName, '(1,1);']);
            if StartTime > FileStartTime
                StartTime = FileStartTime;
            end
        end
        eval(['clear ', VarName]);
    end
catch ME
    AddVerbose(handles, ['Invalid content in file: ', Names(I).name])
    MsgFlag = 1;
end
if exist('MsgFlag', 'var')
    msgbox({'Invalid content,', 'Check "Input Type" and "Data Directory"',...
        'Or it is a problem with a specific file',...
        'Check the Messages for "Invalid content"', 'Not necessarily a show stopper'},...
        'INVALID DATA')
end
    
setappdata(handles.DataPlot, 'StartTime', StartTime);
Hours = floor(StartTime/3600);
Minutes = floor((StartTime/3600 - Hours)*60);
Seconds = floor(((StartTime/3600 - Hours)*60 - Minutes)*60);
MilliSeconds = (((StartTime/3600 - Hours)*60 - Minutes)*60 - Seconds)*1000;
set(handles.edHour, 'String', sprintf('%d',Hours))
set(handles.edMin, 'String', sprintf('%d',Minutes))
set(handles.edSec, 'String', sprintf('%d',Seconds))
set(handles.edmSec, 'String', sprintf('%0.3f',MilliSeconds))
setappdata(handles.DataPlot, 'UpdateStartTime', 'False')

% **** END SetStartTime ****
% *************************************************************************
% *************************************************************************	 
function pbPlotWord_Callback(~, ~, handles)
% Create and plot all the data as specified in the config file
set(handles.DataPlot, 'Pointer', 'watch')
Paths = getappdata(handles.DataPlot, 'Paths');
drawnow 
if strcmp(getappdata(handles.DataPlot, 'UpdateStartTime'), 'True') % Did any parameters change?
    SetStartTime(handles) % Re-calculate the Start Time
end

StartTime = getappdata(handles.DataPlot, 'StartTime');

DispText = 'Loading.';
ParamDetail = GetData(handles, 'ParamDetail'); % Get the data
% Load all the relevant variables
LoadedVars = {''}; % Currently no variables loaded
Cnt = 0; FormulaCnt = 0;
for I = 1:length(ParamDetail)
    set(handles.txtProgress, 'String', DispText);
    drawnow
    if strcmp(ParamDetail(I).VarName, '#FORMULA#')
        FormulaCnt = FormulaCnt + 1;
        ParamDetail(I).TmpVar = ['FORMULA__', num2str(FormulaCnt), '__'];
        eval(['FORMULA__', num2str(FormulaCnt),...
            '__ = RunUserFormula(ParamDetail(I).Formula, handles);'])
        ParamDetail(I).VarName = ParamDetail(I).TmpVar;
        continue
    else
        ParamDetail(I).TmpVar = ParamDetail(I).VarName;
    end
    
    for J = 1:length(LoadedVars)                  % Check if the variable name 
        if(strfind(char(LoadedVars{J}), ParamDetail(I).VarName)) % is already in the list
            continue
        end
    end
    Cnt = Cnt + 1; % Keep track of amount of different words / variables
    LoadedVars{Cnt} = ParamDetail(I).VarName; % Add word / variable to list
    

    FileName = sprintf('%s%s%s.%s.mat',get(handles.edDataDir, 'String'),...
        Paths.Sym, ParamDetail(I).VarName, get(handles.edFileId, 'String'));    

    try
        load(FileName); % For .mat or .txt files
    catch ME
        AddVerbose(handles,sprintf('No such File: %s', FileName));
        ParamDetail(I).TmpVar = '?!FILE_NOT_LOADED!?';
        LoadedVars{Cnt} = '';
        Cnt = Cnt-1;
        continue
    end
    DispText = sprintf('%s.', DispText);
end

% Get Graph Properties
GP = getappdata(handles.DataPlot, 'GraphProperties');

% Creates figure in which to plot
if ishghandle(get(handles.pmnFigures, 'Value')) % Check if Figure exists
    figure(get(handles.pmnFigures, 'Value')) % Make this the current figure
    PreviousZoom = axis;% Store current zoom Value
    clf(get(handles.pmnFigures, 'Value')) % Clear old plots from figure
else
    figure(get(handles.pmnFigures, 'Value')) % Create this figure  
end

% % ******************** FUTURE ************************
% % FigureData.SubPlot(I).Title
% % FigureData.SubPlot(I).XLabel
% % FigureData.SubPlot(I).YLabel
% % FigureData.ParamDetail(J).SubPlotNum
% FigureData = GetData(handles, 'All');
% SubPlotNum = length(FigureData.Subplot);
% for I = 1:SubPlotNum
%     PlotHandle(I) = subPlot(SubPlotNum,1,I)
%     if I == 1
%         title(PlotHandle(I), [get(handles.edTestDescription, 'String'),...
%             FigureData.SubPlot(I).Title]);
%     else
%         title(PlotHandle(I), FigureData.SubPlot(I).Title);
%     end
%     xlabel(PlotHandle(I), FigureData.SubPlot(I).XLabel)
%     ylabel(PlotHandle(I), FigureData.SubPlot(I).YLabel) 
% end
% 
% % INSIDE FOR LOOPS
%      plot(PlotHandle(ParamDetail(I).SubPlotNum), TmpVar(:,1),...
%                     TmpVar(:,2) * ParamDetail(I).Factor + ParamDetail(I).Offset,...
%                     [ParamDetail(I).Symbol, ParamDetail(I).LineType],...
%                     'MarkerSize', GP.MarkerSize, 'LineWidth', GP.LineWidth, ...
%                     'Color', ParamDetail(I).ColorArray)
% 
% 
% ****************** END FUTURE ***********************

axesH = axes; %*********************
title(axesH, [get(handles.edTitle, 'String'),...
    get(handles.edTestDescription, 'String')]);
hDatatip = datacursormode(get(handles.pmnFigures, 'Value')); % Get handle for the Data Tip properties
set(hDatatip, 'Enable', 'Off', 'SnapToDataVertex','On',... % Set Data Tip properties in figure
    'UpdateFcn', @DataTipProperties)

% Massage decimal time to readable format
mSeconds = get(handles.edmSec, 'String');
GetDot = strfind(mSeconds, '.');
mSec = mSeconds(1:GetDot(1)-1);
uSec = mSeconds(GetDot(1)+1:end);
XlabelTime = sprintf('Start Time = %02d:%02d:%02d.%03d%03d',...
    str2double(get(handles.edHour, 'String')),...
    str2double(get(handles.edMin, 'String')),...
    str2double(get(handles.edSec, 'String')),...
    str2double(mSec),...
    str2double(uSec));
xlabel(axesH, [get(handles.edXaxes, 'String'), char(10), XlabelTime])

hold(axesH, 'on')
grid(axesH, 'on')
set(handles.txtProgress, 'String', ['Constructing Plot for:'; get(handles.edTitle, 'String')])
drawnow

if(get(handles.rdBitPlot, 'Value') == 1) % This is a BIT plot
    YTicks(1:length(ParamDetail)) = 0;
    YTickLabel = cell(1,length(ParamDetail));
    PlotPos = 0; TickCnt = 0; 
    
    StructLen = length(ParamDetail); 
    for I = 1:StructLen % Swap the ParamDetail around so that it ties up with the DataPlot spreadsheet
        NewDataStruct(I) = ParamDetail(StructLen + 1 - I);
    end
    ParamDetail = NewDataStruct;
    
    for I = 1:StructLen
        if(strcmp(ParamDetail(I).TmpVar, '?!FILE_NOT_LOADED!?'))
            TmpVar = [StartTime 0]; % Give 0 values so that the program don't crash
        else
        	TmpVar = eval(ParamDetail(I).TmpVar); % Load the actual data     
        end   
        if(isempty(TmpVar))
            TmpVar = [StartTime 0]; % Give 0 values so that the program don't crash
            AddVerbose(handles,sprintf('Empty variable: %s', ParamDetail(I).TmpVar));
        end
        TmpData = bitplot(TmpVar(:,2),ParamDetail(I).Size); 
        BitNum = ParamDetail(I).Bit;
        if(strfind(BitNum, '-'))
            Place =  strfind(BitNum, '-');
            StartBit = str2double(BitNum(1:Place(1)-1))+1; % get the StartBit value out of the string
            if(length(Place) == 2) % Determine if the user specified a Indexing size
                EndBit = str2double(BitNum(Place(1)+1:Place(2)-1))+1; % get the EndBit value out of the string
                Indexing = str2double(BitNum(Place(2)+1:end));
            else
                EndBit = str2double(BitNum(Place(1)+1:end))+1; % get the EndBit value out of the string
                Indexing = -1;
            end
            Scaling = EndBit - StartBit + 1;
            MaxBitVal = 2^Scaling;
            NewData = Mybin2dec(TmpData(:,StartBit:EndBit)); % Get the decimal value of the bits
            NewData = NewData * ParamDetail(I).Factor / Scaling;  % Scale the value according to the amount of bits
            NewData = NewData + PlotPos + ParamDetail(I).Offset; % Add the Plot position to offset the graph
            PlotPos = PlotPos + MaxBitVal/Scaling + 1 + ParamDetail(I).Offset; % Increment the Plot position for the next graphs
            TickPos = PlotPos - MaxBitVal/Scaling - 1;
            if Indexing == -1 % Don't add any additional tick marks
                TickCnt = TickCnt + 1;
                YTicks(TickCnt) = TickPos;
                YTickLabel{TickCnt} = ParamDetail(I).Descript;
            elseif Indexing == 0     % Add tick marks
                for J = 1:MaxBitVal  % Scale according to number of bits
                    TickCnt = TickCnt + 1;
                    YTicks(TickCnt) = TickPos;
                    TickPos = TickPos + ParamDetail(I).Factor/Scaling;
                    if J == 1
                        YTickLabel{TickCnt} = ParamDetail(I).Descript;
                    else
                        YTickLabel{TickCnt} = J-1;             
                    end
                end
            else                            % Add tick marks
                Increment = (MaxBitVal-1)/(Indexing*Scaling); % Scale according to user Values
                for J = 1:Indexing + 1 
                    TickCnt = TickCnt + 1;
                    YTicks(TickCnt) = TickPos;
                    TickPos = TickPos + ParamDetail(I).Factor*Increment;
                    if J == 1
                        YTickLabel{TickCnt} = ParamDetail(I).Descript;
                    else
                        YTickLabel{TickCnt} = (J-1)*(MaxBitVal-1) / Indexing;
                    end
                end
            end
        else
            NewData = TmpData(:,str2double(BitNum)+1); % Get data for specific bit
            NewData = NewData * ParamDetail(I).Factor / 3; % Divide answer by 3 for better plotting results
            NewData = NewData + PlotPos + ParamDetail(I).Offset; % Add plotting position to offset graph from others  
            PlotPos = PlotPos + ParamDetail(I).Offset + 1;
            TickPos = PlotPos - 1;
            TickCnt = TickCnt + 1;
            YTicks(TickCnt) = TickPos;
            YTickLabel{TickCnt} = ParamDetail(I).Descript;
        end
        if get(handles.rdTimeOnX, 'Value')
            stairs(axesH,(TmpVar(:,1)-StartTime), NewData ,...
                 [ParamDetail(I).Symbol, ParamDetail(I).LineType],...
                    'MarkerSize', GP.MarkerSize, 'LineWidth', GP.LineWidth, ...
                    'Color', ParamDetail(I).ColorArray)
        else
            stairs(axesH,TmpVar(:,1), NewData ,...
                 [ParamDetail(I).Symbol, ParamDetail(I).LineType],...
                    'MarkerSize', GP.MarkerSize, 'LineWidth', GP.LineWidth, ...
                    'Color', ParamDetail(I).ColorArray)
        end
      %  drawnow - Wastes a lot of time 
    end
    try
        set(axesH, 'YTickLabel',YTickLabel, 'FontSize', GP.AxesFontSize ) % Creates the labels on the Y axes
        set(axesH, 'YTick', YTicks)         % Sets the amount of labels on the Y axes
    catch ME
        msgbox({sprintf('For FIGURE %s :', char(get(handles.edTitle, 'String'))),...
            'Offset for parameter is too negative',...
            'Ytick label marks must be increasing',...
            'Y-axes labels will be corrupt',...
            'Change Offset Value for paremeters'},'Plotting ERROR')
    end
else  % This is a WORD plot
    ylabel(axesH, get(handles.edYaxes, 'String'))
    for I = 1:length(ParamDetail) 
        if(strcmp(ParamDetail(I).TmpVar, '?!FILE_NOT_LOADED!?'))... % File don't exist
                || strcmp(eval(ParamDetail(I).TmpVar), 'NP') % Do not plot this formula (Answer = 'NP')
            TmpVar = [StartTime 0]; % Give 0 values so that the program don't crash
        else
            TmpVar = eval(ParamDetail(I).TmpVar); % Load the actual data     
        end
        if(isempty(TmpVar))
            TmpVar = [StartTime 0]; % Give 0 values so that the program don't crash
            AddVerbose(handles,sprintf('Empty variable: %s', ParamDetail(I).TmpVar));
        end
 
        % Perform Data Filtering if requested
        if ParamDetail(I).Filter > 0
            TmpVar = DataSmooth(TmpVar, ParamDetail(I).Filter);
        end
        
        if get(handles.rdTimeOnX, 'Value')
            if ParamDetail(I).StepPlot == 1
                stairs(axesH, (TmpVar(:,1)-StartTime),...
                    TmpVar(:,2) * ParamDetail(I).Factor + ParamDetail(I).Offset,...
                    [ParamDetail(I).Symbol, ParamDetail(I).LineType],...
                    'MarkerSize', GP.MarkerSize, 'LineWidth', GP.LineWidth, ...
                    'Color', ParamDetail(I).ColorArray)
            else      
                plot(axesH, (TmpVar(:,1)-StartTime),...
                    TmpVar(:,2) * ParamDetail(I).Factor + ParamDetail(I).Offset,...
                    [ParamDetail(I).Symbol, ParamDetail(I).LineType],...
                    'MarkerSize', GP.MarkerSize, 'LineWidth', GP.LineWidth, ...
                    'Color', ParamDetail(I).ColorArray)
            end
        else
            if ParamDetail(I).StepPlot == 1
                stairs(axesH, TmpVar(:,1),...
                    TmpVar(:,2) * ParamDetail(I).Factor + ParamDetail(I).Offset,...
                    [ParamDetail(I).Symbol, ParamDetail(I).LineType],...
                    'MarkerSize', GP.MarkerSize, 'LineWidth', GP.LineWidth, ...
                    'Color', ParamDetail(I).ColorArray)
            else
                plot(axesH, TmpVar(:,1),...
                    TmpVar(:,2) * ParamDetail(I).Factor + ParamDetail(I).Offset,...
                    [ParamDetail(I).Symbol, ParamDetail(I).LineType],...
                    'MarkerSize', GP.MarkerSize, 'LineWidth', GP.LineWidth, ...
                    'Color', ParamDetail(I).ColorArray)
            end
        end
        LegendList{I} = ParamDetail(I).Descript;
    end
     legend(axesH, LegendList,'location', 'NorthEastOutside')
    set(axesH, 'FontSize', GP.AxesFontSize)
end

if exist('PreviousZoom', 'var') % Check if variable exist
    zoom(get(handles.pmnFigures, 'Value'), 'reset'); % Set default zoom value to current
    axis(PreviousZoom) % Now zoom the figure to where it was previously
end
if get(handles.rdbSetXY, 'Value') == 1
    axis([str2double(get(handles.edXmin, 'String')) str2double(get(handles.edXmax, 'String'))...
            str2double(get(handles.edYmin, 'String')) str2double(get(handles.edYmax, 'String'))])
end

hTitle = get(axesH, 'Title');
set(hTitle, 'FontSize', GP.TitleFontSize)

hold off
set(handles.txtProgress, 'String', ' ');
set(handles.DataPlot, 'Pointer', 'arrow')

% ---- END pbPlotWord_Callback ----
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function Data = DataSmooth(Data, Smooth)
% Perform Smoothing if needed

Smooth = round(Smooth/2);
if Smooth > 0.1*length(Data(:,2))
    AddVerbose(handles,sprintf('The Smoothing value is too big for the set of data: %s', ParamDetail(I).TmpVar));
    return
end

VarLen = length(Data(:,2));
TmpVar = Data;
if Smooth > 0
    for J = 1:VarLen
        if J <= Smooth && J < VarLen - Smooth
            TmpVar(J,2) = mean(Data(1:J+Smooth,2));
        elseif J < VarLen - Smooth
            TmpVar(J,2) = mean(Data(J-Smooth:J+Smooth,2));
        else
            TmpVar(J,2) = mean(Data(J-Smooth:end,2));
        end
    end
end
Data = TmpVar;

% **** END pbPlotWord_Callback ****
%**************************************************************************
%**************************************************************************
function pbPlotAll_Callback(hObject, eventdata, handles)
% Perform the pbPlotWord_Callback for each of the Figures 

List = get(handles.pmnFigures, 'String'); % Get the length of the Figures list
set(handles.lbVerbose, 'String', '');
for I = 1:length(List)-1
    set(handles.pmnFigures, 'Value', I) % Set the Current Figure
    PopulateDisplay(handles) % Update the display 
    pbPlotWord_Callback(hObject, eventdata, handles) % Plot the current Figure
end

% **** END pbPlotAll_Callback ****
%**************************************************************************
%**************************************************************************
% Convert Decimal to Binary
function BitMatrix = bitplot(DecValue, BitSize)
MaxBitSize = ceil(log2(max(DecValue)));
if MaxBitSize < 1 
    MaxBitSize = 1; % Incase of a -inf value due to a empty DecValue
end
BitMatrix(1:length(DecValue),1:MaxBitSize) = 0;

for I = 1:length(DecValue)    
    BitMatrix(I,1:BitSize) = rem(floor(DecValue(I)*pow2(1-BitSize:0)),2);
end

% **** END bitplot ****
% *************************************************************************
% *************************************************************************
function pbAdd_Callback(hObject, eventdata, handles)
%

ParamDetail = GetData(handles, 'ParamDetail');
if(isfield(ParamDetail, 'VarName'))
    LengthBit = length(ParamDetail);
else
    LengthBit = 0;
end
 
LastWord = getappdata(handles.DataPlot, 'LastWord');
if(isempty(LastWord))
    LastWord = '*.mat';
end
Paths = getappdata(handles.DataPlot, 'Paths');
[FileName, Paths.Data] = uigetfile(sprintf('%s\\%s',...
    Paths.Data,...
    LastWord), 'SELECT FILE');
if(Paths.Data == 0) % In case the User press Cancel
    return
end
setappdata(handles.DataPlot, 'Paths', Paths)
setappdata(handles.DataPlot, 'LastWord', FileName)
[VarName, Remainder] = strtok(FileName, '.');
ParamDetail(LengthBit + 1).VarName = VarName;   


if(strcmp(get(handles.pbAdd, 'String'), 'Add a Bit')) % Are you adding a Bit or a Word
    Answer = inputdlg({'Bit nr.', 'Parameter description'},'PARAMETER DETAIL');
    if isempty(Answer)
        return
    end
    ParamDetail(LengthBit + 1).Bit = cell2mat(Answer(1));
else % Detail needed for adding a Word
    Answer(2) = inputdlg('Parameter description','PARAMETER DETAIL');
    ParamDetail(LengthBit + 1).Bit = '0';
end
ParamDetail(LengthBit + 1).Descript = char(Answer(2)); 
ParamDetail(LengthBit + 1).Size = 16;
ParamDetail(LengthBit + 1).Offset = 0;
ParamDetail(LengthBit + 1).Factor = 1;
ParamDetail(LengthBit + 1).ColorArray = [0 0 0];
ParamDetail(LengthBit + 1).Symbol = '';
ParamDetail(LengthBit + 1).LineType = '-';
ParamDetail(LengthBit + 1).StepPlot = 1;
ParamDetail(LengthBit + 1).Filter = 0;
SetBitData(handles, ParamDetail);

PopulateDisplay(handles) % Update the display 
%setappdata(handles.DataPlot, 'UpdateStartTime', 'True') % StartTime must be re-calculated

% **** END pbAdd_Callback ****
% *************************************************************************
% *************************************************************************
function pbAddAllBits_Callback(hObject, eventdata, handles)
%
ParamDetail = GetData(handles, 'ParamDetail');

if(isfield(ParamDetail, 'VarName'))
    LengthBit = length(ParamDetail);
else
    LengthBit = 0;
end

LastWord = getappdata(handles.DataPlot, 'LastWord'); % Get FileName and PathName 
if(isempty(LastWord))
    LastWord = '*.mat';
end
Paths = getappdata(handles.DataPlot, 'Paths');
[FileName, Paths.Data] = uigetfile(sprintf('%s\\%s',...
    Paths.Data,...
    LastWord), 'SELECT FILE');
if(Paths.Data == 0) % In case the User press Cancel
    return
end
setappdata(handles.DataPlot, 'Paths', Paths)
setappdata(handles.DataPlot, 'LastWord', FileName)
[VarName, Remainder] = strtok(FileName, '.');

Answer = str2double(inputdlg('Bit size of Parameter ? ','PARAMETER SIZE', 1, {'16'}));
if Answer < 1 || Answer > 1000
    Answer = 16; % Just try and add sanity to the value of Answer
end

for I = 1:Answer
    ParamDetail(LengthBit + I).VarName = VarName; 
    ParamDetail(LengthBit + I).Size = Answer; 
    ParamDetail(LengthBit + I).Bit = num2str(I-1);
    ParamDetail(LengthBit + I).Descript = num2str(I-1);
    ParamDetail(LengthBit + I).Offset = 0;
    ParamDetail(LengthBit + I).Factor = 1;
    ParamDetail(LengthBit + I).ColorArray = [0 0 0];
    ParamDetail(LengthBit + I).Symbol = '';
    ParamDetail(LengthBit + I).LineType = '-';
    ParamDetail(LengthBit + I).StepPlot = 1;
    ParamDetail(LengthBit + I).Filter = 0;
    SetBitData(handles, ParamDetail);
end
PopulateDisplay(handles) % Update the display 
%setappdata(handles.DataPlot, 'UpdateStartTime', 'True') % StartTime must be re-calculated

% **** END pbAddWord_Callback ****
% *************************************************************************
% *************************************************************************
function PopulateDisplay(handles)%
% Updates all display fields according to current Figure selection

FigureGroup = GetData(handles, 'FigureGroup');

if ~isfield(FigureGroup, 'ParamDetail') % Startup condition - If DataPlot is still blank - nothing loaded etc. just return
    set(handles.rdBitPlot, 'Value', 1); % Ensure Bit Plot stay selected - just so that it does not go out of sync
    return % Nothing to pouplate so return
end

if(get(handles.rdBitPlot, 'Value') == 1) % Setup Buttons and Wording for BITPLOT
    set(handles.pbAddAllBits, 'Visible', 'On')
    set(handles.pbAdd, 'String', 'Add a Bit')
    set(handles.edYaxes, 'Enable', 'off')
    set([handles.pbFormula, handles.pbEditFormula], 'Visible', 'Off')
    set(handles.txtBitWord, 'String', 'BIT PLOT');
else % Setup Buttons and Wording for WORDPLOT
    set([handles.pbAddAllBits], 'Visible', 'Off')
    set([handles.pbFormula, handles.pbEditFormula], 'Visible', 'On')
    set(handles.pbAdd, 'String', 'Add Word')
    set(handles.edYaxes, 'Enable', 'on')
    set(handles.txtBitWord, 'String', 'WORD PLOT');
end

set([handles.pbAdd, handles.pbUp, handles.pbDown], 'Visible', 'On')


if ~isfield(FigureGroup.ParamDetail, 'VarName') % If there are no VarName 
    set(handles.tblBitNames, 'Data', '');   % just clear the Table
    return                                  % and return
end

for I = 1:length(FigureGroup.ParamDetail)
     TableData{I,1} = FigureGroup.ParamDetail(I).VarName;
     TableData{I,2} = FigureGroup.ParamDetail(I).Size;
     TableData{I,3} = FigureGroup.ParamDetail(I).Bit;
     TableData{I,4} = FigureGroup.ParamDetail(I).Descript;
     TableData{I,5} = FigureGroup.ParamDetail(I).Offset;
     TableData{I,6} = FigureGroup.ParamDetail(I).Factor;
     TableData{I,7} = GetColorName(FigureGroup.ParamDetail(I).ColorArray);
     TableData{I,8} = FigureGroup.ParamDetail(I).Symbol;
     TableData{I,9} = FigureGroup.ParamDetail(I).LineType;  
     TableData{I,10} = FigureGroup.ParamDetail(I).StepPlot;
     TableData{I,11} = FigureGroup.ParamDetail(I).Filter;
end
set(handles.tblBitNames, 'Data', TableData);

FigureList = get(handles.pmnFigures, 'String');
set(handles.edTitle, 'String', FigureList(get(handles.pmnFigures, 'Value')))
set(handles.edYaxes, 'String', FigureGroup.Ylabel)
set(handles.edXaxes, 'String', FigureGroup.Xlabel)
set(handles.rdBitPlot, 'Value', FigureGroup.BitPlot)
set(handles.rdTimeOnX, 'Value', FigureGroup.TimeOnX)
set([handles.pbPlotAll, handles.pbPlotWord], 'Visible', 'On')

% **** END Populatetable ****
% *************************************************************************
% *************************************************************************
function LineColor = GetColorName(ColorArray)
switch ColorArray(3) + ColorArray(2)*10 + ColorArray(1)*100
    case 0
        LineColor = 'Black';    % [0 0 0]
    case 1
        LineColor = 'Blue';     % [0 0 1]
    case 10
        LineColor = 'Green';    % [0 1 0]
    case 100
        LineColor = 'Red';      % [1 0 0]
    case 101
        LineColor = 'Magenta';  % [1 0 1]
    case 110
        LineColor = 'Yellow';   % [1 1 0]
    case 011
        LineColor = 'Cyan';     % [0 1 1]
    case 66.6
        LineColor = 'Grey';     % [0.6 0.6 0.6]
    case 5
        LineColor = 'D_Green';  % [0.0 0.5 0.0]
    case 77
        LineColor = 'Mustard';  % [0.7 0.7 0.0]
    case 7.7
        LineColor = 'B_Green';  % [0.0 0.7 0.7]
    case 60.7
        LineColor = 'Purple';   % [0.6 0.0 0.7]
    case 106
        LineColor = 'Orange';   % [1.0 0.6 0.0]
    case 60
        LineColor = 'Brown';    % [0.6 0.0 0.0]
end

% **** END GetColorName ****
% *************************************************************************
% *************************************************************************
function LineColor = GetColorArray(ColorName)

switch lower(ColorName)
    case 'black'
        LineColor = [0 0 0];
    case 'blue'
        LineColor = [0 0 1];
    case 'green'
        LineColor = [0 1 0];
    case 'red'
        LineColor = [1 0 0];
    case 'magenta'
        LineColor = [1 0 1];
    case 'yellow'
        LineColor = [1 1 0];
    case 'cyan'
        LineColor = [0 1 1];
    case 'grey'
        LineColor = [0.6 0.6 0.6];
    case 'd_green'
        LineColor = [0.0 0.5 0.0];
    case 'mustard'
        LineColor = [0.7 0.7 0.0];
    case 'b_green'
        LineColor = [0.0 0.7 0.7];
    case 'purple'
        LineColor = [0.6 0.0 0.7];
    case 'orange'
        LineColor = [1.0 0.6 0.0];
    case 'brown'
        LineColor = [0.6 0.0 0.0];
end

% **** END GetColorArray ****
% *************************************************************************
% *************************************************************************
function tblBitNames_CellEditCallback(hObject, eventdata, handles)
% Updating the ParamDetail struct when a user edit the contents of the table 

ParamDetail = GetData(handles, 'ParamDetail');

switch eventdata.Indices(2) % Check which which column was edited 
    case 1                  % Indices(1) identifies in which row the edited cell is
      if isempty(eventdata.NewData)
            Quest = questdlg(['Remove parameter  "',...
                ParamDetail(eventdata.Indices(1)).VarName, '"  ?'],...
                    'WARNING','Yes','No','Yes');
            if(strcmp(Quest, 'Yes')) || (isempty(Quest))
                DeleteParameter(eventdata.Indices(1), handles);
                ParamDetail = GetData(handles, 'ParamDetail');
            end
      else
        ParamDetail(eventdata.Indices(1)).VarName = eventdata.NewData;
      end
    case 2
        ParamDetail(eventdata.Indices(1)).Size = eventdata.NewData; % Size column
    case 3
        if(str2double(eventdata.NewData) > ParamDetail(eventdata.Indices(1)).Size-1)
            msgbox('Bit Value must be smaller than the bit size', 'INVALID BIT')
            ParamDetail(eventdata.Indices(1)).Bit = eventdata.PreviousData; % Bit column 
        else
            ParamDetail(eventdata.Indices(1)).Bit = eventdata.NewData; % Bit column   
        end
    case 4
        ParamDetail(eventdata.Indices(1)).Descript = eventdata.NewData; % Parameter column
    case 5
        ParamDetail(eventdata.Indices(1)).Offset = eventdata.NewData; % Offset for plotting
    case 6
        ParamDetail(eventdata.Indices(1)).Factor = eventdata.NewData; % Factor for Scaling
    case 7
       ParamDetail(eventdata.Indices(1)).ColorArray = GetColorArray(eventdata.NewData); % color of plot
    case 8
        ParamDetail(eventdata.Indices(1)).Symbol = eventdata.NewData; % Symbol of plot
    case 9
        ParamDetail(eventdata.Indices(1)).LineType = eventdata.NewData; % LineType of plot
    case 10  
        ParamDetail(eventdata.Indices(1)).StepPlot = eventdata.NewData; % StepPlot 
    case 11  
        ParamDetail(eventdata.Indices(1)).Filter = eventdata.NewData; % StepPlot 
end

SetBitData(handles, ParamDetail);
PopulateDisplay(handles) % Update the display 
CommitData(hObject, eventdata, handles)

% **** END tblBitNames_CellEditCallback ****
% *************************************************************************
% *************************************************************************
function DeleteParameter(RowNum, handles)
%
ParamDetail = GetData(handles, 'ParamDetail');
NewBitNameData = ParamDetail(1:RowNum-1); % Copy all up to the row before the deletion
NewBitNameData(RowNum:length(ParamDetail)-1) = ParamDetail(RowNum+1:length(ParamDetail)); % Copy all after the deleted row
SetBitData(handles, NewBitNameData);
% **** END DeleteParameter ****
% *************************************************************************
% *************************************************************************
function pbUp_Callback(hObject, eventdata, handles)
% 
SelRow = str2double(getappdata(handles.DataPlot, 'SelectedRow'));
ParamDetail = GetData(handles, 'ParamDetail');

if(SelRow < 2)
    return
end

RowBitNameData = ParamDetail(SelRow);
ParamDetail(SelRow) = ParamDetail(SelRow-1);
ParamDetail(SelRow-1) = RowBitNameData;

SetBitData(handles, ParamDetail)
PopulateDisplay(handles) % Update the display 
setappdata(handles.DataPlot, 'SelectedRow', num2str(SelRow-1))

% **** END pbUp_Callback ****
% *************************************************************************
% *************************************************************************
function pbDown_Callback(hObject, eventdata, handles)
% 
SelRow = str2double(getappdata(handles.DataPlot, 'SelectedRow'));
ParamDetail = GetData(handles, 'ParamDetail');

if(SelRow == 0) || (SelRow > length(ParamDetail)-1)
    return
end

RowBitNameData = ParamDetail(SelRow);
ParamDetail(SelRow) = ParamDetail(SelRow+1);
ParamDetail(SelRow+1) = RowBitNameData;
SetBitData(handles, ParamDetail)

PopulateDisplay(handles) % Update the display 
setappdata(handles.DataPlot, 'SelectedRow', num2str(SelRow+1))

% **** END pbDown_Callback ****
% *************************************************************************
% *************************************************************************
function Data = GetData(handles, Level)
Project = getappdata(handles.DataPlot, 'Project');

if (strcmp(Level,'ParamDetail'))
    Data = Project.FigureGroup(get(handles.pmnFigures, 'Value')).ParamDetail;
else
    Data = Project.FigureGroup(get(handles.pmnFigures, 'Value'));
end

% **** END GetBitNameData ****
% *************************************************************************
% *************************************************************************
function SetBitData(handles, BitData)
Project = getappdata(handles.DataPlot, 'Project');
Project.FigureGroup(get(handles.pmnFigures, 'Value')).ParamDetail = BitData;
setappdata(handles.DataPlot, 'Project', Project);

% **** END SetBitNameData ****
% *************************************************************************
% *************************************************************************
function tblBitNames_CellSelectionCallback(hObject, eventdata, handles)
% Remember which cell was selected

if(numel(eventdata.Indices) == 0)
    return
end
setappdata(handles.DataPlot, 'SelectedCol', num2str(eventdata.Indices(2)))
setappdata(handles.DataPlot, 'SelectedRow', num2str(eventdata.Indices(1)))

% **** END tblBitNames_CellSelectionCallback ****
% *************************************************************************
% *************************************************************************
function tblBitNames_ButtonDownFcn(hObject, eventdata, handles)
% Right click function on mouse for the Table

Row = str2double(getappdata(handles.DataPlot, 'SelectedRow'));
Col = str2double(getappdata(handles.DataPlot, 'SelectedCol'));
if Row == 0
    return
end

if Col == 1 % Give 2 options to the user
    [Sel,Status] = listdlg('PromptString','Options:','SelectionMode',...
        'single', 'ListSize', [120 90],...
        'ListString', {'Help', 'Delete', 'Copy to memory', 'Paste from memory', 'Local Copy'});
     %   'ListString', {'Help','Delete','Edit', 'Copy'});
 
    if ~Status 
        return
    end
    switch Sel
        case 1 % Help
            msgbox(['WORD is usually the parameter name as defined in ',...
                'the 1553 ICD documentation. More precisely WORD ',...
                'is part of the filename in which the parameter data ',...
                'is stored. The files for a specific flight will ',...
                'typically be stored in one directory using the ',...
                'following format:', char(10), 'PARAM.NUM.EXT , where:', char(10),...
                '- PARAM is the parameter name as defined in the ICD,', char(10),...
                '- NUM is usually a 3 digit flight number and ', char(10),...
                '- EXT is the extension of the file, typically  ".mat"', char(10),...
                'Only the "PARAM" part is used in the WORD column', char(10), char(10),...
                'Example:', char(10), 'The file c:\Data\673_flt090\rpmfte11.090.mat',...
                char(10), 'Should be entered in the WORD column as "rpmfte11"'],...
                'DataPlot HELP - WORD')
        
        case 2 % Delete
            eventdata.Indices = [Row, 1]; 
          	eventdata.NewData = {};
        	tblBitNames_CellEditCallback(hObject, eventdata, handles) % Need to streamline this at some stage
        case 3 % Copy to memory
            ParamDetail = GetData(handles, 'ParamDetail');
            setappdata(handles.DataPlot, 'FormulaInMemory', ParamDetail(Row));
            
        % case ? % EDIT   
        %   	eventdata.Indices = [Row, 1]; 
        %  	eventdata.NewData = {'Change'};
        % 	tblBitNames_CellEditCallback(hObject, eventdata, handles) % Need to streamline this at some stage
        case 4 % Paste from memory
            ParamDetail = GetData(handles, 'ParamDetail');
            % Check that both  have the .Formula field
            MemDetail = getappdata(handles.DataPlot, 'FormulaInMemory');
            if isfield(MemDetail, 'Formula') && ~isfield(ParamDetail, 'Formula')
                ParamDetail(1).Formula = '';
            end    
            if   ~isfield(MemDetail, 'Formula') && isfield(ParamDetail, 'Formula')
                MemDetail(1).Formula = '';
            end
            ParamDetail(end+1) = orderfields(MemDetail, ParamDetail);
            SetBitData(handles, ParamDetail);
            PopulateDisplay(handles) % Update the display 
            CommitData(hObject, eventdata, handles)
        case 5 % Local copy
            ParamDetail = GetData(handles, 'ParamDetail');
            ParamDetail(end+1) = ParamDetail(Row); % Make an exact copy of the selected Formula
            ParamDetail(end).Descript = ''; % Clear the description
            SetBitData(handles, ParamDetail);
            PopulateDisplay(handles) % Update the display 
            CommitData(hObject, eventdata, handles)
    end
else % Only give the Help option
     switch Col
         case 2
             msgbox(['SIZE is the bit size of the Parameter'],...
                 'DataPlot HELP - SIZE')
         case 3
             msgbox(['BIT specifies which bit of the 16bit word must ',...
                 'be plotted. Bit is set to "0" when plotting the ',...
                 'parameter as a word.', char(10), 'There are also ',...
                 '3 overloaded methods which gives more flexibility ',...
                 'to the bitplot tool, the format is "#1-#2-#3"', char(10),...
                 '- #1 on its own will only plot the specific bit', char(10),...
                 '- #1-#2 Converts a range of bits from #1 to #2 ',...
                 'into a decimal value before plotting it in the ',...
                 'relevant space.', char(10),...
                 '- #1-#2-#3 the same as above but the #3 value ',...
                 'tells DataPlot how many grid lines and corresponding ',...
                 'indexing values to use for the display. If #3 is set ',...
                 'to "0" DataPlot will use the maximum decimal value ',...
                 'of the range of bits selected for determining the ',...
                 'amount of gridlines and corresponding indexing',...
                 char(10), char(10),'Example: ',...
                 char(10), '"5" Will only plot the value of bit 5', char(10),...
                 '"5-7" will convert bits 5-7 into a decimal value before ',...
                 'plotting it. The space required for the decimal ',...
                 'represenation is automatically calculated and assigned ',...
                 'by DataPlot.', char(10), '"5-7-0" will automatically put ',...
                 'in grid lines on the integer intervals', char(10),...
                 '"5-7-3" will divide the decimal value of 8 into 3 ',...
                 'intervals for displaying gridlines, use this option ',...
                 'if the -0 option is too cluttered'],...
                 'DataPlot HELP - BIT')
         case 4
             msgbox(['PARAMETER is just a text description that will  ',...
                 'be displayed next to the relevant bit during a ',...
                 'Bitplot or it will be used for the legend during a Word plot'],...
                 'DataPlot HELP - PARAMETER')
         case 5
             msgbox(['OFFSET is purely an offset added to the actual ',...
                 'value when plotting it.'],...
                 'DataPlot HELP - OFFSET')
         case 6
             msgbox(['FACTOR - The actual value gets multiplied by ',...
                 'FACTOR before being plotted.'], 'DataPlot HELP - FACTOR')
         case 7
             msgbox(['Choose the color of the plot line'],...
                 'DataPlot HELP - COLOR')
         case 8
             msgbox(['If left blank DataPlot will plot a line. If ',...
                 'however you want to see the individual data points ',...
                 'select one of the symbols from the drop down list'],...
                 'DataPlot HELP - SYMBOL')
         case 9
             msgbox(['Determine the type of line DataPlot will use ',...
                 'for plotting the graph'],...
                 'DataPlot HELP - LINE')
     end
end

% **** END tblBitNames_ButtonDownFcn ****
% *************************************************************************
% *************************************************************************
function DataPlot_ButtonDownFcn(hObject, eventdata, handles)
% When clicking elsewhere on the GUI set the Row nr. to 0

setappdata(handles.DataPlot, 'SelectedRow', '0');
setappdata(handles.DataPlot, 'SelectedCol', '0');

% **** END DataPlot_ButtonDownFcn ****
% *************************************************************************
% *************************************************************************
function mnFile_SaveFigure_Callback(hObject, eventdata, handles)
ParamDetail = GetData(handles, 'ParamDetail');
Paths = getappdata(handles.DataPlot, 'Paths');
[FileName,Paths.Config] = uiputfile(sprintf('%s*.cfg.mat',...
    Paths.Config), 'Save Config file');
if isequal(FileName,0) || isequal(Paths.Config,0)
    return
end
setappdata(handles.DataPlot, 'Paths', Paths);

eval(['save(''', Paths.Config, FileName, ''', ''ParamDetail'')']);

% **** END mnFile_Save_Callback ****
% *************************************************************************
% *************************************************************************
function  mnFile_LoadFigure_Callback(hObject, eventdata, handles)

FigureList = get(handles.pmnFigures, 'String');
if(strcmp(FigureList(get(handles.pmnFigures, 'Value')),''))
    msgbox('First Create or Select a Figure', 'NO FIGURE');
    return
end
Paths = getappdata(handles.DataPlot, 'Paths');
[FileName, Paths.Config] = uigetfile(sprintf('%s*.cfg.mat',Paths.Config)); 
if isequal(FileName,0) || isequal(Paths.Config,0)
    return
end
setappdata(handles.DataPlot, 'Paths', Paths);
eval(['load(''',Paths.Config,FileName,''');'])
try
    eval(['load(''',Paths.Config,FileName,''');'])
    ParamDetail;
catch ME
    msgbox('Config file is broken', 'Try another one');
    return
end

SetBitData(handles, ParamDetail)

PopulateDisplay(handles) % Update the display 

% **** END mnFile_LoadFigure_Callback ****
% *************************************************************************
% *************************************************************************
function mnFile_SaveProject_Callback(hObject, eventdata, handles)
Paths = getappdata(handles.DataPlot, 'Paths');
Project = getappdata(handles.DataPlot, 'Project');

Project.DataDir = get(handles.edDataDir, 'String');
Project.FileId = get(handles.edFileId, 'String');
Project.GraphProperties = getappdata(handles.DataPlot, 'GraphProperties');

if strcmp(get(hObject, 'Label'), 'Save Project As') ||...
        strcmp(get(handles.pnProject, 'Title'), 'Project') % Perform "Save As"
    [FileName,Paths.Config] = uiputfile(sprintf('%s*.mat',...
        Paths.Config), 'Save Config file');
    if isequal(FileName,0) || isequal(Paths.Config,0)
        return
    end
    setappdata(handles.DataPlot, 'Paths', Paths)
else % Save under the current name
    ProjectName = get(handles.pnProject, 'Title');
    Pos = strfind(ProjectName, ':');
    FileName = ProjectName(Pos(1)+3:end);
end

save(sprintf('%s%s', Paths.Config, FileName), 'Project');
set(handles.pnProject, 'Title', sprintf('Project :  %s', FileName))

% **** END mnFile_SaveProject_Callback ****
% *************************************************************************
% *************************************************************************
function mnFile_LoadProject_Callback(~, eventdata, handles)
% Load a new project File, clearing current environment
if ~isfield(eventdata, 'FileName')
    Paths = getappdata(handles.DataPlot, 'Paths');
    [FileName, Paths.Config] = uigetfile(sprintf('%s*.mat',Paths.Config)); 
    if isequal(FileName,0) || isequal(Paths.Config,0)
        return
    end
    setappdata(handles.DataPlot, 'Paths', Paths)
else
   FileName =  eventdata.FileName;
   Paths.Config = eventdata.Path;
end
try
    load(sprintf('%s%s',Paths.Config, FileName));

    for I = 1:length(Project.FigureGroup)           % Must be a better way ????????????????
        NameList(I) = Project.FigureGroup(I).Title;  % Must be a better way ????????????????
    end
catch ME
    Ans = questdlg('Config file is broken, try to fix it automatically ?',...
     'CONFIG FILE','Yes' , 'No', 'Yes');
    if strcmp(Ans, 'Yes')
        mnTools_FixProject_Callback(0, FileName, handles)
    else
        msgbox('Config file is broken', 'CONFIG FILE');  
    end
    return
end

if isfield(Project, 'ConfigVersion') && Project.ConfigVersion == 5 % CURRENT CONFIG VERSION
else
    Ans = questdlg('Config file has outdated structure, try to fix it automatically ?',...
     'CONFIG FILE','Yes' , 'No', 'Yes');
    if strcmp(Ans, 'Yes')
        mnTools_FixProject_Callback(0, FileName, handles)
    else
        msgbox('Config file is outdated', 'CONFIG FILE');
    end
    return
end

NameList(I+1) = {'<NEW>'};
set(handles.pmnFigures, 'String', NameList, 'Value', 1);
set(handles.edDataDir, 'String', '');
set(handles.edFileId, 'String', '');
setappdata(handles.DataPlot, 'Project', Project);
setappdata(handles.DataPlot, 'GraphProperties', Project.GraphProperties);
set(handles.pnProject, 'Title', sprintf('Project :  %s', FileName))
PopulateDisplay(handles) % Update the display  

% **** END mnFile_LoadProject_Callback ****
% *************************************************************************
% *************************************************************************
function mnFile_NewProject_Callback(hObject, eventdata, handles)
% 
Project.FigureGroup.ParamDetail = struct; % Create an empty Project structure
Project.ConfigVersion = 5; % Added the Size field in version 2
setappdata(handles.DataPlot, 'Project', Project); 

% Clear all Figures
for I = 1:length(get(handles.pmnFigures,'String'))
    try
        delete(I)
    catch
    end
end
set(handles.pmnFigures,'String', {'','<NEW>'}, 'Value', 1)
PopulateDisplay(handles) % Clean out most of the stuff from the display
set([handles.edFileId, handles.edTitle, handles.edYaxes, handles.edDataDir], 'String', '')
set(handles.pnProject, 'Title', 'Project')
set(handles.edXaxes,'String', 'Time (s)')

pbClear_Callback(hObject, eventdata, handles)

% ***   END mnFile_NewProject_Callback ***
% *************************************************************************
% *************************************************************************
function pmnFigures_Callback(hObject, eventdata, handles)
%

Project = getappdata(handles.DataPlot, 'Project');

NameList = get(handles.pmnFigures,'String');
Figure = NameList{get(handles.pmnFigures,'Value')};
ListLen = length(NameList);

if(strcmp(Figure, '<NEW>'))
    if(strcmp(NameList{1},''))
        ListLen = 1; % If no entires exist, set ListLen to 1      
    end
    Answer = inputdlg('Title of figure ?','TITLE');
    if(isempty(Answer))
        set(handles.pmnFigures, 'Value', 1)
        PopulateDisplay(handles) % Update the display 
        return
    end
    
    NameList(ListLen) = Answer;
    NameList{ListLen+1} = '<NEW>';
    set(hObject, 'String', NameList);
    
    set(handles.edTitle, 'String', Answer)
    Project.FigureGroup(ListLen).Title = Answer;
    Project.FigureGroup(ListLen).Ylabel = '';
    Project.FigureGroup(ListLen).Xlabel = 'Time (s)';
    if strcmp(get(handles.pbAdd, 'String'), 'Add a Bit')
        Project.FigureGroup(ListLen).BitPlot = 1;
    else
        Project.FigureGroup(ListLen).BitPlot = 0;
    end
    Project.FigureGroup(ListLen).TimeOnX = 1;
    Project.FigureGroup(ListLen).ParamDetail = struct;
    setappdata(handles.DataPlot, 'Project', Project)
    set(hObject,'Value', ListLen) % Set the dropdown menu to the latest entry
    ClearFigureData(hObject, eventdata, handles)
else
    FigNum = get(handles.pmnFigures, 'Value'); % Get the current selected dropdown menu item
    set(handles.edTitle, 'String', Project.FigureGroup(FigNum).Title)
    set(handles.edYaxes, 'String', Project.FigureGroup(FigNum).Ylabel)
    set(handles.edXaxes, 'String', Project.FigureGroup(FigNum).Xlabel)
    set(handles.rdBitPlot, 'Value', Project.FigureGroup(FigNum).BitPlot)
    set(handles.rdTimeOnX, 'Value', Project.FigureGroup(FigNum).TimeOnX)
    PopulateDisplay(handles) % Update the display 
end

% **** END pmnFigures_Callback ****
% *************************************************************************
% *************************************************************************
function ClearFigureData(hObject, eventdata, handles)
% Clear all the data specific to this figure

PopulateDisplay(handles) % Update the display 
set(handles.edYaxes, 'String', '')
set(handles.edXaxes, 'String', 'Time (s)')

% **** END ClearFigureData ****
% *************************************************************************
% *************************************************************************
function CommitData(hObject, eventdata, handles)
% This procedure ensures that all currently displayed data are updated to
% the Project dataset before moving on.
Project = getappdata(handles.DataPlot, 'Project');  
FigNum = get(handles.pmnFigures, 'Value'); % Get the current selected dropdown menu item
Project.FileId = get(handles.edFileId, 'String');
Project.DataDir = get(handles.edDataDir, 'String');
Project.FigureGroup(FigNum).Title = get(handles.edTitle, 'String');
Project.FigureGroup(FigNum).Ylabel = get(handles.edYaxes, 'String');
Project.FigureGroup(FigNum).Xlabel = get(handles.edXaxes, 'String');
Project.FigureGroup(FigNum).BitPlot = get(handles.rdBitPlot, 'Value');
Project.FigureGroup(FigNum).TimeOnX = get(handles.rdTimeOnX, 'Value');

setappdata(handles.DataPlot, 'Project', Project); 

% **** END SaveCurrentFigure ****
% *************************************************************************
% *************************************************************************
% Editing the Title / Figure Nr. description
function edTitle_Callback(hObject, eventdata, handles)

List = get(handles.pmnFigures, 'String'); % get the list of Figure titles
FigNum = get(handles.pmnFigures, 'Value'); % Get the current Figure Title to change
ListLen = length(List);
Project = getappdata(handles.DataPlot, 'Project'); 

if(strcmp(get(hObject, 'String'),''))% If empty delete the Figure from the list
    Quest = questdlg(['Delete Figure: ',char(10), '"',...
        char(Project.FigureGroup(FigNum).Title), '" ?'],...
                    'WARNING','Yes','No','No');
    if(strcmp(Quest, 'Yes')) || (isempty(Quest))
        NewProject = Project;
        NewProject.FigureGroup = Project.FigureGroup(1:FigNum-1);
        if(ListLen-2 > FigNum-1)
            NewProject.FigureGroup(FigNum:ListLen-2) = Project.FigureGroup(FigNum+1:ListLen-1);
        end
        NewList = List(1:FigNum-1);
        NewList(FigNum:ListLen-1) = List(FigNum+1:ListLen);
        set(handles.pmnFigures, 'Value', 1);    
    else
        NewList = List;
        NewProject = Project;
    end
else % Modify the name
    NewList = List;
    NewList(FigNum) = get(hObject, 'String'); % Set the specific Figure title according to changed Title edit box 
    NewProject = Project;
    NewProject.FigureGroup(FigNum).Title = get(hObject, 'String'); %update the Project struct with new name
end
set(handles.pmnFigures, 'String', NewList) % Update the popup menu with changed figure name
setappdata(handles.DataPlot, 'Project', NewProject);
pmnFigures_Callback(hObject, eventdata, handles);

% **** END edTitle_Callback ****
% *************************************************************************
% *************************************************************************
%
function rdBitPlot_Callback(hObject, eventdata, handles)

CommitData(hObject, eventdata, handles)
PopulateDisplay(handles) % Update the display 

% **** END rdBitPlot_Callback ****
% *************************************************************************
% *************************************************************************
%
function edXaxes_Callback(hObject, eventdata, handles)
CommitData(hObject, eventdata, handles)
% **** END edXaxes_Callback ****
% *************************************************************************
% *************************************************************************
%
function edYaxes_Callback(hObject, eventdata, handles)
CommitData(hObject, eventdata, handles)

% **** END edYaxes_Callback ****
% *************************************************************************
% *************************************************************************
%
function AddVerbose(handles,TextInput)
CurrentText = get(handles.lbVerbose, 'String');
CurrentText{end+1} = TextInput;
set(handles.lbVerbose, 'Value', length(CurrentText), 'String', CurrentText);
drawnow
% **** END AddVerbose ****
% *************************************************************************
% *************************************************************************
% 
function mnHelp_Help_Callback(hObject, eventdata, handles)

Paths = getappdata(handles.DataPlot, 'Paths');
web(sprintf('%sDataPlot.html', [Paths.Exe, 'HelpFiles\']))


% *************************************************************************
% *************************************************************************
% 
function pbClear_Callback(hObject, eventdata, handles)
% 
set(handles.lbVerbose, 'String', '');

% *************************************************************************
% *************************************************************************
% 
function mnTools_Graph_Callback(hObject, eventdata, handles)

GP = getappdata(handles.DataPlot, 'GraphProperties');
try
    Answer = inputdlg({'Title Font Size','Axes Font Size', 'Line Width',...
        'Marker Size', 'Data Tip X label decimal places',...
        'Data Tip Y Label decimal places'}, 'Graphics Properties',...
        1, {num2str(GP.TitleFontSize), num2str(GP.AxesFontSize),...
        num2str(GP.LineWidth), num2str(GP.MarkerSize),...
        num2str(GP.DataTipDecX), num2str(GP.DataTipDecY)});
catch % In case the guy still has old config files
    msgbox('Broken or old Project file, try running "Fix old Project file"',...
        'BROKEN CONFIG FILE')
    return
end
if(isempty(Answer))
    return
end
GP.TitleFontSize = str2num(char(Answer(1)));
GP.AxesFontSize = str2num(char(Answer(2)));
GP.LineWidth = str2num(char(Answer(3)));
GP.MarkerSize = str2num(char(Answer(4)));
GP.DataTipDecX = str2num(char(Answer(5)));
GP.DataTipDecY = str2num(char(Answer(6)));

setappdata(handles.DataPlot, 'GraphProperties', GP)

% *************************************************************************
% *************************************************************************
% Faster num2str conversion
function Dec = Mybin2dec(x)
[rows, cols] = size(x);
s = char(zeros(rows, cols));
for I = 1:rows
    s(I,:) = sprintf('%d', x(I,:));
end

% Convert to numbers
v = s - '0'; 
twos = pow2(cols-1:-1:0);
Dec = sum(v .* twos(ones(rows,1),:),2);

% **** END DataPlot_CloseRequestFcn ****
% *************************************************************************
% *************************************************************************
function edDataDir_Callback(hObject, eventdata, handles)
% Update the StartTime whenever the directory changes
Paths = getappdata(handles.DataPlot, 'Paths');
Paths.Data = get(handles.edDataDir, 'String');
setappdata(handles.DataPlot, 'Paths', Paths)
setappdata(handles.DataPlot, 'UpdateStartTime', 'True') % StartTime must be re-calculated
set(handles.edTestDescription, 'BackgroundColor', [1;0;0]) % Warn that tile must change
% **** END edDataDir_Callback ****
% *************************************************************************
% *************************************************************************
function edTestDescription_Callback(hObject, eventdata, handles)
% 
set(hObject, 'BackgroundColor', [1;1;1])

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function pbFormula_Callback(hObject, eventdata, handles)
% Add a new formula to the figure
if isappdata(handles.DataPlot, 'Formula')
    rmappdata(handles.DataPlot, 'Formula');
end
set(handles.pmnFigures, 'Enable', 'Off')% Must not be able to change figures while editor is open otherwise it overwrites the wrong figures
h = FormulaEditor(handles);
waitfor(h);
set(handles.pmnFigures, 'Enable', 'On')
if ~isappdata(handles.DataPlot, 'Formula')
    return
end
Formula = getappdata(handles.DataPlot, 'Formula');

ParamDetail = GetData(handles, 'ParamDetail');
if(isfield(ParamDetail, 'VarName'))
    LengthBit = length(ParamDetail);
else
    LengthBit = 0;
end

Answer = inputdlg('Parameter description','PARAMETER DETAIL');
ParamDetail(LengthBit + 1).VarName = '#FORMULA#';   
ParamDetail(LengthBit + 1).Size = 16;
ParamDetail(LengthBit + 1).Bit = '0';
ParamDetail(LengthBit + 1).Descript = char(Answer);
ParamDetail(LengthBit + 1).Offset = 0;
ParamDetail(LengthBit + 1).Factor = 1;
ParamDetail(LengthBit + 1).ColorArray = [0 0 0];
ParamDetail(LengthBit + 1).Symbol = '';
ParamDetail(LengthBit + 1).LineType = '-';
ParamDetail(LengthBit + 1).Formula = Formula;
ParamDetail(LengthBit + 1).StepPlot = 0;
ParamDetail(LengthBit + 1).Filter = 0;
SetBitData(handles, ParamDetail);

PopulateDisplay(handles) % Update the display 

% **** END  ****
% *************************************************************************
% *************************************************************************
function Answer = RunUserFormula(RUF_Text, handles)
%
Paths = getappdata(handles.DataPlot, 'Paths');
Flt = get(handles.edFileId, 'String');

UserFormString = '';
RUF_Cnt = 1; Len = length(RUF_Text);
while RUF_Cnt < Len +1
    if strncmp(RUF_Text(RUF_Cnt), 'load ',5)
        Tmp = char(RUF_Text(RUF_Cnt));
        Parameter = strtrim(Tmp(6:end));
        Pos = strfind(Parameter,';');
        if ~isempty(Pos) % In case the user ended the load statement with a ";"
            Parameter = Parameter(1:Pos-1); % remove ";"
        end
        UserFormString = [UserFormString,... 
            'load ''', Paths.Data,'\', Parameter, '.', Flt, '.mat'';'];
    else
        UserFormString = [UserFormString,...
            char(RUF_Text(RUF_Cnt)), ';'];
    end
    RUF_Cnt = RUF_Cnt+1; 
end

try
    eval(UserFormString)   
catch Error
    uiwait(msgbox(Error.message,'FORMULA ERROR','modal'));
    Answer = [-1 -1; -1 1; 1 1; 0 2; -1 1; 1 -1; -1 -1; 1 1; 1 -1]; % Private joke
    return
end

if ~exist('Answer')
    uiwait(msgbox(['Must assign Time and Data values to the variable ',...
        '"Answer" inside your formula.',char(10), 'DataPlot uses the "Answer" ',...
        'variable to create the plot', char(10), 'Example:', char(10),...
        'Answer = [-1 -1; -1 1; 1 1; 0 2; -1 1; 1 -1; -1 -1; 1 1; 1 -1] ',...
        'will be plotted since you haven''t provided values',...
        char(10), '- ENJOY!' ;],...
        'FORMULA ERROR','modal'));
    Answer = [-1 -1; -1 1; 1 1; 0 2; -1 1; 1 -1; -1 -1; 1 1; 1 -1]; % Private joke
end

% **** END  ****
% *************************************************************************
% *************************************************************************
function pbEditFormula_Callback(hObject, eventdata, handles)
% 
if isappdata(handles.DataPlot, 'Formula')
    rmappdata(handles.DataPlot, 'Formula'); % First clear any Formulas from appdata
end
ParamDetail = GetData(handles, 'ParamDetail');

Selection = getappdata(handles.DataPlot, 'SelectedRow');
set(handles.pmnFigures, 'Enable', 'Off') % Must not be able to change figures while editor is open otherwise it overwrites the wrong figures
h = FormulaEditor(handles, ParamDetail(str2double(Selection)).Formula);
waitfor(h);
set(handles.pmnFigures, 'Enable', 'On')
if ~isappdata(handles.DataPlot, 'Formula') % If Cancel was selected there would be no new formula to save
    return
end

Formula = getappdata(handles.DataPlot, 'Formula');

ParamDetail(str2double(Selection)).Formula = Formula;
SetBitData(handles, ParamDetail);

PopulateDisplay(handles) % Update the display 

% **** END  ****
% *************************************************************************
% *************************************************************************
function pmnFigures_ButtonDownFcn(hObject, eventdata, handles)
% Mouse Right-click functionality for Figure drop down menu
% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pmnFigures.

SelFigure = get(hObject, 'Value');

[Sel,Status] = listdlg('PromptString','Figure Options:','SelectionMode',...
    'single', 'ListSize', [90 60],...
    'ListString', {'Help','New','Delete', 'Copy'},...
    'Name', 'FIGURE');
if ~Status 
    return
end
switch Sel
    case 1 % Help
        msgbox(['Select a specific Figure to Plot or Edit. ',...
            'The contents of the figure will appear in the ',...
            'table on the right. There are 2 types of figures, ',...
            'Bitplot or Wordplot.', char(10), 'See "Help" for more info.',...
            'DataPlot HELP - WORD'])
    case 2 % New         
        NameList = get(handles.pmnFigures,'String');
        set(handles.pmnFigures,'Value', length(NameList)); % Move pointer to last entry in List which will point to <NEW>
        pmnFigures_Callback(hObject, eventdata, handles) % Call the function that actually adds the new Figure      
    case 3 % Delete
        set(handles.edTitle, 'String', '') % Set title String to ''
        edTitle_Callback(handles.edTitle, eventdata, handles) % Call Title function which will now delete the Figure
    case 4 % Copy 
        Project = getappdata(handles.DataPlot, 'Project');
        NameList = get(handles.pmnFigures,'String');
        SelFig = get(handles.pmnFigures,'Value');
        ListLen = length(NameList);

        if(strcmp(NameList{1},''))
            ListLen = 1; % If no entires exist, set ListLen to 1
            return
        end

        NameList(ListLen) = {'Copy'}; % Create a title called "Copy"
        NameList{ListLen+1} = '<NEW>'; % Move the <NEW> option to the bottom
        set(handles.pmnFigures, 'String', NameList); % Populate the listbox with the new values

        Project.FigureGroup(ListLen)= Project.FigureGroup(SelFig); % Make a copy of the Selected Figure to the new 'Copy" Figure
        Project.FigureGroup(ListLen).Title = {'Copy'}; % Set Title to "Copy"
        set(handles.edTitle, 'String', 'Copy'); % Set Title box to "Copy"
        setappdata(handles.DataPlot, 'Project', Project); % Save the new addition to Project
        set(hObject,'Value', ListLen) % Set the dropdown menu to the latest entry
        PopulateDisplay(handles)
end      


% ***   END pmnFigures_ButtonDownFcn ***
% ********************************************************************
% ********************************************************************
function [txt] = DataTipProperties(obj,event_obj)

hDataPlot = findobj('Tag', 'DataPlot');

GP = getappdata(hDataPlot, 'GraphProperties');

pos = get(event_obj,'Position');
txt = {['X: ', num2str(pos(1), ['%0.', num2str(GP.DataTipDecX), 'f'])],... 
    ['Y: ', num2str(pos(2),['%0.', num2str(GP.DataTipDecY), 'f'])]};


% --- Executes on button press in rdTimeOnX.
function rdTimeOnX_Callback(hObject, eventdata, handles)
% 
CommitData(hObject, eventdata, handles)
setappdata(handles.DataPlot, 'UpdateStartTime', 'True') % StartTime must be re-calculated

% ***   END DataTipProperties ***


% *************************************************************************
% *************************************************************************
function mnTools_FixProject_Callback(~, FileName, handles)
% 
Paths = getappdata(handles.DataPlot, 'Paths');

if isempty(FileName)
    [FileName, Paths.Config] = uigetfile(sprintf('%s*.mat',Paths.Config)); 
    if isequal(FileName,0) || isequal(Paths.Config,0)
        return
    end
end

try
    load(sprintf('%s%s',Paths.Config, FileName));
catch
    msgbox({'No this Project file is really stuffed',...
        'Unfortunately you''ll have to create a new one.'}, 'PROJECT FILE')
end

if ~exist('Project','var') %Check for the basics
    msgbox({'Doesn''t look like a Project file !!'...
        'Unfortunately you''ll have to create a new one.'}, 'PROJECT FILE')
    return
end

% Save the old file - just in case
save([Paths.Config, 'Old_', FileName], 'Project')

% Start fixing / converting Old to New
if isfield(Project, 'DataSet') % Old structure field names
    NewProj = Project;
    NewProj = rmfield(NewProj, 'DataSet');
    for I = 1:length(Project.DataSet)  
        NewProj.FigureGroup(I).Title = Project.DataSet(I).Title;
        NewProj.FigureGroup(I).Ylabel = Project.DataSet(I).Ylabel;
        NewProj.FigureGroup(I).Xlabel = Project.DataSet(I).Xlabel;
        NewProj.FigureGroup(I).BitPlot = Project.DataSet(I).BitPlot;
        if isfield(Project.DataSet(I), 'TimeOnX')
            NewProj.FigureGroup(I).TimeOnX = Project.DataSet(I).TimeOnX;
        end
        NewProj.FigureGroup(I).ParamDetail = Project.DataSet(I).BitNameData;
    end
    Project = NewProj;
    clear NewProj
    
elseif ~isfield(Project, 'FigureGroup') % Old structure field names
    msgbox({'Not even a FigureGroup data structure !!'...
        'Unfortunately you''ll have to create a new one.'}, 'PROJECT FILE')
    return
end

% Remove FileName from Project.FigureGroup(?).ParamDetail
if isfield(Project, 'FigureGroup')
    for I = 1:length(Project.FigureGroup)
        if isfield(Project.FigureGroup(I).ParamDetail, 'FileName')
            Project.FigureGroup(I).ParamDetail = rmfield(Project.FigureGroup(I).ParamDetail, 'FileName');
        end
    end
end

if ~isfield(Project, 'GraphProperties')
    Project.GraphProperties = struct;
end
if ~isfield(Project.GraphProperties, 'TitleFontSize') 
    Project.GraphProperties.TitleFontSize = 12;
end
if ~isfield(Project.GraphProperties, 'AxesFontSize') 
    Project.GraphProperties.AxesFontSize = 10;
end
if ~isfield(Project.GraphProperties, 'LineWidth')
    Project.GraphProperties.LineWidth = 1;
end
if ~isfield(Project.GraphProperties, 'MarkerSize')
    Project.GraphProperties.MarkerSize = 5;
end
if ~isfield(Project.GraphProperties, 'DataTipDecX')
    Project.GraphProperties.DataTipDecX = 3;
end
if ~isfield(Project.GraphProperties, 'DataTipDecY')
    Project.GraphProperties.DataTipDecY = 3;
end

if ~isfield(Project.FigureGroup, 'TimeOnX')
        for I = 1:length(Project.FigureGroup)
            Project.FigureGroup(I).TimeOnX = 1;
        end
end

% Add New Size parameter
if ~isfield(Project.FigureGroup(1).ParamDetail(1), 'Size')
    for I = 1:length(Project.FigureGroup)
        for J = 1:length(Project.FigureGroup(I).ParamDetail)
            Project.FigureGroup(I).ParamDetail(J).Size = 16;
        end
    end
end

% Add New StepPlot parameter
if ~isfield(Project.FigureGroup(1).ParamDetail(1), 'StepPlot')
    for I = 1:length(Project.FigureGroup)
        for J = 1:length(Project.FigureGroup(I).ParamDetail)
            Project.FigureGroup(I).ParamDetail(J).StepPlot = 0;
        end
    end
end

% Convert the Color names to Color Arrays TO BE REMOVED IN FUTURE VERSIONS
if ~isfield(Project.FigureGroup(1).ParamDetail, 'ColorArray')
    for I = 1:length(Project.FigureGroup)
        for J = 1:length(Project.FigureGroup(I).ParamDetail)
            Project.FigureGroup(I).ParamDetail(J).ColorArray = GetColorArray(Project.FigureGroup(I).ParamDetail(J).Color);
        end
        Project.FigureGroup(I).ParamDetail = rmfield(Project.FigureGroup(I).ParamDetail, 'Color');
    end   
end

% Add the Filter collumn
if ~isfield(Project.FigureGroup(1).ParamDetail, 'Filter')
    for I = 1:length(Project.FigureGroup)
        for J = 1:length(Project.FigureGroup(I).ParamDetail)
            Project.FigureGroup(I).ParamDetail(J).Filter = 0;
        end
    end   
end

Project.ConfigVersion = 5; % Added the Filter collumn

% Save the new file
save([Paths.Config, FileName], 'Project')

% Now load the new file
eventdata.FileName = FileName;
eventdata.Path = Paths.Config;
mnFile_LoadProject_Callback( 0, eventdata, handles)

% ***   END mnTools_FixConfig_Callback ***


% --------------------------------------------------------------------
% --------------------------------------------------------------------
function mnHelp_About_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.DataPlot, 'Paths');

eval(['!"', Paths.Exe, 'md5.exe" -n -o"', Paths.Exe, 'CRC_tmp.txt" "',...
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

Jabberwock = imread('Jabberwock_m.jpg');

Version={'DataPlot - Version 6.3';...
         'Date: 2018-03-09';...
        ['CRC: ', CRC, '']; char(10);...
        'Developer: Cobus van Zyl'};
Handle=helpdlg(Version,'DataPlot');

% *************************************************************************
% ******************* CALL CONVERTER PROGRAMS *****************************
% *************************************************************************
function mnTools_Csv2DataPlot_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.DataPlot, 'Paths');
Csv2DataPlot(Paths)

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function mnTools_Array2DataPlot_Callback(hObject, eventdata, handles)
% 
Paths = getappdata(handles.DataPlot, 'Paths');

Array2DataPlot(Paths)

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function mnTools_Acra2Mat_Callback(hObject, eventdata, handles)
Paths = getappdata(handles.DataPlot, 'Paths');
Acra2DataPlot(Paths)

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function mnTools_Pass2Mat_Callback(hObject, eventdata, handles)
% 
!conversion\Pass2Mat\Pass2Mat.exe

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function mnToolsSeeker_Callback(hObject, eventdata, handles)
% 
!conversion\printK\printK2DataPlot.exe

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function mnToolsInu_Callback(hObject, eventdata, handles)
% 
!conversion\Inu\Inu2DataPlot.exe
