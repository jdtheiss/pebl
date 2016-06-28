function varargout = auto_batch(cmd,varargin)
% varargout = auto_batch(cmd,varargin)
% This function will allow you to set arguments for the command line function
% funname and then run the function.
%
% Inputs:
% cmd - command to use (i.e. 'add_funciton','set_options','auto_run')
% varargin - arguments to be passed to cmd
%
% Outputs: 
% fp - funpass struct containing variables from call cmd(varargin)
%
% Example:
% funcs = matlabbatch;
% options{1,1}(1:4,1) = {'test1','test2','test3','test4'};
% itemidx{1}(1) = 3;
% rep{1}(1) = 0;
% fp = struct('funcs',{funcs},'options',{options},'itemidx',{itemidx},'rep',{rep});
% fp = auto_batch('run_batch',fp)
%
% requires: choose_fields choose_spm closedlg funpass printres 
% sawa_createvars sawa_evalvars sawa_getfield
% sawa_savebatchjob sawa_setbatch sawa_setdeps  
% sawa_setupjob sawa_strjoin settimeleft subidx
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
% create vars from fp
funpass(fp);

% init vars
if ~exist('funcs','var'), fp.funcs = {}; funcs = {}; end;
if ~exist('program','var')||isempty(program), fp.program = {}; program = {}; end;
if ~exist('idx','var')||isempty(idx)||idx==0, idx = numel(funcs)+1; end;
fx = ismember(program,'auto_batch'); fx(find(~fx(idx:end),1)+idx:end) = false;
fx = find(fx);
if ~exist('itemidx','var')||isempty(itemidx), fp.itemidx = cell(size(funcs)); itemidx = fp.itemidx; end;
if ~exist('rep','var')||isempty(rep), fp.rep = cell(size(funcs)); else clear rep; end;
if ~exist('str','var')||isempty(str), fp.str = cell(size(funcs)); else clear str; end;
if ~exist('names','var')||isempty(names), fp.names = cell(size(funcs)); else clear names; end;
if ~exist('options','var')||isempty(options), fp.options = cell(numel(funcs),1); end;
if ~exist('outchc','var')||isempty(outchc), fp.outchc = cell(size(funcs)); end;
if ~exist('vars','var')||isempty(vars), fp.vars = cell(numel(funcs),1); end;
if ~exist('sa','var'), sa = {}; end; 
if ~exist('subrun','var'), subrun = []; end;
if ~exist('sawafile','var'), sawafile = []; end;

% get only auto_batch funcs %PROBLEM?
funcs = funcs(fx); itemidx = itemidx(fx); options = fp.options(fx,:);

% set m
m = find(fx==idx); if isempty(m), m = 1; end;

% choose spm ver
spmver = choose_spm;

% run setupjob
disp('Loading Batch Editor...'); 
disp(char('Load/Choose Modules to use:',...
        'Select items and press right arrow to set sawa variables.',...
        'Press left arrow to remove sawa variables.',...
        'Close Batch Editor when finished.'));
    
% load matlabbatch with sawa_setupjob 
[funcs,itemidx,str]=sawa_setupjob(funcs,itemidx,m); 

try % get job/module ids 
[~,cjob,mod_ids] = evalc('cfg_util(''initjob'',funcs)'); 
catch err
disp(err.message); set(findobj('tag','setup batch job'),'tooltipstring','Empty'); return; 
end

% get names
for m = 1:numel(funcs)
[~,~,contents{m}]=cfg_util('listmod',cjob,mod_ids{m},[],cfg_findspec({{'hidden',false}}),...
    cfg_tropts({{'hidden',true}},1,inf,1,inf,false),{'name','all_set_item'});
names{m} = contents{m}{1}{1};
end
clear cjob mod_ids;

% save folder
disp('Choose a folder to save the job(s) for this function. Click cancel to choose a subject field (e.g., subjFolders)');
jobsavfld = uigetdir(cd, 'Choose a folder to save the job(s) for this function. Click cancel to choose a subject field (e.g., subjFolders)');
try % if no folder chosen, ask to choose fields
if ~any(jobsavfld), jobsavfld = strcat('sa(i).',subidx(choose_fields(sa,subrun,'Choose a field to save jobs folder:'),'{1}')); end; 
if strcmp(jobsavfld,'sa(i).'), jobsavfld = []; disp('Will not save jobs.'); end; % if didn't choose a field
catch err % if no jobsavfld, empty and disp warning
jobsavfld = []; disp(['Will not save jobs: ' err.message]);
end;
clear err;

% job name
if isempty(sawafile) % enter job name
jobname = cell2mat(inputdlg('Enter a name to save the job (e.g., FirstLevelAnalysis):'));
elseif ~exist('jobname','var')||isempty(jobname) % set jobname to sawafile
[~,jobname] = fileparts(sawafile);
jobname = cell2mat(inputdlg('Enter a name to save the job:','Job Name',1,{jobname}));
if isempty(jobname), [~,jobname] = fileparts(sawafile); end;
else % otherwise allow edit
tmpname = cell2mat(inputdlg('Enter a name to save the job:','Job Name',1,{jobname}));
if ~isempty(tmpname), jobname = tmpname; end; clear tmpname;
end

% check if complete
job_sts = 'Complete';
for m = 1:numel(funcs), 
if ~all(cell2mat(contents{m}{2}(~ismember(1:numel(contents{m}{2}),itemidx{m})))), 
job_sts = 'Incomplete'; break; % if any not set (other than itemidx), incomplete
end
end
clear contents m;

% set job status
set(findobj('tag','setup batch job'),'tooltipstring',[jobname ': ' job_sts]);
clear job_sts; 

% save or run?
if ~isempty(jobsavfld), 
saveorrun = questdlg('Save jobs or run jobs?','Save or Run','Save','Run','Run');
else % can't save
saveorrun = 'Run';    
end

% overwrite previous data? (for spm jobs with dir only) 
if ~isempty(sawa_getfield(funcs,'expr','\.spm\..*\.dir$'))
overwrite = questdlg('Overwrite previous SPM files? (if applicable)','Overwrite','Yes','No','No');
end

% set options for any changes
prenames = fp.names(fx);
preidx = fp.itemidx(fx);
preopts = fp.options(fx,:);
noptions = cell(numel(names),max(cellfun('size',[itemidx,1],2))); 
for n = 1:numel(names),
f = find(strcmp(prenames(n:end),names{n}),1)+n-1;
noptions(n,ismember(itemidx{n},[preidx{f}])) = preopts(f,ismember([preidx{f}],itemidx{n}));
end
clear prenames preidx preopts n f;

% if no fx, set to idx:idx+numel(funcs)-1
if ~any(fx), fx = idx:idx+numel(funcs)-1; end;

% insert vars into previous
itemidx = sawa_insert(fp.itemidx,fx,itemidx);
rep = sawa_insert(fp.rep,fx,cell(size(funcs)));
str = sawa_insert(fp.str,fx,str);
names = sawa_insert(fp.names,fx,names);
options = sawa_insert(fp.options,{fx,':'},noptions);
program = sawa_insert(fp.program,fx,repmat({'auto_batch'},size(funcs)));
outchc = sawa_insert(fp.outchc,fx,cell(size(funcs)));
vars = sawa_insert(fp.vars,{fx,':'},cell(numel(funcs),1));
funcs = sawa_insert(fp.funcs,fx,funcs);
clear noptions fx;

% set vars to fp
fp = funpass(fp);

% set outputs for each module
fx = ismember(program,'auto_batch'); fx(find(~fx(idx:end),1)+idx:end) = false;
fx = find(fx);
fp = set_output(fp,fx); 
return;

function fp = set_options(fp)
% get vars from fp
funpass(fp);

% init vars
if ~exist('funcs','var'), return; elseif ~iscell(funcs), funcs = {funcs}; end;
if ~exist('idx','var')||isempty(idx)||idx==0, idx = 1; end;
if ~exist('itemidx','var'), return; elseif ~iscell(itemidx), itemidx{idx} = itemidx; end;
if ~exist('names','var'), names = {}; end;
if ~exist('sa','var'), sa = {}; end; if ~exist('subrun','var'), subrun = []; end;

% get auto_batch indices
fx = ismember(program,'auto_batch');
fx(find(~fx(idx:end),1)+idx:end) = false; 
funcs = funcs(fx); 

try % get job/module ids  
[~,cjob,mod_ids(fx)] = evalc('cfg_util(''initjob'',funcs)'); 
catch err
disp(err.message); set(findobj('tag','setup batch job'),'string','Empty'); return; 
end

% get id, contents, and names
[id,~,contents]=cfg_util('listmod',cjob,mod_ids{idx},[],cfg_findspec({{'hidden',false}}),...
cfg_tropts({{'hidden',true}},1,inf,1,inf,false),{'name','class','level'});
itemnames{idx} = contents{1}(itemidx{idx});  

% if empty itemidx, skip
if ~isempty(itemidx{idx}), 

% set options for chosen itemidx
for v = listdlg('PromptString','Choose items to set:','ListString',itemnames{idx});
    % get index of cfg_repeat or set to itemidx
    rep_idx = subidx(find(strcmp(contents{2}(1:itemidx{idx}(v)),'cfg_repeat')),'(end)');
    if isempty(rep_idx), rep_idx = itemidx{idx}(v); end;
    
    % get repeat contents
    [~,~,repcon]=cfg_util('listmod',cjob,mod_ids{idx},id{rep_idx},cfg_findspec({{'name',itemnames{idx}{v}}}),...
    cfg_tropts({{'hidden',true}},1,inf,1,inf,false),{'name'});
    
    % set default index
    defidx = 1:numel(repcon{1}); if isempty(defidx), defidx = 1; end;
    if numel(defidx) > 1, defidx = defidx(find(strcmp(itemnames{idx},itemnames{idx}{v}))==v); end;

    % find parents of itemidx
    itempar = [];
    try
    p = find(ismember(contents{2}(1:itemidx{idx}(v)),'cfg_repeat'));
    p = p(cell2mat(contents{3}(p))<contents{3}{itemidx{idx}(v)});
    itempar = contents{1}(p);
    end
    
    % choose parents to replicate
    if ~isempty(itempar)
        pchc = listdlg('PromptString',{['Choose components of ' itemnames{idx}{v}...
            ' ' num2str(defidx) ' to replicate (cancel if not replicating)'],'','',''},...
            'ListString',itempar,'selectionmode','single');
    else
        pchc = []; 
    end
    
    % set rep
    if ~isempty(pchc), rep{idx}(v) = p(pchc); else rep{idx}(v) = 0; end;
    
    % set tmpnames and tmpvars
    tmpnames = strcat('@', names(1:idx-1));
    if ~exist('vars','var'), vars = {}; else vars = vars(1:idx-1,:); end;
    tmpnames = tmpnames(~prod(cellfun('isempty',vars),2)');
    tmpvars = vars(~prod(cellfun('isempty',vars),2),:);

    % set default options
    clear defopts; try defopts = options{idx,v}; catch, defopts = {}; end; 
    
    % create val
    val = {}; done = 0;
    while ~done
    val{end+1,1} = sawa_createvars([itemnames{idx}{v} ' ' num2str(defidx)],'(cancel when finished)',subrun,sa,defopts,tmpnames{:},tmpvars);
    if isempty(val{end}), val(end) = []; done = 1; end;
    end
    
    % set to options
    if numel(val)==1&&iscell(val{1}), options{idx,v} = val{1}; else options{idx,v} = val; end;
end
end

% insert vars into previous
funcs = sawa_insert(fp.funcs,fx,funcs);

% set vars to fp
fp = funpass(fp,{'funcs','options','rep'});
return;

% set/get output based on dependencies
function fp = set_output(fp,f,n,cjob)
% get vars from fp
funpass(fp,{'funcs','vars','output','outchc'});

% init vars
if ~exist('funcs','var'), return; end;
if ~exist('f','var'), f = 1; end;
if ~exist('outchc','var'), outchc{f} = []; end;
if f > numel(outchc), outchc(end+1:max(f)) = {[]}; end; 
if ~exist('cjob','var'), [~,cjob] = evalc('cfg_util(''initjob'',funcs(f))'); end;

% get str, dep and sout
[~,str,sts,~,sout]=cfg_util('showjob',cjob); 

% for each module
for m = 1:numel(f)
if isempty([sout{m}]), continue; end; 

if nargin==2
% choose dependency to output
outchc{f(m)} = listdlg('PromptString',{['Choose dependencies to output from ' str{m} ':'],'',''},...
    'ListString',{sout{m}.sname});
end

% for each outchc
for x = outchc{f(m)}
% get name from sout sname
varnam = regexp(sout{m}(x).sname,['^' str{m} ': (?<name>.+):?'],'names');
if isempty(varnam), varnam(1).name = ['Output ' num2str(x)]; end;

% set vars
vars{f(m),x} = varnam.name;

% set output
if sts(m) && nargin > 2, 
vals = cfg_util('getalloutputs',cjob); 
output{f(m),x}{n,1} = subsref(vals{m}(x),sout{m}(x).src_output); 
end
end
end

% set vars to fp
fp = funpass(fp,{'vars','output','outchc'});
return;

function fp = auto_run(fp)
% get vars from fp
funpass(fp);

% init vars
if ~exist('funcs','var')||isempty(funcs), return; elseif ~iscell(funcs), funcs = {funcs}; end;
if ~exist('sa','var'), sa = {}; end; if ~exist('subrun','var'), subrun = []; end;
if ~exist('itemidx','var'), return; elseif ~iscell(itemidx), itemidx{idx} = itemidx; fp.itemidx = itemidx; end;
if ~exist('rep','var')||isempty(rep), fp.rep(fiter) = {zeros(size(itemidx{1}))}; end;
if ~exist('saveorrun','var'), saveorrun = 'Run'; end;
if ~exist('overwrite','var'), overwrite = 'No'; end;
if ~exist('hres','var'), hres = []; end;
if ~exist('jobsavfld','var'), jobsavfld = []; end;
if ~exist('sawafile','var')||isempty(sawafile), sawafile = 'Batch Editor'; end;
if ~exist('jobname','var')||isempty(jobname), [~, jobname] = fileparts(sawafile); end;
if ~exist('output','var'), output = cell(size(funcs,1),1); end; if ~exist('vars','var'), vars = {}; end;
if ~exist('program','var'), program = repmat({mfilename},size(funcs)); end;
if ~exist('fiter','var'), fiter = find(ismember(program,mfilename)); end;
if ~exist('i','var'), i = 1; end;

% ensure correct spmver
if exist('spmver','var'), spmver = choose_spm(spmver); else spmver = spm('ver'); end;

% get matlabbatch from funcs and set preidx
matlabbatch = funcs(fiter); preidx = itemidx;

% get updated job id and mod ids 
cfg_util('initcfg');
[~,cjob,mod_ids(fiter)] = evalc('cfg_util(''initjob'',matlabbatch)');

% get names
for f = fiter
[~,~,contents{f}]=cfg_util('listmod',cjob,mod_ids{f},[],...
cfg_findspec({{'hidden',false}}),cfg_tropts({{'hidden',true}},1,inf,1,inf,false),{'name','val','all_set_item'});
itemnames{f} = contents{f}{1};
end

% set options, names, itemidx, rep, sa, and hres
fp = funpass(fp,{'options','fiter','itemnames','itemidx','rep','sa','hres'});

% print current variables/spm version
if (~isfield(fp,'funrun')&&~isfield(fp,'i'))||i==funrun(1),
for f = fiter
prntidx{f} = ~ismember(1:numel(itemnames{f}),itemidx{f});
% print itemnames and string rep of values for non-itemidx
cellfun(@(x,y){printres([x ': ' sawa_strjoin(any2str(y),'\n')],hres)},itemnames{f}(prntidx{f}),contents{f}{2}(prntidx{f}));
end; 
end

% set warning off
w = warning; warning('off','all'); 

% if funrun == options, set n to i
if isfield(fp,'funrun')&&numel(funrun)==max(max(cellfun('size',options,1)))
    if isfield(fp,'i'), iter = find(funrun==i); else iter = 1:numel(funrun); end;
else % otherwise set to options
    iter = 1:max(max(cellfun('size',options,1)));
    if isempty(iter), iter = 1; end;
end

% for each iteration
for n = iter
try
% skip if already run
if ~all(iter==n) && n > max(max(cellfun('size',options(fiter,:),1))), continue; end;

% set matlabbatch
cfg_util('initcfg'); clear cjob; cjob = [];
clear matlabbatch; matlabbatch = funcs(ismember(program,mfilename));

for f = fiter, 
% set variables for each module
matlabbatch = local_setbatch(fp,matlabbatch,f,n);

% set dependencies
matlabbatch = sawa_setdeps(matlabbatch,cjob,f); 

% check if able to run 
[~,cjob(f)] = evalc('cfg_util(''initjob'',matlabbatch(f))'); 
clear run; [~,~,run] = cfg_util('showjob',cjob(f)); 

% run cfg_util
if all(run) && strcmp(saveorrun,'Run')

% if overwriting, set str to continue, otherwise stop (if applicable)
if strcmpi(overwrite,'yes'), str = 'continue'; else str = 'stop'; end;
% close dlg if opens
closedlg({'-regexp','tag',spm('ver')},{'string',str});

% run serial
cfg_util('runserial',cjob(f));

% set outputs
fp = set_output(fp,f,find(iter==n),cjob(f)); 

% print outputs
funpass(fp,{'vars','output'}); 
% for f = fiter
try cellfun(@(x,y){printres(cell2strtable(sawa_cat(1,x,any2str(y{end})),' '),hres)},vars(f,:),output(f,:)); end;
% end

elseif ~all(run) % if can't run, print reason
printres('Could not run. Empty components:',hres);
printres([itemnames{f}{1} ': ' sawa_strjoin(itemnames{f}(~cell2mat(contents{f}{3})),', ')], hres);
end
end

catch err % error, print message
printres(['Error ' jobname ': ' err.message],hres);
end

% save matlabbatch job
if ~isempty(jobsavfld)
clear jobsave; jobsave = sawa_evalvars(jobsavfld); 
jobsave = sawa_savebatchjob(jobsave,jobname,matlabbatch);
printres(['Saving job to ' jobsave],hres); 
end
end

% reset warnings
warning(w.state,w.identifier);

% set fp 
fp = rmfield(fp,'itemnames');
return;

function matlabbatch = local_setbatch(fp,matlabbatch,m,n)
% get vars from fp
funpass(fp); 

% init valf
valf = cell(1, numel(itemidx{m}));

% for each itemidx
for mx = 1:numel(itemidx{m})

% if not enough options, set to end; if empty options, skip
clear s; s = min([numel(options{m,mx}),n]);
if isempty(options{m,mx}), continue; end;

% eval vars
valf{mx} = sawa_evalvars(options{m,mx}{s});
if iscell(valf{mx})&&rep{m}(mx)==0, valf{mx} = sawa_getfield(valf{mx}); end;

% print vars
printres([itemnames{m}{itemidx{m}(mx)} ': ' sawa_strjoin(any2str(valf{mx}),'\n')],hres);

% if any empty with group, remove subject
if iscell(valf{mx})&&any(cellfun('isempty',valf{mx}))
n = cellfun('isempty',valf{mx})'; n = regexprep(options{m,mx}{s}(n),'.*sa\(([\d\w]+\)\..*','$1');
printres(['Missing ' itemnames{m}{itemidx{m}(mx)} ' for subject(s) ' sawa_strjoin(sa(str2double(n)).subj,'\n')],hres);
% remove from others
for r = 1:size(options,2), 
    if isempty(options{m,mx}), continue; end;
    options{m,mx}{s} = regexprep(options{m,mx}{s},strcat('.*sa\(',n,'\)\..*'),'');
    options{m,mx}{s}(cellfun('isempty',options{m,mx}{s})) = [];
end
end
end

% set items
if isempty(valf)||all(cellfun('isempty',valf)), return; end;
[matlabbatch,sts] = sawa_setbatch(matlabbatch,valf,itemidx{m},rep{m},m); 
return;
