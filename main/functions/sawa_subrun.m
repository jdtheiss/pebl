function [subrun,sa,task,fileName] = sawa_subrun(sa,subrun,isubrun)
% [subrun,sa,task,fileName] = sawa_subrun(sa,subrun,isubrun) 
% Choose fileName, task, subjects, and refine subjects based on subject
% fields
%
% Inputs:
% - sa (optional): subject array to use (if empty, choose subject array)
% - subrun (optional): indices of subjects in subject array to choose from
% (if empty, choose subjects to run)
% - isubrun (optional): indices of subjects in subject array that are
% already chosen
%
% Outputs:
% - subrun: numeric array of subject indices
% - sa: subject array to use
% - task: task name (string)
% - fileName: filepath of subjects.mat file containing subject array
%
% Example 1:
% subrun = sawa_subrun(mid)
% Choose a field: [age], Choose cell of age: [1]
% Enter function for age{1}: [eq]
% Enter search for age{1}: [13]
% Refine or Add: [Refine]
% Choose a field: [group], Choose cell of group: [cancel]
% Enter function for group: [ismember]
% Enter search for group: [ADHD]
% Refine or Add: [Add]
% Choose a field: [cancel]
% Output is subrun array with indices of subjects in array mid, the first of
% which are age 13 followed by subjects in the ADHD group.
%
% requires: choose_SubjectArray choose_fields sawa_find
%
% Created by Justin Theiss


% init vars
if ~exist('sa','var')||isempty(sa), sa = []; end;
if ~exist('subrun','var')||isempty(subrun), subrun = []; end;
task = []; fileName = [];

try
% load tasks/subject array
fileName = choose_SubjectArray; 
% no input and fileName
if nargin==0&&~isempty(fileName)
[sa, task] = choose_SubjectArray(fileName);
elseif isempty(sa) % if no subject array, return
return;
end

% set subrun, isubrun, ivals
if isempty(subrun), subrun = 1:numel(sa); end;
if ~exist('isubrun','var')
    isubrun = []; ivals = [];
else % otherwise set ivals for initialvalue
    ivals = find(ismember(subrun,isubrun));
end

% create sublist
subjs = {sa(subrun).subj};

% which subjects to run
subrun = subrun(listdlg('PromptString','Select subject(s):','ListString',subjs,...
    'InitialValue',ivals));
catch exception
disp(exception.message); return; 
end

% set temp and done
tmpsubrun = subrun; done=0;
% choose subjects
try
while ~done 
% choose fields
flds = choose_fields(sa,tmpsubrun,{'Choose field to refine subject list by (cancel when finished)',''});
if isempty(flds), done=1; break; end;

% enter func, enter search
func = cell2mat(inputdlg(['Enter the function to use for ' flds{1} ' (e.g., isempty or strcmp):'],'Function')); % enter function
search = cell2mat(inputdlg(['Enter search to use for ' flds{1} ' separate by comma if applicable (e.g., Control or 14):'],'Search')); % enter search

% strsplit by commas and convert any digits to double
search = strsplit(search); 
for x = 1:numel(search), if all(isstrprop(search{x},'digit')), search{x} = str2double(search{x}); end; end;

% run sawa_find for each subject individually
clear nsubrun; 
nsubrun = find(arrayfun(@(x)any(sawa_find(func,search,sa(x),'',['\.',regexptranslate('escape',flds{1}),'$'])),1:numel(sa)));

% refine or add
addto = questdlg('Refine or add new subjects to subject list?','Refine or Add','Refine','Add','Refine');
if strcmp(addto,'Refine'), tmpsubrun = tmpsubrun(ismember(tmpsubrun,nsubrun)); else tmpsubrun = [tmpsubrun,nsubrun]; end;
end 
catch exception
disp(exception.message);
end

% continue?
res = questdlg(['Number of subjects: ' num2str(numel(tmpsubrun))],'Continue?','Yes','No','Yes');

% re-run or output
if ~strcmp(res,'Yes'), % re-run
subrun = sawa_subrun(sa,subrun,isubrun);
else % otherwise output
subrun = tmpsubrun;
end
