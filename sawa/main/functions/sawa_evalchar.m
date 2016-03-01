function out = sawa_evalchar(str,expr)
% out = sawa_evalchar(str,expr)
% evaluate strings using subject array (or evaluate expr within str)
%
% Inputs:
% str - the string containing the expression to be evaluated
% expr (optional) - the expression to be evaluated (default is
% 'sa\([\w\d]+\)\.') 
% Outputs:
% out - the new string with expr replaced by the evaluation
% 
% example:
% i = 1;
% str = 'sa(i).subjFolders{1}\SubFolder\File.nii'
% expr = 'sa(i)\..*\}'
% out = sawa_evalchar(str,expr);
% out = 'J:\Justin\SPM\NIRR001\SubFolder\File.nii'
%
% example 2:
% str = 'sa(1).subj,sa(2).age{1}';
% out = sawa_evalchar(str);
% out = {'Subj001',12};
%
% note: if evaluating two str at once and one at least one is not char,
% output will be cell array (see example 2).
%
% Created by Justin Theiss


% init vars
if ~exist('expr','var'), expr = 'sa\([\w\d]+\)\.'; end;
out = str; if ~ischar(out)||size(out,1)>1, return; end;

% find match for expr
m = regexp(out,expr); 
if isempty(m), return; else m = [m, numel(out)+1]; end; 
mstr = arrayfun(@(x){out(m(x):m(x+1)-1)},1:numel(m)-1); % separate based on matches
mstr = regexprep(mstr,'[/*+-]',''); % remove math chars to avoid eval problems

% for each found match, eval
for x = 1:numel(mstr),
    set = 0; meval{x} = {};
    while ~set % until set, remove end char
    try meval{x} = evalin('caller',mstr{x}); set = 1; catch; mstr{x} = mstr{x}(1:end-1); end;
    if isempty(mstr{x}), break; end; % if removed all chars
    end; 
end

% output
% if all char, strrep matches
if all(cellfun('isclass',meval,'char')), 
% strrep each match
for x = 1:numel(mstr), out = strrep(out,mstr{x},num2str(meval{x})); end;
else % otherwise output match evals
out = meval;
end
if iscell(out)&&numel(out)==1, out = out{1}; end;
