function [A, S, R] = sawa_setfield(varargin)
% [A,S,R] = sawa_setfield(A,'property1','value1',...)
% Set field/index for object A. 
%
% Inputs:
% A - object to set field/index
% 
% Properties:
% 'S' - substruct(s) to set
% 'R' - string representations to set
% 'C' - values to set to A(idx).field
% For other properties, see also sawa_getfield
%
% Outputs:
% A - object A with set fields/index(es)
% S - substructs for each set value
% R - string representation of locations for each set value
%
% Example:
% A = struct('test', {1, 2}, 'test2', {3, 4});
% A = sawa_setfield(A, 'R', {'(1).test2', '(2).test3'}, 'C', {nan, nan})
%     
% A = 
% 
% 1x2 struct array with fields:
% 
%     test
%     test2
%     test3
% 
% A(1) = 
% 
%      test: 1
%     test2: NaN
%     test3: []
% 
% A(2) = 
% 
%      test: 2
%     test2: 4
%     test3: NaN
%
% requires: sawa_getfield
%
% Created by Justin Theiss

% init vars/remove varargin{1}
if nargin==0, A = {}; return; end;
A = varargin{1}; varargin(1) = [];

% get setfield vars separate from varargin
vars = {'S','R','C','verbose'}; 
i = 1:2:numel(varargin)-1; i = i(ismember(varargin(i),vars));
arrayfun(@(x)assignin('caller',varargin{x},varargin{x+1}),i);
varargin([i,i+1]) = []; 
if ~exist('verbose','var'), verbose = false; end;

% sawa_getfield
if ~exist('S','var') && ~exist('R','var'),
    [~, S, R] = sawa_getfield(A,varargin{:});
end

% init C/S/R
if ~exist('C','var'), C = []; end;
if ~iscell(C), C = {C}; end;
if exist('S','var')&&~iscell(S), S = {S}; end;
if exist('R','var')&&~iscell(R), R = {R}; end;
    
% for each, subsasgn or evaluate
if exist('S','var'), 
    for n = 1:numel(S),
        try
            A = local_init(A, S{n});
            A = subsasgn(A, S{n}, C{min(n, end)}); 
        catch err
            if verbose, disp(err.message); end;
        end
    end
elseif exist('R','var'),
    for n = 1:numel(R), 
        try
            eval(['A', R{n}, '=C{min(n, end)};']);
        catch err
            if verbose, disp(err.message); end;
        end
    end
end
end

% init A as needed
function A = local_init(A,S)
% go from last substruct index to first, setting empty
for x = numel(S):-1:1, 
    try A = subsasgn(A,S(1:x),{}); return; end; 
end
end