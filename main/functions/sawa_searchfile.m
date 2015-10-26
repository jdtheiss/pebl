function [files,pos] = sawa_searchfile(str,folder,filetype)
% [files, pos] = sawa_searchfile(str,folder,filetype)
% search for str within each .m file (default) in folder
%
% Inputs:
% str - string (regular expression)
% folder - location of scripts to search
% filetype - a regular expression to search files (e.g., \.m$)
%
% Output:
% files - full file script locations in which str was found
% pos - cell array of character position within each func
%
% requires: sawa_searchdir
%
% Created by Justin Theiss


% init vars
if ~exist('str','var'), return; end;
if isempty(str), str = ''; end;
if ~exist('folder','var'), folder = pwd; end;
if ~exist('filetype','var'), filetype = '\.m$'; end;
files = {}; pos = {};

% use sawa_searchdir to get flds
[~,flds] = sawa_searchdir(folder,filetype);

% fore each fld
for i = 1:numel(flds)
if ~isdir(flds{i}) % if not dir, get txt
clear txt; txt = fileread(flds{i});
% find str
if ~isempty(regexp(txt,str,'once'))||isempty(str)
files{end+1} = flds{i}; % set files
pos{end+1} = regexp(txt,str); % set position
end
end
end
