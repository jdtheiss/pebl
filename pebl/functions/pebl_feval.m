function output = pebl_feval(varargin)
% output = pebl_feval('Param1', Value1, 'Param2', Value2, funcs, options1, options2, ...)
% Run wrapper of multiple scripts/functions/system commands/matlabbatch.
%
% Inputs:
% funcs - cell array, functions to run. matlab commands should be function
%   handles (i.e. begin with @), system command should be char, and
%   matlabbatch commands should be struct array or cell array of structs
%   [no default]
% options - cell array, inputs for functions as variable inputs with rows 
%   per function. the options for each function should be entered as a
%   separate argument
%   [default is {} per function, which is not input to the function/script]
% 'loop' - number of times to loop through functions (e.g., 3 to run all
%   functions in sequence 3 times). can be combined with 'iter' to use
%   different parameters on each loop (e.g., 'loop', 3, 'iter', 1:3).
%   [default is 1]
% 'seq' - sequence of functions to run (e.g., [1,2,2,3] to run the first
%   function followed by the second function twice then the third function).
%   [default is 1:numel(funcs)]
% 'iter' - sequence of iterations to run (e.g., [1:2] to run the first two
%   options for each function). alternatively, each function's sequence of
%   iterations can be provied as a cell of sequences coresponding to the 
%   number of functions (e.g., {1:2,1,1:3}).
%   [default is 0, which assumes there is no sequence to iterate]
% 'stop_fcn' - stop function to use as part of a "while loop" (e.g.,
%   @()'output{1}{end}==0' to run until the first output is 0).
%   alternatively, each function's stop function can be provided in a cell
%   array (e.g., {@()'output{1}{end}==0', @()'output{2}{end}==1'}).
%   [default is [], which is no while loop]
% 'n_out' - range of outputs to return from each function (e.g., 2 or 1:3)
%   [default is 1]
% 'verbose' - optional boolean. true displays all inputs/outputs; false 
%   displays nothing in the command prompt; 
%   [default is [], displays normal command behavior]
% 'throw_error' - optional boolean. true throws error when one occurs; 
%   false displays error message without throwing error
%   [default is false]
% 'wait_bar' - optional boolean. true displays a waitbar; false does not
%   [default is false] 
% 
% Outputs:
% output - outputs organized as cells per function with inner cells of rows 
%   per iteration and/or loop and columns based on number of outputs. 
%   outputs can be used as inputs: @()'output{func}{iter, n_out}'.
%
% Example 1: system echo 'this' and compare output with 'that' using
% strcmp, then repeat with system echo 'that'
% output = pebl_feval({'echo',@strcmp}, {'-n',{'this'; 'that'}},...
%          {@()'output{1}{end}', 'that'}, 'loop', 2, 'iter', {1:2,0})
% this
% that
% 
% output{1} = 
% 
%     'this'
%     'that'
% 
% output{2} = 
% 
%     [0]
%     [1]
%     
% Example 2: subtract 1 from each previous output
% output = pebl_feval({@randi, @minus}, 10, {@()'output{end}{end}', 1},...
%          'seq', [1,2,2], 'verbose', true)
% randi 10
% 
% Output:
% 10
% 
% minus 10 1
% 
% Output:
% 9
% 
% minus 9 1
% 
% Output:
% 8
% 
% output{1} = 
% 
%     [10]
%
% output{2} = 
%
%     [ 9]
%     [ 8]
%
% Example 3: get fullfile path of template image, then display image using matlabbatch
% matlabbatch{1}.spm.util.disp.data = '<UNDEFINED>';
% output = pebl_feval({@fullfile, matlabbatch}, ...
%          {fileparts(which('spm')), 'canonical', 'avg152T1.nii'},...
%          {'.*\.data$', @()'output{1}(1)'})
% 
% ------------------------------------------------------------------------
% Running job #1
% ------------------------------------------------------------------------
% Running 'Display Image'
% 
% SPM12: spm_image (v6425)                           16:29:10 - 17/11/2016
% ========================================================================
% Display /Applications/spm12/canonical/avg152T1.nii,1
% Done    'Display Image'
% Done
% 
% output{1} = 
% 
%     '/Applications/spm12/canonical/avg152T1.nii'
% 
% output{2} = 
% 
%     {[]}
%
% 
% Example 4: use @() to evaluate inputs
% output = pebl_feval({'echo',@minus}, {'-n', {@()'randi(10)';'2'}},...
%          {@()'str2double(output{1}{end})', 2}, 'loop', 2, 'iter', {1:2,0})
%
% 5
% 2
% 
% output{1} = 
% 
%     '5'
%     '2'
% 
% output{2} = 
% 
%     [3]
%     [0]
% 
% Example 5: run while loop until last two numbers are same
% output = pebl_feval(@randi, {10;10}, 'iter', 1:2, 'stop_fcn',...
%          @()'output{1}{end}==output{1}{end-1}')
% 
% output{1} = 
% 
%     [ 1]
%     [ 8]
%     [10]
%     [ 4]
%     [10]
%     [ 4]
%     [ 9]
%     [ 5]
%     [ 5]
%     [ 3]
%     [ 2]
%     [ 4]
%     [ 8]
%     [ 8]
%     
% Note: in order to avoid overlap between system commands and matlab 
% built-in functions, matlab functions/scripts should be input as 
% function_handles (i.e. @func instead of 'func'). also, in order to avoid
% function inputs being incorrectly assigned as parameters, put any 
% inputs sharing parameter names in cell brackets 
% (e.g., pebl_feval('verbose', true, @disp, {'verbose'})).
%
% Created by Justin Theiss

% init output if no nargin
output = cell(1, 1);
if nargin==0, return; end; 

% init varargin parameters
params = {'loop', 'seq', 'iter', 'stop_fcn', 'verbose', 'throw_error', 'wait_bar', 'n_out'};
values = {1, [], 0, [], [], false, false, 1};
x = 1;
while x < numel(varargin),
    if ischar(varargin{x}) && any(strcmp(params, varargin{x})),
        switch varargin{x}
            case 'loop'
                loop = varargin{x+1};
            case 'seq'
                seq = varargin{x+1};
            case 'iter'
                iter = varargin{x+1};
            case 'stop_fcn'
                stop_fcn = varargin{x+1};
            case 'verbose'
                verbose = varargin{x+1};
            case 'throw_error'
                throw_error = varargin{x+1};
            case 'wait_bar'
                wait_bar = varargin{x+1};
            case 'n_out'
                n_out = varargin{x+1};
            otherwise % advance
                x = x + 1;
                continue;
        end
        % remove from params/values/varargin
        values(strcmp(params, varargin{x})) = [];
        params(strcmp(params, varargin{x})) = [];
        varargin(x:x+1) = [];
    else % advance
        x = x + 1;
    end
end

% set defaults
for x = 1:numel(params),
    eval([params{x} '= values{x};']);
end

% get funcs
funcs = varargin{1};
if ~iscell(funcs), funcs = {funcs}; end;
funcs = funcs(:);

% set options and ensure cell
if numel(varargin) >= numel(funcs)+1,
    options = varargin(2:numel(funcs)+1);
elseif all(cellfun('isclass',funcs,'struct')), % if all batch
    funcs = {funcs};
    options = varargin(2:numel(funcs)+1);
else % set options empty
    options = repmat({{}}, 1, numel(funcs));
end

% if seq is empty, set to 1:numel(funcs)
if isempty(seq), seq = 1:numel(funcs); end;

% if iter is not cell, repmat
if ~iscell(iter), 
    iter = repmat({iter}, 1, numel(funcs));
end

% if stop_fcn is not cell, repmat
if ~iscell(stop_fcn),
    stop_fcn = repmat({stop_fcn}, 1, numel(funcs));
end

% init output
output = {{}};
% for loop/sequence order
for l = 1:loop,
for f = seq,
    if f > numel(iter), iter{f} = 0; end;
    % if while loop
    done = false; 
    while ~done, 
        % wait_bar
        if wait_bar,
            h = settimeleft;
        end
        % for specified loops/iterations
        for n = iter{f}, 
            % if looping with iterations, skip unless n == l 
            if loop > 1 && n > 0 && n ~= l, continue; end;
            % set program
            program = local_setprog(funcs{f}); 
            try % run program with funcs and options
                try o = abs(nargout(funcs{f})); o = max(o, max(n_out)); catch, o = max(n_out); end;
                % set options (for using outputs/dep)
                evaled_opts = local_eval(options{f}, 'output', output, 'func', funcs{f}, 'n', n); 
                % feval
                [results{1:o}] = feval(program, funcs{f}, evaled_opts, verbose); 
                % display outputs
                if verbose, 
                    fprintf('\nOutput:\n');
                    disp(cell2strtable(any2str(results{1:o}),' ')); 
                    fprintf('\n'); 
                end
            catch err % display error
                % if throw_error is true, rethrow
                if throw_error,
                    rethrow(err);
                end
                % if not string, set to string
                if isa(funcs{f},'function_handle'),
                    func = func2str(funcs{f});
                elseif ~ischar(funcs{f}),
                    func = 'matlabbatch';
                else % set to funcs{f}
                    func = funcs{f};
                end
                % display error
                if isempty(verbose) || verbose, 
                    fprintf('%s %s %s\n',func,'error:',err.message); 
                end;
                % set output to empty
                results(1:o) = {[]};
            end
            % concatenate results to output
            if f > numel(output), output{f, 1} = {}; end;
            output{f} = pebl_cat(1, output{f}, results); 
            % wait_bar
            if wait_bar,
                settimeleft(f, 1:numel(iter), h);
            end
        end
        % check stop_func
        if isempty(stop_fcn{f}),
            done = true;
        else
            done = cell2mat(local_eval(stop_fcn{f}, 'output', output, 'func', funcs{f}));
        end
    end
end
end
% return output{f}(:, n_out)
output = cellfun(@(x){x(:, n_out)}, output);
end

% evaluate @() inputs
function options = local_eval(options, varargin)
    % for each varargin, set as variable
    for x = 1:2:numel(varargin), 
        eval([varargin{x} '= varargin{x+1};']);
    end
    % if no n, set to 0
    if ~exist('n', 'var'), n = 0; end;
    % get row from options
    if ~any(n==0) && iscell(options), 
        if any(cellfun('isclass', options, 'cell')),
            % for each column, set to row
            for x = find(cellfun('isclass',options,'cell')),
                if size(options{x}, 1) > 1,
                    options{x} = options{x}{min(end,n)};
                end
            end
        elseif ~isempty(options) && size(options, 1) > 1, 
            % if cell, set to row
            options = options{min(end,n)};
        end
    end
    
    % find functions in options
    if ~iscell(options), options = {options}; end;
    [C,S] = pebl_getfield(options,'fun',@(x)isa(x,'function_handle')); 
    
    if ~isempty(C),
        % convert to str to check
        C = cellfun(@(x){func2str(x)},C);
        % get only those beginning with @()
        S = S(strncmp(C,'@()',3));
        C = C(strncmp(C,'@()',3));
    
        % get functions with output
        o_idx = ~cellfun('isempty', regexp(C, 'output'));

        % set options based on output
        for x = find(o_idx),
            C{x} = subsref(options, S{x});
            options = subsasgn(options,S{x},eval(feval(C{x}))); 
        end

        % if program is batch, get depenencies
        if iscell(func)||isstruct(func),
            [~, dep] = local_setbatch(func, options);
        else % otherwise set dep to []
            dep = [];
        end

        % set options based on dependencies
        for x = find(~o_idx),
            C{x} = subsref(options, S{x});
            options = subsasgn(options,S{x},eval(feval(C{x}))); 
        end
    end
    
    % eval remaining options
    if ischar(func), opt = 'system'; else opt = ''; end;
    options = pebl_eval(options, opt);
end

% set program types
function program = local_setprog(func)
    % get first function if cell
    if iscell(func), func = func{1}; end;
    % switch class
    switch class(func),
        case 'struct' % matlabbatch
            program = 'local_batch'; 
        case 'function_handle' % function/builtin
            program = 'local_feval';
        case 'char' % system
            program = 'local_system'; 
    end
end

% matlab functions
function varargout = local_feval(func, options, verbose)
    % init varargout
    varargout = cell(1, nargout); 
    
    % set func to str if function_handle
    if isa(func,'function_handle'), func = func2str(func); end;

    % if nargin is less than 2, remove empty cells
    if ~iscell(options), options = {options}; end;
    
    % get number of outputs
    try o = nargout(func); catch, o = 0; end;
    if o < 0, o = nargout; elseif o > 0, o = min(nargout, o); end;
    
    % display function and options
    if verbose, disp(cell2strtable(any2str(func,options{:}),' ')); end;
    
    % if no ouputs, use evalc output
    if o == 0,
        varargout{1} = evalc([func '(options{:});']);
        if isempty(verbose) || verbose, disp(varargout{1}); end;
    else  % multiple outputs
        if isempty(verbose) || verbose,
            [varargout{1:o}] = feval(func, options{:}); 
        else % prevent display
            [~,varargout{1:o}] = evalc([func '(options{:});']);
        end
    end
end

% system commands
function varargout = local_system(func, options, verbose)
    % init varargout
    varargout = cell(1, nargout);

    % ensure all options are strings
    if ~iscell(options), options = {options}; end;
    options = cellfun(@(x){num2str(x)}, options);

    % concatenate func and options with spacing
    stropts = sprintf('%s ', func, options{:});
    
    % display function and options
    if verbose, disp(stropts); end;
    
    % run system call
    [sts, tmpout] = system(stropts);
    
    % if verbose isempty, display tmpout
    if isempty(verbose), disp(tmpout); end;
    
    % set output cell
    output = cell(1, nargout);

    % if sts is 0, no error
    if sts == 0,
        if nargout > 1,
            % attempt to separate output
            tmpout = regexp(tmpout, '\n', 'split');
            tmpout(cellfun('isempty',tmpout)) = [];
            tmpout = regexp(tmpout, '\s+', 'split');
            tmpout = pebl_cat(1, tmpout{:}); 
            tmpout(cellfun('isempty',tmpout)) = {''};
            tmpout = arrayfun(@(x){char(tmpout(:,x))}, 1:size(tmpout,2));
            % set to output
            if ~isempty(tmpout), [output{1:numel(tmpout)}] = tmpout{:}; end;
        else % otherwise set to tmpout
            output{1} = tmpout;
        end
    else % throw error
        error('%d %s',sts,tmpout);
    end

    % set to varargout
    [varargout{1:nargout}] = output{1:nargout};
end

% set batch
function [matlabbatch, dep] = local_setbatch(matlabbatch, options)
    % ensure cells
    if ~iscell(matlabbatch), matlabbatch = {matlabbatch}; end;
    if ~iscell(options), options = {options}; end;
    if numel(options) < 1, options{2} = []; end;
    % for each option, get subsref struct
    for x = 1:2:numel(options)
        % if @() function, skip setting (it should be evaluated with local_eval)
        if isa(options{x+1}, 'function_handle') && strncmp(func2str(options{x+1}), '@()', 3), 
            continue; 
        end
        switch class(options{x})
            case 'struct' % use pebl_setfield with S
                % if cell substruct but not cell in matlabbatch, set to {}
                if strcmp(options{x}(end).type,'{}')&&~iscell(subsref(matlabbatch,options{x}(1:end-1))),
                    matlabbatch = subsasgn(matlabbatch, options{x}(1:end-1), {});
                end
                matlabbatch = pebl_setfield(matlabbatch, 'S', options{x}, 'C', options{x+1});
            case 'cell' % use pebl_setfield with options
                matlabbatch = pebl_setfield(matlabbatch, options{x}{:}, 'C', options{x+1});
            case 'char' % use pebl_setfield with expr
                matlabbatch = pebl_setfield(matlabbatch, 'expr', options{x}, 'C', options{x+1});
        end
    end
    % get dependencies
    if nargout == 2,
        [~, cjob] = evalc('cfg_util(''initjob'',matlabbatch);'); 
        [~,~,~,~,dep]=cfg_util('showjob',cjob); 
    end
end

% matlabbatch commands
function varargout = local_batch(matlabbatch, options, verbose)
    % init varargout
    varargout = cell(1, nargout); 
    
    % set batch
    matlabbatch = local_setbatch(matlabbatch, options);
   
    % display functions of structure
    if verbose,
        [C,~,R] = pebl_getfield(matlabbatch);
        cellfun(@(x,y)fprintf('%s: %s\n', x, genstr(y)), R, C);
    end;
    
    % run job
    cjob = cfg_util('initjob',matlabbatch); 
    if isempty(verbose) || verbose, 
        cfg_util('run',cjob);
    else % prevent display
        evalc('cfg_util(''run'',cjob);');
    end
    
    % get outputs
    [~,~,~,~,dep]=cfg_util('showjob',cjob); 
    vals = cfg_util('getalloutputs',cjob);

    % subsref vals
    output = cell(1, nargout);
    for x = 1:numel(vals),
        % if empty, skip
        if isempty(vals{x}) || isempty(dep{x}), continue; end;
        for y = 1:numel(dep{x}), 
            % set output from vals
            output{x}{y} = subsref(vals{x},dep{x}(y).src_output); 
        end
    end

    % set to varargout
    [varargout{1:nargout}] = output{1:nargout};
end