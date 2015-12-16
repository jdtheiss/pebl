function [sts,msg]=sawa_system(fun,opts)
% [sts,msg] = sawa_system(fun,opts)
% This function will run "system" but uses the wine function if running a 
% .exe on mac.
%
% Input:
% fun - the function to be run 
% opts - the options to be included (as a string)
%
% Output:
% sts - status (0/1) of the function run
% msg - the command output from the function
%
% requires: update_path
%
% Created by Justin Theiss

% init opts
if ~exist('opts','var')||isempty(opts), opts = ''; end;
opts = strtrim(opts);
% get ext
[~,~,ext] = fileparts(fun); 
% use wine if on mac
if strcmp(ext,'.exe')&&ismac 
winepath = '/usr/local/Cellar/wine/1.6.2/bin';
update_path(winepath,mfilename('fullpath'));
% set winepath to path
if isdir(winepath) 
if ~any(strfind(path,winepath)), path(path,winepath); end;
end % run system using wine
[sts,msg]=system(['wine ' fun ' ' opts],'-echo');
else % otherwise run noramlly
[sts,msg]=system([fun ' ' opts],'-echo');    
end
