function [C,S,reps] = sawa_setfield(varargin)
% [C,S,reps] = sawa_setfield(A,'property1','value1',...)
% Set field/index for object A. 
%
% Inputs:
% A - object to set field/index
% 
% Properties:
% 'idx' - index(es) of A to set 
% 'field' - string representation of field/index(es) to set
% 'tag' - string representation of field/index(es) to append
% 'vals' - values to set to A(idx).field
% For other properties, see also sawa_getfield
%
% Outputs:
% C - object A with set fields/index(es)
% S - substructs for each set value
% reps - (optional) string representation of locations for each set value
%
% Example:
% % create struct array
% [C,S,reps] = sawa_setfield([],'idx',1:4,'field','.test1.test2{1}','vals',{1,2,3,4})
% C = 
% 
% 1x4 struct array with fields:
% 
%     test1
%
% S = 
% 
%     [1x4 struct]    [1x4 struct]    [1x4 struct]    [1x4 struct]
%
% reps = 
% 
%   Columns 1 through 3
% 
%     '(1).test1.test2{1}'    '(2).test1.test2{1}'    '(3).test1.test2{1}'
% 
%   Column 4
% 
%     '(4).test1.test2{1}'
%     
% % set new index equal to same as index 4 
% [C,S,reps] = sawa_setfield(C,'idx',5,'tag','.new','func',@eq,'search',4)
% 
% C = 
% 
% 1x5 struct array with fields:
% 
%     test1
%
% S = 
% 
%     [1x5 struct]
%
% reps = 
% 
%     'C(5).test1.test2{1}.new'
%     
% requires: sawa_getfield
%
% Created by Justin Theiss

% set warning off
w = warning; warning('off','all');

% init vars/remove varargin{1}
if nargin==0, C = {}; return; end;
A = varargin{1}; C = A; varargin(1) = [];

% get setfield vars separate from varargin
vars = {'rep','idx','field','tag','vals'}; 
i = 1:2:numel(varargin)-1; i = i(ismember(varargin(i),vars));
arrayfun(@(x)assignin('caller',varargin{x},varargin{x+1}),i);
varargin([i,i+1]) = []; 

% init vars
if ~exist('idx','var')||isempty(idx), idx = []; end;
if ~exist('field','var')||isempty(field), field = ''; end;
if ~exist('tag','var')||isempty(tag), tag = ''; end;
if ~exist('rep','var')||isempty(rep), rep = inputname(1); end;
if isempty(rep), rep = ''; end;

% set tags based on idx/field/tag
S = local_substruct(A,idx,field); 

% sawa_getfield
if ~exist('vals','var')||isempty(idx)||isempty(field),
[tmpC,tmpS] = sawa_getfield(A,varargin{:});
end

% init vals/reps
if ~exist('vals','var'), vals = tmpC; end;
if ~iscell(vals), vals = {vals}; end;
if isempty(field),
    if isempty(idx), % use tmpS
        S = tmpS; 
    else % use tmpS(2:end), but S(1)
        S1 = repmat(S,1,numel(tmpS)); tmpS = repmat(tmpS,1,numel(S));
        S = cellfun(@(x,y){cat(2,x(1),y(2:end))},S1,tmpS); 
    end
end
if numel(S)~=numel(vals), vals = repmat(vals,1,numel(S)); end;

% append tag
if ~isempty(tag), S = cellfun(@(x){[x,local_substruct([],[],tag)]},S); end;

% init C as needed
for x = 1:numel(S), C = local_init(C,S{x}); end;

% for each rep, eval 
for n = 1:numel(S), C = subsasgn(C,S{n},vals{n}); end;

% if reps, set reps
if nargout==3, reps = cellfun(@(x){local_strgen(rep,x)},S); end;

% set warning on
warning(w.state,w.identifier);
return;

% get substructs
function S = local_substruct(A,idx,str)
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
if iscell(A), type = '{}'; elseif numel(A) > 1||~isempty(idx), type = '()'; else type = '.'; end;

% check for fieldnames
try f = ~isempty(fieldnames(A)); catch, f = ~isempty(idx); end;
if ~f, S = S1; return; end;

% if . type, set to fieldnames
if strcmp(type,'.'),
    S = cellfun(@(x){substruct(type,x)},fieldnames(A));
else % otherwise set to index
    n = num2cell(size(A));
    if isempty(idx)
        % get indices from 1 to size A
        n1 = [1:sub2ind(size(A),n{:})]';
    else % get indices from idx
        if ~iscell(idx), idx = {idx}; end;
        idx(end+1:numel(size(A))) = {1}; 
        tmp = subsasgn(zeros(size(A)),substruct('()',idx),1);
        n1 = find(tmp); 
    end
    % get indices per dim
    [n{1:numel(n)}] = ind2sub(max(size(A),ones(1,numel(size(A)))),n1); 

    % if all one row, set to only second dim
    if size(A,1)<=1&&all(n{1}==1)&&numel(n)==2, n = n(:,2); end;
    
    % set substruct
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

% init C as needed
function C = local_init(C,S)
% go from last substruct index to first, setting empty
for x = numel(S):-1:1, 
    try C = subsasgn(C,S(1:x),{}); return; end; 
end;
return;