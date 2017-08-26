function [subjs,array] = pebl_subjs(array, isubjs)
% [subjs,array] = pebl_subjs(array, isubjs) 
% Choose subjects, and refine subjects based on subject fields
%
% Inputs:
% - array (optional): study array to use 
% (if empty, choose study array file)
% - isubjs (optional): indices of subjects in study array to choose from
% (defualt is all subjects)
%
% Outputs:
% - subjs: numeric array of subject indices (relative to array)
% - array: study array
% 
% Example 1:
% array = struct('subj',{'sub1','sub2','sub3'},'age',{12,13,14},'group',{'hc','patient','hc'});
% subjs = pebl_subjs(array)
%
% %Choose subjects: Select All
% %Choose field: age
% %Enter function for age: gt
% %Enter parameter for eq: 12
% %Refine or Add: Refine
% %Choose subjects: Select All
% %Choose field: group
% %Enter function for group: strcmp
% %Enter parameter for strcmp: patient
% %Refine or Add: Done
% 
% subjs =
% 
%      2
%
% Note: Choosing "Add" will append the list with newly selected subjects.
% Choosing "Refine" will return subjects that have met criteria across 
% all function/searches.
%
% requires: choose_fields pebl_find
%
% Created by Justin Theiss

% init vars
if ~exist('array','var')||isempty(array),
    array_file = uigetfile('*.mat','Choose study array file');
    if ~any(array_file), error('No study array file selected.'); end;
    arrays = load(array_file); names = fieldnames(arrays);
    chc = listdlg('PromptString','Choose study array:','ListString',names,...
        'SelectionMode','single');
    array = arrays.(names{chc});
end;
if ~exist('isubjs','var')||isempty(isubjs), isubjs = 1:numel(array); end;

% choose subjects
chc = listdlg('PromptString','Choose subjects:','ListString',{array(isubjs).subj});
subjs = isubjs(chc);

% choose fields
fld = choose_fields(array,subjs,'Choose field to refine subjects:');
if isempty(fld), return; end;
fld = fld{1};

% find subjs with search function
fun = cell2mat(inputdlg(['Enter function to refine subjects by ' fld]));
param = cell2mat(inputdlg(['Enter parameter for ' fun ' to refine subjects']));
if isstrprop(param,'digit'), param = str2double(param); end;

% pebl_find
fnd = pebl_find(fun,param,array(subjs),'str',['.', fld]);
if ~isempty(fnd), subjs = subjs(fnd); end;

% add or refine
type = questdlg('Add to or refine subjects','Add/Refine','add','refine','done','done');
switch type
    case 'add' % add to subject list
        subjs = cat(2, subjs, pebl_subjs(array, isubjs));
    case 'refine' % refine within current subjects
        subjs = pebl_subjs(array, subjs);
end
end
