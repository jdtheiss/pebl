function [C, idx] = collapse_array(A)
% [C, idx] = collapse_array(A)
%
% This functon collapses consecutive identical components of an array.
%
% Inputs:
% - A - array (string, cell, numeric)
% 
% Outputs:
% - C - new collapsed array
% - idx - cell array of indicies (relating to array A) for each component
%
% Example:
% A = {'this','this','is','a','a','test'}
% [C, idx] = collapse_array(A)
% C = 
%    'this'    'is'    'a'    'test'
%
% idx = 
%    [1x2 double]    [3]    [1x2 double]    [6]
%
% Created by Justin Theiss

% init outputs
C = A; idx = num2cell(1:numel(A));

% if only one, return
if numel(C)==1, return; end;

% get unique indices
[~,~,tmpidx] = unique(A,'stable');
tmpidx = tmpidx';

% remove repeated indices
C(diff(tmpidx)==0) = []; 

% if all same, stop
if sum(diff(tmpidx))==0, idx = {cell2mat(idx)}; return; end;

% set tmpidx end to 1 for below
tmpidx = [tmpidx, 1];

% find indices for each component that is repeated
for x = find(diff(tmpidx)==0), 
    if isempty(idx{x}), continue; end;
    idx{x} = x:find(diff(tmpidx(x+1:end))~=0,1)+x; 
    idx(x+1:find(diff(tmpidx(x+1:end))~=0,1)+x) = {[]};
end;
idx = idx(~cellfun('isempty',idx));

    