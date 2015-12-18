function vals = sawa_createvars(varnam,msg,subrun,sa,varargin)
% vars = sawa_createvars(varnam,msg,subrun,sa,varargin)
% Creates variables for specific use in auto_batch, auto_cmd, auto_function.
% 
% Inputs:
% varnam - variable name 
% msg - optional string message to display in listdlg
% subrun - numeric array of subjects to use (optional)
% sa - subject array (optional)
% varargin - can be default value or previous functions to use output
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
vals = {};

% set choices
choices = {'String','Number','Evaluate','Cell','Structure','Choose File','Choose Directory','Function','Subject Array'};
if isempty(sa), choices = choices(1:end-1); end;

% get varargin class for defaults
if numel(varargin) > 0, 
% set defaults based on class
switch class(varargin{1})
    case 'cell' % if not cellstr, set iv to 2
        if ~iscellstr(varargin{1})&&numel(varargin{1})==1, varargin = varargin{1}; iv = 4; 
        elseif iscellstr(varargin{1}) vars = varargin{1}; iv = 1; end;
    case 'char' % if @, set functions to choices
        if strncmp(varargin{1},'@',1), choices = horzcat(choices,varargin{:});
        else vars = cellstr(varargin{1}); iv = 1; end;
        % if eval
        if strncmp(vars{1},'eval(',5), iv = 3; end;
    case 'double' % if double, num2str
        vars = {num2str(varargin{1})}; iv = 2;
    case 'struct' % if struct
        vars = varargin{1}; iv = 5;
    case 'function_handle' % if function_handle, set to choices
        varargin = cellfun(@(x){['@' func2str(x)]},varargin);
        choices = horzcat(choices,varargin{:});
    otherwise % otherwise set default without iv
        vars = varargin{1};
end     
end

% init default vars
if ~exist('iv','var')||isempty(iv), iv = []; end;
if ~exist('vars','var')||isempty(vars), vars = {}; end;

% choose method for invars
chc = listdlg('PromptString',{['Choose method to set ' varnam ' ' msg],'',''},'ListString',choices,'InitialValue',iv); 
if isempty(chc), vals = vars; return; end; 

% set vars if empty to {''} for inputdlg
if isempty(vars), vars = {''}; end;

for c = chc
% set based on choice
switch lower(choices{c})
case {'string','number','evaluate'} % input
    vars = cell2mat(inputdlg(['Set ' varnam],varnam,2,vars));
    vars = strtrim(arrayfun(@(x){vars(x,:)},1:size(vars,1)));
    if c > 1 % number or evaluate
        vars = cellfun(@(x){eval(['[' x ']'])},vars);
    end
case 'cell' % cell
    vars = sawa_createvars(varnam,msg,subrun,sa,varargin{:});
    vals = cat(1,vals,{vars}); continue;
case 'structure' % struct
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
            if isfield(vars,fld), varargin = {vars.(fld)}; elseif numel(varargin)==1, varargin = {}; end;
            vars.(fld) = sawa_createvars(fld,'',subrun,sa,varargin{:}); 
            substr = vertcat(fieldnames(vars),'Add'); 
        end;
    end
case 'choose file' % choose file
    vars = cellstr(spm_select(Inf,'any',['Select file for ' varnam],vars));
case 'choose directory' % choose dir
    vars = cellstr(spm_select(Inf,'dir',['Select directory for ' varnam],vars));
case 'function' % function
    fp = funpass(struct,'sa'); 
    fp = auto_function([],fp); vars = [fp.output{:}]; clear fp; 
case 'subject array' % subject array
    % choose group
    if ~isempty(subrun)
    grp = questdlg(['Choose group or individual for ' varnam '?'],varnam,'Group','Individual','Individual');
    else % set to group if empty
    grp = 'Group';
    end
    % get subrun
    if strcmp(grp,'Group')
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
case lower(varargin) % functions 
    % find choice in varargin
    n = find(strcmp(varargin,choices{x}),1,'first');
    % get outargs
    outargs = getargs(choices{x});
    if isempty(outargs), outargs = {'varargout'}; end;
    % choose outargs
    v = listdlg('PromptString',['Choose output from ' choices{x}],'ListString',outargs);
    if isempty(v), return; end;
    % strcat
    vars = strcat('evalin(''caller'',','''output{i}{', num2str(n),',',arrayfun(@(x){num2str(x)},v),'}'');');
end
if iscell(vars)&&size(vars,2) > size(vars,1), vars = vars'; end; % if horizontal
% vertcat
vals = cat(1,vals,vars);
if iscell(vals)&&numel(vals) == 1, vals = vals{1}; end; % if one cell
end

