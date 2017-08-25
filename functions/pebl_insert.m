function C = pebl_insert(dim, A, index, B)
% C = pebl_insert(dim, A, index, B)
% Insert array B into A before an index along a certain dimension.
%
% Inputs:
% dim - dimension along which to insert B into A (default is first
% non-singleton dimension)
% A - array (cell, numeric, char)
% index - index at which to insert B (default is 1)
% B - array to insert
%
% Outputs:
% C - new array with inserted components
% 
% Example 1: insert text into character array
% C = pebl_insert(2, 'example text', 8, ' 1')
% C = 
%
% example 1 text
%
% Example 2: insert horizontal cells into vertical array
% C = pebl_insert([], {1;2;3;4}, 2, {0,0,0})
% C = 
% 
%     [1]     []     []
%     [0]    [0]    [0]
%     [2]     []     []
%     [3]     []     []
%     [4]     []     []
%
% requires: pebl_cat
%
% Created by Justin Theiss

% init vars
if isempty(dim), dim = find(size(A) > 1, 1); end;
if isempty(dim), dim = 1; end;
if isempty(index), index = 1; end;

% for each index, set D
D = {};
index = [0, index];
for n = 2:numel(index),
    D{end+1} = local_index(dim, A, max(1, index(n-1)), index(n));
    D{end+1} = B;
end
D{end+1} = local_index(dim, A, index(end), size(A, dim) + 1);

% concatenate along dimension with pebl_cat
C = pebl_cat(dim, D{:});
end

function A = local_index(dim, A, i0, i1)

% create a index with ':' in dimensions other than dim
a_idx = repmat({':'}, 1, numel(size(A)));
% set index at dim i0 to i1-1
a_idx{dim} = i0:min(i1-1, size(A, dim));
% return A at a_idx
A = A(a_idx{:});
end