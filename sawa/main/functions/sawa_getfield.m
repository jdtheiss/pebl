function [C,S,reps] = sawa_getfield(varargin)
% [C,S,reps] = sawa_getfield(A,'property1','value1',...)
% Return values, substructs, and/or string representations from an object A.
%
% Inputs: 
% A - object to be indexed
%
% Properties: 
% 'S0' - initial substruct. default is []
% 'rep' - string representation of A (see example 2). default is inputname(1) or ''
% 'str' - string to evaluate for each index in A (see example 3). default is []
% 'expr' - regular expression to search within A. default is '.*' which will
% return all values in A
% 'r' - number of recursions allowed. default is inf
% 'func' - function to search values to return. default is {}
% 'search' - input for function. default is {}
%
% Outputs:
% C - values indexed from A
% S - substruct of locations C in A (i.e. C{1} == subsref(A,S{1}))
% reps - string representations correpsonding to location of each value in C
% (i.e. C{1} == eval(reps{1}))
%
% Example 1:
% A{1,1}.field = 'test1'; A{2,1}.field2.field3{2}.field4 = 'test2';
% A{3,1}.field(2).field2.field3{1}.field4 = 'test3';
% 
% [C, S] = sawa_getfield(A)
% 
% C = 
% 
%     'test1'    []    'test2'    []    'test3'
%
% S = 
% 
%     Columns 1 through 4
% 
%     [1x2 struct]    [1x4 struct]    [1x5 struct]    [1x4 struct]
% 
%   Column 5
% 
%     [1x7 struct]
%     
% Example 2:
% testarray{1}.field1.field2{1} = 'test1'; 
% testarray{1}.field1(2).field2{1} = 1;
%
% [C, S, reps] = sawa_getfield(testarray{1},'rep','testarray{1}','func',@eq,'search',1)
%
% C = 
% 
%     [1]
% 
% S = 
% 
%     [1x4 struct]
% 
% reps = 
% 
%     'testarray{1}.field1(2).field2{1}'
%
% Example 3:
% sa = struct('group',{'Control','Control','Patient','Control','Patient'});
%     
% [C, S] = sawa_getfield(sa,'str','.group')
%
% C = 
% 
%     'Control'    'Control'    'Patient'    'Control'    'Patient'
%  
% S = 
% 
%   Columns 1 through 4
% 
%     [1x2 struct]    [1x2 struct]    [1x2 struct]    [1x2 struct]
% 
%   Column 5
% 
%     [1x2 struct]
%     
% Note 1: String representations will only be generated if reps is output
% or an expr other than '.*' is input. Generating string representations
% can slow down performance.
%
% Note 2: the number of recursions needed corresponds to the number of
% levels to search (i.e. index.field). For example, 7 recursions are used
% to return values in example 1 ('{3,1}.field(2).field2.field3{1}.field4'),
% while only 4 recursions are needed in example 2 ('field(2).field2{1})').
% For example, setting r to 0 will return {}, setting r to 1 will return A,
% and so forth. For returning values from multi-leveled structures or
% figure handles, it is advisable to restrict the number of recursions to 
% the minimum that is needed (or use 'str' for faster performance).
%
% Created by Justin Theiss

% init outputs
C = {}; S = {}; reps = {};

% init vars
if nargin==0, return; end; 
A = varargin{1}; 
arrayfun(@(x)assignin('caller',varargin{x},varargin{x+1}),2:2:numel(varargin)-1); 
if ~exist('S0','var'), S0 = []; end; 
if ~exist('rep','var')||isempty(rep), rep = inputname(1); end;
if isempty(rep), rep = ' '; end;
if ~exist('str','var')||isempty(str), str = []; end; 
if ~exist('expr','var')||isempty(expr), expr = '.*'; end;
if ~exist('r','var')||isempty(r), r = inf; end;
if ~exist('func','var')||isempty(func), func = {}; end;
if ~exist('search','var')||isempty(search), search = {}; end;

% if number of recursions > r, return (avoid loop errors)
dbs = dbstack; recs = numel(find(strcmp({dbs.name},mfilename))); 
if recs > r, return; end; 

% get substructs 
S1 = local_substruct(A,str);

% if returning reps or searching with expr, get str rep
if nargout==3 || ~strcmp(expr,'.*'), rep1 = local_strgen(rep,S0); else rep1 = rep; end;

% init fnd as false
fnd = false;    

% if found
if any(regexp(rep1,expr)),
if ~isempty(func) && recs > 1 % eval func(A,search)
   fnd = local_find(A,func,search); 
elseif isempty(S1) || recs == r % if no substruct/recursion met
    fnd = true;
elseif ~strcmp(expr,'.*') % otherwise if not returning all
    fnd = true;
end
end

% if found, return
if fnd && (~isempty(S0) || r==1), 
    C = {A}; 
    S = {S0}; 
    reps = strtrim({rep1});
    return;
elseif ~isempty(S1) % otherwise set C with subsref
    C = cell(size(S1)); S = cell(size(S1));
    for x = 1:numel(S1), 
        try % try to subsref
            C{x} = subsref(A,S1{x}); S{x} = cat(2,S0,S1{x});
        catch % if fails, set to empty
            C{x} = []; S{x} = [];
        end
    end;
    % if str, end on next recursion
    if ~isempty(str), r = recs + 1; end;
end

% set vars for sawa_getfield
vars = cellfun(@(x){[x,{eval(x)}]},{'rep','expr','r','func','search'}); vars = [vars{:}];

% for each val, sawa_getfield
for x = 1:numel(C), 
    if nargout==3 % output reps
    [C{x},S{x},reps{x}] = sawa_getfield(C{x},'S0',S{x},vars{:}); 
    else % otherwise
    [C{x},S{x}] = sawa_getfield(C{x},'S0',S{x},vars{:}); 
    end
end;

% output cells without empty substructs
fnd = ~cellfun('isempty',S);
C = [C{fnd}]; S = [S{fnd}]; 
if nargout==3, reps = [reps{fnd}]; end;
return;

% get substructs
function S = local_substruct(A,str)
% set initial to empty
S = {}; S1 = {};
if ~exist('str','var')||isempty(str), str = []; end;

% create substruct from str
if ~isempty(str) % get types
    types = regexp(str,'(?<type1>\([^\)]+\))?(?<type2>\.[\w\d]+)?(?<type3>\{[^\}]+\})?','names');
     % get type in order
    type = squeeze(struct2cell(types));
    type = type(~cellfun('isempty',type)); 
    type = reshape(type,1,numel(type));
    % get val in order
    subs = cellfun(@(x)x,regexp(type,'[^\(\)\.\{\}]+','match'));
    % remove val from type
    type = strrep(type,subs,'');
    % set quotes around :
    subs = strrep(subs,':',''':''');
    % eval subs for {} or ()
    subs(ismember(type,{'()','{}'})) = cellfun(@(x){eval(['{' x '}'])},subs(ismember(type,{'()','{}'})));
    % get new substruct
    S1 = cellfun(@(x,y)substruct(x,y),type,subs);
end

% get type
clear type;
if iscell(A)&&~isempty(A), type = '{}'; elseif numel(A) > 1, type = '()'; else type = '.'; end;

% check for fieldnames
try f = ~isempty(fieldnames(A)); catch, f = iscell(A)&&~isempty(A); end;
if ~f, S = S1; return; end;

% if . type, set to fieldnames
if strcmp(type,'.'),
    if isempty(str), % if no str, set to fieldnames
        S = cellfun(@(x){substruct(type,x)},fieldnames(A)); 
    else % otherwise, set to one cell
        S = {[]};
    end;
else % otherwise set to index
    n = num2cell(size(A)); 
    idx = [1:sub2ind(size(A),n{:})]';
    [n{1:numel(n)}] = ind2sub(size(A),idx);
    if size(A,1)==1 && numel(n)==2, n = n(:,2); end;
    n = num2cell([n{:}]);
    S = arrayfun(@(x){substruct(type,n(x,:))},1:size(n,1));
end

% if str, append
if ~isempty(S1), S = cellfun(@(x){cat(2,x,S1)},S); end;
return;

% generate string rep
function rep = local_strgen(rep,S)
% if no substruct, return
if ~exist('rep','var')||isempty(rep), rep = ''; end;
if ~exist('S','var')||isempty(S), return; end;

% append rep
for x = 1:numel(S),
    if strcmp(S(x).type,'.')
        rep = cat(2,rep,S(x).type,S(x).subs);
    else % otherwise () or {}
        subs = cellfun(@(x){num2str(x)},S(x).subs);
        rep = cat(2,rep,S(x).type(1),strjoin(subs,','),S(x).type(2));
    end
end
return;

% evaluate search function
function fnd = local_find(A,func,search)
% init vars
if any(strncmp(func,'~',1)), n = true; else n = false; end;
if n, func = strrep(func,'~',''); end;
if ~iscell(func), func = {func}; end;
if ~iscell(search), search = {search}; end;

try % eval fun, search
    fnd = feval(func{:},A,search{:}); 
catch % set to 0
    fnd = false;    
end 

% if cell, find ~empty
if iscell(fnd), fnd = any(~cellfun('isempty',fnd)); end;

% if empty, return false
if isempty(fnd), fnd = false; end;

% if not, get opposite
if n, fnd = not(fnd); end;

% return if any 
fnd = any(fnd); 
return;