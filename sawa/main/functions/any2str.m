function out = any2str(maxrow,varargin)
% out = any2str(maxrow,varargin)
% This function will convert any class to its string representation.
% 
% Inputs:
% maxrow - max row that an input can have (see example). Default is inf.
% varargin - any class to be input (see example)
%
% Outputs:
% out - string representation equal to the number of arguments input
%
% Example:
% out = any2str(2,'test',{'test';10},[1,2,3],@disp,{struct('testing',{'this'}),12,'testing'})
% out = 
%
%   'test'  'test'  [1 2 3]   @disp   {[1x1 struct] 12 'testing'}
%           10
%
% Note: for vertical cell arrays, no '{}'s are added (see example above).
%
% Created by Justin Theiss

% init vars
out = cell(size(varargin));
if ~exist('maxrow','var'), return; end;
if isempty(maxrow), maxrow = inf; end;
% for each varargin
for v = 1:numel(varargin)
% set out
out{v} = [];

% if more than maxrow, create string representation
if size(varargin{v},1)>maxrow||(~ischar(varargin{v})&&size(varargin{v},1)>maxrow), 
varargin{v}=['[' num2str(size(varargin{v})) ' ' class(varargin{v}) ']'];
varargin{v} = regexprep(varargin{v},'\s\s','x'); 
end

% if varargin{v} is empty and cell, set to '{}' and skip
if iscell(varargin{v})&&isempty(varargin{v}), out{v} = '{}'; continue; end;

% switch class of varargin
switch class(varargin{v})
case 'char' % char
    clear tmp; tmp = cellstr(varargin{v}); 
    out{v} = char(cellfun(@(x){['''' x '''']},tmp)); % set '' around each
case 'cell' % run any2str for cell
    out{v} = cellfun(@(x){any2str(maxrow,x)},varargin{v}); 
    r = size(varargin{v},1); % get rows
    clear tmp; tmp = arrayfun(@(x){sprintf('%s ',out{v}{x,:})},1:r);
    if r ==1, tmp{1} = ['{' tmp{1}]; tmp{end} = [deblank(tmp{end}) '}']; end; % set {}
    out{v} = sprintf('%s\n',tmp{:}); 
case {'double','numeric','logical'} % mat2str
    out{v} = mat2str(varargin{v});
case 'function_handle' % put @ in front
    clear tmp; tmp = func2str(varargin{v});
    if ~strncmp(tmp,'@',1), tmp = ['@' tmp]; end;
    out{v} = tmp;
otherwise % [size class]
    if any(strfind(class(varargin{v}),'int')), % if integer, run as double
    out{v} = any2str(maxrow, double(varargin{v}));
    else % if not integer, set to [size class]
    out{v} = ['[' num2str(size(varargin{v})) ' ' class(varargin{v}) ']'];
    out{v} = regexprep(out{v},'\s\s','x');
    end
end
end

% if only one output, set out 
if numel(out)==1, out = out{1}; end;
