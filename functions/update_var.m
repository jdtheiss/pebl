function [str, file] = update_var(file, varargin)
% [str, file] = update_var(file, 'var1', value1, ...)
% Update variables within a file
%
% Inputs:
% file - string file path of file to be updated
% varargin - pairs of varible name and value for each variable to update
% 
% Outputs:
% str - updated string from file
% file - updated file path
% 
% Example:
% file = 'test.txt';
% str = 'test_dir = ''test1/test2'';\ntest_str = ''test3'';';
% fid = fopen(file, 'w');
% fprintf(fid, str);
% fclose(fid);
% [updated_str, updated_file] = update_var(file, 'test_dir', '/test/test', 'test_str, 'test')
% 
% updated_str =
% 
% test_dir = '/test/test';
% test_str = 'test';
% 
% 
% updated_file =
% 
% test.txt
%
% Note: Variable types of struct are not supported. 
% 
% Created by Justin Theiss

% init vars
if ~exist('file','var')||~exist(file,'file'), return; end;
if isempty(varargin), return; end; 

% get string from file
str = fileread(file);

% for each varargin, set str
for x = 1:2:numel(varargin),
    % find str match
    fndstr = regexp(str,['[^\n]*', varargin{x}, '\s?=\s?[^\n]*'], 'match');
    % replace match
    str = strrep(str, fndstr{1}, [varargin{x} ' = ' genstr(varargin{x+1}) ';']);
end

% write to file
fid = fopen(file, 'w');
fwrite(fid, str);
fclose(fid);
end
