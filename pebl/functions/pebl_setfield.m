function [A, S, R] = pebl_setfield(varargin)
% [A, S, R] = pebl_setfield(A,'property1','value1',...)
% Set field/index for object A. 
%
% Inputs:
% A - object to set field/index
% 
% Optional Properties:
% 'S' - substruct(s) to set
% 'R' - string representations to set
% 'C' - values to set to A
% 'append' - string to append to each S or R (e.g., '.field' or '(2)')
% 'remove' - true/false to remove fields at S/R/append (default is false)
% 'verbose' - true/false to display errors (default is false)
% For other properties, see also pebl_getfield
%
% Outputs:
% A - object A with set fields/index(es)
% S - substructs for each set value
% R - string representation of locations for each set value
%
% Example:
% A = struct('test', {1, 2}, 'test2', {3, 4});
% A = pebl_setfield(A, 'R', {'(1).test2', '(2).test3'}, 'C', {nan, nan})
%     
% A = 
% 
% 1x2 struct array with fields:
% 
%     test
%     test2
%     test3
% 
% A(1) = 
% 
%      test: 1
%     test2: NaN
%     test3: []
% 
% A(2) = 
% 
%      test: 2
%     test2: 4
%     test3: NaN
%
% requires: pebl_getfield
%
% Note: if the number of components to set is equal to the number of cells
% in 'C', each component will be set iteratively to the corresponding 
% value. if the number of components does not equal the number of cells in 
% 'C', the minimum between number of components and number of values will 
% be set. finally, if there is only one component, it will be set to 'C' as
% is.
%
% Created by Justin Theiss

% init vars/remove varargin{1}
if nargin==0, A = {}; return; end;
A = varargin{1}; varargin(1) = [];

% get setfield vars separate from varargin
vars = {'S','R','C','append','remove','verbose'}; 
i = 1:2:numel(varargin)-1; i = i(ismember(varargin(i),vars));
arrayfun(@(x)assignin('caller',varargin{x},varargin{x+1}),i);
varargin([i,i+1]) = []; 
if ~exist('verbose','var'), verbose = false; end;

% pebl_getfield
if ~exist('S','var') && ~exist('R','var'),
    [~, S] = pebl_getfield(A, varargin{:});
end

% init S/R/append/remove
if ~exist('R','var'), R = []; end;
if ~iscell(R), R = {R}; end;
if ~exist('S','var'), S = cell(size(R)); end;
if ~iscell(S), S = {S}; end;
if ~exist('append','var'), append = []; end;
if ~exist('remove','var'), remove = false; end;

% set (:end)/{:end} to number of previous struct
for n = find(~cellfun('isempty',R)),
    R1 = regexprep(R{n}, '[\{\(]\[?(\d*:?)*end(\+?:?-?\d*)*\]?[\)\}].*', '');
    if strcmp(R1, R{n}), continue; end;
    if isempty(R1), R1 = '(:)'; end;
    e = numel(subsref(A, sub2str(R1)));
    R{n} = regexprep(R{n}, '(:?)end', sprintf('$1%d', e));
end

% append S with R/append
for n = 1:numel(S),
    S1 = sub2str([R{min(n, end)}, append]);
    if ~iscell(S1), S1 = {S1}; end;
    S{n} = cellfun(@(x){[S{n}, x]}, S1);
end

% init C
if ~exist('C','var'), C = []; end;
if ~iscell(C) || numel(C)==1 || numel(S)==1, C = {C}; end;
if numel(C)==1 && numel(S)>1, C = repmat(C, 1, numel(S)); end;

% set C based on S
for n = 1:numel(S),
    if ~iscell(C{n}) || numel(C{n})==1 || numel(S{n})==1,
        C{n} = repmat(C(n), size(S{n}));
    elseif numel(C{n}) ~= numel(S{n}),
        C{n} = C{n}(1:min(numel(S{n}), numel(C{n})));
        S{n} = S{n}(1:min(numel(S{n}), numel(C{n})));
    end
end

% expand S and C
S = [S{:}];
C = [C{:}];

% init R for output
R = cell(size(S));

% for each, subsasgn or evaluate
for n = 1:numel(S),
    try
        % set new R
        R{n} = sub2str(S{n});
        if remove, % remove at substruct location
            if strcmp(S{n}(end).type, '.'),
                if strcmp(S{n}(max(1, end-1)).type, '()'), 
                    % remove all instances (will throw error after first)
                    S_end = S{n}(end); S{n} = S{n}(1:end-1);
                    C{n} = rmfield(subsref(A, S{n}(1:end-1)), S_end.subs);
                    A = subsasgn(A, S{n}(1:end-1), C{n});
                elseif numel(S{n}) > 1, % remove field with subsref
                    C{n} = rmfield(subsref(A, S{n}(1:end-1)), S{n}(end).subs);
                    S{n} = S{n}(1:end-1); 
                    A = subsasgn(A, S{n}, C{n});
                else % remove field without subsref
                    C{n} = rmfield(A, S{n}(end).subs);
                    S{n} = substruct('()',{1});
                    A = C{n}; 
                end
            else % cell/numeric array
                if strcmp(S{n}(end).type, '{}'), S{n}(end).type = '()'; end;
                C{n} =  [];
                A = subsasgn(A, S{n}, C{n});
            end
        else
            % ensure cell
            if ~isempty(A) && strcmp(S{n}(end).type,'{}'), 
                try
                    ck = iscell(subsref(A, S{n}));
                catch
                    ck = false;
                end
                if ~ck, 
                    eval(sprintf('[A%s] = {};', sub2str(S{n}(1:end-1))));
                end
            end
            % set field with eavl
            eval(sprintf('[A%s] = C{n};', R{n}));
        end 
    catch err
        if verbose, disp(err.message); end;
    end
end
end