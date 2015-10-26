function out = sawa_cat(dim,varargin)
% out = sawa_cat(dim,A1,A2,...)
% This function will force the directional concatenation of the set of
% inputs A1, A2, etc. by padding inconsistencies with cells.
%
% Inputs: 
% dim - 1 for vertcat, 2 for horzcat
% varargin - the inputs to concatenate
%
% Outputs:
% out - the concatenated cell array
% 
% Example:
% out = sawa_cat(1,{'Cell1','Cell2'},'Test',{'Cell4',5,'Cell6'})
% out = 
% 'Cell1'   'Cell2' []
% 'Test'    []      []
% 'Cell4'   5       'Cell6'
%
% Created by Justin Theiss

% set out to empty
out = {}; 
% for each varargin
for x = 1:numel(varargin)
% make cell if not already
if ~iscell(varargin{x}), varargin{x} = varargin(x); end;
% get current sizes
outsize = size(out); varsize = size(varargin{x});
% create padding
pad(mod(dim,2)+1) = abs(outsize(mod(dim,2)+1)-varsize(mod(dim,2)+1));
% pad out or varargin
if varsize(mod(dim,2)+1) > outsize(mod(dim,2)+1)
pad(dim) = outsize(dim);
out = cat(mod(dim,2)+1,out,cell(pad));
elseif outsize(mod(dim,2)+1) > varsize(mod(dim,2)+1)
pad(dim) = varsize(dim);
varargin{x} = cat(mod(dim,2)+1,varargin{x},cell(pad));
end
% cat
out = cat(dim,out,varargin{x});
end
