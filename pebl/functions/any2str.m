function out = any2str(varargin)
% out = any2str(varargin)
% This function will convert any class to its string representation (via @disp).
% 
% Inputs:
% varargin - any class to be input (see example)
%
% Outputs:
% out - cellstr representation equal to the number of arguments input
%
% Example:
% out = any2str('test',{'test';10},[1,2,3],@disp,{struct('testing',{'this'}),12,'testing'})
% out = 
%
%   'test'  'test'  1   2   3   @disp   [1x1 struct]    [12]   'testing'
%           [10]
%
% Created by Justin Theiss

% get string rep from disp
out = cellfun(@(x){evalc('disp(x)')},varargin); 

% remove leading spaces
out = regexprep(out,'^([^\n])','\n$1');
[ns,ne] = regexp(out,'\n\s*\S','start','end');
out = cellfun(@(x,y,z){regexprep(x,['\n\s{' num2str(min(z-y)-1) '}'],'\n')},out,ns,ne);
out = regexprep(out,{'^\n*','\n*$'},'');

% get rid of links
out = regexprep(out,{'<a href=[^>]+>','</a>'},'');

% set cell ({} or [])
out(cellfun('isempty',varargin)&cellfun('isclass',varargin,'cell')) = {'{}'};
out(cellfun('isempty',varargin)&cellfun('isclass',varargin,'double')) = {'[]'};
end
