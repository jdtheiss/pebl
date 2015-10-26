function [gcstr,idx] = match_string(str)
% match string
% [gcstr,idx] = match_string(str)
% This function will find the greatest common string derivative of str 
% that matches the greatest number of strings in cellstr
%
% Input:
% str - a cell array of strings to be matched 
%
% Output:
% gcstr - cell array of greatest common string derivative found in all cellstr
% idx - cell array of index of cellstr where gcstr matched
%
% Example: 
% str = {'J:\This','J:\That','J:\Where','J:\Why'};
% [gcstr,idx] = match_string(str);
% gcstr = {'J:\'}; idx = {[1 1 1 1]};
%
% requires: subidx
%
% Created by Justin Theiss

if ~iscell(str), str = {str}; end;
gcstr = {}; idx = {};
tmp = numel(str);
for n = 1:size(char(str),2)
tmpstr = unique(cellstr(subidx(char(str),['(:,1:' num2str(n) ')'])));
if numel(tmpstr) > tmp 
break;
else
tmp = numel(tmpstr);
gcstr = tmpstr;
end
end
for i = 1:numel(gcstr), idx{i} = strncmp(str,gcstr{i},numel(gcstr{i})); end;
