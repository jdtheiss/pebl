function [subjs,sa] = pebl_subjs(sa, isubjs)
% [subjs,sa] = pebl_subjs(sa, isubjs) 
% Choose subjects, and refine subjects based on subject fields
%
% Inputs:
% - sa (optional): subject array to use 
% (if empty, choose subject array file)
% - isubjs (optional): indices of subjects in subject array to choose from
% (defualt is all subjects)
%
% Outputs:
% - subjs: numeric array of subject indices (relative to sa)
% - sa: subject array
% 
% Example 1:
% sa = struct('subj',{'sub1','sub2','sub3'},'age',{12,13,14},'group',{'hc','patient','hc'});
% subjs = pebl_subjs(sa)
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
if ~exist('sa','var')||isempty(sa),
    sa_file = uigetfile('*.mat','Choose subject array file');
    if ~any(sa_file), error('No subject array file selected.'); end;
    sas = load(sa_file); names = fieldnames(sas);
    chc = listdlg('PromptString','Choose subject array:','ListString',names,...
        'SelectionMode','single');
    sa = sas.(names{chc});
end;
if ~exist('isubjs','var')||isempty(isubjs), isubjs = 1:numel(sa); end;

% choose subjects
chc = listdlg('PromptString','Choose subjects:','ListString',{sa(isubjs).subj});
subjs = isubjs(chc);

% choose fields
fld = choose_fields(sa,subjs,'Choose field to refine subjects:');
if isempty(fld), return; end;
fld = fld{1};

% find subjs with search function
fun = cell2mat(inputdlg(['Enter function to refine subjects by ' fld]));
param = cell2mat(inputdlg(['Enter parameter for ' fun ' to refine subjects']));
if isstrprop(param,'digit'), param = str2double(param); end;

% pebl_find
fnd = pebl_find(fun,param,sa(subjs),'str',['.', fld]);
if ~isempty(fnd), subjs = subjs(fnd); end;

% add or refine
type = questdlg('Add to or refine subjects','Add/Refine','add','refine','done','done');
switch type
    case 'add' % add to subject list
        subjs = cat(2, subjs, pebl_subjs(sa, isubjs));
    case 'refine' % refine within current subjects
        subjs = pebl_subjs(sa, subjs);
end
end
