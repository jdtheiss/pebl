function [fnd,vals,tags,reps]=sawa_find(fun,search,varargin)
% [fnd,vals,tags,reps]=sawa_find(fun,search,varargin)
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
% vals - a cell array of the values of true indices
% tags - a cell array of the tags of true indices
% reps - a cell array of the string representations of true indices   
%
% Example1:
% sa = struct('group',{{'Control'},{''},{''},{''},{'','Control'},{''},{''},{'Control'}});
% [fnd,vals,tags,reps] = sawa_find(@strcmp,'Control',sa,'ddt','\.group\{\d+\}$')
% fnd =
%      1     0     0     0     0     1     0     0     1
% vals = 
%     'Control'    'Control'    'Control'
% tags = 
%     '{1}'    '{2}'    '{1}'
% reps = 
%     'ddt(1).group{1}'    'ddt(5).group{2}'    'ddt(8).group{1}' 
%
% Example2:
% printres; % creates "Results" figure with two handles containing "string" property
% [fnd,vals,tags,reps] = sawa_find(@strfind,'Results',findobj('-property','string'),'','\.String$')
% fnd =
%      0    1
% vals = 
%     'Results:'
% tags = 
%     'String'
% reps =  
%     '(2).String'
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
fnd = false; vals = {}; tags = {}; reps = {};
if ~exist('fun','var')||isempty(fun), fun = {}; end;
if ~exist('search','var')||isempty(search), search = {}; end;
if ~iscell(fun), fun = {fun}; end;
if ~iscell(search), search = {search}; end;
if any(strncmp(fun,'~',1)), n = true; else n = false; end;
fun(cellfun('isclass',fun,'char')) = strrep(fun(cellfun('isclass',fun,'char')),'~',''); 
if isempty(varargin), varargin{1} = findobj; end;
if numel(varargin) < 3, varargin{3} = '.$'; end;

% getfield
[vals,tags,reps] = sawa_getfield(varargin{:});

% init outputs
fnd = num2cell(true(size(vals)));

% if any fun
if ~all(cellfun('isempty',fun))    
for i = 1:numel(vals) 
    % for each val
    fnd{i} = local_find(vals{i},fun,search,n); 
end
end

% output
fnd = cellfun(@(x)any(x),fnd); 
vals = vals(fnd); tags = tags(fnd); reps = reps(fnd); 
if iscell(vals)&&any(cellfun('isclass',vals,'cell')), vals = [vals{:}]; tags = [tags{:}]; reps = [reps{:}]; end;

function fnd = local_find(vals,fun,search,n)
    try % eval fun, search
        fnd = feval(fun{:},vals,search{:}); 
    catch % set to 0
        fnd = false;    
    end 
    
    % if cell, find ~empty
    if iscell(fnd), any(~cellfun('isempty',fnd)); end;
    
    % if empty, return false
    if isempty(fnd), fnd = false; end;
    
    % if not, get opposite
    if n, fnd = not(fnd); end;
    
    % return if any 
    fnd = any(fnd); 
return;
