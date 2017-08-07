function [C, S, R] = pebl_getfield(A, varargin)
% [C, S, R] = pebl_getfield(A, 'property1', value1, ...)
% Return values, substructs, and string representations from A.
%
% Inputs:
% A - object (cell, structure, etc.)
% 'S' - substruct(s) of locations in A (i.e. subsref(A, S{1}))
% 'R' - string(s) representation corresponding to location in A 
%   (i.e. eval(['A', R]))
% 'expr' - regular expression to search within A (default returns all values)
% 'fun' - function and arguments to be used to evaluate with each C as 
%   feval(fun{1}, C{x}, fun{2:end}).
%   The result from each evaluation should be true or false in order to
%   create a logical array to be used in indexing C, S, and R.
% 'r' - recursion limit/number of levels to search (default is inf)
% 'verbose' - set to true if you wish to see error messages
%   (default is false)
%
% Outputs:
% C - values indexed from A
% S - substruct of locations C in A (i.e. C{1} == subsref(A, S{1}))
% R - string representations correpsonding to location of each value in C
% (i.e. C{1} == eval(['A', R{1}]))
%
% Example 1:
% matlabbatch{1}.spm.util.disp.data = '<UNDEFINED>';
% [C, S, R] = pebl_getfield(matlabbatch, 'expr', '.*\.disp')
% 
% C = 
% 
%     [1x1 struct]
% 
% 
% S = 
% 
%     [1x4 struct]
% 
% 
% R = 
% 
%     '{1}.spm.util.disp'
%
% Example 2:
% [C, S, R] = pebl_getfield(matlabbatch, 'fun', @(x)strcmp(x, '<UNDEFINED>'))
% 
% C = 
% 
%     '<UNDEFINED>'
% 
% 
% S = 
% 
%     [1x5 struct]
% 
% 
% R = 
% 
%     '{1}.spm.util.disp.data'
%
% Note: when searching large arrays or arrays with repetitive elements 
% (e.g., a figure handle) it's best to set the recursion limit 'r' to a 
% lower number.
%
% Created by Justin Theiss

% init other options
arrayfun(@(x)assignin('caller',varargin{x},varargin{x+1}), 1:2:numel(varargin));
if ~exist('r','var')||isempty(r), r = inf; end;
if ~exist('verbose','var')||isempty(verbose), verbose = false; end;
if exist('R','var')||exist('S','var'), input_SR = true; else input_SR = false; end;

% get substructs of A
if ~exist('S', 'var'),
    S = struct2sub(A, r);
elseif ~iscell(S),
    S = {S};
end

% set S from R
if exist('R', 'var'), 
    if ~iscell(R), R = {R}; end;
    S = cellfun(@(x){sub2str(x)}, R);
    if all(cellfun('isclass', S, 'cell')), S = [S{:}]; end;
end
% reset R (in case changes from S)
R = cellfun(@(x){sub2str(x)}, S);

% find R using regexp
if exist('expr','var'),
    if ~iscell(expr), expr = {expr}; end;
    R_ = cell(size(expr));
    for x = 1:numel(expr),
        R_ = regexp(R, expr{x}, 'match', 'once');
    end
    if any(cellfun('isclass',R_,'cell')), R_ = [R_{:}]; end;
    R = R_;
    S = cellfun(@(x){sub2str(x)}, R);
end

% use subsref to get values of subsref(A, S)
C = cell(size(S)); 
for x = 1:numel(S),
    try
        C{x} = subsref(A, S{x});
    catch err
        if verbose, fprintf('%s\n', R{x}, err.message); end;
        % if input R and failed, remove from outputs
        if input_SR, S{x} = []; R{x} = []; end;
    end
end

% remove empty cells
C = C(~cellfun('isempty', R));
S = S(~cellfun('isempty', R));
R = R(~cellfun('isempty', R));

% find using function
if exist('fun','var'),
    if ~iscell(fun), fun = {fun}; end;
    fnd = false(1, numel(C));
    for x = 1:numel(C),
        try
            fnd(x) = feval(fun{1}, C{x}, fun{2:end});
            if ~islogical(fnd(x)), fnd(x) = false; end;
        catch
            fnd(x) = false;
        end
    end
    C = C(fnd);
    S = S(fnd);
    R = R(fnd);
end

% return only unique R
if ~all(cellfun('isempty',R)),
    [R, uidx] = unique(R, 'stable');
    C = C(uidx);
    S = S(uidx);
end
end