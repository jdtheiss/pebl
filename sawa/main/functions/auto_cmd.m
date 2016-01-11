function varargout = auto_cmd(cmd,varargin)
% varargout = auto_cmd(cmd,varargin)
% This function will allow you to set arguments for the command line function
% funname and then run the function.
%
% Inputs:
% cmd - command to use (i.e. 'add_funciton','set_options','auto_run')
% varargin - arguments to be passed to cmd
%
% Outputs: 
% fp - funpass struct containing variables from call cmd(varargin)
% - output - the char output from the command line (including the command
% and options used, see example)
% - funcs - cell array of functions used
% - options - cell array of options used
% - subrun - numeric array of subjects/iterations run
%
% Example:
% fp = struct('funcs',{'echo'},'options',{' this is a test'});
% fp = auto_cmd('auto_run',fp)
% Command Prompt:
% 1
% echo this is a test
% this is a test
%
% fp = 
%       funcs: 'echo'
%     options: ' this is a test'
%      output: {{1x1 cell}}
%
% fp.output{1}{1} = 
%
% this is a test
%
% requires: funpass printres sawa_cat sawa_createvars sawa_evalvars 
% sawa_setfield sawa_strjoin sawa_system settimeleft
%
% Created by Justin Theiss

% init vars
if ~exist('cmd','var')||isempty(cmd), cmd = {'add_function','set_options','auto_run'}; end;
if ~iscell(cmd), cmd = {cmd}; end; 
if isempty(varargin), varargin = {struct}; end;
% run chosen cmds
for x = 1:numel(cmd), varargin{1} = feval(cmd{x},varargin{:}); end;
% output
if ~iscell(varargin{1}), varargin{1} = varargin(1); end;
varargout = varargin{1};

% callback functions
function fp = add_function(fp)
% get vars from fp
funpass(fp);

% init vars
if ~exist('funcs','var'), funcs = {}; end;
if ~exist('names','var'), names = {}; end;

% set funcs
funcs{end+1} = cell2mat(inputdlg('Enter command line function:'));
if isempty(funcs{end}), return; end;
names{end+1} = funcs{end};

% set funcs
set(findobj('-regexp','tag','_listbox'),'value',1);
set(findobj('-regexp','tag','_listbox'),'string',names);

% set funcs and options to fp
fp = funpass(fp,{'funcs','names'});
return;

% set_options 
function fp = set_options(fp) 
% only get sa and subrun from fp
funpass(fp,{'funcs','options','sa','subrun','funrun'});

% init vars
if ~exist('funcs','var')||isempty(funcs), 
funcs = get(findobj('-regexp','tag','_listbox'),'string');
end
if isempty(funcs), return; end;
if ~exist('idx','var'), idx = get(findobj('-regexp','tag','_listbox'),'value'); end;
if iscell(idx), idx = idx{1}; end; if isempty(idx)||idx==0, idx = 1; end;
if ~exist('sa','var'), sa = {}; end; if ~exist('subrun','var'), subrun = []; end;
if ~exist('funrun','var'), if isempty(subrun), funrun = []; else funrun = subrun; end; end;
if ~exist('options','var')||idx>size(options,1), options{idx,1} = repmat({''},[numel(funrun),1]); end;
iter = 1:numel(funrun);

% set help switch based on pc/mac
if ispc, hswitch = {'/h','/H','/?'}; else hswitch = {'-help','-h','--help','-H','-?'}; end;
% get help message
helpmsg = ''; 
for o = hswitch
clear tmpmsg; tmpmsg = evalc(['sawa_system(''' funcs{idx} ''',''' o{1} ''');']); 
if ~isempty(tmpmsg)&&numel(tmpmsg)>numel(helpmsg), helpmsg = tmpmsg; end;    
end
if any(regexpi(helpmsg,'invalid option')) % if msg includes "invalid option"
    helpmsg = regexprep(helpmsg,'.*\wnvalid \wption',''); 
end

% display helpmsg
if any(cellfun('isempty',options{idx,1}))||isempty(funrun), disp(helpmsg); end;

% get switches
if ispc % pc switches
opts = regexp(helpmsg,'\W/\w+','match'); 
else % mac switches
opts = regexp(helpmsg,'\W-{1,2}\w+','match'); 
end % get unique and remove space etc.
opts = unique(regexprep(opts,'[^-/\w]',''));
opts = opts(~ismember(opts,hswitch));
% set other, edit to end
opts{end+1} = 'other'; opts{end+1} = 'edit';

% choose options
chc = listdlg('PromptString','Choose option(s) to edit:','ListString',opts);

% Edit
if any(strcmp(opts(chc),'edit'))
options{idx,1} = cell2mat(inputdlg('Edit options:','Edit',[max([numel(funrun),2]),50],{char(options{idx,1})}));
options{idx,1} = strtrim(arrayfun(@(x){options{idx,1}(x,:)},1:size(options{idx,1},1)));
% if no funrun, set to rows
if isempty(funrun), funrun = 1:size(options{idx,1},1); iter = funrun; end;
chc = []; % empty chc 
end

% for each choice
for o = chc 
    try
    % Other or chosen
    if strcmp(opts{o},'other')
    opts{o} = cell2mat(inputdlg('Enter the option to use (e.g., -flag or leave blank if none):')); 
    if isempty(opts{o}), opts{o} = ''; end;
    end 
    
    % create val
    val = {}; done = 0;
    while ~done
    val{end+1,1} = sawa_createvars(opts{o},'(cancel when finished)',subrun,sa);
    if isempty(val{end}), val(end) = []; done = 1; end;
    end
    
    % if only one cell, set to inner cell
    if numel(val)==1, val = val{1}; end;
    
    % set "" around paths
    val = regexprep(val,['.*' filesep '.*'],'"$0"');

    % set funrun if empty 
    if isempty(funrun), funrun = 1:size(val,1); iter = funrun; end;
    
    % if iterations don't match, set to all
    if ~iscell(val)||numel(funrun)~=numel(val)&&numel(val)>1, val = {val}; end;

    % set valf to val
    valf = cell(numel(iter),1);
    valf(iter,1) = sawa_setfield(valf,iter,[],[],val{:}); 

    % ensure options and valf are vertical
    options{idx,1} = sawa_cat(1,options{idx,1}{:}); valf = sawa_cat(1,valf{:});
    if isempty(valf), valf = cell(numel(iter),1); end;
    
    % if iter greater than options, init
    if numel(iter)>size(options{idx,1},1), 
        options{idx,1}(iter,1) = options{idx,1}(1);
    end
    
    % set options
    options{idx,1}(iter,1) = cellfun(@(x,y){sawa_strjoin({x,opts{o},y},' ')},options{idx,1}(iter),valf(iter));
    
    catch err % if error
        disp(err.message);
    end
end

% if empty, set to {''}
if isempty(options{idx,1}), options{idx,1} = repmat({''},[numel(funrun),1]); end;

% display options
cellfun(@(x)disp([funcs{idx} ' ' x]),options{idx,1});

% set vars to fp
fp = funpass(fp,{'funrun','options'});
return;

% run cmd
function fp = auto_run(fp)
% get vars from fp
funpass(fp);

% init vars
if ~exist('funcs','var'), return; end;
if ~iscell(funcs), funcs = {funcs}; end;
if ~exist('sa','var'), sa = {}; end; if ~exist('subrun','var'), subrun = []; end;
if ~exist('funrun','var')||isempty(funrun), if isempty(subrun), funrun = 1; else funrun = subrun; end; end;
if isempty(sa), subjs = arrayfun(@(x){num2str(x)},funrun); [sa(funrun).subj] = deal(subjs{:}); end;
if ~exist('auto_i','var'), auto_i = funrun; end;
if ~exist('auto_f','var'), auto_f = 1:numel(funcs); end;
if ~exist('options','var'), options(auto_f,1) = {repmat({''},[numel(funrun),1])}; end;
if ~iscell(options), options = {{options}}; end;
for f = auto_f, 
    if f > size(options,1), options{f,1} = {[]}; end;
    if numel(funrun) > numel(options{f,1}), options{f,1}(1:numel(funrun),1) = options{f,1}(1); end; 
end;
if ~exist('hres','var'), hres = []; end;

% for each subj 
for i = auto_i
% func, run with options
for f = auto_f
try
% print subject 
if numel(funrun)==numel(subrun)&&all(funrun==subrun), 
    printres(sa(i).subj,hres);
end;

% get subject index
s = find(funrun==i,1);

% evaluate options
clear valf; valf = sawa_evalvars(options{f,1}{s},'cmd');

% print command
printres([funcs{f} ' ' valf],hres); 

% run command
clear tmp;
[~,tmp]= sawa_system(funcs{f},valf); 

% print output if hres (already prints to command line)
if ~isempty(hres), printres(tmp,hres); end;

% set output
[output{i}(f,:)] = {tmp}; 

catch err % if error
    printres(['Error: ' funcs{f} ' ' sa(i).subj ' ' err.message],hres);
end
end
end

% set vars to fp
fp = funpass(fp,'output');
return;
