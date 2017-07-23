function files = pebl_search(folder, expr, type, varargin)
% files = pebl_searchdir(folder, expr, type, ...)
% Search for files, folders, or text within files.
%
% Inputs:
% folder - (optional) starting folder to search within. (default is pwd)
% expr - (optional) expression to search (regular expression; default is '.*')
% type - (optional) type of search: 'dir' for searching for files in
% directories or an expression to characterize files to search within
% (default is 'dir')
% Other inputs:
% 'verbose' - true/false to show current folder being searched 
% (default is false)
% 'n_levels' - number of levels to search (default is inf)
%
% Outputs:
% files - files matching search criteria
%
% Example 1: search for this file
% folder = fileparts(which('pebl_search')); expr = 'pebl_search';
% type = 'dir';
% files = pebl_search(folder, expr, type)
% 
% files = 
% 
%     '/Applications/pebl/main/functions/pebl_search.m'
%     
% Example 2: search for this phrase in files
% folder = fileparts(which('pebl_search')); expr = 'search for this phrase';
% type = '\.m$';
% files = pebl_search(folder, expr, type)
%
% files = 
% 
%     '/Applications/pebl/main/functions/pebl_search.m'
%
% Note: when searching within files, type can be any regular expression to
% narrow files to search within (e.g., '\.m$' or ['.*', date, '\.txt$']).
% If n_levels is 0, only the current folder is searched.
%
% Created by Justin Theiss

% init vars
if ~exist('folder','var')||isempty(folder), folder = pwd; end;
if ~exist('expr','var'), expr = []; end;
if ~exist('type','var'), type = 'dir'; end;
files = {};
arrayfun(@(x)assignin('caller',varargin{x},varargin{x+1}), 1:2:numel(varargin));
if ~exist('verbose','var'), verbose = false; end;
if ~exist('n_levels','var'), n_levels = inf; end;

% if verbose, display current folder
if verbose, disp(folder); end;

% list directory files/folders
d = dir(folder);
d = d([~ismember({d.name},{'.','..'})]);
dir_idx = [d.isdir];

% if type dir, regexp expr
if strcmp(type,'dir'),
    fnd = ~cellfun('isempty', regexp({d.name}, expr, 'once'));
    files = fullfile(folder, {d(fnd).name});
else % otherwise find type, and fileread
    fnd = ~cellfun('isempty', regexp({d.name}, type, 'once'));
    fnd = and(fnd, ~dir_idx);
    for x = find(fnd),
        txt = fileread(fullfile(folder, d(x).name));
        if ~isempty(regexp(txt, expr, 'once')),
            files{end+1} = fullfile(folder, d(x).name);
        end
    end
end

% for each dir, pebl_search
if n_levels > 0,
    for x = find(dir_idx),
        files = horzcat(files,...
            pebl_search(fullfile(folder, d(x).name), expr, type,...
            'verbose', verbose, 'n_levels', n_levels-1));
    end
end
end
