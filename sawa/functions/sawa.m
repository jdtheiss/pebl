function params = sawa(cmd, varargin)
% params = sawa(cmd, varargin)
% sawa allows users create a pipeline of functions using matlab,
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
% Example 1: add a function, set the options, and run the function
% params = sawa({'add_function','set_options','run_params'})
% [enter @disp at prompt]
% [choose "varargin"]
% [choose "String"]
% [enter test at prompt]
%
% test
% 
% params = 
% 
%           funcs: {@disp}
%         options: {'test'}
%     verbose_arg: []
%         outputs: {{1x1 cell}}
% 
% Example 2: run parameters from example 1 with verbose on, and save output
% to 'output.txt' 
% params.print_type = 'diary'; 
% params.print_file = 'output.txt';
% params = sawa('run_params', params)
%
% Output will be saved in: output.txt
% @disp test
% test
% 
% test
% 
% params = 
% 
%           funcs: {@disp}
%         options: {'test'}
%     verbose_arg: 1
%         outputs: {{1x1 cell}}
%      print_type: 'diary'
%      print_file: 'output.txt'
%         
% Note the following commands are supported: 'setup', 'set_subjectarray',
% 'load_editor', 'set_iter', 'init_env', 'add_function', 'set_options',
% 'get_docstr', 'load_save_params', 'print_options', and 'run_params'. 
% Type help sawa>subfunction to get help for desired subfunction.
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
% Sets path for sawa functions directory and runs @sawa_test.

    % set path to mfilename directory
    P = fileparts(mfilename('fullpath'));
    if ~any(strfind(path, P)),
        path(path, P);
    end
    % msgbox regarding tests
    uiwait(msgbox('Running tests. Please ignore windows that display.', 'Running Tests'));
    % run tests
    sawa_test;
end

% load subject array
function params = set_subjectarray(params)
% params = set_subjectarray(params)
% Load/create subject array (sa) using @subjectarray.

    % init sa
    sa = subjectarray;
    % set sa to params
    params = struct2var(params,'sa');
end

% create editor
function params = load_editor(params)
% params = load_editor(params)
% Loads gui editor for input params. Additionally, runs init_env to set
% environments if 'env' is a field in params.

    % init funcs
    if ~isfield(params,'funcs'), params.funcs = {}; end;
    % set environments if 'env' field
    if isfield(params,'env'), init_env(params,params.env); end;
    % setup structure for make_gui
    s.name = 'sawa';
    [s.push(1:5).string] = deal('add path/environment', 'subject array',...
        'iterations', 'add function', 'set options');
    [s.push.order] = deal([1,2],[1,3],[1,4],[1,5],[1,6]);
    [s.push.tag] = deal(s.push.string);
    [s.push.callback] = deal(@(x,y)guidata(gcf,init_env(guidata(gcf))),...
        @(x,y)guidata(gcf,set_subjectarray(guidata(gcf))),...
        @(x,y)guidata(gcf,set_iter(guidata(gcf))),...
        @(x,y)guidata(gcf,add_function(guidata(gcf))),...
        @(x,y)guidata(gcf,set_options(guidata(gcf))));
    s.popupmenu(1).string = {'verbose output','quiet output','save output'};
    s.popupmenu(2).string = {'load','save','run'};
    s.popupmenu(1).callback = @(x,y)switchcase(get(x,'value'),...
        1, @()guidata(gcf,print_options(guidata(gcf),'print_type','on')),...
        2, @()guidata(gcf,print_options(guidata(gcf),'print_type','off')),...
        3, @()guidata(gcf,print_options(guidata(gcf),'print_type','diary')),...
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
            funcs{x} = func2str(funcs{x});
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
            {'copy','delete','edit','help','insert'},'SelectionMode','single');
        if isempty(chc), return; end; 
        % switch option
        switch chc
            case 1 % copy
                params.funcs(end+1) = params.funcs(idx);
                params.options(end+1) = params.options(idx);
                idx = numel(params.funcs);
            case 2 % delete
                params.funcs(idx) = [];
                params.options(idx) = [];
                idx = numel(params.funcs);
            case 3 % edit
                params = add_function(params, idx);
            case 4 % help
                docstr = get_docstr(params.funcs, idx);
                disp(docstr{idx});
            case 5 % insert
                params.funcs = sawa_insert(2, params.funcs, idx, {[]});
                params.options = sawa_insert(2, params.options, idx, {[]});
                params = add_function(params, idx);
        end
    end
    % set idx to params
    params = struct2var(params, 'idx');
    % update params
    params = update_editor(params);
end

% set iterations
function params = set_iter(params, iter_args)
% params = set_iter(params, iter_args)
% Set the number of iterations for @sawa_feval
% If no iter_args, 

    % load iter if not input
    if nargin == 1,
        % load iter_args
        struct2var(params, 'iter_args');
        if ~exist('iter_args','var'), iter_args = {}; end;
        % set default fields, values
        fields = {'loop', 'seq', 'iter'};
        values = {1, [], 0};
        % set values if in iter_args
        for x = 1:numel(fields),
            f = find(strcmp(iter_args, fields{x}), 1);
            if f < numel(iter_args),
                values{x} = iter_args{f+1};
            end
        end
        % choose fields
        chc = listdlg('PromptString',{'Choose @sawa_feval field(s) to set',''},...
                      'ListString',fields);
        % set fields
        for x = chc,
            % find place in iter_args
            f = find(strcmp(iter_args, fields{x}), 1);
            if isempty(f), f = numel(iter_args)+1; end;
            % set field
            iter_args{f} = fields{x};
            % set value
            iter_args{f+1} = eval(cell2mat(inputdlg(['Input value for ' fields{x}],...
                             fields{x}, 1, {genstr(values{x})})));
        end
    end
    % set iter to params
    params = struct2var(params, 'iter_args');
end

% set environments
function params = init_env(params, env_func, P)
% params = init_env(params, env_func, P) 
% Add a path or set environmental variable as feval(env_func, P{:}).
% If no env_func, choose from @addpath, @setenv, @rmpath, or enter with
% @inputdlg. 
% If no P, set using @sawa_createvars.
% A new field, 'env', will be set to params as a cell containing the
% function and path/etc. as {env_func, P{:}}, which will be used the next
% time params is loaded using @load_editor.

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
        P{2} = sawa_createvars([env_func ' input']);
    elseif ~exist('P','var')||isempty(P), % normal input
        P{1} = sawa_createvars([env_func ' input']);
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
% func - function to add (e.g., @function, command, or ''matlabbatch'')
% Function will be entered using @inputdlg. If matlabbatch is entered,
% @sawa_setbatch will be called.
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
    % for each idx, set function
    for x = idx,
        % input function
        if nargin < 3,
            func = cell2mat(inputdlg('Enter @function, command, or ''matlabbatch'':'));
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
            [funcs{idx}, options{idx}] = sawa_setbatch(funcs{idx}, options{idx});
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
% Options will be set using @sawa_createvars.

    % load params
    struct2var(params,{'funcs','options','idx','subjs','sa'});
    % init vars
    if ~exist('funcs','var')||isempty(funcs), return; end;
    if ~exist('idx','var')||isempty(idx), idx = 1:numel(funcs); end;
    if ~exist('subjs','var'), subjs = []; end;
    if ~exist('sa','var'), sa = struct; end;
    % get string funcs
    strfuncs = local_getfunctions(funcs);
    strfuncs = strcat('@', strfuncs);
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
                options{x}{y} = sawa_createvars(option{y},'',subjs,sa,options{x}{y},strfuncs{1:x-1}); 
            end
            % if gui, done
            if ~isempty(findobj('type','figure','name','sawa')),
                done = true;
            else % otherwise ask continue
                done = strcmp(questdlg('Add new variable?','New variable','Yes','No','No'),'No');
            end
        end
    end
    % set options to params
    params = struct2var(params,'options');
    % update editor
    params = update_editor(params);
end

% get docstring
function docstr = get_docstr(funcs, idx)
% docstr = get_docstr(funcs, idx)
% Get the help documentation for function at index idx.
% If no idx, documentation for each function in funcs will be returned.

    % init funcs
    if ~exist('funcs','var') || isempty(funcs), funcs = {}; end;
    if ~iscell(funcs), funcs = {funcs}; end;
    % init idx
    if ~exist('idx','var') || isempty(idx), idx = 1:numel(funcs); end;
    % init docstring
    docstr = cell(size(idx));
    % for each idx, get docstring
    for x = idx,
        % switch class
        switch class(funcs{x})
            case 'function_handle' % help
                docstr{x} = help(func2str(funcs{x}));
            case 'char' % command -h
                docstr{x} = cmd_help(funcs{x});
            case {'cell','struct'} % cfg_util('showdoc'...)
                if ~iscell(funcs{x}), funcs{x} = funcs(x); end;
                docstr{x} = '';
                cfg_util('initcfg');
                [job, mods] = cfg_util('initjob', funcs{x});
                for n = 1:numel(mods),
                    tagstr = cfg_util('harvest', job, mods{n});
                    [~,~,rep] = sawa_getfield(funcs{x}{n}, 'expr', ['.*', tagstr]);
                    tmpstr = cfg_util('showdocwidth', 70, rep{1}(2:end));
                    docstr{x} = char(docstr{x}, tmpstr{:});
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
    if isfield(params,'env'), init_env(params, params.env); end;
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
% set to 'sawa_diary.txt'.
%
% options:
% 'print_type' - 'diary' (save all outputs), 'off' (no outputs)
% 'print_file' - if 'diary' print_type, set file to save output 
% 'verbose_arg' - directly set verbose_arg to true (verbose) or false (off)

    % load print_type
    if isempty(varargin),
        struct2var(params,{'print_type','print_file'});
        % init verbose_arg
        verbose_arg = [];
    else % set from varargin
        arrayfun(@(x)assignin('caller',varargin{x},varargin{x+1}),1:2:numel(varargin)-1);
    end
    % init print_type
    if ~exist('print_type','var'), print_type = ''; end;
    % switch print_type
    switch print_type
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
            verbose_arg = true;
        case 'on' % set verbose to true
            verbose_arg = true;
        case 'off' % set verbose to false
            verbose_arg = false;
        otherwise % if set directly
            struct2var(params,'verbose_arg');
    end 
    % set verbose_arg to params
    params = struct2var(params,{'verbose_arg','print_type','print_file'});
end

% run functions
function params = run_params(params)
% params = run_params(params)
% Run parameters using @sawa_feval after evaluating any subject array
% variables in options using @sawa_evalvars and setting print options with
% @print_options.
%
% Available options (fields of params):
% iter_args - cell array of arguments related to iter/loop/seq for
%   sawa_feval (e.g., {'iter', 1:2, 'loop', 2})
%   [default {}]
% funcs - cell array of functions to be run 
%   [default {}]
% options - cell array of options corresponding to functions (e.g.,
%   options{1} for funcs{1}) 
%   [default {}]
% n_out - number of outputs expected (max) for all functions 
%   [default 1]
% wait_bar - boolean for displaying waitbar of time left
%   [default false]
%
% Outputs (field of params):
% outputs - cell array of outputs from each function call organized as
%   output{func}{iter/loop, n_out}

    % load iter, funcs, options, nout
    struct2var(params,{'iter_args','funcs','options','n_out','wait_bar','sa'});
    % init iter, funcs, options if not exist
    if ~exist('iter_args','var'), iter_args = {}; end;
    if ~exist('funcs','var'), funcs = {}; end;
    if ~exist('options','var'), options = {}; end;
    if ~exist('n_out','var'), n_out = 1; end;
    if ~exist('wait_bar','var'), wait_bar = false; end;
    % eval options
    cmd_idx = cellfun(@(x)ischar(x),funcs);
    options(cmd_idx) = sawa_evalvars(options(cmd_idx),'cmd');
    options(~cmd_idx) = sawa_evalvars(options(~cmd_idx));
    % print outputs as selected, return verbose
    params = print_options(params); 
    struct2var(params,'verbose_arg'); 
    if isempty(funcs), return; end;
    try
        % run sawa_feval
        outputs = sawa_feval(iter_args{:},'n_out',n_out,'verbose',verbose_arg,...
                            'wait_bar',wait_bar,funcs,options{:});
    catch err
        disp(['fatal error:', err.message]);
    end
    % set outputs to params
    params = struct2var(params,'outputs');
    % finish printing outputs
    print_options(params);
end