function fp = sawa_editor(cmd,varargin)
% sawa_editor(sawafile, sv, savedvars)
% Loads/runs sawafile functions (e.g., auto_batch, auto_cmd, auto_wrap) with
% make_gui.
%
% Inputs: 
% cmd - function to be called (i.e. 'load_sawafile','set_environments',
% 'choose_subjects','save_presets', or 'load/save/run')
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
if ~isempty(savedvars), load(savedvars,'fp'); end;

% set sawafile, sv, and savedvars to fp
fp = funpass(fp,{'sawafile','sv','savedvars'});

% get vars from fp
funpass(fp);

% if no structure, return
if ~exist('structure','var'), disp('Missing "structure".'); return; end;

% setenv if needed
if exist('envvar','var'), 
for x = 1:numel(envvar), 
if ~any(strfind(getenv(envvar{x}),newpath{x})),
setenv(envvar{x},[getenv(envvar{x}) ':' newpath{x}]);
end;
end;
end; 

% set structure.listbox.string to funcs
if ~exist('names','var'), names = funcs; end;
structure.listbox.string = names; 

% run make_gui
if ~sv 
fp = make_gui(structure,struct('data',fp));
else % using savedvars
fp.lsr = 'run'; fp = loadsaverun(fp);    
end
return;

% set environment if needed
function fp = set_environments(fp)
% get vars from fp
funpass(fp);

% init vars
if ~exist('envvar','var')||~exist('newpath','var'), envvar = {}; newpath = {}; end;

% enter variable to set 
envvar{end+1} = cell2mat(inputdlg('Enter the variable to setenv for (e.g., PATH):'));
if isempty(envvar{end}), return; end;

% clear previous path?
if ~isempty(getenv(envvar{end}))&&~strcmp(questdlg(['Clear ' envvar{end} ': '...
        getenv(envvar{end}) '?'],'Clear?','Yes','No','No'),'Yes')
oldpath = [getenv(envvar{end}) ':'];
else % otherwise add to path
oldpath = [];
end

% get new path
newpath{end+1} = uigetdir(pwd,['Choose path for ' envvar{end}]);
if ~any(newpath{end}), return; end;

% set environment
setenv(envvar{end},[oldpath newpath{end}]); 

% set envvar to fp
fp = funpass(fp,{'envvar','newpath'});
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
funrun = subrun; iter = 1; % set to subrun
toolstr = [task ': ' num2str(numel(subrun)) ' subjects']; 
else % set to iterations
funrun = 1:str2double(cell2mat(inputdlg('Enter number of iterations to run')));
subrun = []; iter = funrun;
toolstr = [num2str(numel(funrun)) ' iterations'];
end 

% set tooltipstring
set(findobj('tag','choose subjects'),'tooltipstring',toolstr);

% set batch editor struct
fp = funpass(fp,{'subrun','sa','task','fileName','funrun','iter'});
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
helpmsg = cell2mat(inputdlg(['Enter "help message" for ' savefile],'help message',2));

% save
save(sawafile,'structure','fp','program','helpmsg');
return;

% listbox callback for copy/delete
function fp = listbox_callback(fp,fx,x)
% get vars from fp
funpass(fp,{'funcs','options','itemidx','str'});

% if no funcs, fx, or x, return
if ~exist('funcs','var')||nargin < 3, return; end;

% get names
names = get(x,'string'); if isempty(names), return; end;

% get idx
idx = get(x,'value'); if idx > numel(names), return; end;

% if no options, set idx options
if ~exist('options','var')||idx > numel(options), options{idx,1} = {}; end;

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
    if exist('itemidx','var')&&exist('str','var'), itemidx{end+1} = itemidx{idx}; str{end+1} = str{idx}; end;
case 'delete' % delete funcs and options idx
    funcs(idx) = []; names(idx) = []; options(idx,:) = []; 
    if exist('itemidx','var')&&exist('str','var'), itemidx(idx) = []; str(idx) = []; end;
end

% set listbox
set(x,'string',names); set(x,'value',1);

% set vars to fp
if exist('itemidx','var')&&exist('str','var')
fp = funpass(fp,{'funcs','options','itemidx','str'});
else % if not auto_batch
fp = funpass(fp,{'funcs','options'});    
end
return;

% load/save/run
function fp = loadsaverun(fp)
% get vars from fp
funpass(fp);

% load save run
if ~exist('lsr','var')
lsr = questdlg('Load/Save/Run','Load/Save/Run','Load','Save','Run','Load');
end

% get savename
if ~exist('sawafile','var'), savename = 'sawa_editor'; else [~,savename]=fileparts(sawafile); end;

% switch based on lsr
switch lower(lsr)

case {'load','save'} % load or save
curdir = pwd; % get current dir
% cd to jobs folder
cd(fileparts(fileparts(mfilename('fullpath'))));
if ~isdir('jobs'), mkdir('jobs'); end;
cd('jobs');
if strcmpi(lsr,'load') % load
savedvars = uigetfile('*savedvars*.mat','Load savedvars file to use:');
if ~any(savedvars), return; end; % return if none chosen
load(savedvars,'fp'); % load savedvars
% close current
close(gcf);
% load_sawafile
fp = sawa_editor('load_sawafile',fp.sawafile,sv,savedvars); return;
else % save
savedvars = cell2mat(inputdlg('Enter savedvars filename to save:','savedvars',1,{[savename '_savedvars.mat']}));
if isempty(savedvars), return; end; save(savedvars,'fp'); % save savedvars
end % return to curdir, and clear
cd(curdir); clear curdir; 

case 'run' % run
% init vars
if ~exist('program','var')||isempty(program), load(sawafile,'program'); end;
% print results
hres = printres(savename); fp = funpass(fp,'hres'); 
% auto_run program
output = feval(program,'auto_run',fp);
% print notes
printres('Notes:',hres);
end

% set tooltipstring
if ~ischar(savedvars), savedvars = ''; end;
set(findobj('string','load/save/run'),'tooltipstring',savedvars);

% set vars to fp
clear lsr; fp = funpass(fp,who);
return;
