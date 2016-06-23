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
% fp = struct('funcs',{{'echo'}},'options',{{' this is a test'}});
% fp = auto_cmd('auto_run',fp)
%
% Command Prompt:
% echo this is a test
% Output1
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
% sawa_strjoin sawa_system settimeleft
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
if ~exist('idx','var'), idx = numel(funcs)+1; end;
if ~exist('program','var'), program = {}; end;

% enter function
funcs{idx} = cell2mat(inputdlg('Enter command line function to use:','Function'));
if isempty(funcs{idx}), return; end;
names{idx} = funcs{idx};

% set outputs
fp = funpass(fp,'funcs');
fp = set_output(fp,idx);

% set options
if ~exist('options','var')||idx > size(options,1)||isempty(options(idx,:)), options{idx,1} = {}; end;

% set program
program{idx} = mfilename;

% set vars to fp
fp = funpass(fp,{'funcs','options','names','program'});
return;

% set_options 
function fp = set_options(fp) 
% only get sa and subrun from fp
funpass(fp);

% init vars
if ~exist('funcs','var')||isempty(funcs), return; end;
if ~exist('idx','var')||isempty(idx)||idx==0, idx = numel(funcs); end;
if ~exist('sa','var'), sa = {}; end; if ~exist('subrun','var'), subrun = []; end;
if ~exist('options','var')||idx > size(options,1), options{idx,1} = {''}; end;

% set help switch based on pc/mac
if ispc, hswitch = {'/h','/H','/?',''}; else hswitch = {'-help','--help','-h','-H','-?',''}; end;
% get help message
helpmsg = ''; 
if ~strcmp(funcs{idx}(end),'=') % if not setting variable
for o = hswitch % for each, try to get switches
% set timer to stop from running long function
t = timer('StartDelay',1,'TimerFcn',@(x,y)error('')); start(t);
clear tmpmsg tmpval; % eval help option
[tmpmsg,tmpval] = evalc(['sawa_system(''' funcs{idx} ''',''' o{1} ''');']);
stop(t); delete(t); 
% set if return val is >= previous and < 127 
if tmpval==0||isempty(helpmsg), helpmsg = tmpmsg; end;    
end
if any(regexpi(helpmsg,'invalid option')) % if msg includes "invalid option"
    helpmsg = regexprep(helpmsg,'[^\n]*\wnvalid \wption[^\n]*',''); 
elseif any(regexpi(helpmsg,'illegal option')) % or msg includes "illegal option"
    helpmsg = regexprep(helpmsg,'[^\n]*\wllegal \wption[^\n]*','');
end % if msg empty and val = 127, command not found
if isempty(helpmsg)&&tmpval==127, helpmsg = [funcs{idx} ': command not found']; end;
end

% display helpmsg
if idx > size(options,1)||all(cellfun('isempty',options(idx,:))), disp(helpmsg); end;

% get switches
if ispc % pc switches
opts = regexp(helpmsg,'\W/\w+','match'); 
else % mac switches
opts = regexp(helpmsg,'\W[-+]{1,2}\w+','match'); 
end % get unique and remove space etc.
opts = unique(regexprep(opts,'[^-+/\w]',''));
opts = opts(~ismember(opts,hswitch));
% set other, edit to end
opts{end+1} = 'other'; % opts{end+1} = 'edit';

% get current options
if idx <= size(options,1)&&~all(cellfun('isempty',options(idx,:))),
curopts = cellfun(@(x){regexp(x{1},'^\S+','match')},options(idx,~cellfun('isempty',options(idx,:))));
if ~isempty(curopts)&&~all(cellfun('isempty',options(idx,:))), 
params = arrayfun(@(x){['param' num2str(x)]},1:sum(cellfun('isempty',curopts)));
curopts(cellfun('isempty',curopts)) = params;
if any(cellfun('isclass',curopts,'cell')), curopts = [curopts{:}]; end;
if ~iscell(curopts), curopts = {curopts}; end;

% choose options
chc = listdlg('PromptString','Choose option(s) to edit:','ListString',[curopts,'delete','append']);
if isempty(chc), return; end;
end
end

% if no curopts or append choose other options
if ~exist('chc','var') || any(chc == numel(curopts)+2), % append
    chc = listdlg('PromptString','Choose option(s) to append:','ListString',opts); 
    if ~all(cellfun('isempty',options(idx,:))), n = numel(curopts); else n = 0; end;
    v = n+1:n+numel(chc);
elseif any(chc == numel(curopts)+1) % delete
    chc = listdlg('PromptString','Choose option(s) to delete:','ListString',curopts);
    % delete choice
    options = sawa_insert(options,{idx,':'},options(idx,~ismember(1:size(options,2),chc))); 
    if isempty(options), options{idx,1} = {}; end;
    chc = []; % skip setting choice
else % otherwise set to curopts
    opts = curopts; v = chc;
end;

% for each choice
for o = chc 
    try
    x = find(chc==o);
    % Other or chosen
    if strcmp(opts{o},'other')
    opts{o} = cell2mat(inputdlg('Enter the option to use (e.g., -flag or leave blank if none):')); 
    if isempty(opts{o}), opts{o} = ''; end;
    end 
    
    % set tmpnames and tmpvars
    tmpnames = strcat('@', names(1:idx-1)); 
    if ~exist('vars','var')||isempty(vars), vars = {}; else vars = vars(1:idx-1,:); end;
    tmpnames = tmpnames(~prod(cellfun('isempty',vars),2)');
    tmpvars = vars(~prod(cellfun('isempty',vars),2),:);

    % set default options
    clear defopts; try defopts = strtrim(regexprep(options{idx,v(x)},opts{o},'')); catch, defopts = {}; end;
    
    % create val
    val = {}; done = 0;
    while ~done
    val{end+1,1} = sawa_createvars(opts{o},'(cancel when finished)',subrun,sa,defopts,tmpnames{:},tmpvars);
    if isempty(val{end}), val(end) = []; done = 1; end;
    end
    
    % if only one cell, set to inner cell
    if numel(val)==1&&iscell(val{1}), val = val{1}; end;
    if isempty(val), val = {''}; end;
    
    % set "" around paths
    val = regexprep(val,['[\s"]*(.+' filesep '[^"]+)"?'],'"$1"'); 
    
    % set opt to val
    if strncmp(opts{o},'param',5), opts{o} = ''; end;
    val = strcat(opts{o},{' '},val); 
    
    % set options
    if numel(val)==1&&iscell(val{1}), options{idx,v(x)} = val{1}; else options{idx,v(x)} = val; end;
    
    catch err % if error, display message
        disp(err.message);
    end
end

% display options
n = max(cellfun('size',options(idx,:),1)); 
if ~all(cellfun('isempty',options(idx,:))), 
catopts = cellfun(@(x){cat(1,x,repmat(x(end),n-numel(x),1))},options(idx,~cellfun('isempty',options(idx,:))));
catopts = cellfun(@(x){strcat({' '},x)},catopts);
catopts = strcat(catopts{:});
cellfun(@(x)disp([funcs{idx}, x]),catopts);
end

% set vars to fp
fp = funpass(fp,'options');
return;

% set outputs
function fp = set_output(fp,f,n,tmpout)
% get vars from fp
funpass(fp,{'funcs','options','vars','output','outchc','dlm'});

% init vars
if ~exist('funcs','var'), return; end;
if ~exist('f','var'), f = 1; end;
if ~exist('outchc','var')||f > numel(outchc), outchc{f} = []; end;

% choose output vars
if strcmp(funcs{f}(end),'=') % set vars mac
    outargs = {funcs{f}(1:end-1)};
elseif strcmp(funcs{f},'set') % set vars pc
    outargs = {regexp(options{f,1},'[^s=]+','match')};
else
    outargs = {'Output'};
end

% enter estimated outputs
if nargin==2,
    v = cell2mat(inputdlg('Enter outputs to return (cancel for total output):','outputs',1,{':'}));
    if ~strcmp(v,':'), try v = eval(v); end; end;
    if ~any(isnan(v)) && all(v > 0) && ~any(isinf(v)), outchc{f} = v; end;
    if ~isempty(v), dlm{f} = cell2mat(inputdlg('Enter delimiter to separate outputs:','Delimiter',1,{'\s+'})); end;

% set outputs
elseif nargin==4, 
    % multiple outputs
    if ~isempty(outchc{f})&&~isempty(dlm{f}), tmpout = strsplit(tmpout,dlm{f},'DelimiterType','RegularExpression'); end;
    if ~iscell(tmpout), tmpout = {tmpout}; end;
    if strcmp(outchc{f},':'), outchc{f} = find(~cellfun('isempty',tmpout)); end;
    if isempty(outchc{f}), outchc{f} = 1; end;
    % set outputs
    for x = 1:numel(outchc{f}), output{f,x}{n,1} = tmpout{outchc{f}(x)}; end;
end;

% set outargs
if ~isempty(outchc{f}), outargs = arrayfun(@(x){[outargs{1} num2str(x)]},1:max(outchc{f})); end;
if strcmp(outchc{f},':'), outargs = {'Output1'}; end;

% set vars
for x = 1:numel(outchc{f}), vars{f,x} = outargs{outchc{f}(x)}; end;

% set vars to fp
fp = funpass(fp,{'output','vars','outchc','dlm'});
return;

% run cmd
function fp = auto_run(fp)
% get vars from fp
funpass(fp);

% init vars
if ~exist('funcs','var'), return; end;
if ~iscell(funcs), funcs = {funcs}; fp.funcs = funcs; end;
if ~exist('sa','var'), sa = {}; end; if ~exist('subrun','var'), subrun = []; end;
if ~iscell(options), options = {{options}}; end;
if ~all(cellfun('isclass',options,'cell')), options = cellfun(@(x){{x}},options); end;
if ~exist('output','var'), output = cell(size(funcs,1),1); end; 
if ~exist('vars','var'), vars = {}; end;
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
% func, run with options
clear valf; valf = cell(numel(funcs),1);
for f = fiter
try
 % skip if already run
if ~all(iter==n) && n > max(max(cellfun('size',options(f,:),1))), continue; end;

% evaluate options
clear s; 
for x = find(~cellfun('isempty',options(f,:))),
    s = min([size(options{f,x},1),n]); % set n to minimum between n and iterations
    if isempty(options{f,x}{s}), continue; end;
    valf{f,x} = sawa_evalvars(options{f,x}{s},'cmd'); 
end
valf(f,:) = cellfun(@(x){strcat({' '},x)},valf(f,:));

% print command
printres(char(strcat(funcs{f}, valf{f,:})),hres); 

% run command
clear tmpout; [~,tmpout]= sawa_system(funcs(fiter<=f),arrayfun(@(x)strcat(valf{x,:}),find(fiter<=f)),f); 

% set outputs
if strcmp(funcs{f}(end),'='), % set vars mac
    clear tmpout; tmpout = valf{f,1}; 
elseif strcmp(funcs{f},'set'), % set vars pc
    clear tmpout; tmpout = strtrim(regexprep(valf{f,1},'.*=',''));
end; 
fp = set_output(fp,f,find(iter==n),tmpout);

% print outputs
funpass(fp,{'vars','output'}); 
if ~exist('vars','var')||f > numel(vars), continue; end;
cellfun(@(x,y){printres(cell2strtable(sawa_cat(1,x,any2str(y{end})),' '),hres)},vars(f,:),output(f,:));

catch err % if error
    printres(['Error ' funcs{f} ': ' err.message],hres);
end
end
end

% set vars to fp
fp = funpass(fp,{'output','vars','outchc'});
return;