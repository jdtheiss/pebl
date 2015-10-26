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
%   'test'  {'test'}  [1 2 3]   @disp   {[1x1 struct]} {12} {'testing'}
%           {10}
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
% switch class of varargin
switch class(varargin{v})
case 'char' % char
    out{v} = strcat('''', varargin{v}, '''');
    out{v} = char(out{v});
case 'cell' % run any2str for cell
    out{v} = strcat('{',cellfun(@(x){any2str(maxrow,x)},varargin{v}),'}');
    r = size(out{v},1); % get rows
    clear tmp; tmp = arrayfun(@(x){sprintf('%s ',out{v}{x,:})},1:r);
    out{v} = char(tmp{:});
case 'double' % mat2str
    out{v} = mat2str(varargin{v});
case 'function_handle' % put @ in front
    out{v} = ['@' func2str(varargin{v})];
otherwise % [size class]
    out{v} = ['[' num2str(size(varargin{v})) ' ' class(varargin{v}) ']'];
    out{v} = regexprep(out{v},'\s\s','x');
end
end
% if only one output, set out 
if numel(out)==1, out = out{1}; end;