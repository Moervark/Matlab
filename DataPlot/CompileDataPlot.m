% CompileDataPlot: Quick and easy way to Compile DataPlot correctly
% Written by:	J. van Zyl
% Date:			2014-07-15
% Updated:      J. van Zyl
% Last Date:  

function varargout = CompileDataPlot(varargin)

% Last Modified by GUIDE v2.5 15-Jul-2014 09:25:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CompileDataPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @CompileDataPlot_OutputFcn, ...
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

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% --- Executes just before CompileDataPlot is made visible.
function CompileDataPlot_OpeningFcn(hObject, eventdata, handles, varargin)
% 
handles.output = hObject; % Choose default command line output for CompileDataPlot
guidata(hObject, handles); % Update handles structure

% Get Jabberwock logo
Jabberwock = imread('Jabberwock_m.jpg');
image(Jabberwock, 'Parent', handles.axJabberwock)
set(handles.axJabberwock, 'YTickLabel',[])
set(handles.axJabberwock, 'XTickLabel',[])
set(handles.axJabberwock, 'XTick',[])
set(handles.axJabberwock, 'YTick',[])
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = CompileDataPlot_OutputFcn(hObject, eventdata, handles) 
% 
varargout{1} = handles.output;
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
function pbCompile_Callback(hObject, eventdata, handles)
% 
set(handles.DataplotCompiler, 'Pointer', 'watch')
set(handles.pbCompile, 'Visible', 'Off')

set(handles.chkDataPlot, 'Visible', 'Off')
set(handles.chkPass2Mat, 'Visible', 'Off')
set(handles.chkPrintK, 'Visible', 'Off')
set(handles.chkInu2DataPlot, 'Visible', 'Off')

refresh
if get(handles.rdDataplot, 'Value')
    set(handles.chkDataPlot, 'Visible', 'ON', 'String', 'Compiling...', 'Value', 0)
    mcc -e DataPlot -a BIF.m -o DataPlot -v
    set(handles.chkDataPlot, 'String', '', 'Value', 1)
end

if get(handles.rdPass2Mat, 'Value')
    set(handles.chkPass2Mat, 'Visible', 'ON', 'String', 'Compiling...', 'Value', 0)
    cd Conversion\Pass2Mat\
    mcc -e Pass2Mat -a ../../BIF.m -o Pass2Mat -v
    cd ../../
    set(handles.chkPass2Mat, 'String', '', 'Value', 1)
end

if get(handles.rdPrintK, 'Value')
    set(handles.chkPrintK, 'Visible', 'ON', 'String', 'Compiling...', 'Value', 0)
    cd Conversion\printK\
    mcc -e printK2DataPlot -o printK2DataPlot -v
    cd ../../
    set(handles.chkPrintK, 'String', '', 'Value', 1)
end

if get(handles.rdInu2DataPlot, 'Value')
    set(handles.chkInu2DataPlot, 'Visible', 'ON', 'String', 'Compiling...', 'Value', 0)
    cd Conversion\Inu\
    mcc -e Inu2DataPlot -o Inu2DataPlot -v
    cd ../../
    set(handles.chkInu2DataPlot, 'String', '', 'Value', 1)
end

if get(handles.rdFormulaEd, 'Value')
    set(handles.chkFormulaEd, 'Visible', 'ON', 'String', 'Compiling...', 'Value', 0)
    mcc -e Link1BER2DataPlot -o Link1BER2DataPlot -v
    set(handles.chkFormulaEd, 'String', '', 'Value', 1)
end

if get(handles.rdArray, 'Value')
    set(handles.chkArray, 'Visible', 'ON', 'String', 'Compiling...', 'Value', 0)
    mcc -e Array2DataPlot -o Array2DataPlot -v
    set(handles.chkArray, 'String', '', 'Value', 1)
end

set(handles.DataplotCompiler, 'Pointer', 'arrow')
set(handles.pbCompile, 'Visible', 'On')
