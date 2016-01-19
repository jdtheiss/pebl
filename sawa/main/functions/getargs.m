function [outArgs, inArgs] = getargs(fun, subfun)
% [outparams,inparams] = getargs(func)
% This function will retreive the out parameters and in parameters for a
% function.
%
% Inputs:
% fun - string or function handle of function to be parsed
% subfun - (optional) string or function handle of subfunction to be parsed
%
% Outputs:
% outparames - out argument parameters
% inparams - in argument parameters
%
% Example:
% [outparams,inparams] = getfunparams('ttest')
% outparams = {'h','p','ci','stats'}
% inparams = {'x','m','varargin'}
% 
% NOTE: This function will only work for functions that have a file listed
% when calling functions(func) or built-in matlab functions
%
% requires: subidx
%
% Created by Justin Theiss

% init vars
outArgs = {}; inArgs = {};
if ~exist('subfun','var'), subfun = []; end;
if ~isa(subfun,'function_handle')&&~isempty(subfun), subfun = str2func(subfun); end;
% if ischar, set to function handle
if ~isa(fun,'function_handle'), fun = str2func(fun); end;
% get file, if doesn't exist, return
file = subidx(functions(fun),'.file');
if isempty(file)||strcmp(file,'MATLAB built-in function'), return; end;
% get first line of function then parse output/input regions
txt = fileread(file); txt = regexprep(txt,'\s',''); % remove spaces
% if subfunction, set fun to subfun
if ~isempty(subfun), fun = subfun; end;
% set match string
matchstr = ['function\[?(?<outArgs>[\w,]*)\]?=?(' func2str(fun) ')\(?(?<inArgs>[\w,]*)\)?'];
% get args
args = regexpi(txt,matchstr,'names'); if isempty(args), return; end; 
% remove spaces and split outArgs and inArgs
outArgs = regexp(args(1).outArgs,'[^,]+','match'); inArgs = regexp(args(1).inArgs,'[^,]+','match');
