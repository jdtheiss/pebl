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
% Note: if multiple functions/options, they will be run together separated
% by '; '.
%
% requires: update_path
%
% Created by Justin Theiss

% init vars
if ~exist('opts','var')||isempty(opts), opts = ''; end;
if ~iscell(fun), fun = {fun}; end;
if ~iscell(opts), opts = {opts}; end;
opts = strtrim(opts);

% check for .exe on mac
if ismac
for x = 1:numel(fun), 
clear ext; [~,~,ext] = fileparts(fun{x}); 
% use wine if on mac
if strcmp(ext,'.exe')
fun{x} = ['wine ' fun{x}];
end
end
end

% set winepath if needed
if any(strncmp(fun,'wine ',5))
winepath = '/usr/local/Cellar/wine/1.6.2/bin';
update_path(winepath,mfilename('fullpath'));
% set winepath to path
if isdir(winepath) 
if ~any(strfind(path,winepath)), path(path,winepath); end;
end
end

% join fun and opts
fun = regexprep(fun,'([^=])$','$1 ');
opts = regexprep(opts,'([^;])$','$1; ');
vars = strcat(fun,opts);

% run system
[sts,msg]=system(strcat(vars{:}),'-echo');    
return
