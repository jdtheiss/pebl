function [files,pos] = sawa_searchfile(expr,fld,filetype)
% [files, pos] = sawa_searchfile(expr,fld,filetype)
% search for expr within each .m file (default) in fld
%
% Inputs:
% expr - regular expression to search within files
% fld - location of scripts to search
% filetype - a regular expression to search files (default: '\.m$')
%
% Output:
% files - full file script locations in which expr was found
% pos - cell array of character position within each func
%
% Example:
% expr = 'sawa_searchfile'; fld = fileparts(which('sawa_searchfile')); 
% filetype = '\.m$';
% [files, pos] = sawa_searchfile(expr,fld,filetype)
% 
% files = 
% 
%     '/Applications/sawa/main/functions/sawa_searchfile.m'
% 
% pos = 
% 
%     [1x6 double]
% 
% requires: sawa_searchdir
%
% Created by Justin Theiss


% init vars
if ~exist('expr','var'), return; end;
if isempty(expr), expr = ''; end;
if ~exist('fld','var'), fld = pwd; end;
if ~exist('filetype','var'), filetype = '\.m$'; end;
files = {}; pos = {};

% use sawa_searchdir to get flds
flds = sawa_searchdir(fld,filetype);

% fore each fld
for i = 1:numel(flds)
if ~isdir(flds{i}) % if not dir, get txt
clear txt; txt = fileread(flds{i});

% find expr
if ~isempty(regexp(txt,expr,'once'))||isempty(expr)
files{end+1} = flds{i}; % set files
pos{end+1} = regexp(txt,expr); % set position
end
end
end
return;