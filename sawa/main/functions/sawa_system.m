function [sts,msg]=sawa_system(funcs,opts,n)
% [sts,msg] = sawa_system(funcs,opts,n)
% This function will run "system" but uses the wine function if running a 
% .exe on mac.
%
% Input:
% funcs - the function(s) to be run 
% opts - the options to be included (as a string)
% n - (optional) index of functions to run if running serially
%
% Output:
% sts - status (0/1) of the function run
% msg - the command output from the function
%
% Note: If multiple functions/options without input "n", functions will be 
% run together separated by '; '. If "n" is input, only funcs{n} and
% preceding functions used to set variables (e.g., var=) will be run.
%
% Note 2: If "msg" is chosen as output, the msg will not be displayed in
% the command prompt.
%
% requires: update_path
%
% Created by Justin Theiss

% init vars
if ~exist('opts','var')||isempty(opts), opts = ''; end;
if ~iscell(funcs), funcs = {funcs}; end;
if ~iscell(opts), opts = {opts}; end;
opts = strtrim(opts);
if ~exist('n','var')||isempty(n), n = numel(funcs); end;

% set functions to only up to n
funcs = funcs(1:n);

% check for .exe on mac
if ismac
for x = 1:numel(funcs), 
clear ext; [~,~,ext] = fileparts(funcs{x}); 
% use wine if on mac
if strcmp(ext,'.exe')
funcs{x} = ['wine ' funcs{x}];
end
end
end

% set winepath if needed
if any(strncmp(funcs,'wine ',5))
winepath = '/usr/local/Cellar/wine/1.6.2/bin';
update_path(winepath,mfilename('fullpath'));
% set winepath to path
if isdir(winepath) 
if ~any(strfind(path,winepath)), path(path,winepath); end;
end
end

% if n input, include only var= or set funcs prior to n
if nargin==3, 
   v = ~cellfun('isempty',regexp(funcs,'=$'))|strcmp(funcs,'set'); 
   v(n) = true;
   funcs = funcs(v); opts = opts(v);
end

% join fun and opts
funcs = regexprep(funcs,'([^=])$','$1 ');
opts = regexprep(opts,'([^;])$','$1; ');
vars = strcat(funcs,opts);

% run system
[~,sts,msg]=evalc('system(strcat(vars{:}),''-echo'')'); 

% only display if msg is not output
if nargout < 2, disp(msg); end;
return
