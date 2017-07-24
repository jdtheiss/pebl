function output = pebl_input(varargin)
% output = pebl_input('parameter1',value1,...)
% Creates variables with user interface
% 
% Inputs:
% 'variable' - variable name that is being output
%   [default 'output']
% 'title' - title for input dialogs 
%   [default '']
% 'msg' - optional string message to display in listdlg
%   [default sprintf('Choose method to set %s', variable)]
% 'func' - previous functions to use output (must be string and begin with '@')
%   [default {}]
% 'value' - default value 
%   [default {}]
% 'options' - options for setting output
%   [default {'String','Number','Evaluate','Index','Structure','Choose File',...
%     'Choose Directory','Function','Workspace Variable','Study Array'}]
% 'iter' - numeric array of subjects to use (optional)
%   [default []]
% 'array' - study array (optional)
%   [default {}]
% 
% Outputs:
% output - variable returned
%
% Example:
% output = pebl_input('variable','a','title','Set variable: a','func',...
%                    {'@disp','@minus'}, 'value', 10)
% [select @minus]
% [select OK]
% 
% output = 
% 
%     @()'output{2}{end,1}'
%
% Created by Justin Theiss

% init vars
cellfun(@(x,y)assignin('caller',x,y), varargin(1:2:end), varargin(2:2:end));
output = {};

% set options
inputs = {'variable','title','msg','func','value','options','iter','array'};
for x = 1:numel(inputs),
    if ~exist(inputs{x}, 'var'),
        switch inputs{x},
            case 'variable'
                variable = 'output';
            case 'title'
                title = '';
            case 'msg'
                msg = sprintf('Choose method to set %s', variable);
            case 'func'
                func = {};
            case 'value'
                value = [];
            case 'options'
                options = {'String','Number','Evaluate','Index','Structure',...
                           'Choose File','Choose Directory','Function',...
                           'Workspace Variable','Study Array'};
            case 'iter'
                iter = [];
            case 'array'
                array = {};
        end
    end
end

% add functions
options = cat(2, options, func);

% set defaults based on class
try
    switch class(value)
        case 'cell' % if cellstr, set to 1
            if iscellstr(value)&&~isempty(value), % cellstr 
                if size(value, 1) > 1, % set to string
                    ival = find(strcmpi(options,'string'),1); 
                else % set to evaluate, genstr
                    value = genstr(value);
                    ival = find(strcmpi(options,'evaluate'),1);
                end
            elseif all(cellfun(@(x)iscell(x)||isstruct(x),value)) % all cell/struct
                ival = find(strcmpi(options,'index'),1); % set to index
            elseif ~isempty(value) % otherwise, set to number
                ival = find(strcmpi(options,'number'),1);
            end
        case 'char' % set char to cellstr
            value = cellstr(value); ival = find(strcmpi(options,'string'),1);
        case 'double' % if double, num2str
            if isempty(value), 
                ival = find(strcmpi(options,'string'),1); 
            else
                ival = find(strcmpi(options,'number'),1);
            end
            value = {num2str(value)};
        case 'function_handle' % function handle should go to number
            ival = find(strcmpi(options,'number'),1);
        case 'struct' % if struct
            ival = find(strcmpi(options,'structure'),1);
        otherwise % default to string
            ival = find(strcmpi(options,'string'),1);
    end
catch err % if error, set ival to string
    ival = find(strcmpi(options,'string'),1);
    disp(['error:', err.message]);
end

% if cellstr, check for evals/files/dirs
if iscellstr(value)&&~isempty(value), 
    if all(cellfun(@(x)exist(x,'file'),value)), % if files
        ival = find(strcmpi(options,'choose file'),1); 
    end
    if all(cellfun(@(x)isdir(x),value)), % if dir
        ival = find(strcmpi(options,'choose directory'),1);
    end
end

% choose method for invars
chc = listdlg('Name',title,'PromptString',{msg,'',''},'ListString',options,...
              'InitialValue',ival); 
if isempty(chc), return; end; 

for c = chc
    % set based on choice
    switch options{c}
        case {'String','Number','Evaluate'} % input
            if ~iscell(value)||isempty(value), value = {value}; end;
            if all(cellfun('isempty',value)), value = {''}; end;
            n_rows = numel(value);
            if ~iscellstr(value), value = genstr(value{:}); end;
            value = cell2mat(inputdlg(['Set ', variable],title,...
                            [max(n_rows,2),50],{char(value)}));
            if isempty(value), output = {}; return; end;
            value = arrayfun(@(x){value(x,:)},1:size(value,1));
            % number or evaluate
            if any(strcmpi({'number','evaluate'},options{c})), 
                % if @, convert to function handle
                value(strncmp(value,'@',1)) = cellfun(@(x){str2func(x)},...
                                                value(strncmp(value,'@',1)));
                % if string, evaluate
                value(cellfun(@(x)ischar(x),value)) = cellfun(@(x){eval(['[' x ']'])},...
                                                        value(cellfun(@(x)ischar(x),value)));
            end
        case 'Index' % index
            if ival==find(strcmpi(options,'index'),1), 
                [~,~,rep]=pebl_getfield(value,'r',1); 
            end
            ind = '{1}'; 
            while ~isempty(ind), % set index
                if ival==find(strcmpi(options,'index'),1)&&~isempty(rep), 
                    ind = rep{1}; rep(1)=[]; % get input index
                end
                ind = cell2mat(inputdlg('Enter index to set (e.g., {1,1} or (2)). Cancel when done.',...
                    'Index',1,{ind}));
                if isempty(ind), break; end;
                s = sub2str(ind); % create s var for subsasgn
                if ival==find(strcmpi(options,'index'),1), 
                    try value = subsref(value,s); end; % set value
                end
                value = subsasgn(value,s,pebl_input(varargin{:}));
            end
        case 'Structure' % struct
            if isstruct(value), % if exists, choose component to edit
                substr = vertcat(fieldnames(value),'Add'); 
                n = listdlg('PromptString','Choose component to edit:','ListString',...
                [arrayfun(@(x){num2str(x)},1:numel(value)),'Add']);
                if isempty(n), return; end;
                if any(n > numel(value)), 
                    value(n(end)) = cell2struct(cell(size(fieldnames(value))),fieldnames(value)); 
                end
            else % if new, create struct
                n = cell2mat(inputdlg('Enter number of components to create'));
                n = 1:str2double(n); if isnan(n), return; end;
                value = repmat(struct,1,max(n)); substr = {'Add'};
            end;
            % for each component
            for n = n
                done = 0; 
                while ~done
                    % choose fields to edit, add, delete
                    subchc = listdlg('PromptString',{['Add/Edit subfields for '...
                        variable '(' num2str(n) ') (cancel when finished):'],'',''},...
                        'ListString',substr,'selectionmode','single');
                    if isempty(subchc), done = 1; break; end;
                    if subchc == numel(substr), tmpfld = ''; else tmpfld = substr{subchc}; end;
                    % set field
                    fld = cell2mat(inputdlg('Enter field name to add (cancel to delete):',...
                        'Field Name',1,{tmpfld}));
                    if isempty(fld)&&~isempty(tmpfld), % if no fld, remove
                        value = rmfield(value,substr{subchc}); 
                        substr(subchc) = []; 
                        continue;
                    end
                    % run pebl_input
                    if ~isempty(fld), 
                        if isfield(value(n),fld), tmpvalue = value(n).(fld); else tmpvalue = {}; end;
                        value(n).(fld) = pebl_input(varargin{:},'value',tmpvalue); 
                        substr = vertcat(fieldnames(value),'Add'); 
                    end
                end
            end
        case 'Choose File' % choose file
            if exist('spm_select','file'),
                value = cellstr(spm_select(Inf,'any',['Select file for ' variable],value)); 
            else % no spm_select
                try value = cellstr(uigetfile('*.*',['Select file for ' variable],'MultiSelect','on')); end;
            end
        case 'Choose Directory' % choose dir
            if exist('spm_select','file'),
                value = cellstr(spm_select(Inf,'dir',['Select directory for ' variable],value));
            else % no spm_select
                done = 0; value = {};
                while ~done
                    value{end+1} = uigetdir(cd,['Select directory for ' variable]);
                    if ~ischar(value{end}), value(end) = []; done = 1; break; end;
                end
            end 
        case 'Function' % function
            params = pebl({'add_function','set_options','run_params'},...
                struct('array',array,'iter',iter,'verbose_arg',false));
            value = params.outputs{1};
            clear params;
        case 'Workspace Variable' % workspace variable
            variable = cell2mat(inputdlg('Enter variable name from base workspace:'));
            if evalin('base',sprintf('exist(''%s'',''var'')',variable)), % check for variable
                value = evalin('base',variable); % evaluate
            else % display that it does not exist
                disp([variable ' does not exist in the base workspace.']);
            end
        case 'Study Array' % study array
            % choose group
            if ~isempty(iter),
                grp = questdlg(['Choose group or individual for ' variable '?'],...
                    title,'Group','Individual','Individual');
            else % set to group if empty
                grp = 'Group';
            end
            % get iter
            if strcmp(grp,'Group'), 
                iter = pebl_subjs(sa,iter);
            end
            % choose fields
            vars = choose_fields(sa,iter,['Choose field(s) for ' variable]);
            subvalue = cell2mat(inputdlg('Enter subfolder, files, etc.'));
            % strcat
            if strcmp(grp,'Individual')
                value = strcat('sa(i).',value,subvars);
            else % group (only one field can be returned)
                for v = 1:numel(value)
                    value{v} = strcat('sa(', arrayfun(@(x){num2str(x)},iter),').',value{v},subvars)'; 
                end
            end
        case func % functions 
            % get relative function position
            if ~iscell(func), func = {func}; end;
            v = num2str(c - (numel(options)-numel(func))); 
            % inputdlg for value{f}{r, c}
            out_fn = cell2mat(inputdlg('Enter output to use:','',1,{['output{',v,'}{end,1}']}));
            if isempty(out_fn), return; end;
            % str2func for use in pebl_feval
            value = str2func(['@()''', out_fn, '''']);
    end
    % if horizontal, set vertical
    if iscell(value)&&size(value,2) > size(value,1), value = value'; end; 
    % vertcat
    output = cat(1,output,value);
    % if one cell, get inner cell
    if iscell(output)&&numel(output)==1&&~any(strcmpi(options(chc),'index')), 
        output = output{1}; 
    end
end
end