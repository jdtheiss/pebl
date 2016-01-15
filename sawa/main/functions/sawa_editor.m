function fp = sawa_editor(cmd,varargin)
% sawa_editor(sawafile, sv, savedvars)
% Loads/runs sawafile functions (e.g., auto_batch, auto_cmd, auto_function) with
% make_gui.
%
% Inputs: 
% cmd - function to be called (i.e. 'load_sawafile','set_environments',
% 'choose_subjects','add_function','set_options','save_presets', or 'load/save/run')
% varargin - arguments to be sent to call of cmd (in most cases, the
% funpass struct of variables to use with fieldnames as variable names)
%
% Outputs:
% fp - funpass struct containing various output variables
%
% Note: default cmd is 'load_sawafile', and the sawa file to be loaded should
% be a .mat file with the following varaibles (created during call to save_presets): 
% - structure - the make_gui structure that will be used
% - fp - funpass structure with "sawafile", "funcs", and "options"
% sawafile is the fullpath to this .mat file, funcs is a cellstr of
% functions to run, and options is a cell array of options to use with
% funcs (must be equal in size to funcs).
% - program - string name of the program to run (e.g., 'auto_batch')
% See Batch_Editor.mat, Command_Line.mat, Wrap_Functions.mat for examples.
% Note2: if an output exists in fp, output will be assigned in the base
% workspace.
%
% requires: make_gui funpass printres sawa_subrun
%
% Created by Justin Theiss

% init vars
if ~exist('cmd','var'), cmd = 'load_sawafile'; end;
if ~iscell(cmd), cmd = {cmd}; end;
if isempty(varargin), 
[fl,pt] = uigetfile('*.mat','Choose sawa file to load:');
if ~any(fl), return; end;
varargin{1} = fullfile(pt,fl);
end
% for each cmd, run
for x = 1:numel(cmd), fp = feval(cmd{x},varargin{:}); end;

% load sawafile and run make_gui
function fp = load_sawafile(sawafile,sv,savedvars)

% load sawafile
load(sawafile);  

% init vars
if ~exist('sv','var')||isempty(sv), sv = 0; end;
if ~exist('savedvars','var'), savedvars = ''; end;
if ~exist('fp','var'), fp = struct; end;

% load savedvars
if ~isempty(savedvars)&&sv, load(savedvars,'fp'); end;

% set sawafile, sv, and savedvars to fp
fp = funpass(fp,{'sawafile','sv','savedvars'});

% get vars from fp
funpass(fp);

% if no structure, return
if ~exist('structure','var'), disp('Missing "structure".'); return; end;

% setenv/path if needed
if exist('envvar','var'), 
for x = 1:numel(envvar), 
if ~isempty(envvar{x}) % setenv
if ~any(strfind(getenv(envvar{x}),newpath{x})),
if any(strfind(newpath{x},filesep)), newpath{x} = [':' newpath{x}]; end;
setenv(envvar{x},[getenv(envvar{x}) newpath{x}]);
end;
else % addpath
addpath(newpath{x});    
end;
end;
end; 

% set structure.listbox.string to funcs
if ~exist('names','var'), names = funcs; end;
structure.listbox.string = names; 

% run make_gui if all inputs (otherwise output fp structure)
if ~sv && nargin > 1
fp = make_gui(structure,struct('data',fp));  
elseif sv % using savedvars
fp = loadsaverun(fp,'run');    
end

% if savedvars and not sv, save savedvars
if ~isempty(savedvars)&&~sv, fp = loadsaverun(fp,'save'); end;
return;

% set environment if needed
function fp = set_environments(fp)
% get vars from fp
funpass(fp);

% init vars
if ~exist('envvar','var')||~exist('newpath','var'), envvar = {}; newpath = {}; end;

if strcmp(questdlg('Set Environments or Add Path?','Environment or Path','environments','path','environments'),'environments')
% enter variable to set 
envvar{end+1} = cell2mat(inputdlg('Enter the variable to setenv for (e.g., PATH):'));
if isempty(envvar{end}), return; end;

% clear previous path?
if ~strcmp(questdlg(['Clear ' envvar{end} ': ' getenv(envvar{end}) '?'],'Clear?','Yes','No','No'),'Yes')
oldpath = [getenv(envvar{end}) ':'];
else % otherwise add to path
oldpath = [];
end
else % adding path
    envvar{end+1} = [];
end

% get new path
newpath{end+1} = uigetdir(pwd,'Choose path to set');
if ~any(newpath{end}), newpath{end} = cell2mat(inputdlg(['Enter value for ' envvar{end}])); end;

% set environment/path only if newpath{end} is not empty
if ~isempty(newpath{end})
if ~isempty(envvar{end})&&~any(strfind(oldpath,newpath{end})) 
setenv(envvar{end},[oldpath newpath{end}]); % setenv
else % addpath
addpath(newpath{end});    
end
% set envvar to fp if newpath{end} is not empty
fp = funpass(fp,{'envvar','newpath'});
end
return;

% choose subjects to use 
function fp = choose_subjects(fp)
% create vars from fp
funpass(fp); 

% get subrun, sa, task, fileName
[subrun,sa,task,fileName] = sawa_subrun;

% run per subject or iterations
if ~isempty(subrun)
runiter = questdlg('Run per subject or iterations?',...
    'Per Subject/Iterations','per subject','iterations','per subject');
end

% set funrun based on runiter
if exist('runiter','var')&&strcmp(runiter,'per subject')
% if per subject set to subrun
funrun = subrun; % set to subrun
toolstr = [task ': ' num2str(numel(subrun)) ' subjects']; 
else % set to iterations
funrun = 1:str2double(cell2mat(inputdlg('Enter number of iterations to run')));
subrun = [];
toolstr = [num2str(numel(funrun)) ' iterations'];
end 

% set tooltipstring
set(findobj('tag','choose subjects'),'tooltipstring',toolstr);

% set batch editor struct
fp = funpass(fp,{'subrun','sa','task','fileName','funrun'});
return;

% add function to list
function fp = add_function(fp)
% create vars from fp
funpass(fp);

% get auto_ programs in main
d = dir(fullfile(fileparts(mfilename('fullpath')),'auto_*.m'));

% choose program to use
chc = listdlg('PromptString','Choose program to use:','ListString',{d.name},'SelectionMode','single');
if isempty(chc), return; end;

% get program name
if ~exist('program','var'), program = {}; end;
[~,program{end+1}] = fileparts(d(chc).name);

% run program's add_function
fp = feval(program{end},'add_function',fp);

% set names
set(findobj('-regexp','tag','_listbox'),'string',fp.names);

% update program for auto_batch
if strcmp(program{end},'auto_batch'), 
    if ~exist('names','var'), names = {}; end;
    program = horzcat(program{1:end-1},repmat({'auto_batch'},1,numel(fp.names)-numel(names)));
end

% set program to struct
fp = funpass(fp,'program');
return;

% set options for function
function fp = set_options(fp)
% create vars from fp
funpass(fp);

% if no funcs, return
if ~exist('funcs','var')||isempty(funcs), return; end;

% get idx from listbox
if ~exist('idx','var'), idx = get(findobj('-regexp','tag','_listbox'),'value'); end;
if iscell(idx), idx = idx{1}; end; if isempty(idx)||idx==0, idx = 1; end;

% if no program, get program
if ~exist('program','var')||idx > numel(program)
    % get auto_ programs in main
    d = dir(fullfile(fileparts(mfilename('fullpath')),'auto_*.m'));

    % choose program to use
    chc = listdlg('PromptString','Choose program to use:','ListString',{d.name},'SelectionMode','single');
    if isempty(chc), return; end;
    
    % set program name
    [~,program{idx}] = fileparts(d(chc).name);
end
    
% set names
set(findobj('-regexp','tag','_listbox'),'string',fp.names);

% run program's set_options
fp = feval(program{idx},'set_options',fp);
return;

% save the preset values
function fp = save_presets(fp)
% get vars from fp
funpass(fp);

% set name
[savefile,savepath] = uiputfile('*.mat','Save file as:');
if ~any(savefile), return; end;

% set fp
fp = funpass(fp,{'names','funcs','options'});

% set structure
load(sawafile,'structure','program');

% set sawafile
sawafile = fullfile(savepath,savefile);

% set sawafile to fp
fp = funpass(fp,'sawafile');

% set name to structure
[~,structure.name] = fileparts(savefile);

% set funcs to listbox
if ~exist('names','var'), names = funcs; end;
structure.listbox.string = names;

% enter helpmsg
helpmsg = char(textwrap(inputdlg(['Enter "help message" for ' savefile],'help message',[2,75]),75));

% save
save(sawafile,'structure','fp','program','helpmsg');
return;

% listbox callback for copy/delete
function fp = listbox_callback(fp,fx,x)
% get vars from fp
funpass(fp,{'funcs','names','options','program','idx','itemidx','str'});

% if no funcs, fx, or x, return
if ~exist('funcs','var')||nargin < 3, return; end;

% get names
if ~exist('names','var')||isempty(names), names = get(x,'string'); end;
if isempty(names), return; end;

% get idx
if ~exist('idx','var')||isempty(idx), idx = get(x,'value'); end;
if idx > numel(names), return; end;

% if no options, set idx options
if ~exist('options','var')||idx > numel(options), options{idx,1} = {[]}; end;

% get click type
if strcmp(get(fx,'selectiontype'),'alt') % right click
    edcode = questdlg('copy or delete?','copy or delete','copy','delete','copy');
else % otherwise
    return; 
end

% switch based on edcode
switch edcode
case 'copy' % copy funcs and options idx
    funcs{end+1} = funcs{idx}; names{end+1} = names{idx}; options(end+1,:) = options(idx,:);
    program{end+1} = program{idx};
    if exist('itemidx','var')&&idx==numel(itemidx), itemidx{end+1} = itemidx{idx}; str{end+1} = str{idx}; end;
case 'delete' % delete funcs and options idx
    funcs(idx) = []; names(idx) = []; options(idx,:) = []; program(idx) = [];
    if exist('itemidx','var')&&idx==numel(itemidx), itemidx(idx) = []; str(idx) = []; end;
end

% set listbox
set(x,'string',names); set(x,'value',1);

% set vars to fp
fp = funpass(fp,{'funcs','names','options','program','itemidx','str'});
return;

% load/save/run
function fp = loadsaverun(fp,lsr)
% get vars from fp
funpass(fp);

% load save run
if ~exist('lsr','var')
lsr = questdlg('Load/Save/Run','Load/Save/Run','Load','Save','Run','Load');
end

% get savename
if ~exist('sawafile','var'), savename = 'wrapper_automation'; else [~,savename]=fileparts(sawafile); end;

% switch based on lsr
switch lower(lsr)

case {'load','save'} % load or save
curdir = pwd; % get current dir
% cd to jobs folder
cd(fileparts(fileparts(mfilename('fullpath'))));
if ~isdir('jobs'), mkdir('jobs'); end;
cd('jobs');
if strcmpi(lsr,'load') % load
[savedvars, spath] = uigetfile('*savedvars*.mat','Load savedvars file to use:');
if ~any(savedvars), return; end; % return if none chosen
savedvars = fullfile(spath, savedvars); load(savedvars,'fp'); % load savedvars
% set structure names to fp.names
funpass(fp,{'names','funcs'}); if ~exist('names','var'), names = funcs; end;
set(findobj('-regexp','tag','_listbox'),'string',names); % set names
guidata(gcf,fp); return; % set new data to guidata

else % save
if ~exist('savedvars','var')||isempty(savedvars)
savedvars = cell2mat(inputdlg('Enter savedvars filename to save:','savedvars',1,{[savename '_savedvars.mat']}));
end
if isempty(savedvars), return; end; save(savedvars,'fp'); % save savedvars
end % return to curdir, and clear
cd(curdir); clear curdir; 

case 'run' % run
% init vars
if ~exist('program','var')||isempty(program), load(sawafile,'program'); end;
if ~iscell(program), program = {program}; end;
% print results
hres = printres(savename); fp = funpass(fp,'hres'); 
% run for each subject
wb = settimeleft;
for i = funrun
% get unique programs in order as they appear
[uprog,frun] = collapse_array(program);
% for each unique program
for f = 1:numel(uprog),
% auto_run program
fp.auto_i = i; fp.auto_f = frun{f};
fp = feval(uprog{f},'auto_run',fp);
end
% display time left
settimeleft(i,funrun,wb);
end
% if output, set to workspace
if isfield(fp,'output'), assignin('base','output',fp.output); end;
% print notes
printres('Notes:',hres);
end

% set tooltipstring
if ~ischar(savedvars), savedvars = ''; end;
set(findobj('string','load/save/run'),'tooltipstring',savedvars);

% set vars to fp
clear lsr; fp = funpass(fp,who);
return;
