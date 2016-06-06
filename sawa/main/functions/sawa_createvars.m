function vals = sawa_createvars(varnam,msg,subrun,sa,varargin)
% vars = sawa_createvars(varnam,msg,subrun,sa,varargin)
% Creates variables for specific use in auto_batch, auto_cmd, auto_function.
% 
% Inputs:
% varnam - variable name 
% msg - optional string message to display in listdlg
% subrun - numeric array of subjects to use (optional)
% sa - subject array (optional)
% varargin - can be default value or previous functions to use output (must
% be string and begin with '@')
% Note: if subrun/sa are not entered, user will choose
%
% Outputs:
% vars - variable returned
%
% Example:
% varnam = 'Resting State Files';
% msg = '';
% subrun = 1:33;
% sa = ocd;
% vars = sawa_createvars(varnam,msg,subrun,sa)
% [choose "Subject Array"]
% [choose "subjFolders 1"]
% [enter "/RestingState/Resting*.nii"]
% vars = 'sa(i).subjFolders{1}';
%
% requires: choose_fields getargs sawa_subrun
%
% Created by Justin Theiss

% init vars
if ~exist('varnam','var')||isempty(varnam), varnam = 'Variable'; end;
if ~exist('msg','var'), msg = ''; end;
if ~exist('subrun','var'), subrun = []; end;
if ~exist('sa','var'), sa = {}; end;
if ~exist('ival','var')||isempty(ival), ival = []; end;
if ~exist('vars','var')||isempty(vars), vars = {''}; end;
vals = {};

% set choices
choices = {'String','Number','Evaluate','Index','Structure','Choose File','Choose Directory','Function','Subject Array'};
if isempty(sa), choices = choices(1:end-1); end;

% get varargin class for defaults
if numel(varargin) > 0, 
% get functions to add to choices
funcs = varargin(strncmp(varargin,'@',1)); 
choices = horzcat(choices,funcs{:});
% default vars
vars = varargin{1};

% set defaults based on class
try
switch class(varargin{1})
    case 'cell' % if cellstr, set to 1
        if iscellstr(varargin{1})&&~isempty(varargin{1}), % cellstr 
            vars = varargin{1}; ival = 1; 
        elseif all(cellfun(@(x)iscell(x)||isstruct(x),varargin{1})) % all cell/struct
            vars = varargin{1}; ival = 4; % set to index
        elseif ~isempty(varargin{1}) % otherwise, set to number
            vars = varargin{1}; ival = 2;
        end;
    case 'char' % set char to cellstr
        vars = cellstr(varargin{1}); ival = 1;
    case 'double' % if double, num2str
        if isempty(varargin{1}), ival = 1; else ival = 2; end;
        vars = {num2str(varargin{1})};
    case 'struct' % if struct
        vars = varargin{1}; ival = 5;
end
end

% if cellstr, check for evals/files/dirs
if iscellstr(vars)&&~isempty(vars), 
if all(cellfun(@(x)exist(x,'file'),vars)), ival = 6; end; % if files
if all(cellfun(@(x)isdir(x),vars)), ival = 7; end; % if dirs
end
end

% choose method for invars
chc = listdlg('PromptString',{['Choose method to set ' varnam ' ' msg],'',''},'ListString',choices,'InitialValue',ival); 
if isempty(chc), return; end; 

for c = chc
% set based on choice
switch choices{c}
case {'String','Number','Evaluate'} % input
    if ~iscell(vars), vars = {vars}; end;
    if ~iscellstr(vars), vars = any2str(vars{:}); end;
    vars = cell2mat(inputdlg(['Set ' varnam],varnam,[max(numel(vars),2),50],{char(vars)}));
    if isempty(vars), vars = {}; return; end;
    vars = strtrim(arrayfun(@(x){vars(x,:)},1:size(vars,1)));
    if c > 1 % number or evaluate
        % if @, convert to function handle
        vars(strncmp(vars,'@',1)) = cellfun(@(x){str2func(x)},vars(strncmp(vars,'@',1)));
        % if string, evaluate
        vars(cellfun(@(x)ischar(x),vars)) = cellfun(@(x){eval(['[' x ']'])},vars(cellfun(@(x)ischar(x),vars)));
    end
case 'Index' % index
    if ival==4, [~,~,tmpr]=sawa_getfield(vars,'rep','','r',2); end; ind = '{1}'; 
    while ~isempty(ind), % set index
    if ival==4&&~isempty(tmpr), ind = tmpr{1}; tmpr(1)=[]; end; % get input index
    ind = cell2mat(inputdlg(['Enter index to set for ' varnam ' (e.g., {1,1} or (2)). Cancel when done.'],'Index',1,{ind}));
    if isempty(ind), break; end;
    s = substruct(ind([1,end]),eval(ind)); % create s var for subsasgn
    if ival==4, try varargin{1} = subsref(vars,s); end; end; % set varargin
    vals = subsasgn(vals,s,sawa_createvars([varnam ind],msg,subrun,sa,varargin{:}));
    end
    continue; % done, vals already set
case 'Structure' % struct
    if isstruct(vars), % if exists, choose component to edit
        substr = vertcat(fieldnames(vars),'Add'); 
        n = listdlg('PromptString','Choose component to edit:','ListString',...
        [arrayfun(@(x){num2str(x)},1:numel(vars)),'Add']);
        if isempty(n), return; end;
        if any(n > numel(vars)), vars(n(end)) = cell2struct(cell(size(fieldnames(vars))),fieldnames(vars)); end;
    else % if new, create struct
        n = cell2mat(inputdlg('Enter number of components to create'));
        n = 1:str2double(n); if isnan(n), return; end;
        vars = repmat(struct,1,max(n)); substr = {'Add'};
    end;
    % for each component
    for n = n
        done = 0; 
        while ~done
            % choose fields to edit, add, delete
            subchc = listdlg('PromptString',{['Add/Edit subfields for ' varnam '(' num2str(n) ') (cancel when finished):'],'',''},...
                'ListString',substr,'selectionmode','single');
            if isempty(subchc), done = 1; break; end;
            if subchc == numel(substr), tmpfld = ''; else tmpfld = substr{subchc}; end;
            % set field
            fld = cell2mat(inputdlg('Enter field name to add to structure (cancel to delete):','Field Name',1,{tmpfld}));
            if isempty(fld)&&~isempty(tmpfld), vars = rmfield(vars,substr{subchc}); substr(subchc) = []; continue; end; % if no fld, remove
            % run sawa_createvars
            if ~isempty(fld), 
                if isfield(vars(n),fld), varargin{1} = vars(n).(fld); else varargin{1} = {}; end;
                vars(n).(fld) = sawa_createvars(fld,'',subrun,sa,varargin{:}); 
                substr = vertcat(fieldnames(vars),'Add'); 
            end;
        end
    end
case 'Choose File' % choose file
    vars = cellstr(spm_select(Inf,'any',['Select file for ' varnam],vars));
case 'Choose Directory' % choose dir
    vars = cellstr(spm_select(Inf,'dir',['Select directory for ' varnam],vars));
case 'Function' % function
    fp = funpass(struct,'sa'); fp.idx = 1; 
    fp = auto_function([],fp); 
    if strcmp(fp.vars{1},'varargout'), 
        fp.outchc{1} = str2double(cell2mat(inputdlg('Enter index of varargout:','Index',1,{'1'})));
    end
    vars = arrayfun(@(x)fp.output{x,fp.outchc{1}},1:numel(fp.output));
    clear fp; 
case 'Subject Array' % subject array
    % choose group
    if ~isempty(subrun),
    grp = questdlg(['Choose group or individual for ' varnam '?'],varnam,'Group','Individual','Individual');
    else % set to group if empty
    grp = 'Group';
    end
    % get subrun
    if strcmp(grp,'Group'), 
    subrun = sawa_subrun(sa,[],subrun);
    end
    % choose fields
    vars = choose_fields(sa,subrun,['Choose field(s) for ' varnam]);
    subvars = cell2mat(inputdlg('Enter subfolder, files, etc.'));
    % strcat
    if strcmp(grp,'Individual')
    vars = strcat('sa(i).',vars,subvars);
    else % group (only one field can be returned)
    for v = 1:numel(vars)
        vars{v} = strcat('sa(', arrayfun(@(x){num2str(x)},subrun),').',vars{v},subvars)'; 
    end
    end
case funcs % functions 
    % find choice relative to functions
    r = c - (numel(choices)-numel(funcs));
    % get outargs from vars
    outargs = varargin{end}(r,:);
    outargs(cellfun('isempty',outargs)) = []; 
    if isempty(outargs), return; end;
    % choose outargs
    v = listdlg('PromptString',{['Choose output from ' choices{c}],''},'ListString',outargs);
    if isempty(v), return; end;
    % strcat
    vars = strcat('evalin(''caller'',','''output{',num2str(r),',',arrayfun(@(x){num2str(x)},v),'}{end}'');');
end
if iscell(vars)&&size(vars,2) > size(vars,1), vars = vars'; end; % if horizontal
% vertcat
vals = cat(1,vals,vars);
if iscell(vals)&&numel(vals) == 1, vals = vals{1}; end; % if one cell
end