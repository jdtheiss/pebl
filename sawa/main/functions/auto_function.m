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
% sawa_createvars sawa_evalvars sawa_strjoin settimeleft
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
if ~exist('idx','var'), idx = numel(funcs)+1; end;
if ~exist('program','var'), program = {}; end;

% enter function
funcs{idx} = cell2mat(inputdlg('Enter function to use:','Function'));
if isempty(funcs{idx}), return; end;
names{idx} = funcs{idx};

% set outputs
fp = funpass(fp,'funcs');
fp = set_output(fp,idx);

% set options
if ~exist('options','var')||idx > size(options,1), options{idx,1} = {}; end;

% set program
program{idx} = mfilename;

% set vars to fp
fp = funpass(fp,{'funcs','options','names','program'});
return;

% set input/output args
function fp = set_options(fp)
% get vars from fp
funpass(fp);

% init vars
if ~exist('funcs','var')||isempty(funcs), return; end;
if ~exist('names','var')||isempty(names), names = funcs; end;
if ~exist('idx','var')||isempty(idx)||idx==0, idx = numel(funcs); end;
if ~exist('sa','var'), sa = {}; end; if ~exist('subrun','var'), subrun = []; end;

% display help msg
feval(@help,funcs{idx});

% if no function, return
if isempty(which(funcs{idx})), return; end;

% get out and in args
[~,inargs] = getargs(funcs{idx}); 
if isempty(inargs)&&abs(nargin(funcs{idx}))>0, inargs = {'varargin'}; end;

% set options
if ~exist('options','var')||idx>size(options,1), 
    options(idx,1:numel(inargs)) = {[]}; 
end;

% choose input vars
if ~isempty(inargs)
inchc = listdlg('PromptString','Choose input variables:','ListString',inargs);
else % no inargs
inchc = [];    
end

% set invars based on input, file, sa
for v = inchc
done1 = 0;  % set done to 0
ind = v; % set index 
varnum = 1;

while ~done1 % loop for varargin
    
% set ind if not varargin
if strncmp(inargs{v},'varargin',8), inargs{v} = ['varargin ' num2str(varnum)]; end;

% set tmpnames and tmpvars
tmpnames = strcat('@', names(1:idx-1));
if ~exist('vars','var'), vars = {}; else vars = vars(1:idx-1,:); end;
tmpnames = tmpnames(~prod(cellfun('isempty',vars),2)');
tmpvars = vars(~prod(cellfun('isempty',vars),2),:);

% set default options
clear defopts; try defopts = options{idx,ind}; catch, defopts = {}; end;
    
% create val
val = {}; done2 = 0;
while ~done2
val{end+1,1} = sawa_createvars(inargs{v},'(cancel when finished)',subrun,sa,defopts,tmpnames{:},tmpvars);
if isempty(val{end}), val(end) = []; done2 = 1; end;
end

% set to options
if numel(val)==1&&iscell(val{1}), options{idx,ind} = val{1}; else options{idx,ind} = val; end;

% if varargin, ask to continue
if strncmp(inargs{v},'varargin',8)&&strcmp(questdlg('New varargin?','New Varargin?','Yes','No','No'),'Yes'),
    ind = ind +1; varnum = varnum +1;
else % no varargin
    done1 = 1;
end
end
end

% output
fp = funpass(fp,{'funcs','options','outchc'});
return;

% set outputs
function fp = set_output(fp,f,n,tmpout)
% get vars from fp
funpass(fp,{'funcs','vars','output','outchc'});

% init vars
if ~exist('funcs','var'), return; end;
if ~exist('f','var'), f = 1; end;
if ~exist('outchc','var')||f > numel(outchc), outchc{f} = []; end;

% get outargs
outargs = getargs(funcs{f}); 
if isempty(outargs), outargs = {'varargout'}; end;

if nargin==2,
    % choose output vars
    outchc{f} = listdlg('PromptString','Choose output variables:','ListString',outargs);
    if any(strcmp(outargs(outchc{f}),'varargout')),
        v0 = find(strcmp(outargs(outchc{f}),'varargout'));
        v = cell2mat(inputdlg('Enter range of variable outputs to return:','Variable Outputs',1,{'1'}));
        if ~strcmp(v,':'), try v = eval(v); end; end;
        if ~any(isnan(v))&& all(v > 0) && ~any(isinf(v)), outchc{f} = [outchc{f}(1:end-1),v0-1+v]; end;
    end
% set outputs
elseif nargin==4 
    if strcmp(outchc{f},':'), outchc{f} = find(~cellfun('isempty',tmpout)); end;    
    for x = 1:numel(outchc{f}), output{f,x}{n,1} = tmpout{outchc{f}(x)}; end;
end

% set vars
v0 = find(strcmp(outargs,'varargout'));
if ~isempty(v0),
outargs = sawa_insert(outargs,v0,arrayfun(@(x){['varargout ' num2str(x)]},outchc{f}(v0:end)));
end; 
for x = 1:numel(outchc{f}),vars{f,x} = outargs{outchc{f}(x)}; end;

% set vars to fp
fp = funpass(fp,{'vars','output','outchc'});
return;

% run wrapper
function fp = auto_run(fp)
% get vars from fp
funpass(fp);

% init vars
if ~exist('funcs','var')||isempty(funcs), return; end;
if ~iscell(funcs), funcs = {funcs}; end;
if ~exist('sa','var'), sa = {}; end; if ~exist('subrun','var'), subrun = []; end;
if ~exist('output','var'), output = cell(size(funcs,1),1); end; if ~exist('vars','var'), vars = {}; end;
if ~exist('program','var'), program = repmat({mfilename},size(funcs)); end;
if ~exist('fiter','var'), fiter = find(ismember(program,mfilename)); end;
if ~exist('hres','var'), hres = []; end;
if ~exist('i','var'), i = 1; end;

% if funrun == options, set n to i
if isfield(fp,'funrun')&&numel(funrun)==max(max(cellfun('size',options,1)))
    if isfield(fp,'i'), iter = find(funrun==i); else iter = 1:numel(funrun); end;
else % otherwise set to options
    iter = 1:max(max(cellfun('size',options,1)));
end

% for each iteration
for n = iter

% for each func
for f = fiter
try
% skip if already run
if ~all(iter==n) && n > max(max(cellfun('size',options(f,:),1))), continue; end;

% get outargs, inargs
[outargs,inargs] = getargs(funcs{f}); 
if isempty(outargs)&&abs(nargout(funcs{f}))>0, outargs = {'varargout'}; end;
if isempty(inargs)&&abs(nargin(funcs{f}))>0, inargs = {'varargin'}; end;
    
% evaluate options
valf = {}; clear s; 
for x = find(~cellfun('isempty',options(f,:))),
    s = min([size(options{f,x},1),n]); % set n to minimum between n and iterations
    if isempty(options{f,x}{s}), continue; end;
    valf{x} = sawa_evalvars(options{f,x}{s}); 
end

% set subject integer for output
s = find(iter==n);

% print command
if isempty(valf), printres(funcs{f},hres);
else printres(cell2strtable(sawa_cat(1,funcs{f},inargs,any2str(valf{:})),' '),hres); end;

% evaluate function
if nargout(funcs{f})==0 
% if function is save, get vars    
if strcmp(funcs{f},'save')&&~isempty(vars),
    if size(valf,2) > 1, % specific vars
        ivars = valf(2:end); 
    else % all vars
        ivars = vars(~cellfun('isempty',vars));
        ivars = unique(ivars);
    end
    % save the only latest variables found
    ivals = cell(size(ivars));
    for x = 1:numel(ivars)
        [r,c] = find(strcmp(vars,ivars{x})); A = sortrows([r,c]);
        if ~any(isempty(A)), ivals{x} = output{A(end,1),A(end,2)}{s}; end;
    end
    % if user entered -struct option
    if strcmp(ivars{1},'-struct'), 
        ivars(1)=[]; ivals(1)=[]; % remove '-struct'
        for x = 1:numel(ivars)
            ivars = horzcat(ivars,fieldnames(ivals{x})');
            ivals = horzcat(ivals,struct2cell(ivals{x})');
            ivars(x) = []; ivals(x) = [];
        end
    end
    % get other options and remove from ivals/ivars
    opts = ivars(strncmp(ivars,'-',1));
    ivals(strncmp(ivars,'-',1)) = [];
    ivars(strncmp(ivars,'-',1)) = []; 
    % set to struct
    ivars = reshape(ivars,1,numel(ivars));
    ivals = reshape(ivals,1,numel(ivals));
    tmp = cell2struct(ivals,ivars,2);
    % set valf 
    valf = horzcat(valf(1),'-struct','tmp',opts{:});
elseif strcmp(funcs{f},'assignin') % if using assignin, set to output/vars
    vars = sawa_cat(1,vars,valf{2});
    outchc{f} = 1;
    output{f,1}{s,1} = valf{3};
    % if workspace is base, set
    if strcmp(valf{1},'base'), feval(funcs{f},valf{:}); end;
    continue; % skip rest
end

% if chosen outputs, try to get output 
try
    [~,tmpout{1:max(outchc{f})}] = evalc([funcs{f} '(valf{:})']);
catch % otherwise get command prompt output
    tmpout{1} = evalc([funcs{f} '(valf{:})']);
end

% if no tmpout, set to {[]}
if isempty(tmpout), tmpout = {[]}; end;

% if output is structure (e.g., load), output struct2cell of tmpout{1}
if isstruct(tmpout{1}),
    outargs = fieldnames(tmpout{1})';
    tmpout = struct2cell(tmpout{1});
else % otherwise set outargs to {''}
    outargs = {''};
    % print output
    if ~isempty(hres), disp(tmpout{1}); end;
end

else % otherwise set tmpout 
% set outchc if needed
if ~exist('outchc','var')||~iscell(outchc), outchc{f} = 1:numel(outargs); end;

% run feval
[tmpout{1:max(outchc{f})}] = feval(funcs{f},valf{:});
end

if ~isempty(outchc{f})
% set output
fp = funpass(fp,{'output','outchc'});
fp = set_output(fp,f,find(iter==n),tmpout); 
funpass(fp,{'output','outchc','vars'});

% print output
printres(cell2strtable(sawa_cat(1,vars(f,:),cellfun(@(x)any2str(x{end}),output(f,~cellfun('isempty',output(f,:))))),' '),hres);
end

catch err % if error, display message
printres(['Error ' funcs{f} ': ' err.message],hres);
end
end
end

% set vars to fp
fp = funpass(fp,{'output','outchc','vars'});
return;
