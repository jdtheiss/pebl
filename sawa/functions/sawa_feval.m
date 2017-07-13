function varargout = sawa_feval(varargin)
% outputs = sawa_feval('Param1', Value1, 'Param2', Value2, funcs, options1, options2, ...)
% Run wrapper of multiple scripts/functions/system commands/matlabbatch.
%
% Inputs:
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
% 'verbose' - optional boolean. true displays all inputs/outputs; false 
%   displays nothing in the command prompt; 
%   [default is [], displays normal command behavior]
% 'throw_error' - optional boolean. true throws error when one occurs; 
%   false displays error message without throwing error
%   [default is false]
% 'wait_bar' - optional boolean. true displays a waitbar; false does not
%   [default is false] 
% funcs - cellstr, function(s) to run  
%   [no default]
% options - cell array, inputs for functions as variable inputs with rows 
%   per function. the options for each function should be entered as a
%   separate argument
%   [default is {} per function, which is not input to the function/script]
% 
% Outputs:
% output - variable number of outputs with columns per output and rows per 
%   function. outputs can be used as inputs as @()'output{col}{row}'.
%
% Example 1: system echo 'this' and compare output with 'that' using
% strcmp, then repeat with system echo 'that'
% output = sawa_feval('loop', 2, 'iter', {1:2,0}, {'echo',@strcmp},...
%                    {'-n',{'this'; 'that'}}, {@()'output{1}{end}', 'that'})
% this
% that
% 
% output = 
% 
%     'this'
%     [   0]
%     'that'
%     [   1]
%     
% Example 2: subtract 1 from each previous output
% output = sawa_feval('seq', [1,2,2], 'verbose', true, {@randi, @minus}, 10, {@()'output{1}{end}', 1})
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
% output = 
% 
%     [10]
%     [ 9]
%     [ 8]
%
% Example 3: get fullfile path of template image, then display image using matlabbatch
% matlabbatch{1}.spm.util.disp.data = '<UNDEFINED>';
% output = sawa_feval({@fullfile, matlabbatch}, ...
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
% output = 
% 
%     '/Applications/spm12/canonical/avg152T1.nii'
%     []
%
% 
% Example 4: use @() to evaluate inputs
% output = sawa_feval('loop', 2, 'iter', {1:2,0}, {'echo',@minus},...
%          {'-n', {@()'randi(10)';'2'}}, {@()'str2double(output{1}{end})', 2})
%
% 10
% 2
% 
% output = 
% 
%     '10'
%     [ 8]
%     '2'
%     [ 0]
% 
% Example 5: run while loop until last two numbers are same
% output = sawa_feval('iter',1:2,'stop_fcn',@()'output{1}{end}==output{1}{end-1}',...
%          @randi, {10;10})
% 
% output = 
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
% (e.g., sawa_feval('verbose', true, @disp, {'verbose'})).
%
% Created by Justin Theiss

% if no outputs, set o to 1
o = max([1,nargout]);

% init varargout
varargout = cell(1,o);
if nargin==0, return; end; 

% init varargin parameters
params = {'loop', 'seq', 'iter', 'stop_fcn', 'verbose', 'throw_error', 'wait_bar'};
values = {1, [], 0, [], [], false, false};
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

% for loop/sequence order
for l = 1:loop,
for f = seq,
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
                % set options (for varargout)
                tmpopts = local_eval(varargout, options{f}, n); 
                % feval
                [output{1:o}] = feval(program, funcs{f}, tmpopts, verbose); 
                % display outputs
                if verbose, 
                    fprintf('\nOutput:\n');
                    disp(cell2strtable(any2str(output{1:o}),' ')); 
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
                output(1:o) = {[]};
            end
            % concatenate results to varargout
            varargout = cellfun(@(x,y){cat(1,x,{y})}, varargout, output); 
            % wait_bar
            if wait_bar,
                settimeleft(f, 1:numel(iter), h);
            end
        end
        % check stop_func
        if isempty(stop_fcn{f}),
            done = true;
        else
            done = cell2mat(local_eval(varargout, stop_fcn{f}, 0));
        end
    end
end
end
end

% evaluate @() inputs
function options = local_eval(output, options, n)
    % get row from options
    if ~any(n==0),
        if any(cellfun('isclass', options, 'cell')) && size(options, 2) > 1,
        % for each column, set to row
        for x = find(cellfun('isclass',options,'cell')),
            if size(options{x}, 1) > 1,
                options{x} = options{x}{min(end,n)};
            end
        end
        elseif iscell(options) && ~isempty(options) && size(options, 1) > 1, 
            % if cell, set to row
            options = options{min(end,n)};
        end
    end
    if ~iscell(options), options = {options}; end;
    
    % find functions in options
    [C,S] = sawa_getfield(options,'fun',@(x)isa(x,'function_handle')); 
    if isempty(C), return; end;
    
    % convert to str to check
    C = cellfun(@(x){func2str(x)},C);

    % get only those beginning with @()'output
    S = S(strncmp(C,'@()',3));
    C = C(strncmp(C,'@()',3));

    % if no C, return
    if isempty(C), return; end; 
    
    % set options
    for x = 1:numel(C),
        C{x} = subsref(options, S{x});
        options = subsasgn(options,S{x},eval(feval(C{x}))); 
    end;
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
            tmpout = sawa_cat(1, tmpout{:}); 
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
function matlabbatch = local_setbatch(matlabbatch, options)
    % ensure cells
    if ~iscell(options), options = {options}; end;
    
    % for each option, get subsref struct
    for x = 1:2:numel(options)
        switch class(options{x})
            case 'struct' % set S to options
                S{x} = options(x);
            case 'cell' % use sawa_getfield with options
                [~,S{x}] = sawa_getfield(matlabbatch, options{x}{:});
            case 'char' % use sawa getfield with expr
                [~,S{x}] = sawa_getfield(matlabbatch, 'expr', options{x}); 
        end
    end
    
    % set batch using options
    for x = 1:2:numel(options), 
        for y = 1:numel(S{x}), % set each subsref struct to following options
            % if cell substruct but not cell in matlabbatch, set to {}
            if strcmp(S{x}{y}(end).type, '{}') && ~iscell(subsref(matlabbatch, S{x}{y}(1:end-1))),
                matlabbatch = subsasgn(matlabbatch, S{x}{y}(1:end-1), {});
            end
            % assign options
            matlabbatch = subsasgn(matlabbatch, S{x}{y}, options{x+1}); 
        end
    end
end

% matlabbatch commands
function varargout = local_batch(matlabbatch, options, verbose)
    % init varargout
    varargout = cell(1, nargout); 
    
    % if matlabbatch is not cell, make cell
    if ~iscell(matlabbatch), matlabbatch = {matlabbatch}; end;
    
    % set batch
    matlabbatch = local_setbatch(matlabbatch, options);
    
    % display functions of structure
    if verbose,
        [C,~,R] = sawa_getfield(matlabbatch);
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
    [~,~,~,~,sout]=cfg_util('showjob',cjob); 
    vals = cfg_util('getalloutputs',cjob);

    % subsref vals
    output = cell(1, nargout);
    for x = 1:numel(vals),
        % if empty, skip
        if isempty(vals{x}) || isempty(sout{x}), continue; end;
        for y = 1:numel(sout{x}), 
            % set output from vals
            output{x}{y} = subsref(vals{x},sout{x}(y).src_output); 
        end
    end

    % set to varargout
    [varargout{1:nargout}] = output{1:nargout};
end