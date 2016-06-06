function A = convert_paths(A,newpaths,type)
% A = convert_paths(A,newpaths,type)
% This function will convert the paths in the array A from Mac to 
% PC or vice versa.
%
% Inputs:
% A - array containing paths
% newpaths - (optional) cellstr of new file paths (if known, BE CAREFUL)
% type - (optional) 'mac' or 'pc' for destination path type (default is computer type)
%
% Outputs
% A - converted array
%
% Example:
% A = struct('test',{'J:\SPM\NIRR001','J:\SPM\NIRR002'},'test2',{'J:\ROIs\ROI1.nii','J:\ROIs\ROI2.nii'}); 
% newpaths = '/Volumes/J_Drive';
% type = 'mac';
%
% A = convert_paths(A,newpaths,type);
% 
% A(1) = 
%     test: '/Volumes/J_Drive/SPM/NIRR001'
%    test2: '/Volumes/J_Drive/ROIs/ROI1.nii'
%
% A(2) = 
%     test: '/Volumes/J_Drive/SPM/NIRR002'
%    test2: '/Volumes/J_Drive/ROIs/ROI2.nii'
%
% Note: if newpaths variable is not included or empty, user will be asked 
% to select directory for each common file path found. For example, the
% common path in the above example is 'J:\'.
%
% requires: match_string sawa_getfield subidx
%
% Created by Justin Theiss

% init vars
if ~exist('A','var')||isempty(A), return; end;
if ~exist('newpaths','var')||isempty(newpaths), newpaths = {}; end;
if ~iscell(newpaths), newpaths = {newpaths}; end;
if ~exist('type','var')||isempty(type), if ispc, type = 'pc'; else type = 'mac'; end; end;
type = lower(type);

% get all vals and reps from A that are char
[C,S] = sawa_getfield(A,'func',@ischar);

% find any that are char blocks
cb = cellfun('size',C,1)>1; 
pv = zeros(size(C));

% set path vals and file types to change based on choice
if strcmp(type,'pc'),
    pv(~cb) = ~cellfun('isempty',regexp(C(~cb),'^/')); flchng = '/\';
    for xx = find(cb), cb(xx) = any(~cellfun('isempty',regexp(cellstr(C{xx},'^/')))); end;   
else % mac
    pv(~cb) = ~cellfun('isempty',regexp(C(~cb),'^\w:\\')); flchng = '\/';
    for xx = find(cb), cb(xx) = any(~cellfun('isempty',regexp(cellstr(C{xx}),'^\w:\\'))); end;
end

% set pathvals, pathreps  
pathC = C(logical((pv+cb))); pathS= S(logical(pv+cb)); 
cb = cellfun('size',pathC,1)>1; % update char blocks locations
pathC(~cb) = regexprep(pathC(~cb),'^/',''); 

% remove first / for mac paths (otherwise match_string won't be effective)
for xx = find(cb), pathC{xx} = regexprep(cellstr(pathC{xx}),'^/',''); end;
gcstr = match_string(pathC(~cb)); % get greatest common strings in pathvals
for xx = find(cb), gcstr = horzcat(gcstr,match_string(pathC{xx})); end;
if isempty(gcstr), return; end; % if no gcstr, return

% get longest path of gcstr
for x = 1:numel(gcstr) 
gcstr{x} = gcstr{x}(1:subidx(strfind(gcstr{x},flchng(1)),'(end)'));
end
gcstr = unique(gcstr); % get unique paths
if isempty(newpaths), newpaths = cell(size(gcstr)); end;

% choose replacing dir and change pathvals
for x = 1:numel(newpaths) 
if isempty(newpaths{x}) % if no path entered, choose
disp(['Choose the directory to replace ' gcstr{x}]);
repstr{x} = uigetdir(pwd,['Choose the directory to replace ' gcstr{x}]);
else % otherwise use new path
repstr{x} = newpaths{x};  
end % if no path chosen, enter path by hand
if ~any(repstr{x}), repstr{x} = cell2mat(inputdlg(['Enter the path to replace ' gcstr{x}])); end;
if isempty(repstr{x}), continue; end; % skip if not entered
if all(cellfun('isempty',regexp(repstr{x}(end),num2cell(flchng)))), repstr{x} = [repstr{x} flchng(2)]; end; 
if strcmp(type,'mac')&&all(cellfun('isempty',regexp(repstr{x}(1),num2cell(flchng)))), repstr{x} = ['/' repstr{x}]; end;
pathC(~cb) = regexprep(pathC(~cb),['^' regexptranslate('escape',gcstr{x})],regexptranslate('escape',repstr{x}));
pathC(~cb) = regexprep(pathC(~cb),regexptranslate('escape',flchng(1)),regexptranslate('escape',flchng(2)));
for xx = find(cb) % convert for char blocks
pathC{xx} = char(regexprep(cellstr(pathC{xx}),['^' regexptranslate('escape',gcstr{x})],regexptranslate('escape',repstr{x})));
pathC{xx} = char(regexprep(cellstr(pathC{xx}),regexptranslate('escape',flchng(1)),regexptranslate('escape',flchng(2))));  
end
end

% for each path
for i = 1:numel(pathC)
try % set pathreps to pathvals 
A = subsasgn(A,pathS{i},pathC{i});
catch exception
disp(exception.message);
end
end
