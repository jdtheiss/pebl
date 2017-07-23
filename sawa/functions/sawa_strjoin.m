function str = pebl_strjoin(C, delim)
% str = pebl_strjoin(C, delim)
% This function will concatenate any input as string with delimiter.
% 
% Inputs:
% C - input to concatenate
% delim - delimiter to separate string (default is ', ')
%
% Outputs:
% str - string 
% 
% Example:
% str = pebl_strjoin({'test',1,struct('test',{1})}, '\n')
% str = 
%   
% test
% 1
% [1x1 struct]
%
% Note: this function uses any2str to convert non-cell/char/double inputs.
% Also, see sprintf for list of escape characters (e.g., \\ for \).
% 
% requires: any2str
%
% Created by Justin Theiss

% init vars
str = '';
if ~exist('C','var')||isempty(C), return; end;
if ~exist('delim','var'), delim = ', '; end;

% switch class
switch class(C)
    case 'cell' % if cell, run for each
        str = cellfun(@(x){pebl_strjoin(x,delim)},C);
        str = sprintf(['%s' delim], str{:});
    case 'char' % if char, cellstr
        clear tmp; tmp = cellstr(C);
        str = sprintf(['%s' delim],tmp{:});
    case {'double','logical'} % if double/logical, %g
        str = sprintf(['%g' delim],C);
    otherwise % otherwise any2str
        try str = pebl_strjoin(any2str(C),delim); return; end;
end

% remove final delim
str = str(1:end-numel(sprintf(delim)));
