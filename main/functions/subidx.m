function out = subidx(item,idx,bnd)
% out = subidx(item,idx)
% Index item as item(idx)
%
% Inputs: 
% item - object to be indexed
% idx - string or numeric index to use
% bnd - (optional) string representing the type of boundaries to be used
% when evaluating (e.g., '[]' or '{}'). Default is '[]'.
%
% Outputs:
% out - returned object that is item(idx)
%
% example1: 
% out=subidx(class('test'),1:3)
% out='cha'
% example2:
% out=subidx(regexp(report,'Cluster\s(?<names>\d+)','names'),'.names','{}')
% out={'1','2'}
% out=subidx(regexp(report,'Cluster\s(?<names>\d+)','names'),'.names')
% out='12'
% example3:
% curdir = '/Volumes/J_Drive/TestFolder/TestFile.mat'
% out=subidx('fileparts(curdir)','varargout{2}')
% out='TestFile'
%
% Note: to index and output argument of a function, enter item as a string 
% to be evaluated and idx as 'varargout{index}' (see example 3).
% Note2: bnd is only really applicable for indexing structure fields or
% other non-traditional indexing (see example 2).
%
% Created by Justin Theiss


% init vars
out = []; if ~exist('idx','var'), idx = ''; end;
if ~exist('bnd','var'), bnd = '[]'; end;
try 
if ischar(idx)&&any(strfind(idx,'varargout')), % if varargout, eval 
n = max(str2double(regexp(idx,'\d+','match')));
[varargout{1:n}] = evalin('caller',item); out = eval([bnd(1) idx bnd(2)]);
elseif ischar(idx) % if char, eval
out = eval([bnd(1) 'item' idx bnd(2)]);
else % index using number
out=item(idx); 
end
end
