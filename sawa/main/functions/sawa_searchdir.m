function files = sawa_searchdir(fld,search)
% files = sawa_searchdir(fld, search)
% search for files or folders within fld 
%
% Inputs:
% fld - (optional) starting folder to search within. default is pwd
% search - (optional) search term to search (regular expression).
% default is [], which will return all files
%
% Outputs:
% files - files matching search
%
% Example:
% fld = fileparts(which('sawa_searchdir')); search = 'sawa_searchdir';
% files = sawa_searchdir(fld,search)
% 
% files = 
% 
%     '/Applications/sawa/main/functions/sawa_searchdir.m'
%     
% Created by Justin Theiss


% init vars
if ~exist('fld','var')||isempty(fld), fld = pwd; end;
if ~exist('search','var'), search = []; end;
files = {};

% dir startFld
clear d; d = dir(fld); % get dir
d = d([~ismember({d.name},{'.','..'})]); % remove . ..

for x = 1:numel(d) % for each d
% if matches searchT, set files, fullfiles
if any(regexp(fullfile(fld,d(x).name),search))||isempty(search)
try files{end+1} = fullfile(fld,d(x).name); catch, files{1} = fullfile(fld,d(x).name); end;

elseif d(x).isdir % otherwise if isdir, run searchdir
tmpfiles = sawa_searchdir(fullfile(fld,d(x).name),search);
files = horzcat(files,tmpfiles);
end
end
return;
