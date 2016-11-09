function [fnd,C,S,reps]=sawa_find(fun,search,varargin)
% [fnd,C,S,reps]=sawa_find(fun,search,varargin)
% searches array or obj for search using function fun
%
% Inputs:
% fun - (optional) any function used as such:
% feval(fun,itemstosearch,search). To use ~, fun should be string 
% (e.g., '~strcmp'). 
% search - can be a string, number or cell array (for multiple arguments).
% varargin - inputs for sawa_getfield (i.e., A, irep, itag)
%
% Outputs:
% fnd - a numeric array of logicals where the search was true (relating to 
% indices of sawa_getfield(varargin{:})).
% C - a cell array of the values of true indices
% S - a cell array of the tags of true indices
% reps - a cell array of the string representations of true indices   
%
% Example1:
% sa = struct('group',{{'Control'},{''},{''},{''},{'','Control'},{''},{''},{'Control'}});
% [fnd,C,S,reps] = sawa_find(@strcmp,'Control',sa,'ddt','\.group\{\d+\}$')
% fnd = 
%      1     0     0     0     0     1     0     0     1
% C = 
%     'Control'    'Control'    'Control'
% S = 
%     [1x3 struct]    [1x3 struct]    [1x3 struct]
% reps = 
%     'ddt(1).group{1}'    'ddt(5).group{2}'    'ddt(8).group{1}'
%
% Example2:
% printres; % creates "Results" figure with two handles containing "string" property
% h = get(findobj('-property','string'));
% [fnd,C,S,reps] = sawa_find(@strfind,'Results',h,'expr','\.String$')
% fnd =
%      0    1
% C = 
%     'Results:'
% S = 
%     [1x2 struct]
% reps =  
%     '(2,1).String'
% 
% NOTE: If no varargin is entered, the default is findobj. Additioanlly, if
% [] is input as the third varargin (itag), sawa_find will use sawa_getfield to
% recursively search through each value that does not return true. In some cases, 
% this may not return all values if the recursion limit is met. Similarly, when searching
% handles with a vague itag (e.g., '\(1\)$'), it is likely that you will return 
% looped handle referencing (e.g., '.Parent.CurrentFigure.Parent.CurrentFigure.Children(1)').
%
% requires: sawa_getfield
%
% Created by Justin Theiss

% init vars
fnd = false; C = {}; S = {}; reps = {};
if ~exist('fun','var')||isempty(fun), fun = {}; end;
if ~exist('search','var')||isempty(search), search = {}; end;
if ~iscell(fun), fun = {fun}; end;
if ~iscell(search), search = {search}; end;
if any(strncmp(fun,'~',1)), n = true; else n = false; end;
fun(cellfun('isclass',fun,'char')) = strrep(fun(cellfun('isclass',fun,'char')),'~',''); 
if isempty(varargin), varargin{1} = findobj; end;
if numel(varargin) < 3, varargin{2} = 'expr'; varargin{3} = '.$'; end;

% getfield
[C,S,reps] = sawa_getfield(varargin{:});

% init outputs
fnd = num2cell(true(size(C)));

% if any fun
if ~all(cellfun('isempty',fun))    
    for i = 1:numel(C) 
        % for each val
        fnd{i} = local_find(C{i},fun,search,n); 
    end
end

% output
fnd = cellfun(@(x)any(x),fnd); 
C = C(fnd); S = S(fnd); reps = reps(fnd); 

function fnd = local_find(vals,fun,search,n)
    try % eval fun, search
        fnd = feval(fun{:},vals,search{:}); 
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
