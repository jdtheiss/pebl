function varargout = auto_function(cmd,varargin)
% varargout = auto_function(cmd,varargin)
% This function will automatically create a wrapper to be used with chosen
% function and subjects.
% 
% Inputs:
% cmd - command to use (i.e. 'add_funciton','set_options','run_cmd')
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
% auto_function('auto_run',fp)
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
if ~exist('cmd','var')||isempty(cmd), cmd = {'add_function','set_options','auto_run'}; end;
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
if ~exist('names','var'), names = {}; end;

% enter function
funcs{end+1} = cell2mat(inputdlg('Enter function to use:','Function'));
if isempty(funcs{end}), return; end;
names{end+1} = funcs{end};

% set vars to fp
fp = funpass(fp,{'funcs','names'});
return;

% set input/output args
function fp = set_options(fp)
% get vars from fp
funpass(fp);

% init vars
if ~exist('funcs','var')||isempty(funcs),
funcs = get(findobj('-regexp','tag','_listbox'),'string');
end
if ~iscell(funcs), funcs = {funcs}; end;
if isempty(funcs), return; end;
if ~exist('names','var')||isempty(names), names = funcs; end;
if ~exist('idx','var'), idx = get(findobj('-regexp','tag','_listbox'),'value'); end;
if iscell(idx), idx = idx{1}; end; if isempty(idx)||idx==0, idx = 1; end;
if ~exist('sa','var'), sa = {}; end; if ~exist('subrun','var'), subrun = []; end;
if ~exist('funrun','var'), if isempty(subrun), funrun = []; else funrun = subrun; end; end;
if ~exist('program','var')||isempty(program), program = repmat({'auto_function'},1,numel(funcs)); end;
iter = 1:numel(funrun);

% display help msg
feval(@help,funcs{idx});

% if no function, return
if isempty(which(funcs{idx})), return; end;

% get out and in args
[outargs,inargs] = getargs(funcs{idx}); 
if isempty(outargs)&&abs(nargout(funcs{idx}))>0, outargs = {'varargout'}; end;
if isempty(inargs)&&abs(nargin(funcs{idx}))>0, inargs = {'varargin'}; end;

% set options
if ~exist('options','var')||idx>size(options,1), 
    options(idx,1:numel(inargs)) = {repmat({{}},[numel(funrun),1])}; 
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
outchc{idx} = listdlg('PromptString','Choose output variables:','ListString',outargs);
else % no outargs
outchc{idx} = [];
end
else % set outchc by outvars
outchc{idx} = find(strcmp(outargs,outvars)); 
if strcmp(outargs,'varargout'), outchc{idx} = 1; end;
end

% set invars based on input, file, sa
for v = inchc
done1 = 0;  % set done to 0
ind = v; % set index 
varnum = 1;

while ~done1 % loop for varargin
    
% set ind if not varargin
if strncmp(inargs{v},'varargin',8), inargs{v} = ['varargin ' num2str(varnum)]; end;

% set tmpfuncs
tmpnames = names(1:idx-1); funidx = strcmp(program(1:idx-1),'auto_function');
tmpnames(funidx) = strcat('@',tmpnames(funidx));

% set default options
clear defopts; try defopts = options{idx,ind}{1}; catch, defopts = {}; end;
    
% create val
val = {}; done2 = 0;
while ~done2
val{end+1,1} = sawa_createvars(inargs{v},'(cancel when finished)',subrun,sa,defopts,tmpnames{:});
if isempty(val{end}), val(end) = []; done2 = 1; end;
end

% if only once cell, set to inner cell
if numel(val)==1, val = val{1}; end;

% set funrun if empty 
if isempty(funrun), funrun = 1:size(val,1); iter = funrun; end;
   
% if iterations don't match, set to all
if ~iscell(val)||numel(funrun)~=numel(val)&&numel(val)>1, val = {val}; end;

% set to options
if ind > numel(options(idx,:)), options{idx,ind} = repmat({{}},[numel(funrun),1]); end;
options{idx,ind}(iter,1) = sawa_setfield(options{idx,ind},iter,[],[],val{:});

% if varargin, ask to continue
if strncmp(inargs{v},'varargin',8)&&strcmp(questdlg('New varargin?','New Varargin?','Yes','No','No'),'Yes'),
    ind = ind +1; varnum = varnum +1;
else % no varargin
    done1 = 1;
end
end
end

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
if isempty(sa), subjs = arrayfun(@(x){num2str(x)},funrun); [sa(funrun).subj] = deal(subjs{:}); end;
if ~exist('auto_i','var'), auto_i = funrun; end;
if ~exist('auto_f','var'), auto_f = 1:numel(funcs); end;
if ~exist('options','var'), options(auto_f,1) = {{}}; end;
if ~iscell(options), options = {{options}}; end;
if ~all(cellfun('isclass',options,'cell')), options = cellfun(@(x){{x}},options); end;
if numel(funcs)>numel(options), options(numel(options)+1:numel(funcs),1) = {repmat({{}},[numel(funrun),1])}; end;
if ~exist('hres','var'), hres = []; end;

% for each subject, run func
for i = auto_i
% for each func
for f = auto_f
try
% print subject 
if numel(funrun)==numel(subrun)&&all(funrun==subrun), 
    printres(sa(i).subj,hres);
end;

% get outargs, inargs
clear inargs valf tmpout; 
[outargs,inargs] = getargs(funcs{f}); 
if isempty(outargs)&&abs(nargout(funcs{f}))>0, outargs = {'varargout'}; end;
if isempty(inargs)&&abs(nargin(funcs{f}))>0, inargs = {'varargin'}; end;

% evaluate options
for x = find(~cellfun('isempty',options(f,:))),
    clear s; s = min([numel(options{f,x}),find(funrun==i,1)]);
    if isempty(options{f,x}{s}), continue; end;
    valf{x} = sawa_evalvars(options{f,x}{s});
end
if ~exist('valf','var'), valf = {}; end;

% print command
if isempty(valf), printres(funcs{f},hres);
else printres(cell2strtable(sawa_cat(1,funcs{f},inargs,any2str(valf{:})),' '),hres); end;

% evaluate function
if nargout(funcs{f})==0 
% no argout, try to get output (e.g., load)
try 
[~,tmpout{1}] = evalc([funcs{f} '(valf{:})']);
catch % otherwise get command prompt output
tmpout{1} = evalc([funcs{f} '(valf{:})']);
end

% print output
if ~isempty(hres), disp(tmpout{1}); end;
    
% set outchc to 1 and outargs to {''}
outchc{f} = 1; outargs = {''};

else % otherwise set tmpout 
% set outchc if needed
if ~exist('outchc','var')||~iscell(outchc), outchc{f} = 1:numel(outargs); end;

% run feval
[tmpout{1:max(outchc{f})}] = feval(funcs{f},valf{:});
end

if ~isempty(outchc{f})
% output
[output{i}(f,outchc{f})] = tmpout(outchc{f});

% print output
printres(cell2strtable(sawa_cat(1,outargs(outchc{f}),any2str(output{i}{f,outchc{f}})),' '),hres);
end

catch err % if error, display message
printres(['Error ' funcs{f} ' ' sa(i).subj ': ' err.message],hres);
end
end
end

% set vars to fp
fp = funpass(fp,{'output','outchc'});
return;
