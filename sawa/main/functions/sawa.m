function sawa(funcs,sv,savedvars)
% subject array and wrapper automation (sawa)
% This toolbox will allow you to build pipelines for analysis by wrapping any
% command line, matlab, or batch functions with input variables from subject
% arrays or otherwise. The main component of this toolbox is the Subject Array
% (sometimes seen as "sa"), which contains the subject information (e.g.,
% folders, demographic information, etc.) that can be loaded into different
% functions to automate data analysis.
% The toolbox comes with several functions highlighted by an editable batch
% editor, command line editor, function wrapper.
% Furthermore, users may add scripts/functions to the main folder to be
% used or build function pipelines using by saving presets in the aforementioned
% editors.
% 
% Inputs (optional):
% funcs - cellstr of functions to run (fullpath)
% sv - 0/1 indicating whether savedvars will be used
% savedvars - cellstr of savedvars to use (fullpath, must match funcs)
% 
% Note: if no function is input, the sawa gui will load.
%
% requires: make_gui choose_SubjectArray sawa_setvars sawa_system
%
% Created by Justin Theiss

% set to path if not 
if ~any(strfind(path,fileparts(mfilename('fullpath'))))
    path(path,fileparts(mfilename('fullpath')));
end

% no args
if nargin == 0
% check if any sawa's open
if ~isempty(findobj('type','figure','name','subject array and wrapper automation'))
    close('subject array and wrapper automation'); sawa; return;
end

% get fileName
fileName = choose_SubjectArray; if isempty(fileName), fileName = ''; end;

% clear and welcome
clc; disp('welcome');
flds = main_Callback;

% set up make_gui structure
structure.name = 'subject array and wrapper automation';
[structure.push(1:5).string] = deal('subject array','main','choose','help','exit');
[structure.push.callback] = deal(@array_Callback,@main_Callback,@choose_Callback,@help_Callback,@exit_Callback);
[structure.push.tag] = deal(structure.push.string);
structure.push(1).tooltipstring = fileName;
structure.listbox.string = flds; structure.listbox.position = 'right';
structure.listbox.height = 175; structure.listbox.width = 175;
structure.listbox.tag = 'listbox';
% run make_gui without pages
make_gui(structure,struct('nodone',1,'nowait',1));

else % if args, run_Callback
% init vars
if ~iscell(funcs), funcs = {funcs}; end;
if ~exist('sv','var'), sv = 0; end;
if ~exist('savedvars','var'), savedvars = cell(size(funcs)); end;
if ~iscell(savedvars), savedvars = {savedvars}; end;

% run_Callback
run_Callback([],[],funcs,sv,savedvars);
end

% Callback Functions
function array_Callback(source,eventdata)
% choose new fileName
fileName = choose_SubjectArray([]);

% set tooltipstring
if ~isempty(fileName), set(source,'tooltipstring',fileName); end;
return;

function flds = main_Callback(source,eventdata)
% get mainpath folders
mainpath = fileparts(fileparts(fileparts(mfilename('fullpath'))));

% get flds in mainpath
flds = dir(mainpath); flds = {flds([flds.isdir]).name};
flds = flds(~strncmp(flds,'.',1));
flds = flds(~strcmpi(flds,'main')); % remove main folder

% if callback from button push
if nargin > 0 
% set choose button
set(findobj('tag','choose'),'string','choose');
% set listbox
set(findobj('tag','listbox'),'string',flds);
end
return;

function choose_Callback(source,eventdata)
% get mainpath 
mainpath = fileparts(fileparts(fileparts(mfilename('fullpath'))));

% get val of listbox
val = get(findobj('tag','listbox'),'value');

% get string of listbox
str = get(findobj('tag','listbox'),'string'); 

% if is dir, get files
if isdir(fullfile(mainpath,str{val}))
% addpath
addpath(fullfile(mainpath,str{val}));

% get files in path
d = dir(fullfile(mainpath,str{val}));
d = {d(~[d.isdir]).name}; d = d(~strncmp(d,'.',1));

% set choose button
set(source,'string','add');

% set listbox
set(findobj('tag','listbox'),'value',1);
set(findobj('tag','listbox'),'string',d);
else % otherwise create queue of functions
% get current functions (if available)
funcs = get(findobj('tag','funcs'),'string');

% get function
val = get(findobj('tag','listbox'),'value');
str = get(findobj('tag','listbox'),'string');

% set functions
funcs = vertcat(funcs,str(val));

% if not already figure
if isempty(findobj('name','functions to run'))
    
% create new figure
newstructure.name = 'functions to run';
[newstructure.push(1:3).string] = deal('run','enter variables','quit');
[newstructure.push.callback] = deal(@run_Callback,@entervars_Callback,@quit_Callback);
newstructure.checkbox.string = 'use saved variables';
newstructure.checkbox.callback = @savedvars_Callback;
[newstructure.checkbox.tag] = deal(newstructure.checkbox.string);
newstructure.listbox.string = funcs; newstructure.listbox.tag = 'funcs';
newstructure.listbox.position = 'right';
newstructure.listbox.height = 175; newstructure.listbox.width = 175;

% run make_gui without pages
make_gui(newstructure,struct('nodone',1,'nowait',1));

else % otherwise update funcs
set(findobj('tag','funcs'),'string',funcs);    
end
end
return;

function help_Callback(source,eventdata)
% get mainpath 
mainpath = fileparts(fileparts(fileparts(mfilename('fullpath'))));

% get val of listbox
val = get(findobj('tag','listbox'),'value');

% get str of listbox
str = get(findobj('tag','listbox'),'string');

% if isdir, addpath 
if isdir(fullfile(mainpath,str{val})), 
addpath(fullfile(mainpath,str{val}));
end

% get extension
[~,~,ext] = fileparts(str{val});
if strcmp(ext,'.mat') % load helpmsg
    load(str{val},'helpmsg');
    disp(helpmsg);
else % otherwise help function
    feval(@help, str{val});
end
return;
    
function exit_Callback(source,eventdata)
% exit program
close('subject array and wrapper automation');
disp('goodbye'); 
return;

function entervars_Callback(source,eventdata)
% get functions
funcs = get(findobj('tag','funcs'),'string');

% for each function, set vars
for f = 1:numel(funcs)
disp(['Enter variables for ' funcs{f}]);
savedvars{f} = sawa_setvars(funcs{f});
end

% set checkbox of savedvars 
set(findobj('tag','use saved variables'),'value',1);

% set userdata to savedvars
set(findobj('tag','use saved variables'),'userdata',savedvars);
return;

function savedvars_Callback(source,eventdata)
% only if checked
if get(source,'value')
    
% get functions
funcs = get(findobj('tag','funcs'),'string');

% cd to jobs folder
curdir = pwd;
cd(fullfile(fileparts(fileparts(mfilename('fullpath'))),'jobs'));

% for each function, choose savedvars
for f = 1:numel(funcs)
savedvars{f} = uigetfile('*savedvars*.mat',['Choose savedvars for ' funcs{f} ':']);
savedvars{f} = fullfile(pwd,savedvars{f});
end

% set userdata to savedvars
set(source,'userdata',savedvars);

% return to previous dir
cd(curdir);
end
return;

function quit_Callback(source,eventdata)
% close functions to run figure
close('functions to run');
return;

function run_Callback(source,eventdata,funcs,sv,asavedvars)
% if called from pushbutton, set funcs, sv, savedvars
if nargin < 3
% get functions
funcs = get(findobj('tag','funcs'),'string');

% set sv, savedvars
asavedvars = get(findobj('tag','use saved variables'),'userdata');  
if isempty(asavedvars), sv = 0; asavedvars = cell(size(funcs)); else sv = 1; end;
end

% for each function
for f = 1:numel(funcs)
% set savedvars
savedvars = asavedvars{f};
% get ext, to determine how to run
clear path func ext; [path,func,ext] = fileparts(funcs{f});
% if path, addpath
if ~isempty(path), addpath(path); end;
% switch based on ext
switch ext
    
case '.m' % run matlab function
if nargin(func)==0 % if no args
feval(func);
else % otherwise run with sv, savedvars
feval(func,sv,savedvars);
end

case '.mat' % run based on program
% sawa_editor
feval('sawa_editor','load_sawafile',funcs{f},sv,savedvars);

case '.r' % run rscript
try % run with savedvars
[sts,res] = system(['Rscript ' funcs{f} ' ' sv ' ' savedvars]); 
catch % run without savedvars
[sts,res] = system(['Rscript ' funcs{f}]);
end
if sts, disp(res); else disp(['Error: ' funcs{f}]); end;

otherwise % run system
try % run with savedvars
[sts,res] = sawa_system(func,[' ' sv ' ' savedvars]);
catch % run without savedvars
[sts,res] = sawa_system(func);
end
if sts, disp(res); else disp(['Error: ' func]); end;
end
end

% done
disp('done');
return;
