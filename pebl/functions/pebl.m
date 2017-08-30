function params = pebl(cmd, varargin)
% params = pebl(cmd, varargin)
% pebl allows users create a pipeline of functions using matlab,
% command line, or matlabbatch functions.
% 
% Inputs:
% cmd - string/cellstr commands (default is 'load_editor'). 
% see below for supported commands.
% varargin - input parameters for cmd (default is parameters structure).
%
% Outputs:
% params - parameter structure containing following fields:
%   funcs - cell array of functions to use
%   options - cell array of options corresponding to each function
%   outputs - cell array of outputs from functions
%
% Example:
% params = pebl('add_function', [], 1, @disp);
% params = pebl('set_options', params, 1, {'test'});
% params = pebl('set_iter', params, 'loop', 3);
% params = pebl('run_params', params)
% 
% params = 
% 
%          funcs: {@disp}
%        options: {{1x1 cell}}
%           loop: 3
%        verbose: []
%     print_type: ''
%         output: {{3x1 cell}}
% 
% See pebl_demo for further demos.
%         
% Note the following commands are supported: 'setup', 'study_array',
% 'load_editor', 'set_iter', 'add_path', 'add_function', 'set_options',
% 'get_help', 'print_options', 'load_params', 'save_params', and
% 'run_params'. 
% Type help pebl>subfunction to get help for desired subfunction.
%
% See also: pebl_feval
%
% Created by Justin Theiss

    % init cmd
    if ~exist('cmd','var')||isempty(cmd), 
        cmd = {'load_editor'};
    end
    if ~iscell(cmd), cmd = {cmd}; end;
    % init varargin
    if isempty(varargin), varargin{1} = struct('funcs',{{}},'options',{{}}); end;
    params = varargin{1};
    % run each cmd with varargin
    for x = 1:numel(cmd),
        params = feval(cmd{x}, params, varargin{2:end});
    end
end

% setup path and run tests 
function params = setup(params)
% param = setup(params)
% Sets path for pebl functions directory and runs @pebl_test.

    % set path to mfilename directory
    P = fileparts(mfilename('fullpath'));
    if ~any(strfind(path, P)),
        path(path, P); savepath;
    end
    % set path for cfg_ui/cfg_util
    spm_path = fileparts(which('spm'));
    if isempty(spm_path),
        warning('pebl requires spm for matlabbatch use. Errors may occur during tests.');
    elseif ~any(strfind(path,fullfile(spm_path,'matlabbatch')))
        path(path, fullfile(spm_path,'matlabbatch'));
        savepath;
    end
    % msgbox regarding tests
    uiwait(msgbox('Running tests. Please ignore windows that display.', 'Running Tests'));
    % run tests
    pebl_test;
    uiwait(msgbox('Success! See pebl_demo to learn about pebl.'));
end

% load study array
function params = study_array(params, array)
% params = study_array(params, array)
% Load/create study array using @studyarray and add to functions.
% If array is input, sets functions to @deal with options array.
% Otherwise, runs @studyarray.

    % init array
    if ~exist('array','var') || isempty(array),
        array = studyarray;
    end
    params = insert_function(params, 1, @deal);
    params = set_options(params, 1, array);
end

% create editor
function params = load_editor(params)
% params = load_editor(params)
% Loads gui editor for input params. Additionally, runs add_path to set
% environments if 'env' is a field in params.

    % init funcs
    if ~isfield(params,'funcs'), params.funcs = {}; end;
    % set environments if 'env' field
    if isfield(params,'env'), add_path(params,params.env); end;
    % setup structure for make_gui
    s.name = 'pebl';
    [s.push(1:5).string] = deal('add path/environment', 'study array',...
        'iterations', 'add function', 'set options');
    [s.push.order] = deal([1,2],[1,3],[1,4],[1,5],[1,6]);
    [s.push.tag] = deal(s.push.string);
    [s.push.callback] = deal(@(x,y)guidata(gcf,add_path(guidata(gcf))),...
        @(x,y)guidata(gcf,study_array(guidata(gcf))),...
        @(x,y)guidata(gcf,set_iter(guidata(gcf))),...
        @(x,y)guidata(gcf,add_function(guidata(gcf))),...
        @(x,y)guidata(gcf,set_options(guidata(gcf))));
    s.popupmenu(1).string = {'print options','verbose output','quiet output',...
        'save output'};
    s.popupmenu(2).string = {'load','save','run'};
    s.popupmenu(1).callback = @(x,y)switchcase(get(x,'value'),...
        1, @()guidata(gcf,print_options(guidata(gcf),'print_type','current')),...
        2, @()guidata(gcf,print_options(guidata(gcf),'print_type','on')),...
        3, @()guidata(gcf,print_options(guidata(gcf),'print_type','off')),...
        4, @()guidata(gcf,print_options(guidata(gcf),'print_type','diary')),...
        'nargout_n', 0);
    s.popupmenu(2).callback = @(x,y)switchcase(get(x,'value'),...
        1, @()guidata(gcf,load_params(guidata(gcf))),...
        2, @()guidata(gcf,save_params(guidata(gcf))),...
        3, @()guidata(gcf,run_params(guidata(gcf))), 'nargout_n', 0);
    s.popupmenu(1).order = [1,7];
    s.popupmenu(2).order = [2,7];
    btn_callback = @(x,y)guidata(gcf,listbox_callback(guidata(gcf),gcf,x));
    s.listbox = struct('order',[2,6],'tag','function_list',...
        'size',[150,150],'callback',btn_callback,...
        'buttondownfcn',btn_callback);
    % make funcs as str
    s.listbox.string = local_getfunctions(params.funcs); 
    % make_gui
    params = struct2gui(s, 'data', params); 
end

% update editor
function params = update_editor(params)
% params = update_editor(params)
% Updates gui editor with current params

    % get functions
    struct2var(params,{'funcs','idx'});
    if ~exist('funcs','var'), funcs = {}; end;
    if ~exist('idx','var'), idx = numel(funcs); end;
    if idx == 0, idx = 1; end;
    % remove function_list from params
    if isfield(params,'function_list'), 
        params = rmfield(params,'function_list'); 
    end;
    % find editor
    h = findobj('tag','function_list'); 
    if isempty(h), return; end;
    % get funcs as str
    funcs = local_getfunctions(funcs); 
    set(h(1),'value',min(numel(funcs),idx));
    % set listbox
    set(h(1),'string',funcs(:));
    % set idx
    params = struct2var(params,'idx');
end

% local make function name string
function funcs = local_getfunctions(funcs)
% funcs = local_getfunctions(funcs)
% Creates a cell array of functions as strings (to be used in gui listbox)

    % make funcs cellstr
    for x = 1:numel(funcs),
        if isa(funcs{x},'function_handle'),
            funcs{x} = ['@', func2str(funcs{x})];
        elseif iscell(funcs{x}) || isstruct(funcs{x}),
            funcs{x} = 'matlabbatch'; 
        end
    end
end

% local get options
function opts = local_getoptions(func, options, type)
% opts = local_getoptions(func, options, type)
% Get current options as cell array of strings for @set_options. 
% Type can be either 'current' or 'add', which will return the options
% for current options or options that can be added, respectively.
    
    % init type
    if ~exist('type','var'), type = 'current'; end;
    if ~iscell(options), options = {}; end;
    % switch function class
    switch class(func)
        case 'function_handle' % function
            [~, opts0] = getargs(func);
            if isempty(opts0), opts0 = {'varargin'}; end;
            if strcmp(type,'add'),
                opts = opts0(min(end,numel(options)+1):end);
            else % current options
                opts = opts0(1:min(end,numel(options)));
                if ~isempty(opts),
                    opts(end:numel(options)) = opts(end);
                end
            end
        case 'char' % system
            [~, opts0] = cmd_help(func);
            if strcmp(type,'add'),
                opts = [opts0, 'new parameter'];
            else % current options
                opts = options;
                opts(~cellfun('isclass',opts,'char')) = {'parameter'};
                opts(~ismember(opts,opts0)) = {'parameter'};
            end
        case {'cell','struct'} % matlabbatch
            % set current options
            opts = options;
            opts(2:2:end) = {'parameter'};
            for y = 1:2:numel(opts), 
                opts{y} = options{y}; 
                if isstruct(opts{y}), % set to last 3 subs
                    opts{y} = sub2str(opts{y}(max(end-2,1):end)); 
                elseif iscell(opts{y}),
                    opts{y} = opts{y}(cellfun('isclass',opts{y},'char'));
                    opts{y} = sprintf('%s ', opts{y}{:});
                end
            end
            if strcmp(type,'add'),
                opts = [opts,'new parameter'];
            end
        otherwise % return empty
            opts = {};
    end
end

% listbox callback
function params = listbox_callback(params, fig, x)
% params = listbox_callback(params, fig, x)
% Callback for right-clicking on a function in the gui listbox.
% Options after right-click are copy, delete, edit, help, or insert.

    % get idx
    idx = get(x, 'value');
    if isempty(idx), return; end;
    % if right click
    if strcmp(get(fig,'selectiontype'),'alt'),
        % choose options
        chc = listdlg('PromptString','Choose option:','ListString',...
            {'copy','delete','edit','help','insert','move'},...
            'SelectionMode','single');
        if isempty(chc), return; end; 
        % switch option
        switch chc
            case 1 % copy
                to_idx = str2double(cell2mat(inputdlg('Enter index to copy to')));
                params = copy_function(params, idx, to_idx);
            case 2 % delete
                params = delete_function(params, idx);
            case 3 % edit
                params = add_function(params, idx);
            case 4 % help
                helpstr = get_help(params.funcs, idx);
                disp(helpstr{idx});
            case 5 % insert
                params = insert_function(params, idx);
        end
    end
    % set idx to params
    params = struct2var(params, 'idx');
    % update params
    params = update_editor(params);
end

% copy function
function params = copy_function(params, idx, to_idx)
% params = copy_function(params, idx, to_idx)
% Copy function at idx to end of function list
% If no idx, idx is set to 1
% If no to_idx, to_idx is set to numel(funcs) + 1
    
    % init idx
    if ~exist('idx','var')||isempty(idx), idx = 1; end;
    if ~exist('to_idx','var')||isempty(to_idx)||isnan(to_idx), 
        to_idx = numel(params.funcs)+1; 
    end
    % copy func and options
    params.funcs = pebl_insert(2, params.funcs, to_idx, params.funcs(idx));
    params.options = pebl_insert(2, params.options, to_idx, params.options(idx));
    params.idx = max(1, min(numel(params.funcs), to_idx));
end

% delete function
function params = delete_function(params, idx)
% params = delete_function(params, idx)
% Delete function at idx 
% If no idx, idx is set to 1
    
    % init idx
    if ~exist('idx','var')||isempty(idx), idx = 1; end;
    % delete func and options
    params.funcs(idx) = [];
    params.options(idx) = [];
    params.idx = numel(params.funcs);
end

% insert function
function params = insert_function(params, idx, func)
% params = insert_function(params, idx, func)
% Insert function before idx
% If no idx, idx is set to 1
% If no func, function is input via inputdlg

    % init idx
    if ~exist('idx','var')||isempty(idx), idx = 1; end;
    params.funcs = pebl_insert(2, params.funcs, idx, {{}});
    params.options = pebl_insert(2, params.options, idx, {{}});
    if ~exist('func','var')||isempty(func),
        params = add_function(params, idx);
    else
        params = add_function(params, idx, func);
    end
    if isempty(params.funcs{idx}),
        params = delete_function(params, idx);
    end
end

% set iterations
function params = set_iter(params, fields, values)
% params = set_iter(params, field, value)
% Set the number of iterations for @pebl_feval
% Possible fields to set: 'loop', 'seq', 'iter'
% Default values for corresponding fields: 1, [], []
% The cells in 'values' should correspond to the cells in 'fields'

    % load iter if not input
    if nargin == 1,
        % set default fields, values
        fields = {'loop', 'seq', 'iter'};
        values = {1, [], []};
        % set values if in params
        for x = 1:numel(fields),
            if isfield(params, fields{x}),
                values{x} = params.(fields{x});
            end
        end
        % choose fields
        chc = listdlg('PromptString',{'Choose @pebl_feval field(s) to set',''},...
                      'ListString',fields);
        % set fields
        for x = chc,
            % set value
            params.(fields{x}) = eval(cell2mat(inputdlg(['Input value for ' fields{x}],...
                                      fields{x}, 1, {genstr(values{x})})));
        end
    else % set fields
        if ~iscell(fields), fields = {fields}; end;
        if ~iscell(values), values = {values}; end;
        for x = 1:numel(fields),
            params.(fields{x}) = values{x};
        end
    end
end

% set environments
function params = add_path(params, env_func, P)
% params = add_path(params, env_func, P) 
% Add a path or set environmental variable as feval(env_func, P{:}).
% If no env_func, choose from @addpath, @setenv, @rmpath, or enter with
% @inputdlg. 
% If no P, set using @pebl_input.
% A new field, 'env', will be set to params as a cell containing the
% function and path/etc. as {env_func, P{:}}, which will be used the next
% time params are loaded using @load_editor.

    % if env_func iscell, assume 'env'
    if nargin==2 && iscell(env_func),
        for x = 1:numel(env_func),
            feval(env_func{x}{:});
        end
        return;
    end
    % init env_func
    if ~exist('env_func','var')||isempty(env_func), 
        % choose function to use
        liststr = {'addpath','setenv','rmpath','other'};
        chc = listdlg('PromptString',{'Choose function to add/remove path:',''},...
            'ListString',liststr,'SelectionMode','single');
        if isempty(chc), return; else env_func = liststr{chc}; end;
        % set other function
        if strcmp(env_func,'other'), env_func = cell2mat(inputdlg('Enter function to use:')); end;
    end;
    if isa(env_func,'function_handle'), env_func = func2str(env_func); end;
    % setenv input
    if strcmp(env_func, 'setenv') && ~exist('P','var'),
        P{1} = cell2mat(inputdlg('Enter environment name to set','Name',1,{'PATH'}));
        P{2} = pebl_input('variable',[env_func ' input']);
    elseif ~exist('P','var')||isempty(P), % normal input
        P{1} = pebl_input('variable',[env_func ' input']);
    end
    % feval env_func, P
    feval(env_func, P{:});
    % set to params
    struct2var(params, 'env');
    if ~exist('env','var'), env = {}; end;
    env{end+1} = {env_func, P{:}};
    params = struct2var(params, 'env');
end

% add function
function params = add_function(params, idx, func)
% params = add_function(params, idx, func)
% Add a function to use at the index position idx.
% func - function to add (e.g., @function, command, or matlabbatch)
% Function will be entered using @inputdlg. If matlabbatch is entered,
% @pebl_setbatch will be called.
% If no idx, idx = numel(funcs) + 1.

    % load params
    struct2var(params,{'funcs','options'});
    % init funcs
    if ~exist('funcs','var') || isempty(funcs), funcs = {}; end;
    if ~iscell(funcs), funcs = {funcs}; end;
    % init options
    if ~exist('options','var') || isempty(options), options = {}; end;
    if ~iscell(options), options = {options}; end;
    % init idx
    if ~exist('idx','var') || isempty(idx), idx = numel(funcs) + 1; end;
    % init strfuncs
    strfuncs = local_getfunctions(funcs);
    % for each idx, set function
    for x = idx,
        if x > numel(strfuncs), strfuncs{x} = ''; end;
        % input function
        if nargin < 3,
            func = cell2mat(inputdlg('Enter @function, command, or matlabbatch:',...
                '',1,strfuncs(idx)));
        end
        if isempty(func), return; end;
        % init funcs/options
        if idx > numel(funcs), funcs{idx} = []; end;
        if idx > numel(options), options{idx} = {}; end;
        % switch type
        if strncmp(func,'@',1), % matlab function
            funcs{idx} = eval(func);
        elseif strcmp(func,'matlabbatch'), % matlabbatch
            % load matlabbatch
            [funcs{idx}, options{idx}] = pebl_setbatch(funcs{idx}, options{idx});
        else % command
            funcs{idx} = func;
        end
    end
    % load funcs and options to params
    params = struct2var(params,{'funcs','options'}); 
    % update editor
    params = update_editor(params);
end

% set options
function params = set_options(params, idx, option)
% params = set_options(params, idx, option)
% Set the options for function at index idx.
% Options will be set using @pebl_input.

    % load params
    struct2var(params,{'funcs','options'});
    % init vars
    if ~exist('funcs','var')||isempty(funcs), return; end;
    if ~exist('idx','var')||isempty(idx),
        if nargin == 1 && isfield(params,'idx'), 
            idx = params.idx;
        else 
            idx = numel(funcs); 
        end
    end
    % get string funcs
    strfuncs = local_getfunctions(funcs);
    % for each idx, set options
    for x = idx,
        % if option input, set options{x}
        if nargin==3, options{x} = option; continue; end;
        done = false;
        while ~done,
            % get current options
            if ~iscell(options{x}), options{x} = options(x); end;
            option = local_getoptions(funcs{x},options{x},'current');
            % choose args to edit
            chc = listdlg('PromptString','Choose options to edit:',...
                'ListString',[option(:);'add';'remove']);
            if isempty(chc), % cancel
                return; 
            elseif any(chc==numel(option)+1), % add
                option = local_getoptions(funcs{x},options{x},'add');
                chc = listdlg('PromptString','Choose options to add:','ListString',option);
                prechc = chc;
                if isa(funcs{x},'function_handle'), % matlab function
                    chc = numel(options{x})+chc;
                else % cmd or matlabbatch
                    chc = numel(options{x})+(1:numel(chc));
                end
                option(chc) = option(prechc);
            elseif any(chc==numel(option)+2), % remove
                chc = listdlg('PromptString','Choose options to remove:','ListString',option);
                options{x}(chc) = [];
                chc = []; % skip adding options
            end
            % for each choice, create vars
            for y = chc,
                if y > numel(options{x}), 
                    options{x}{y} = option{y};
                end
                if strcmp(strfuncs{x}, '@matlabbatch'),
                    batch = funcs{x}; % set batch option
                else
                    batch = {};
                end
                options{x}{y} = pebl_input('variable',option{y},'value',options{x}{y},...
                                           'func',strfuncs(1:x-1),'batch',batch); 
            end
            % ask continue
            done = strcmp(questdlg('Add new variable?','New variable','Yes','No','No'),'No');
        end
    end
    % set options to params
    params = struct2var(params,'options');
    % update editor
    params = update_editor(params);
end

% get helpstring
function helpstr = get_help(funcs, idx)
% helpstr = get_help(funcs, idx)
% Get the help documentation for function at index idx.
% If no idx, documentation for each function in funcs will be returned.

    % init funcs
    if ~exist('funcs','var') || isempty(funcs), funcs = {}; end;
    if ~iscell(funcs), funcs = {funcs}; end;
    % init idx
    if ~exist('idx','var') || isempty(idx), idx = 1:numel(funcs); end;
    % init helpstring
    helpstr = cell(size(idx));
    % for each idx, get helpstring
    for x = idx,
        % switch class
        switch class(funcs{x})
            case 'function_handle' % help
                helpstr{x} = help(func2str(funcs{x}));
            case 'char' % command -h
                helpstr{x} = cmd_help(funcs{x});
            case {'cell','struct'} % cfg_util('showdoc'...)
                if ~iscell(funcs{x}), funcs{x} = funcs(x); end;
                helpstr{x} = '';
                cfg_util('initcfg');
                [job, mods] = cfg_util('initjob', funcs{x});
                for n = 1:numel(mods),
                    tagstr = cfg_util('harvest', job, mods{n});
                    [~,~,rep] = pebl_getfield(funcs{x}{n}, 'expr', ['.*', tagstr]);
                    tmpstr = cfg_util('showdocwidth', 70, rep{1}(2:end));
                    helpstr{x} = char(helpstr{x}, tmpstr{:});
                end
        end
    end
end

% load params
function params = load_params(params, file)
% params = load_params(params, file)
% Load paramters from .mat file.
% If no file input, choose using @uigetfile.

    % uigetfile if no file
    if ~exist('file','var'),
        % choose params file
        [pfile,ppath] = uigetfile('*.mat','load parameters file');
        if any(pfile) == 0, return; end;
        file = fullfile(ppath,pfile);
    end
    % load params
    load(file, 'params');
    if ~exist('params','var'), params = []; end;
    % set environments
    if isfield(params,'env'), add_path(params, params.env); end;
    % update editor
    params = update_editor(params);
end

% save params
function params = save_params(params, file)
% params = save_params(params, file)
% Save paramters to .mat file.
% If no file input, choose using @uiputfile.

    % uigetfile if no file
    if ~exist('file','var'), 
        % choose params file
        [pfile,ppath] = uiputfile('*.mat','save parameters file');
        if any(pfile) == 0, return; end;
        file = fullfile(ppath,pfile);
    end
    % save params
    if ~exist('params','var'), params = []; end;
    save(file, 'params');
    % update editor
    params = update_editor(params);
end

% print outputs
function params = print_options(params, varargin)
% params = print_options(params, 'option1', 'value1', ...)
% Set verbose_arg or use diary to record subsequent command window text to
% a filename. If print_type = 'diary' and no print_file, print_file will be
% set to 'pebl_diary.txt'.
%
% options:
% 'print_type' - 'current' (prints current options), 'diary' (save all outputs),
%   'off' (no outputs)
% 'print_file' - if 'diary' print_type, set file to save output 
% 'verbose' - directly set verbose to true (print_type 'on') or false 
%   (print_type 'off')

    % load print_type
    if isempty(varargin),
        struct2var(params,{'print_type','print_file'});
        % init verbose_arg
        verbose = [];
    else % set from varargin
        arrayfun(@(x)assignin('caller',varargin{x},varargin{x+1}),1:2:numel(varargin)-1);
    end
    % init print_type
    if ~exist('print_type','var'), print_type = ''; end;
    % switch print_type
    switch print_type
        case 'current' % print current funcs and options
            for n = 1:numel(params.funcs),
                disp(cell2strtable([params.funcs(n), params.options{n}],'\t'));
            end
        case 'diary' % use diary
            if nargout > 0 || ~exist('print_file','var'), 
                % set diary on with filename
                if ~exist('print_file','var'), 
                    print_file = sprintf('%s_%.2d_%.2d_output.txt', date,...
                        subsref(clock, substruct('()',{4:5}))); 
                end
                diary(print_file);
            else % turn diary off
                diary('off');
                disp(['Outputs saved in: ' print_file]);
            end
            verbose = true;
        case 'on' % set verbose to true
            verbose = true;
        case 'off' % set verbose to false
            verbose = false;
        otherwise % if set directly
            struct2var(params, 'verbose');
    end 
    % set verbose_arg to params
    params = struct2var(params,{'verbose','print_type','print_file'});
end

% run functions
function params = run_params(params)
% params = run_params(params)
% Run parameters using @pebl_feval after evaluating any study array
% variables in options using @pebl_eval and setting print options with
% @print_options.
%
% Available options (fields of params):
% funcs - cell array of functions to be run 
%   [default {}]
% options - cell array of options corresponding to functions (e.g.,
%   options{1} for funcs{1}) 
% other inputs for pebl_feval (see @pebl_feval for more information)
%
% Outputs (field of params):
% output - cell array of outputs from each function call organized as
%   output{func}{iter/loop, n_out}

    % load funcs, options
    struct2var(params, {'funcs','options'});
    % init vars
    if ~exist('funcs','var'), return; end;
    if ~exist('options','var'), options = {}; end;
    % print outputs as selected, return verbose
    params = print_options(params); 
    % get args
    f = fieldnames(params)'; c = struct2cell(params)';
    n_idx = ~ismember(f, {'funcs','options'});
    args = cat(1, f(n_idx), c(n_idx));
    try
        % run pebl_feval
        output = pebl_feval(funcs, options{:}, args{:});
    catch err
        disp(['fatal error: ', err.message]);
    end
    % set outputs to params
    params = struct2var(params, 'output');
    % finish printing outputs
    print_options(params);
end