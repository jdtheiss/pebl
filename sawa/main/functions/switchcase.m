function result = switchcase(expr, varargin)
% result = switchcase(expr, case1, value1, case2, value2, ...)
% Return the results of switching cases based on expression.
%
% Inputs:
% expr: any, expression to switch cases
% case: any, case to be switched
% value: any, value to return as result
% 'verbose' (optional): true/false, print the switch statement (default is
% false)
% 'nargout_n' (optional): number of outputs expected (default is 1)
%
% Outputs:
% result: any, result of switched case ([] if no result)
%
% Example 1: switching case based on value of x
% x = 2;
% result = switchcase(x, 1, x-1, 2, x+1, 'otherwise', x, 'verbose', true)
% switch [2]
% case [1]
% [1]
% case [2]
% [3]
% otherwise
% [2]
% end
% 
% 
% result =
% 
%      3
%
% Example 2: using @() function_handles to display result is > or < 1
% switchcase(gt(randn, 1), true, @()disp('greater than'), 'otherwise',...
%   @()disp('less than'), 'verbose', true, 'nargout_n', 0);
% switch [false]
% case [true]
% @()disp('greater than')
% otherwise
% @()disp('less than')
% end
% 
% less than
%
% Created by Justin Theiss

% get verbose input
n = find(strcmp(varargin,'verbose'));
verbose = varargin(n+1);
varargin(n:n+1) = [];
n = find(strcmp(varargin,'nargout_n'));
nargout_n = varargin(n+1);
varargin(n:n+1) = [];

% init verbose and narargout_n
if isempty(verbose), verbose = false; else verbose = verbose{1}; end;
if isempty(nargout_n), nargout_n = 1; else nargout_n = nargout_n{1}; end;

% print statement if verbose
if verbose,
    case_str = cellfun(@(x){genstr(x)}, varargin);
    str = sprintf('case %s\n%s\n', case_str{:});
    str = sprintf('switch %s\n%send\n', genstr(expr), str);
    str = strrep(str, 'case ''otherwise''', 'otherwise');
    fprintf('%s\n', str);
end

% for each varargin, switch case/otherwise
for n = 1:2:numel(varargin), 
    % switch case
    switch local_result(expr, nargout_n)
        case varargin{n},
            result = local_result(varargin{n+1}, nargout_n);
            break;
        otherwise,
            if strcmp(varargin{n}, 'otherwise'),
                result = local_result(varargin{n+1}, nargout_n);
                break;
            end
    end
end

% set result to empty if none set
if ~exist('result','var'), result = []; end;
end

function result = local_result(var, nargout_n)
% return result from var or feval

% if @() function handle, feval
if isa(var,'function_handle') && strncmp(func2str(var), '@()', 3),
    [result{1:nargout_n}] = feval(var);
    if nargout_n == 1, result = result{1}; end;
else % set result to var
    result = var;
end
end