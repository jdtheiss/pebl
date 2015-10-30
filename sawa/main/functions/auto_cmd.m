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

% set funcs
funcs{end+1} = cell2mat(inputdlg('Enter command line function:'));
if isempty(funcs{end}), return; end;

% set funcs
set(findobj('tag','cmd_listbox'),'value',1);
set(findobj('tag','cmd_listbox'),'string',funcs);

% set funcs and options to fp
fp = funpass(fp,{'funcs'});
return;

% set_options 
function fp = set_options(fp) 
% only get sa and subrun from fp
funpass(fp,{'funcs','options','sa','subrun','funrun','iter'});

% init vars
if ~exist('funcs','var')||isempty(funcs), 
funcs = get(findobj('tag','cmd_listbox'),'string');
end
if isempty(funcs), return; end;
if ~exist('idx','var'), idx = get(findobj('tag','cmd_listbox'),'value'); end;
if iscell(idx), idx = idx{1}; end; if isempty(idx)||idx==0, idx = 1; end;
if ~exist('sa','var'), sa = {}; end; if ~exist('subrun','var'), subrun = []; end;
if ~exist('funrun','var'), if isempty(subrun), funrun = []; else funrun = subrun; end; end;
if ~exist('iter','var'), if isempty(subrun), iter = funrun; else iter = 1; end; end;
if ~exist('options','var')||idx>size(options,1), options{idx,1} = repmat({''},[numel(iter),1]); end;

% set help switch based on pc/mac
if ispc, hswitch = {'/h','/H','/?'}; else hswitch = {'-help','-h','--help','-H','-?'}; end;
% get help message
helpmsg = ''; 
for o = hswitch
clear tmpmsg; tmpmsg = evalc(['sawa_system(''' funcs{idx} ''',''' o{1} ''');']); 
if ~isempty(tmpmsg)&&numel(tmpmsg)>numel(helpmsg), helpmsg = tmpmsg; end;    
end

% if options, display
if ~all(cellfun('isempty',options{idx,1})),
    cellfun(@(x)disp([funcs{idx} x]),options{idx,1});
else % otherwise display helpmsg
    disp(helpmsg);
end

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
options{idx,1} = cell2mat(inputdlg('Edit options:','Edit',max([numel(iter),2]),{char(options{idx,1})}));
options{idx,1} = deblank(arrayfun(@(x){options{idx,1}(x,:)},1:size(options{idx,1},1)));
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

    % set message
    if numel(iter) > 1||isempty(funrun), msg = '(cancel when finished)'; else msg = ''; end;
    
    % create val
    val = {}; done = 0;
    while ~done
    val{end+1,1} = sawa_createvars(opts{o},msg,subrun,sa);
    if isempty(val{end})||isempty(msg), done = 1; end;
    if isempty(val{end}), val(end) = []; end;
    end
    
    % if only one val, set to val{1}
    if numel(val)==1, val = val{1}; end;

    % set funrun if empty 
    if isempty(funrun), funrun = 1:size(val,1); iter = funrun; end;
    
    % if iter > number of options{idx,1}, repmat(options{idx,1})
    if numel(iter) > size(options{idx,1},1), 
        if isempty(options{idx,1}), options{idx,1}{1} = ''; end;
        options{idx,1}(iter,1) = {options{idx,1}{1}}; 
    end;
    
    % if iterations don't match, set to all
    if numel(iter)==1||~iscell(val)||numel(iter)~=numel(val), val = {val}; end; 

    % set valf to val
    valf = cell(max(iter),1);
    valf(iter,1) = sawa_setfield(valf,iter,[],[],val{:}); 

    % ensure options and valf are vertical
    options{idx,1} = sawa_cat(1,options{idx,1}{:}); valf = sawa_cat(1,valf{:});
    
    % set options
    options{idx,1} = cellfun(@(x,y){sawa_strjoin({x,opts{o},y},' ')},options{idx,1}(iter),valf(iter));
    
    catch err % if error
        disp(err.message);
    end
end

% if empty, set to {''}
if isempty(options{idx,1}), options{idx,1} = repmat({''},[iter,1]); end;

% display options
cellfun(@(x)disp([funcs{idx} x]),options{idx,1});

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
if isempty(subrun), iter = funrun; else iter = 1; end;
if isempty(sa), subjs = arrayfun(@(x){num2str(x)},funrun); [sa(funrun).subj] = deal(subjs{:}); end;
if ~exist('options','var'), options(1:numel(funcs),1) = {repmat({''},[numel(iter),1])}; end;
if ~iscell(options), options = {{options}}; end;
if numel(funcs)>numel(options), options(numel(options)+1:numel(funcs),1) = {repmat({''},[numel(iter),1])}; end;
if ~exist('hres','var'), hres = []; end;
output(1:numel(funrun),1) = {{}};

% set time left
wb = settimeleft;

% for each subj 
for i = funrun
% func, run with options
for f = 1:numel(funcs)
try
% print subject
printres(sa(i).subj,hres);

% set s to i (iterations) or 1 (per subject)
if numel(iter) > 1, s = i; else s = 1; end;

% evaluate options
clear valf; valf = sawa_evalvars(options{f,1}{s});

% print command
printres([funcs{f} valf],hres); 

% run command
clear tmp;
[~,tmp]= sawa_system(funcs{f},valf); 

% print output if hres (already prints to command line)
if ~isempty(hres), printres(tmp,hres); end;

% set output
[output{i}(f,:)] = {tmp}; 

% set time left
settimeleft(i,funrun,wb,['Running ' funcs{f} ' ' sa(i).subj]); 

catch err % if error
    printres(['Error: ' funcs{f} ' ' sa(i).subj ' ' err.message],hres);
end
end
end

% set vars to fp
fp = funpass(fp,'output');
return;
