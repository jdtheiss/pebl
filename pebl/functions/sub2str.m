function str = sub2str(S)
% str = sub2str(S)
% Convert a substruct to string (or vice versa)
%
% Inputs:
% S - substruct array (see substruct) or string
% 
% Outputs:
% str - string representation of S or substruct from string
%
% Example 1: Generate string from substruct
% S = substruct('{}',{1},'.','spm','.','util','.','disp','.','data');
% str = sub2str(S)
%
% str =
% 
% {1}.spm.util.disp.data
% 
% Example 2: Generate substruct from string
%
% str = '{1}.spm.util.disp.data';
% S = sub2str(str)
%
% S = 
% 
% 1x5 struct array with fields:
% 
%     type
%     subs
% 
% Example 3: Generate multiple substructs for multi-indexing
% 
% str = '(1:3).test';
% S = sub2str(str)
%
% S =
% 
%    [1x2 struct]    [1x2 struct]    [1x2 struct]
% 
% Created by Justin Theiss

% if substruct, generate str
if isstruct(S),
    str = local_genstr(S);
elseif ischar(S), % if char generate substruct
    % get parenthetical index at end 
    P = regexp(S, '\([^\.]+$', 'match');
    if isempty(P), P = ''; end;
    % remove end for getting earlier indices
    R = regexprep(S, '\([^\.]+$', '');
    % get matches of earlier indices
    M = regexp(R, '\d+:\d+', 'match');
    for n = 1:numel(M), % for each match, set to each number in indices
        R = arrayfun(@(x){regexprep(R, M{n}, num2str(x), 'once')}, eval(M{n}));
        if all(cellfun('isclass', R, 'cell')), R = [R{:}]; end;
    end
    % re-append P
    R = strcat(R, P);
    if ~iscell(R), R = {R}; end;
    % init str and get for each R
    str = cell(size(R));
    for x = 1:numel(R),
        str{x} = local_gensub(R{x});
    end
    if numel(str)==1, str = str{1}; end;
else % otherwise, return empty
    str = [];
end
end

function str = local_genstr(S)
% str = local_genstr(S)
% Generate string from substruct

% init str
str = '';
% for each substruct, append to str
for x = 1:numel(S),
    if strcmp(S(x).type,'.')
        str = cat(2,str,S(x).type,S(x).subs);
    else % otherwise () or {}
        subs = cellfun(@(x){genstr(x)},S(x).subs); 
        str = cat(2,str,S(x).type(1),strjoin(subs,','),S(x).type(2));
    end
end
% set ':' to :
str = strrep(str, ''':''', ':');
end

function S = local_gensub(str)
% S = local_gensub(str)
% Generate substruct from string.

% if no str, return empty substruct
S = [];
if isempty(str), return; end;
% remove leading characters
str = regexprep(str, '^\w+', '');
% set : to ':'
str = regexprep(str, '(\D)(:)', '$1''$2''');
% get types and indices
[types, n] = regexp(str, {'\.', '\([^\)]+\)', '\{[^\}]+\}'}, 'match', 'start');
% sort n and get indices for typesubs
y = sort([n{:}]);
i0 = 1:2:numel(y)*2;
i1 = 2:2:numel(y)*2;
% set indices for typesubs
n0 = cellfun(@(x){i0(ismember(y, x))}, n);
n1 = cellfun(@(x){i1(ismember(y, x))}, n);
% set types
typesubs(n0{1}) = {'.'};
typesubs(n0{2}) = {'()'};
typesubs(n0{3}) = {'{}'};
% remove ()/{}
str = regexprep(str, regexptranslate('escape',[types{2:3}]), ''); 
% set subs for .
subs = regexp(str, '\.', 'split');
typesubs(n1{1}) = subs(~cellfun('isempty',subs));
% set subs for ()/{} by evaluating inside ()/{} as cell
typesubs([n1{2:3}]) = cellfun(@(x){eval(['{',x(2:end-1),'}'])}, [types{2:3}]);
S = substruct(typesubs{:});
end