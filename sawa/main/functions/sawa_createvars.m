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
choices = {'String','Number','Evaluate','Cell','Structure','Choose File','Choose Directory','Function','Subject Array'};
if isempty(sa), choices = choices(1:end-1); end;

% get varargin class for defaults
if numel(varargin) > 0, 
% get functions to add to choices
funcs = varargin(strncmp(varargin,'@',1)); 
choices = horzcat(choices,funcs{:});

% set defaults based on class
switch class(varargin{1})
    case 'cell' % if not cellstr, set iv to 2
        if numel(varargin{1})==1&&~isempty(varargin{1}{1}), % single cell
            varargin{1} = varargin{1}{1}; ival = 4; 
        elseif iscellstr(varargin{1})&&~isempty(varargin{1}), % cellstr 
            vars = varargin{1}; ival = 1; 
        end;
    case 'char' % set char to cellstr
        vars = cellstr(varargin{1}); ival = 1;
    case 'double' % if double, num2str
        vars = {num2str(varargin{1})}; ival = 2;
    case 'struct' % if struct
        vars = varargin{1}; ival = 5;
    case 'function_handle' % if function_handle, set to choices
        funcs = cellfun(@(x){['@' func2str(x)]},varargin);
        choices = horzcat(choices,funcs{:});
    otherwise % otherwise set default without iv
        vars = varargin{1};
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
    if ~iscellstr(vars)&&~ischar(vars), vars = []; end;
    vars = cell2mat(inputdlg(['Set ' varnam],varnam,[max(numel(vars),2),50],{char(vars)}));
    if isempty(vars), vars = {}; return; end;
    vars = strtrim(arrayfun(@(x){vars(x,:)},1:size(vars,1)));
    if c > 1 % number or evaluate
        vars = cellfun(@(x){eval(['[' x ']'])},vars);
    end
case 'Cell' % cell
    vars = sawa_createvars(varnam,msg,subrun,sa,varargin{:});
    vals = cat(1,vals,{vars}); continue;
case 'Structure' % struct
    if isstruct(vars), substr = vertcat(fieldnames(vars),'Add'); else vars = struct; substr = {'Add'}; end;
    done = 0; 
    while ~done
        % choose fields to edit, add, delete
        subchc = listdlg('PromptString',{['Add/Edit subfields for ' varnam ' (cancel when finished):'],'',''},...
            'ListString',substr,'selectionmode','single');
        if isempty(subchc), done = 1; break; end;
        if subchc == numel(substr), tmpfld = ''; else tmpfld = substr{subchc}; end;
        % set field
        fld = cell2mat(inputdlg('Enter field name to add to structure (cancel to delete):','Field Name',1,{tmpfld}));
        if isempty(fld)&&~isempty(tmpfld), vars = rmfield(vars,substr{subchc}); substr(subchc) = []; continue; end; % if no fld, remove
        % run sawa_createvars
        if ~isempty(fld), 
            if isfield(vars,fld), varargin{1} = vars.(fld); else varargin{1} = {}; end;
            vars.(fld) = sawa_createvars(fld,'',subrun,sa,varargin{:}); 
            substr = vertcat(fieldnames(vars),'Add'); 
        end;
    end
case 'Choose File' % choose file
    vars = cellstr(spm_select(Inf,'any',['Select file for ' varnam],vars));
case 'Choose Directory' % choose dir
    vars = cellstr(spm_select(Inf,'dir',['Select directory for ' varnam],vars));
case 'Function' % function
    fp = funpass(struct,'sa'); 
    fp = auto_function([],fp); vars = [fp.output{:}]; clear fp; 
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
    vars = strcat('sa(', arrayfun(@(x){num2str(x)},subrun),').',vars{1},subvars)'; 
    end
case funcs % functions 
    % find choice relative to functions
    n = find(find(strncmp(choices,'@',1))==c); 
    % get only char varargins
    tmpvars = varargin(cellfun('isclass',varargin,'char'));
    % find relative idx
    r = subsref(find(strncmp(tmpvars,'@',1)),struct('type',{'()'},'subs',{{n}}));
    % get outargs
    outargs = getargs(choices{c});
    if isempty(outargs), outargs = {'varargout'}; end;
    % choose outargs
    v = listdlg('PromptString',{['Choose output from ' choices{c}],''},'ListString',outargs);
    if isempty(v), return; end;
    % strcat
    vars = strcat('evalin(''caller'',','''output{i}{',num2str(r),',',arrayfun(@(x){num2str(x)},v),'}'');');
end
if iscell(vars)&&size(vars,2) > size(vars,1), vars = vars'; end; % if horizontal
% vertcat
vals = cat(1,vals,vars);
if iscell(vals)&&numel(vals) == 1, vals = vals{1}; end; % if one cell
end

