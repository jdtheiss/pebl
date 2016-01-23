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
idx(diff(tmpidx)==0) = [];

% set 0 before idx initially
idx = [{0},idx];

% get indices 
idx = arrayfun(@(x){idx{x-1}(end)+1:idx{x}},2:numel(idx));

    