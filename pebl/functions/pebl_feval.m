function output = pebl_feval(varargin)
% output = pebl_feval(funcs, options1, options2, ..., 'Param1', Value1, ...)
% Run wrapper of multiple scripts/functions/system commands/matlabbatch.
%
% Inputs:
% funcs - cell array, functions to run. matlab functions as function
%   handles, system commands as char, and matlabbatch modules as cell/struct
%   [no default]
% options - separate inputs per function. each function's input arguments
%   should be contained in a cell array with rows corresponding to iterations
%   [default {} per function]
% 'loop' - number, optional number of times to loop through functions
%   [default 1]
% 'seq' - numeric array, optional sequence of functions to be run
%   [default [] which runs all functions in order]
% 'iter' - cell/numeric array, optional sequence of iterations to be run. 
%   numeric array: iterations to run
%   -1: set each iteration to loop number
%   inf: run all iterations based on number of rows in options
%   []: run as is, assumes no iterations
%   cell array: each function's iter in separate cell
%   [default []]
% 'stop_fn' - cell array/function, function to evaluate during while loop.
%   if function evaluates true, the loop ends.alternatively, cell array of
%   stop_fn per function. stop_fn is overrided by 'iter' option inf
%   [default []]
% 'n_out' - numeric array, range of outputs to return from each function
%   [default [], all outputs from each function]
% 'verbose' - boolean, true displays function call with options and output;
%   false suppresses output; [] displays normal command window behavior
%   [default []]
% 'throw_error' - boolean, true throws error if any occurs
%   [default true]
% 'save_batch' - char, filename to save filled matlabbatch structure
%   [default []]
% 'wait_bar' - boolean, true displays waitbar during loops
%   [default false]
% 'output' -cell, outputs that can be evaluated with @()'output...'
% 
% Outputs:
% output - outputs organized as cells per function with inner cells of rows 
%   per iteration and/or loop and columns based on number of outputs. 
%   outputs can be used as inputs: @()'output{func}{iter, n_out}'.
%
% Example 1: system echo 'this' and compare output with 'that' using
% strcmp, then repeat with system echo 'that'
% output = pebl_feval({'echo',@strcmp}, {'-n',{'this'; 'that'}},...
%          {@()'output{1}{end}', 'that'}, 'loop', 2, 'iter', {-1,[]})
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
%          {@()'str2double(output{1}{end})', 2}, 'loop', 2, 'iter', {-1,[]})
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
% output = pebl_feval(@randi, {10;10}, 'iter', 1:2, 'stop_fn',...
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
% Note: in order to avoid function inputs being incorrectly assigned as 
% parameters, put any inputs sharing parameter names in cell brackets 
% (e.g., pebl_feval(@disp, {'verbose'}, 'verbose', true)). 
% in order to evaluate options at runtime, @() can be prepended to a
% character array within options (see examples above).
% if running iterations, the iterations should be in vertical cells, and 
% the cells to be iterated should have the same number of rows
% outputs for matlabbatch functions are per module (e.g., if there are 4
% modules, there are a possible 4 output cells)
%
% Created by Justin Theiss

% init output if no nargin
output = cell(1, 1);
if nargin==0, return; end; 

% init defaults
vars = {'loop', 'seq', 'iter', 'stop_fn', 'n_out', 'verbose', 'throw_error',...
        'save_batch', 'wait_bar', 'output', 'generate'};
vals = {1, [], [], [], [], [], true, [], false, {{}}, false};
n_idx = ~ismember(vars, varargin(cellfun('isclass',varargin,'char')));
defaults = cat(1, vars(n_idx), vals(n_idx));
varargin = cat(2, varargin, defaults(:)');

% set variables
r_idx = [];
for x = 1:numel(varargin)-1,
    if ischar(varargin{x}), 
        switch varargin{x}
            case 'loop'
                loop = varargin{x+1};
            case 'seq'
                seq = varargin{x+1};
            case 'iter'
                iter = varargin{x+1}; 
            case 'stop_fn'
                stop_fn = varargin{x+1};
            case 'verbose'
                verbose = varargin{x+1};
            case 'throw_error'
                throw_error = varargin{x+1};
            case 'save_batch'
                save_batch = varargin{x+1};
            case 'wait_bar'
                wait_bar = varargin{x+1};
            case 'n_out'
                n_out = varargin{x+1};
            case 'output'
                output = varargin{x+1};
            case 'generate'
                generate = varargin{x+1};
            otherwise % if not found, skip
                continue; 
        end
        % set indices to remove
        r_idx = cat(2, r_idx, x:x+1);
    end
end

% remove r_idx indices
varargin(r_idx) = [];

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

% if stop_fn is not cell, repmat
if ~iscell(stop_fn),
    stop_fn = repmat({stop_fn}, 1, numel(funcs));
end

% for loop/sequence order
for l = 1:loop,
for f = seq,
    % default is [] meaning run once with no iterations
    if f > numel(iter), iter{f} = []; end;
    % different iter options
    if isempty(iter{f}),
        iter{f} = 0; 
    elseif all(iter{f} == inf),
        stop_fn{f} = @()'n==inf'; 
        iter{f} = 1;
    end  
    % if while loop
    done = false; 
    while ~done, 
        % wait_bar
        if wait_bar,
            h = settimeleft;
        end
        % for specified loops/iterations
        for n = iter{f}, 
            % if -1, set to l 
            if n == -1, n = l; end;
            % set program and max number of outputs
            [program, o] = local_setprogram(funcs{f}, n_out);
            try
                % set options (for using outputs/dep)
                [evaled_opts, n] = local_eval(options{f}, 'output', output,...
                                              'func', funcs{f}, 'n', n,...
                                              'generate', generate);
                % feval
                clear results;
                [results{1:o}] = feval(program, funcs{f}, evaled_opts,...
                                       verbose, generate, save_batch);
                % display outputs
                local_print(results, verbose);
            catch err % display error
                % if throw_error is true, rethrow
                if throw_error,
                    rethrow(err);
                end
                % print error
                local_print(funcs{f}, verbose, err);
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
            % if all iterations
            if ~isempty(stop_fn{f}) && strcmp(func2str(stop_fn{f}), '@()''n==inf'''),
                if n == inf, % if inf, done
                    iter{f} = inf;
                else % advance
                    iter{f} = iter{f} + 1;
                end
            end
        end
        % check stop_func
        if isempty(stop_fn{f}),
            done = true;
        else
            done = cell2mat(local_eval(stop_fn{f},'output',output,'n',n));
        end
    end
end
end
% return output{f}(:, n_out)
if isempty(n_out), n_out = 1:max(cellfun('size',output,2)); end;
output = cellfun(@(x){pebl_cat(2, x, cell(1, max(n_out)-size(x,2)))}, output);
if all(n_out > 0), output = cellfun(@(x){x(:, n_out)}, output); end;
if generate, % if outputs used, remove quotes
    output = cat(1, output{:});
    for x = 1:numel(output),
        output = strrep(output, sprintf('''%s''', output{x}), output{x});
    end
    output = sprintf('%s\n', output{:});
end
end

% print outputs or errors
function local_print(msg, verbose, err)
    % not verbose, return
    if ~isempty(verbose) && ~verbose, return; end;
    % print results
    if nargin == 2 && ~isempty(verbose),
        strs = cell(size(msg));
        for s = 1:size(msg, 2),
            if numel(msg{s}) > 1e5, 
                strs(s) = any2str(msg(s));
            else
                strs(s) = any2str(msg{s});
            end
        end
        % print outputs
        if isempty(strs), strs = any2str(strs); end;
        fprintf('\nOutput:\n');
        disp(cell2strtable(strs, ' '));
        fprintf('\n'); 
    elseif nargin == 3, % print error
        % if not string, set to string
        if isa(msg,'function_handle'),
            func = func2str(msg);
        elseif ~ischar(msg),
            func = 'matlabbatch';
        else % set to func
            func = msg;
        end
        % display error
        fprintf('%s %s %s\n',func,'error:',err.message); 
    end
end

% evaluate @() inputs
function [options, n] = local_eval(options, varargin)
    % for each varargin, set as variable
    for x = 1:2:numel(varargin), 
        eval([varargin{x} '= varargin{x+1};']);
    end
    % init n/func
    if ~exist('n', 'var'), n = 0; end;
    if ~exist('func','var'), func = []; end;
    
    % find functions in options
    if ~iscell(options) || size(options, 1) > 1, options = {options}; end;
    [C, S] = pebl_getfield(options, 'fun', @(x)isa(x,'function_handle'), 'r', 3); 
    
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
            options = pebl_setfield(options, 'S', S{x}, 'C', eval(feval(C{x})));
        end
        
        for x = find(~o_idx),
            % if program is batch, get depenencies (for each @()dep)
            if iscell(func)||isstruct(func),
                [~, dep] = local_setbatch(func, options);
            else % otherwise set dep to []
                dep = [];
            end
            C{x} = subsref(options, S{x});
            options = pebl_setfield(options, 'S', S{x}, 'C', eval(feval(C{x})));
        end
    end
    
    % get row from options
    if n~=0,
        [C, S] = pebl_getfield(options, 'fun', @(x)iscell(x) && size(x, 2)==1, 'r', 1);
        max_size = max(cellfun('size', C, 1));
        if n == max_size, n = inf; end;
        for x = find(cellfun('size', C, 1) == max_size),
            options = subsasgn(options, S{x}, C{x}{min(end, n)}); 
        end
    end
    
    % if matlabbatch, check for .nii.gz or 4D .nii
    if iscell(func)||isstruct(func),
        for x = 1:numel(options),
            options{x} = local_niftiframes(options{x});
        end
    elseif ischar(func), % if system, put quotes around files
        for x = 1:numel(options),
            options{x} = local_pathquotes(options{x});
        end
    end
end

% check for nifti frames
function C = local_niftiframes(C)
    % get options based on class
    if iscellstr(C), % cellstr, loop through options
        for x = 1:numel(C),
            C{x} = local_niftiframes(C{x});
        end
        return;
    elseif ischar(C), % char, get fileparts
        [p,f,e] = fileparts(C);
    else % otherwise, return
        return;
    end
    % get frames
    frames = regexp(e, ',.+$', 'match', 'once');
    frames = frames(2:end);
    e = regexprep(e, ',.+$', '');
    if strcmp(e, '.gz'), % gunzip
        gunzip(fullfile(p, [f,e])); e = '';
    elseif ~strcmp(e, '.nii'),
        return;
    end
    % eval frames
    if ~isempty(frames) && ischar(frames),
        frames = eval(frames);
    else
        frames = inf;
    end
    % use spm_select to expand filelist
    C = cellstr(spm_select('ExtFPList',p,['^' regexptranslate('wildcard',[f,e])],frames));
    if numel(C) == 1, C = C{1}; end;
end

% set quotes around files
function C = local_pathquotes(C)
    if ~ischar(C),
        return;
    else % regexprep files with quotes
        C = regexprep(C,['.*' filesep '.*'],'"$0"'); 
        C = regexprep(C,'""','"');
    end
end

% set program types
function [program, o] = local_setprogram(func, n_out)
    % switch class
    switch class(func),
        case {'cell','struct'} % matlabbatch
            program = 'local_batch'; 
            if isstruct(func), o = 1; else o = numel(func); end;
        case 'function_handle' % function/builtin
            program = 'local_feval';
            try o = max(1, abs(nargout(func))); catch, o = 1; end;
        case 'char' % system
            program = 'local_system'; 
            o = 1;
    end
    % set output number
    if ~isempty(n_out) && ~any(n_out==0), 
        o = max(o, max(n_out)); 
    elseif ~isempty(n_out),
        o = n_out;
    end
end

% matlab functions
function varargout = local_feval(func, varargin)
    % set options and verbose
    [options, verbose, generate] = deal(varargin{1:3});
    
    % init varargout
    varargout = cell(1, nargout);
    
    % set func to str if function_handle
    if isa(func,'function_handle'), func = func2str(func); end;

    % if options is not cell or more inputs than nargin, set to cell
    try i = nargin(func); catch, i = 1; end;
    if ~iscell(options) || (i > 0 && numel(options) > i),
        options = {options};
    end
    
    % get number of outputs
    try o = nargout(func); catch, o = 1; end;
    
    % display function and options
    if verbose, disp(cell2strtable(any2str(func,options{:}),' ')); end;
    
    % if generate script, genstr options
    if generate,
        stropts = strjoin(cellfun(@(x){genstr(x)}, options), ',');
        varargout{1} = sprintf('%s(%s)', func, stropts);
    elseif o == 0, % if no ouputs, use evalc output
        % evalc
        varargout{1} = evalc([func '(options{:});']);
        if isempty(verbose) || verbose, disp(varargout{1}); end;
        if nargout == 0, varargout = cell(1, nargout); end;
    else  % multiple outputs
        if isempty(verbose) || verbose,
            [varargout{1:nargout}] = feval(func, options{:}); 
        else % prevent display
            [~,varargout{1:nargout}] = evalc([func '(options{:});']);
        end
    end
end

% system commands
function varargout = local_system(func, varargin)
    % set options and verbose
    [options, verbose, generate] = deal(varargin{1:3});
    
    % init varargout
    varargout = cell(1, nargout);

    % ensure all options are strings
    if ~iscell(options) || isempty(options), options = {options}; end;
    options = cellfun(@(x){num2str(x)}, options);

    % concatenate func and options with spacing
    stropts = sprintf('%s ', func, options{:});
    stropts = stropts(1:end-1);
    
    % display function and options
    if verbose, disp(stropts); end;
    
    % run system call
    if generate,
        varargout{1} = sprintf('system(%s)', genstr(stropts));
        return;
    else
        [sts, tmpout] = system(stropts);
    end
    
    % if verbose isempty, display tmpout
    if isempty(verbose), disp(tmpout); end;
    
    % set output cell
    output = cell(1, nargout);

    % if sts is 0, no error
    if sts == 0,
        if nargout > 1,
            % attempt to separate output
            tmpout = regexp(regexp(tmpout, '\n', 'split'), '\s+', 'split');
            tmpout = pebl_cat(1, tmpout{:});
            tmpout = arrayfun(@(x){pebl_strjoin(tmpout(:, x), '\n')}, 1:size(tmpout, 2));
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
    if ~iscell(options) || isempty(options), options = {options}; end;
    if numel(options) < 2, options{2} = []; end;
    % for each option, get subsref struct
    for x = 1:2:numel(options)
        % if @() function, skip setting (it should be evaluated with local_eval)
        if isa(options{x+1}, 'function_handle') && strncmp(func2str(options{x+1}), '@()', 3), 
            continue;
        end
        % switch based on first option in pair
        switch class(options{x})
            case 'struct' % use pebl_setfield with S
                matlabbatch = pebl_setfield(matlabbatch, 'S', options{x}, 'C', options{x+1});
            case 'cell' % use pebl_setfield with options
                if all(cellfun('isclass', options{x}, 'struct')), % S
                    matlabbatch = pebl_setfield(matlabbatch, 'S', options{x}, 'C', options{x+1});
                elseif iscellstr(options{x}) && ~strcmp(options{x}{1}, 'R'), % R
                    matlabbatch = pebl_setfield(matlabbatch, 'R', options{x}, 'C', options{x+1});
                else % any options
                    matlabbatch = pebl_setfield(matlabbatch, options{x}{:}, 'C', options{x+1});
                end
            case 'char' % use pebl_setfield with expr or R
                if any(regexp(options{x}, '[\\|^$*+?]')),
                    type = 'expr';
                else
                    type = 'R';
                end
                matlabbatch = pebl_setfield(matlabbatch, type, options{x}, 'C', options{x+1});
        end
    end
    % get dependencies
    if nargout == 2,
        [~, cjob] = evalc('cfg_util(''initjob'',matlabbatch);'); 
        [~,~,~,~,dep]=cfg_util('showjob',cjob); 
    end
end

% save batch
function local_savebatch(filename, matlabbatch)
    % append file
    if exist(filename, 'file'),
        tmp = load(filename, 'matlabbatch');
        if ~isfield(tmp, 'matlabbatch'), 
            tmp.matlabbatch = {};
        end
        matlabbatch = cat(1, tmp.matlabbatch(:), matlabbatch(:))';
        save(filename, 'matlabbatch', '-append');
    elseif ~isempty(filename) % save new file
        save(filename, 'matlabbatch');
    end
end

% matlabbatch commands
function varargout = local_batch(matlabbatch, varargin)
    % set options, verbose, and save_batch
    [options, verbose, generate, save_batch] = deal(varargin{1:4});
    
    % init varargout
    varargout = cell(1, nargout); 
    
    % set batch
    matlabbatch = local_setbatch(matlabbatch, options);
    
    % save batch
    local_savebatch(save_batch, matlabbatch);
    
    % display functions of structure
    if ~isempty(verbose) && verbose && ~generate,
        [C,~,R] = pebl_getfield(matlabbatch);
        cellfun(@(x,y)fprintf('%s: %s\n', x, genstr(y)), R, C);
    end
    
    % generate script
    if generate,
        varargout{1} = sprintf('cjob = cfg_util(''initjob'', %s);\n', genstr(matlabbatch));
        varargout{1} = sprintf('%scfg_util(''run'', cjob);\n', varargout{1});
        return;
    else % run job
        cjob = cfg_util('initjob',matlabbatch); 
        if isempty(verbose) || verbose, 
            cfg_util('run',cjob);
        else % prevent display
            evalc('cfg_util(''run'',cjob);');
        end
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