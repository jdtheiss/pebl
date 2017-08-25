function strtable = cell2strtable(celltable,delim)
% strtable = cell2strtable(celltable,delim)
% Create string table from a cell table (different from matlab's table)
% with a specified delimiter separating columns.
%
% Input:
% -celltable - a cell array with rows and columns to create string table
% -delim - (optional) delimiter to separate columns (defualt is tab)
%
% Output: 
% -strtable - a string table based on the celltable with equally spaced
% columns based on delimeter
%
% Example:
% celltable = [{'Column 1 Title','Column 2 Title',''};...
% {'Row 2 Column 1 is longer...','Row 2 Column 2','Extra Column!'}];
% delim = '\t';
% strtable = cell2strtable(celltable,delim);
% strtable = 
% Column 1 Title             	Column 2 Title	             
% Row 2 Column 1 is longer...	Row 2 Column 2	Extra Column!
%
% Created by Justin Theiss

% init vars
strtable = []; 
if ~iscell(celltable), celltable = {celltable}; end;
if ~exist('delim','var'), delim = '\t'; end; 

% for each cell, try to convert to string
if ~all(cellfun('isempty',celltable)),
for x = find(~cellfun('isempty',celltable)), celltable(x) = any2str(celltable{x}); end;
end

% set NaN to ''
celltable(cellfun('isempty',celltable)) = {''};
celltable(ismember(celltable,'NaN')) = {''}; 

% set strings to char
celltable = cellfun(@(x){char(x)},regexp(celltable,'\n','split'));

% get rows for each cell and total rows
r = cellfun('size',celltable,1);
maxr = max(r,[],2); totr = sum(maxr); 

% get cells that need additional rows
chng = repmat(maxr,1,size(celltable,2)) - r;
celltable(chng>0) = arrayfun(@(x){char(celltable{x},zeros(chng(x),0))},find(chng>0));

% horzcat columns 1:end-1
for c = 1:size(celltable,2)-1
    strtable = horzcat(strtable,char(celltable(:,c)),char(repmat({sprintf(['%s' delim],'')},totr,1)));
end

% add last column
strtable = horzcat(strtable,char(celltable(:,end)));

% convert from char to string
strtable = pebl_strjoin(cellstr(strtable),'\n');
