function str = common_str(strs)
% str = commmon_str(strs)
% This function will find the greatest common string (str) among a cell 
% array of strings (strs)
%
% Inputs: 
% strs - cell or character array of strings 
%
% Outputs:
% str - longest common string among strs
%
% Example:
% strs = {'TestingString123','ThisString2','DifferentStrings'}
% str = common_str(strs)
% 
% str =
% 
% String
%
% Created by Justin Theiss

% initvars
str = ''; if ischar(strs), strs = cellstr(strs); end; 
% find smallest string in strs
n = find(min(cellfun('size',strs,2)),1,'first');
% set tmp
tmp = strs{n}; tmpstr = str;
% for each letter in tmp
for x = 1:numel(tmp)
    % add current letter to tmpstr
    tmpstr = horzcat(tmpstr,tmp(x));
    % if not found in all strings, reset tmpstr
    if any(cellfun('isempty',strfind(strs,tmpstr)))
       tmpstr = tmp(x); continue;
    end
    % if tmpstr is longer than current str, set str to tmpstr
    if numel(tmpstr) > numel(str)
       str = tmpstr;
    end 
end
