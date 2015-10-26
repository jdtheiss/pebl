function sa = convert_paths(sa,newpaths)
% sa = convert_paths(sa,task,fileName)
% This function will convert the paths in the subject array sa from Mac to 
% PC or vice versa.
%
% Inputs:
% sa- a subject array (or any other array that holds file paths)
% task- (optional) the name of the subject array
% fileName- (optional) the file name of the .mat file where the subject
% newpaths- (optional) cellstr of new file paths (if known, BE CAREFUL)
%
% Outputs
% sa - converted array
%
% Example:
% sa = gng;
% task = 'gng';
% fileName = '/Applications/sawa/Subjects/subjects.mat';
% newpaths = '/Volumes/J_Drive';
% sa = convert_paths(sa,task,fileName,newpaths);
% This will replace the filepath J:\ with /Volumes/J_Drive and switch file
% separators from \ to /.
%
% requires: match_string sawa_find subidx
%
% Created by Justin Theiss

% init vars
if ~exist('sa','var')||isempty(sa), return; end;
if ~exist('newpaths','var')||isempty(newpaths), newpaths = {}; end;
if ~iscell(newpaths), newpaths = {newpaths}; end;

% get current computer type
if ~ispc, cur = 'Mac'; else cur = 'PC'; end;
if isempty(newpaths), % if no new paths entered ask to convert
conv = questdlg(['Convert paths in ' task ' to:'],'Convert Paths','PC','Mac',cur); % ask
else % otherwise automatically select cur
conv = cur;
end
if isempty(conv), return; end; % if did not respond, return

% get all vals and reps from sa that are char
[~,~,val,~,rep] = sawa_find(@ischar,{},sa,'sa','');
% find any that are char blocks
cb = cellfun('size',val,1)>1; 
pv = zeros(size(val));

% set path vals and file types to change based on choice
switch conv 
case 'PC'; pv(~cb) = ~cellfun('isempty',regexp(val(~cb),'^/')); flchng = '/\';
for xx = find(cb), cb(xx) = any(~cellfun('isempty',regexp(cellstr(val{xx},'^/')))); end;   
case 'Mac'; pv(~cb) = ~cellfun('isempty',regexp(val(~cb),'^\w:\\')); flchng = '\/'; 
for xx = find(cb), cb(xx) = any(~cellfun('isempty',regexp(cellstr(val{xx}),'^\w:\\'))); end;
end

% set pathvals, pathreps  
pathvals = val(logical((pv+cb))); pathreps = rep(logical(pv+cb)); 
cb = cellfun('size',pathvals,1)>1; % update char blocks locations
pathvals(~cb) = regexprep(pathvals(~cb),'^/',''); 

% remove first / for mac paths (otherwise match_string won't be effective)
for xx = find(cb), pathvals{xx} = regexprep(cellstr(pathvals{xx}),'^/',''); end;
gcstr = match_string(pathvals(~cb)); % get greatest common strings in pathvals
for xx = find(cb), gcstr = horzcat(gcstr,match_string(pathvals{xx})); end;
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
repstr{x} = uigetdir(pwd,['Choose the directory to replace ' gcstr{x}]);
else % otherwise use new path
repstr{x} = newpaths{x};  
end % if no path chosen, enter path by hand
if ~any(repstr{x}), repstr{x} = cell2mat(inputdlg(['Enter the path to replace ' gcstr{x}])); end;
if isempty(repstr{x}), continue; end; % skip if not entered
if all(cellfun('isempty',regexp(repstr{x}(end),num2cell(flchng)))), repstr{x} = [repstr{x} flchng(2)]; end; 
if strcmp(conv,'Mac')&&all(cellfun('isempty',regexp(repstr{x}(1),num2cell(flchng)))), repstr{x} = ['/' repstr{x}]; end;
pathvals(~cb) = regexprep(pathvals(~cb),['^' regexptranslate('escape',gcstr{x})],regexptranslate('escape',repstr{x}));
pathvals(~cb) = regexprep(pathvals(~cb),regexptranslate('escape',flchng(1)),regexptranslate('escape',flchng(2)));
for xx = find(cb) % convert for char blocks
pathvals{xx} = char(regexprep(cellstr(pathvals{xx}),['^' regexptranslate('escape',gcstr{x})],regexptranslate('escape',repstr{x})));
pathvals{xx} = char(regexprep(cellstr(pathvals{xx}),regexptranslate('escape',flchng(1)),regexptranslate('escape',flchng(2))));  
end
end

% for each path
for i = 1:numel(pathvals)
try % set pathreps to pathvals
eval([pathreps{i} '=pathvals{i};']); 
catch exception
disp(exception.message);
end
end
