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
% Note: due to differing fonts, this works best with "Courier New"
% (i.e. matlab command prompt font).
%
% Created by Justin Theiss


% init vars
strtable = []; 
if ~iscell(celltable), celltable = {celltable}; end;
if ~exist('delim','var'), delim = '\t'; end; 

% for each cell, try to convert to string
for x = 1:numel(celltable), 
try % ensure all strings, if fails get disp
celltable{x}=num2str(celltable{x}); 
catch % get disp
celltable{x}=regexprep(evalc('disp(celltable(x))'),'^\s*|\s*$','');    
end
end

% set NaN to ''
celltable(ismember(celltable,'NaN')) = {''}; 

% get rows
r = max(sum([cellfun('size',celltable,1);cellfun('isempty',celltable)],1)); 

% for each column
for c = 1:size(celltable,2) 
% get rows of current column
cr = sum([cellfun('size',celltable(:,c),1);cellfun('isempty',celltable(:,c))],1);
% set to strtable
if c < size(celltable,2) % add separator to end
strtable = horzcat(strtable,char([celltable(:,c);repmat({''},r-cr,1)]),char(repmat({sprintf(['%s' delim],'')},r,1)));
else % dont add separator to end on last
strtable = horzcat(strtable,char([celltable(:,c);repmat({''},r-cr,1)]));    
end
end
