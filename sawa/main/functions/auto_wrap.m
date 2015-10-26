function varargout = auto_wrap(cmd,varargin)
% varargout = auto_wrap(cmd,varargin)
% This function will automatically create a wrapper to be used with chosen
% function and subjects.
% 
% Inputs:
% cmd - command to use (i.e. 'add_funciton','set_args','run_cmd')
% varargin - arguments to be passed to cmd
%
% Outputs: 
% fp - funpass struct containing variables from call cmd(varargin)
% - output - the chosen output from the function 
% - funcs - cell array of functions used
% - options - cell array of options used
% - subrun - numeric array of subjects/iterations run
%
% Example:
% funcs = 'strrep'
% options(1,1:3) = {{'test'},{'e'},{'oa'}};
% fp = struct('funcs',{funcs},'options',{options})
% auto_wrap('auto_run',fp)
% Command Prompt:
% 1
% strrep(test, e, oa)
% varargout
% toast
%
% fp = 
%   funcs: 'strrep'
% options: {{1x1 cell} {1x1 cell} {1x1 cell}}
%  output: {{1x1 cell}}
% 
% fp.output{1}{1} =
%
% toast
%
% requires: any2str cell2strtable funpass getargs printres sawa_cat 
% sawa_createvars sawa_evalvars sawa_setfield sawa_strjoin settimeleft
%
% Created by Justin Theiss

% init vars
if ~exist('cmd','var')||isempty(cmd), cmd = {'add_function','set_args','auto_run'}; end;
if ~iscell(cmd), cmd = {cmd}; end; 
if isempty(varargin), varargin = {struct}; end;
% run chosen cmds
for x = 1:numel(cmd), varargin{1} = feval(cmd{x},varargin{:}); end;
% output
if ~iscell(varargin{1}), varargin{1} = varargin(1); end;
varargout = varargin{1};

% add function
function fp = add_function(fp)
% get vars from fp
funpass(fp);

% init vars
if ~exist('funcs','var'), funcs = {}; end;

% enter function
funcs{end+1} = cell2mat(inputdlg('Enter function to use:','Function'));
if isempty(funcs{end}), return; end;

% set funcs
set(findobj('tag','wrap_listbox'),'value',1);
set(findobj('tag','wrap_listbox'),'string',funcs);

% set vars to fp
fp = funpass(fp,{'funcs'});
return;

% set input/output args
function fp = set_args(fp)
% get vars from fp
funpass(fp);

% init vars
if ~exist('funcs','var')||isempty(funcs),
funcs = get(findobj('tag','wrap_listbox'),'string');
end
if ~iscell(funcs), funcs = {funcs}; end;
if isempty(funcs), return; end;
if ~exist('idx','var'), idx = get(findobj('tag','wrap_listbox'),'value'); end;
if iscell(idx), idx = idx{1}; end; if isempty(idx)||idx==0, idx = 1; end;
if ~exist('sa','var'), sa = {}; end; if ~exist('subrun','var'), subrun = []; end;
if ~exist('funrun','var'), if isempty(subrun), funrun = []; else funrun = subrun; end; end;
if ~exist('iter','var'), if isempty(subrun), iter = funrun; else iter = 1; end; end;

% display help msg
feval(@help,funcs{idx});

% get out and in args
[outargs,inargs] = getargs(funcs{idx}); 
if isempty(outargs)&&abs(nargout(funcs{idx}))>0, outargs = {'varargout'}; end;
if isempty(inargs)&&abs(nargin(funcs{idx}))>0, inargs = {'varargin'}; end;

% set options
if ~exist('options','var')||idx>size(options,1), 
    options(idx,1:numel(inargs)) = {repmat({{}},[numel(iter),1])}; 
end;

% choose input vars
if ~exist('invars','var'), 
if ~isempty(inargs)
inchc = listdlg('PromptString','Choose inputs to set:','ListString',inargs);
else % no inargs
inchc = [];    
end
else % get inchc
inchc = find(strcmp(inargs,invars));
end

% choose output vars
if ~exist('outvars','var'),
if ~isempty(outargs)
outchc = listdlg('PromptString','Choose output variables:','ListString',outargs);
else % no outargs
outchc = [];
end
else % set outchc by outvars
outchc = find(strcmp(outargs,outvars)); 
if strcmp(outargs,'varargout'), outchc = 1; end;
end

% set invars based on input, file, sa
ind = 0;
for v = inchc
done = 0;  % set done to 0

% if varargin, set msg to '(cancel when done)'
if strcmp(inargs{v},'varargin'),
    msg='(cancel when done)';
else % set invars v to empty
    msg = ''; ind = v;
end;

while ~done % loop for varargin
% get vals from sawa_createvars
clear val; val = sawa_createvars(inargs{v},msg,subrun,sa,funcs{1:idx-1}); 

% if invars isempty, break
if isempty(val), done = 1; break; end;

% if not varargin, done = 1
if ~strcmp(inargs{v},'varargin'), done = 1; else ind = ind+1; end;

% set funrun if empty 
if isempty(funrun), funrun = 1:size(val,1); iter = funrun; end;
   
% if iterations don't match, set to all
if numel(iter)==1||~iscell(val)||numel(iter)~=numel(val), val = {val}; end;

% set to options
if ind > numel(options(idx,:)), options{idx,ind} = repmat({{}},[numel(iter),1]); end;
options{idx,ind}(iter,1) = sawa_setfield(options{idx,ind},iter,[],[],val{:});
end
end

% set funcs to listbox
set(findobj('tag','wrap_listbox'),'value',1);
set(findobj('tag','wrap_listbox'),'string',funcs);

% output
fp = funpass(fp,{'funrun','funcs','options','subgrp','outchc'});
return;

% run wrapper
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
if ~exist('options','var'), options(1:numel(funcs),1) = {{}}; end;
if ~iscell(options), options = {{options}}; end;
if numel(funcs)>numel(options), options(numel(options)+1:numel(funcs),1) = {repmat({{}},[numel(iter),1])}; end;
if ~exist('hres','var'), hres = []; end;
output(1:numel(funrun),1) = {{}};

% set time left
wb = settimeleft;

% for each subject, run func
for i = funrun
% for each func
for f = 1:numel(funcs)
try
% print subject
printres(sa(i).subj,hres);

% set s to i (iterations) or 1 (per subject)    
if numel(iter) > 1, s = i; else s = 1; end;

% get outargs, inargs
clear inargs valf tmpout; 
[outargs,inargs] = getargs(funcs{f}); 
if isempty(outargs)&&abs(nargout(funcs{f}))>0, outargs = {'varargout'}; end;
if isempty(inargs)&&abs(nargin(funcs{f}))>0, inargs = {'varargin'}; end;

% evaluate options
for x = 1:numel(options(f,:)) 
    if isempty(options{f,x}{s}), continue; end;
    valf{x} = sawa_evalvars(options{f,x}{s});
end

% print command
printres([funcs{f} '(' sawa_strjoin(valf,', ') ')'],hres); 

% evaluate function
if nargout(funcs{f})==0 
% no argout, get command prompt output
tmpout{1} = evalc([funcs{f} '(valf{:})']);

% print output
if ~isempty(hres), disp(tmpout{1}); end;
    
% set outchc to 1 and outargs to {''}
outchc = 1; outargs = {''};

else % otherwise set tmpout 
% set outchc if needed
if ~exist('outchc','var'), outchc = 1:numel(outargs); end;

% run feval
[tmpout{1:max(outchc)}] = feval(funcs{f},valf{:});
end

% output
[output{i}(f,:)] = tmpout(outchc);

% print output
printres(cell2strtable(sawa_cat(1,outargs(outchc),any2str([],output{i}{f,:})),' '),hres);

% set time left
settimeleft(i,funrun,wb,['Running ' funcs{f} ' ' sa(i).subj]);

catch err % if error, display message
printres(['Error: ' funcs{f} ' ' sa(i).subj ': ' err.message],hres);
end
end
end

% set vars to fp
fp = funpass(fp,'output');
return;
