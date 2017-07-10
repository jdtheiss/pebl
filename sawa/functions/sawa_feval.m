function varargout = sawa_feval(i,varargin)
% varargout = sawa_feval(i, funcs, options, ['verbose',true/false,'waitbar',true/false])
% Run wrapper of multiple functions/system commands/matlabbatch.
%
% Inputs:
% i - numeric array or function, iterations of for loop or stop function
% of while loop:
%       if i is empty, all functions will be run in order until there are no
%       iterations left (e.g., [] runs func{1} followed by func{2})
%       if i is a single integer, all functions will be run that many times
%       (e.g., 2, runs two loops of func{1} followed by func{2})
%       if i is an array with size equal to number of functions, each
%       function will be run for the number of times at its index in the
%       array (e.g, [2, 1] runs func{1} 2 times followed by func{2} once)
%       if i is an array unequal to number of functions, each function will
%       be run in the order of i (e.g., [2, 1, 2] runs func{2}, func{1},
%       then func{2})
%       if i is a function, i will be set to [] and the functions will be
%       looped until the evaluation of the function is true
%
% funcs - cellstr, function(s) to run  
% options - cell array, inputs for functions as variable inputs with rows per function
% 'verbose' - optional input pair with true or false. true displays all 
% inputs/outputs; false displays nothing in the command prompt; 
% [] (default) displays normal command behavior
% 'waitbar' - optional input pair with true or false. true displays a
% waitbar; false does not (default)
% 
% Outputs:
% output - variable number of outputs with columns per output and rows per 
% function. outputs can be used as inputs as @()'output{col}{row}'.
%
% Example 1: system echo 'this' and compare output with 'that' using
% strcmp, then repeat with system echo 'that'
% output = sawa_feval(2, {'echo',@strcmp}, {'-n',{'this'; 'that'}}, {@()'output{1}{end}', 'that'})
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
% output = sawa_feval([1,2], {@randi, @minus}, 10, {@()'output{1}{end}', 1}, 'verbose', true)
% @randi 10 []
% 7
% @minus 7 1
% 6
% @minus 6 1
% 5
% 
% output = 
% 
%     [7]
%     [6]
%     [5]
%
% Example 3: get fullfile path of template image, then display image using matlabbatch
% matlabbatch{1}.spm.util.disp.data = '<UNDEFINED>';
% output = sawa_feval([], {@fullfile, matlabbatch}, ...
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
% 
% output = 
% 
%     '/Applications/spm12/canonical/avg152T1.nii'
%     []
%
% Example 4: out of order, create a random int, create eye, and find
% [out1, out2] = sawa_feval([3,1,2,2],{@eye, @find, @randi},...
%                @()'output{1}{end}',...
%                {@()'output{1}{end}'; @()'output{1}{end} > 1'}, 10)
%
% out1{:} =        out2{:} =
%
%      2                []
% 
%      1     0          [] 
%      0     1
% 
%      1                1
%      2                2
% 
%      2                1
% 
% Example 4: use @() to evaluate inputs
% sawa_feval(2,{'echo',@minus}, {@()'randi(10)';'2'}, {@()'str2double(output{1}{end})', 2}, 'verbose', true)
%
% echo 3
% 3
% @minus 3 2
% 1
% echo 2
% 2
% @minus 2 2
% 0
% 
% ans = 
% 
%     '3'
%     [1]
%     '2'
%     [0]
% 
% Example 5: run while loop until last two number are same
% output = sawa_feval(@()'output{1}{end}==output{1}{end-1}', @randi, {10;10})
%
% output = 
% 
%     [ 9]
%     [ 7]
%     [ 6]
%     [ 3]
%     [ 3]
%     [ 9]
%     [ 3]
%     [10]
%     [ 9]
%     [ 3]
%     [ 1]
%     [10]
%     [ 9]
%     [ 6]
%     [ 4]
%     [ 5]
%     [ 7]
%     [ 7]
%     
% Note: in order to avoid overlap between system commands and matlab 
% built-in functions, matlab functions should be input as function_handles
% (i.e. @func instead of 'func').
%
% Created by Justin Theiss

% if no outputs, set o to 1
o = max([1,nargout]);

% init varargout
varargout = cell(1,o);
if nargin==0, return; end; 

% init verbose
verbose = []; wait_bar = false;
for x = numel(varargin):-1:1,
    if x < numel(varargin) && ischar(varargin{x}),
        switch varargin{x}
            case 'verbose'
                verbose = varargin{x+1};
                varargin(x:x+1) = [];
            case 'waitbar'
                wait_bar = varargin{x+1};
                varargin(x:x+1) = [];
        end
    end
end

% set functions
funcs = varargin{1}; 
if ~iscell(funcs), funcs = {funcs}; end;
funcs = funcs(:);

% set options and ensure cell
if numel(varargin) == numel(funcs)+1,
    options = varargin(2:numel(funcs)+1);
else % set options empty
    options = {{}};
end
for x = 1:numel(options), if ~iscell(options{x}), options{x} = options(x); end; end;

% if i is a function, set as while loop
if isa(i, 'function_handle'), 
    stop_func = i; i = []; 
else % default is numel(output) > 0
    stop_func = @()'numel(output) > 0';
end;

% set iter to 1:number of funcs replicated to i
if numel(i)==1, 
    iter = repmat(1:numel(funcs),1,i); 
elseif numel(i) == numel(funcs), % set iter to iterations per function
    iter = arrayfun(@(x,y){repmat(x,1,y)},1:numel(funcs),i);
    iter = [iter{:}];
elseif isempty(i), % set to 
    % get rows per function
    i = nan(size(options));
    for x = 1:numel(options),
        if size(options{x},2) > 1,
            i(x) = max(cellfun(@(x)size(x,1), options{x}));
        elseif iscell(options{x}),
            i(x) = max(1, size(options{x},1));
        end
    end
    % set iter using max number of rows
    iter = repmat(1:numel(funcs),1,max(i));
    % get indices of iter to keep
    m = [];
    for x = 1:numel(i),
        m = cat(2, m, find(iter==x, i(x)));
    end
    % remove iterations beyond a function's number of rows
    iter = iter(sort(m));
elseif isnumeric(i) % set to i
    iter = i;
end

% if while loop, set
done = false; 
while ~done, 
% wait_bar
if wait_bar,
    h = settimeleft;
end
for f = 1:numel(iter),
    % set i for functions iteration
    i = iter(f);
    % set n for options iteration
    n = find(find(iter==i)==f);
    % set program
    program = local_setprog(funcs{i}); 
%     try % run program with funcs and options
        % set options (for varargout)
        tmpopts = local_eval(varargout, options{i}, n); 
        % feval
        [output{1:o}] = feval(program, funcs{i}, tmpopts, verbose); 
        % display outputs
        if verbose, 
            fprintf('\nOutput:\n');
            disp(cell2strtable(any2str(output{1:o}),' ')); 
            fprintf('\n'); 
        end;
%     catch err % display error
%         % if not string, set to string
%         if isa(funcs{i},'function_handle'),
%             func = func2str(funcs{i});
%         elseif ~ischar(funcs{i}),
%             func = 'matlabbatch';
%         else % set to funcs{i}
%             func = funcs{i};
%         end
%         % display error
%         if isempty(verbose) || verbose, 
%             fprintf('%s %s %s\n',func,'error:',err.message); 
%         end;
%         % set output to empty
%         output(1:o) = {[]};
%     end
    % concatenate results to varargout
    varargout = cellfun(@(x,y){cat(1,x,{y})}, varargout, output); 
    % wait_bar
    if wait_bar,
        settimeleft(f, 1:numel(iter), h);
    end
end
% check stop_func
done = cell2mat(local_eval(varargout, stop_func, 1));
end
end

% evaluate @() inputs
function options = local_eval(output, options, n)
    % get row from options
    if size(options, 2) > 1, % for each column, set to row
        for x = find(cellfun('isclass',options,'cell')),
            options{x} = options{x}{min(end,n)};
        end
    elseif iscell(options) && ~isempty(options), % if cell, set to row
        options = options{min(end,n)};
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

    % remove '' from @()'output{#}'
    C = regexprep(C, '^(@\(\))''(.*)''$', '$1$2');
    
    % set options
    for x = 1:numel(C), options = subsasgn(options,S{x},feval(eval(C{x}))); end;
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
    o = nargout(func); if o < 0, o = nargout; elseif o > 0, o = min(nargout, o); end;
    
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