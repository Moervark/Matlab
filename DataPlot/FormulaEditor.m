% FormulaEditor: Used by Main program DataPlot. 
%       This is a set of "Built In Formulas" (BIF) to give the DataPlot
%       user more functionality.
% Written by:	J. van Zyl
% Date:			2010
% Updated:      J. van Zyl
% Last Date:  2013-11-11

function varargout = FormulaEditor(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FormulaEditor_OpeningFcn, ...
                   'gui_OutputFcn',  @FormulaEditor_OutputFcn, ...
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
% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function FormulaEditor_OpeningFcn(hObject, eventdata, handles, varargin)
% 
% Choose default command line output for FormulaEditor
handles.output = hObject;
switch nargin
    case 4 % In case it is a new formula
        handles.DataPlot = varargin{1};
        set(handles.tblFormula, 'Data', {'';'';'';'';'';'';'';'';'';''}) % Start with 10 blank lines
    case 5
        handles.DataPlot = varargin{1};
        set(handles.tblFormula, 'Data', varargin{2})
end
% Update handles structure
guidata(hObject, handles);

% Get Jabberwock logo
Jabberwock = imread('Jabberwock_m.jpg');
image(Jabberwock, 'Parent', handles.axJabberwock)
set(handles.axJabberwock, 'YTickLabel',[])
set(handles.axJabberwock, 'XTickLabel',[])
set(handles.axJabberwock, 'XTick',[])
set(handles.axJabberwock, 'YTick',[])
% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = FormulaEditor_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);

varargout{1} = handles.output;
% --------------------------------------------------------------------
% --------------------------------------------------------------------

% --- Executes on button press in pbTest.
function pbTest_Callback(hObject, eventdata, handles)
% Test the code to see if it will execute

Paths = getappdata(handles.DataPlot.DataPlot, 'Paths');
Flt = get(handles.DataPlot.edFileId, 'String');

FME_Text = get(handles.tblFormula, 'Data');
UserFormString = '';
FME_Cnt = 1; Len = length(FME_Text);
while FME_Cnt < Len +1
    if strncmp(FME_Text(FME_Cnt), 'load ',5)   % If Text starts with load
        Tmp = char(FME_Text(FME_Cnt));         % Extracts the filename add the right path and load it
        Parameter = strtrim(Tmp(6:end)); % right path and load it
        Pos = strfind(Parameter,';');
        if ~isempty(Pos) % In case the user ended the load statement with a ";"
            Parameter = Parameter(1:Pos-1); % remove ";"
        end
        UserFormString = [UserFormString,... 
            'load ''', Paths.Data,'\', Parameter, '.', Flt, '.mat'';'];
    else
        UserFormString = [UserFormString,...
            char(FME_Text(FME_Cnt)), ';'];
    end
    FME_Cnt = FME_Cnt+1; 
end

try
    eval(UserFormString)
catch Error
    uiwait(msgbox(Error.message,'FORMULA ERROR','modal'));
    return
end

if ~exist('Answer','var')
    uiwait(msgbox('Must assign Time and Data values to variable name "Answer" or if it must not perform a normal plot add Answer = ''NP''',...
        'FORMULA ERROR','modal'));
    return
end
if ~strcmp(Answer, 'NP') % Meaning don't plot
    figure(100)
    plot(Answer(:,1), Answer(:,2))
end
% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --- Executes on button press in pbDone.
function pbDone_Callback(hObject, eventdata, handles)
% Save User code to DataPlot and exit Formula Editor

if isfield(handles, 'DataPlot')
    setappdata(handles.DataPlot.DataPlot, 'Formula', get(handles.tblFormula, 'Data'));
end

delete(handles.formulaeditor)
if ishandle(100) % test for figure created by Test
    delete(100); % Delete the figure created by Test
end
% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --- Executes when user attempts to close formulaeditor.
function formulaeditor_CloseRequestFcn(hObject, eventdata, handles)

delete(hObject);
% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --- Executes on button press in pbCancel.
function pbCancel_Callback(hObject, eventdata, handles)
% 
delete(handles.formulaeditor)
% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --- Executes on button press in pbHelp.
function pbHelp_Callback(hObject, eventdata, handles)
% 
if isfield(handles, 'DataPlot')
    Paths = getappdata(handles.DataPlot.DataPlot, 'Paths');
else
    Paths.Exe = [pwd, '\'];
end
web(sprintf('%sFormulaEditor.html', [Paths.Exe, 'HelpFiles\']))
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function tblFormula_ButtonDownFcn(hObject, eventdata, handles)
% TBD
disp('REMOVE')

% --- Executes when entered data in editable cell(s) in tblFormula.
function tblFormula_CellEditCallback(hObject, eventdata, handles)
% 

Data = get(handles.tblFormula, 'Data');


[Rows, Cols] = size(Data); % Find out why their is sometimes two collumns ?????
if Cols > 1
    Data = Data(:,1) % Tmp fix
end

if ~isempty(char(Data(end,1)))
    Data{end+1} = '';
end

set(handles.tblFormula, 'Data', Data);
        
