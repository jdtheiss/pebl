function C = pebl_cat(dim, varargin)
% C = pebl_cat(dim, A1, A2,...)
% This function will force the directional concatenation of a set of
% inputs A1, A2, etc. by padding inconsistencies with cells/nans.
%
% Inputs: 
% dim - dimension along which to concatenate
% varargin - inputs to concatenate
%
% Outputs:
% C - concatenated array
% 
% Example 1: concatenate cells with varying sizes along first dimension
% C = pebl_cat(1,{'Cell1','Cell2'},'3',{'Cell4',5,'Cell6'})
% C = 
% 
%     'Cell1'    'Cell2'         []
%     '3'             []         []
%     'Cell4'    [    5]    'Cell6'
%
% Example 2: concatenate numbers with different dimensions
% C = pebl_cat(4, [1;2], [3,4], 5 * ones(1,1,2))
% C(:,:,1,1) =
% 
%      1   NaN
%      2   NaN
% 
% C(:,:,2,1) =
% 
%    NaN   NaN
%    NaN   NaN
% 
% C(:,:,1,2) =
% 
%      3     4
%    NaN   NaN
% 
% C(:,:,2,2) =
% 
%    NaN   NaN
%    NaN   NaN
% 
% C(:,:,1,3) =
% 
%      5   NaN
%    NaN   NaN
% 
% C(:,:,2,3) =
% 
%      5   NaN
%    NaN   NaN
%    
% Created by Justin Theiss

% set C to empty
if any(cellfun('isclass',varargin,'cell')), C = {}; else C = []; end;
% pad cell or pad nan
if iscell(C), padfn = @cell; else padfn = @nan; end;
% for each varargin
for x = 1:numel(varargin)
    % make cell if out is cell
    if ~iscell(varargin{x}) && iscell(C), varargin{x} = varargin(x); end;
    % pad C and varargin{x} (after first)
    if x > 1, 
        C = update_pad(dim, C, varargin{x}, padfn); 
        varargin{x} = update_pad(dim, varargin{x}, C, padfn); 
    end
    % cat each varargin to C
    C = cat(dim, C, varargin{x});
end
end

function [sizeA, sizeB] = update_size(dim, A, B)

% get sizes
sizeA = size(A); 
sizeB = size(B);
% update sizes so that max dimension in each 
maxdim = max(max(numel(sizeA), numel(sizeB)), dim);
sizeA(end+1:maxdim) = 1;
sizeB(end+1:maxdim) = 1;
end

function A = update_pad(dim, A, B, fn)

% get size differences
[sizeA, sizeB] = update_size(dim, A, B);
dif = sizeB - sizeA;
% for each difference, cat along dimension
for x = 1:numel(dif),
    if dif(x) > 0 && x ~= dim,
        idx = update_size(dim, A, B);
        idx(x) = dif(x);
        A = cat(x, A, fn(idx));
    end
end
end