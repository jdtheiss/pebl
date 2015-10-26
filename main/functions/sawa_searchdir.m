function [files,fullfiles] = sawa_searchdir(fld,search)
% [files,fullfiles] = sawa_searchdir(fld, search)
% search for files or folders within fld 
%
% Inputs:
% fld - (optional) starting folder to search within. default is pwd
% search - (optional) search term to search (regular expression).
% default is [], which will return all files
%
% Outputs:
% files - files matching search
% fullfiles - full path and filenames of matching files
%
% Example:
% fld = 'X:\MainFolder'; search = 'spm.*\.img';
% [files,fullfiles] = sawa_searchdir(fld,search)
% files = 'spmT_0001.img' 'spmT_0001.img' 'spmF_0001.img'
% fullfiles = 'X:\MainFolder\spmT_0001.img'
% 'X:\MainFolder\Subfolder1\SPM\spmT_0001.img'
% 'X:\MainFolder\Subfolder2\Subsubfolder\SPM2\spmF_0001.img'
%
% Created by Justin Theiss


% init vars
if ~exist('fld','var')||isempty(fld), fld = pwd; end;
if ~exist('search','var'), search = []; end;
files = {}; fullfiles = {};
% dir startFld
clear d; d = dir(fld); % get dir
d = d([~ismember({d.name},{'.','..'})]); % remove . ..
for x = 1:numel(d) % for each d
% if matches searchT, set files, fullfiles
if any(regexp(fullfile(fld,d(x).name),search))||isempty(search)
try files{end+1} = d(x).name; catch, files{1} = d(x).name; end;
try fullfiles{end+1} = fullfile(fld,d(x).name); catch, fullfiles{1} = fullfile(fld,d(x).name); end;
elseif d(x).isdir % otherwise if isdir, run searchdir
[tmpfiles,tmpfullfiles] = sawa_searchdir(fullfile(fld,d(x).name),search);
files = horzcat(files,tmpfiles); fullfiles = horzcat(fullfiles,tmpfullfiles);
end
end
