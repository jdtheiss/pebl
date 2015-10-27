function sa = update_array(task)
% sa = update_array(task)
%
% Used to update array (sa) with the latest data. Primarily used when
% savedvars is chosen, to ensure that the array is not going to save older
% data.
%
% Inputs:
% task - string of task to update
%
% Outputs:
% sa - subject array updated
%
% Example:
% task = 'ddt';
% load(savedvars); sa = update_array(task);
% 
% Created by Justin Theiss

% init sa
sa = [];
% get fileName
fileName = choose_SubjectArray;
if isempty(fileName), return; end;
% load task
load(fileName,task);
% set output sa
sa = eval(task);
