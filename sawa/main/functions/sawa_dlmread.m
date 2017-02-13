function raw = sawa_dlmread(file,delim)
% raw = sawa_dlmread(file, delim)
% This function will read csv/txt files and create a cell array based on
% delimiters. 
%
% Input:
% -file - file path for .csv, .txt files or actual string to delimit
% -delim - (optional) string delimiter (default is |)
%
% Output:
% -raw - the raw output in cell array (rows x columns format)
%
% Example:
% file.csv =
% Test data; Column 2; Column 3;
% Data1; Data2; Data3;
% file = '/Test/place/file.csv'; delim = ';';
% raw = sawa_dlmread(file,delim)
% raw = 
% 'Test Data'   'Column 2'  'Column 3'
% 'Data1'       'Data2'     'Data3'  
%
% Created by Justin Theiss

% if no delim, | is default
if ~exist('delim','var'), delim = '\|'; end;
if exist(file,'file'), 
    txt = fileread(file); 
else
    txt = cellstr(file);
    txt = sprintf('%s\n',txt{:});
end;
% get txt, get only 0 to 127 (chars)
txt = txt(txt>0); txt = txt(txt<127);
% get rows
rows = regexp(txt, '[\r\n]', 'split');
% remove returns
rows = regexprep(rows, '[\r\n]', '');
rows(cellfun('isempty',rows)) = [];
% split with delim
raw = regexp(rows, delim, 'split'); 
% concatenate vertically
raw = sawa_cat(1, raw{:});
end