function varargout = sawa_fileparts(inputs, part, str2rep, repstr)
% outputs = sawa_fileparts(inptus, part, str2rep, repstr)
% function to get fileparts of multiple cells, remove parts of all strings
%
% Inputs:
% inputs - cell array of strings
% part - empty (to use the entire string) or 'path', 'file', or 'ext'
% if part is a cell array of strings (e.g., {'path','file'}), will return
% multiple outputs (i.e., output{1} = path, output{2} = file)
% str2rep - string (or cell of strings) to replace within each input
% repstr - string (or cell of strings) that will replace str2rep
% 
% Outputs:
% varargout - cell array of string results
%
% example:
% inputs = {'X:\Task\Data\Subject1\Structural.nii','X:\Task\Data\Subject2\
% Structural.nii'};
% outputs = sawa_fileparts(inputs, 'path', 'X:\Task\Data\', '');
% Would result in:
% outputs = {'Subject1', 'Subject2'};
%
% NOTE: to replace a filepart, put a '"' in front and behind
% (i.e. str2rep = '"ext"' and repstr = '_1_"ext"';
%
% Created by Justin Theiss


% if no str2rep or repstr
if ~exist('str2rep', 'var')
    str2rep = {};
end
if ~exist('repstr', 'var')
    repstr = '';
end
% if str2rep isn't cell
if ~iscell(str2rep), str2rep = {str2rep}; end;
if ~iscell(repstr), repstr = {repstr}; end;
% if no part
if ~exist('part', 'var')
    part = '';
end
% if inputs is not a cell, make it one
if ~iscell(inputs)
    inputs = {inputs};
end
% for each input get fileparts
for x = 1:length(inputs)
    % get all fileparts
    try
    [f1{x}, f2{x}, f3{x}] = fileparts(inputs{x});
    catch
        f1{x} = []; f2{x} = []; f3{x} = [];
    end
end
% if request multiple parts
if iscell(part)
    runpart = 1:length(part);
elseif isempty(part)
    clear part
    part{1} = '';
    runpart = 1;
elseif ~iscell(part)
    part = {part};
    runpart = 1;
end
for x2 = runpart
% get outputs based on fileparts
switch part{x2}
    case 'path'
        outputs{x2} = f1;
    case 'file'
        outputs{x2} = f2;
    case 'ext'
        outputs{x2} = f3;
    otherwise
        outputs{x2} = inputs;
end
% get outputs based on str2rep
try
% check str2rep and repstr for \\
tmpstr = {str2rep{x2},repstr{x2}};
for n0 = 1:2
srchs = {'"path"','"file"','"ext"'};
nam = {f1,f2,f3};
n = regexp(repmat(tmpstr{n0},1,3),srchs);
for r = 1:numel(n)
if ~isempty(n{r})
% create str2rep or repstr based on nam
tmpstr{n0} = strrep(tmpstr{n0},repmat(srchs(r),size(nam{r})),nam{r});
end
end
end
% reset str2rep and repstr
str2rep{x2} = {}; repstr{x2} = {};
str2rep{x2} = tmpstr{1}; repstr{x2} = tmpstr{2};
if ~isempty(str2rep{x2})
    outputs{x2} = strrep(outputs{x2}, str2rep{x2}, repstr{x2});
end
catch % if not a cell
if ~isempty(str2rep)
    outputs{x2} = strrep(outputs{x2}, str2rep, repstr);
end
end
end
% set varargout
if nargout<numel(outputs), varargout{1} = [outputs{:}]; else varargout = outputs; end;
end
