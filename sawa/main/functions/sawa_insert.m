function output = sawa_insert(A,idx,B)
% output = sawa_insert(A, idx, B)
% This function allows users to insert components of arrays without
% error. 
%
% Inputs:
% A - array (cell, numeric, char)
% idx - indices to replace as {x, y, etc.}. To insert rather than replace
% an index, enter a negative idx for the dimension to insert (see example 2
% below).
% B - components to insert
%
% Outputs:
% output - new array with inserted components
% 
% Example:
% output = sawa_insert('this doesn''t work',6:12,'does')
% output = 
%
% this does work
%
% Example 2:
% output = sawa_insert({1;2;3;4},{-2,1},{0;0;0})
% output = 
%
%     [1]
%     [0]
%     [0]
%     [0]
%     [2]
%     [3]
%     [4]
%
% Note: as in example 1, if a numeric array is entered for idx, the
% indices will be assumed to be horizontal (i.e. idx = {1, idx}).
% Furthermore, if idx is an empty array, idx will default to {1,1}. 
%
% requires: sawa_cat
%
% Created by Justin Theiss

% init idx
if isempty(idx), idx = 1; end; if ~iscell(idx), idx = {1,idx}; end;
idx(cellfun('isclass',idx,'logical')) = cellfun(@(x){find(x)},idx(cellfun('isclass',idx,'logical')));

% if any negative idx, cat B and A for insert
if all(cellfun(@(x)numel(x)==1,idx))&&any(cellfun(@(x)x<0,idx)), 
    i = find(cellfun(@(x)x<0,idx),1);
    idx{i} = abs(idx{i});
    B = sawa_cat(i, B, A(idx{:})); 
end

% get max idx and number of indices to replace
m = cellfun(@(x)max(x),idx); n = cellfun(@(x)numel(x),idx);
% replace ':' with size of A at dim x
m(cellfun('isclass',idx,'char')) = arrayfun(@(x)size(A,x),find(cellfun('isclass',idx,'char')));
n(cellfun('isclass',idx,'char')) = arrayfun(@(x)size(A,x),find(cellfun('isclass',idx,'char')));

% calculate size of output array
dim = ones(2,max([numel(size(A)),numel(size(B)),numel(m)]));
dim(1,1:numel(size(A))) = size(A); 
dim(2,1:numel(m)) = m; 
dimB = size(B); dimB(end+1:size(dim,2)) = 1; n(end+1:size(dim,2)) = 1; 
dim = arrayfun(@(x,y,z)x+(y-z)*(y>z),max(dim),dimB,n); 

% create output cell or numeric array
if iscell(A), output = cell(dim); else output = nan(dim); end;  

% update idx ':' to size of output
idx(cellfun('isclass',idx,'char')) = arrayfun(@(x){1:size(output,x)},find(cellfun('isclass',idx,'char')));

% set substruct for subsasgn
Sb = substruct('()', cellfun(@(x,y){min(x):max(x)+(y-numel(x))},idx,num2cell(dimB)));

% set B to output
output = subsasgn(output,Sb,B);

% get new coordinates for A
arr = ones(size(A)); arr(idx{:}) = nan;
[coords{1:numel(size(A))}] = ind2sub(size(arr),find(arr==1)); coords(end+1:size(dim,2)) = {1};
nidx = cellfun(@(x,y,z){x+(y-numel(z))*(x>max(z))},coords,num2cell(dimB),idx); 
nidx = sub2ind(size(output),nidx{:}); coords = sub2ind(size(A),coords{:});

% set A to output
output(nidx) = A(coords);

% clean up by removing rows of all Nan/empty cells from each dim
if iscell(A), arr = cellfun('isempty',output); else arr = isnan(output); end;
arr = subsasgn(arr,Sb,0); arr(nidx) = 0;
clear coords; [coords{1:numel(size(output))}] = ind2sub(size(arr),find(arr));
ucoords = cellfun(@(x){unique(x)},coords); dimO = size(arr);
dimO = arrayfun(@(x){dimO(setxor(1:numel(dimO),x))},1:numel(dimO));

% find indices in each dimension that equal product of other 2 dimensions
ridx = cellfun(@(x,y,z){y(arrayfun(@(a)sum(x==a)==prod(z),y))},coords,ucoords,dimO);

% remove rows of nan/empty cells from each dim
for r = find(~cellfun('isempty',ridx))
    output = subsasgn(output,substruct('()',circshift([ridx{r},repmat({':'},1,numel(dim))],r-1,2)),[]);
end

% if char, output as char
if ischar(A), output = char(output); end;


