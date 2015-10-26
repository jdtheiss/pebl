function varargout = choose_SubjectArray(fileName,task)
% varargout = SubjectArray(fileName,task)
% holder for subjects.mat location
%
% Inputs:
% fileName - fullpath to the subjects.mat file
% task - string representing task to load
%
% Outputs:
% if no inputs, fileName will be returned
% if empty fileName is input, fileName file will be chosen and returned
% if fileName only is input, task will be chosen and fileName and task will be returned
% if fileName and task input, task will be loaded and subject array and task will be returned
%
% Created by Justin Theiss

% init vars
varargout = cell(1,nargout);

% get fileName
if nargin==0||isempty(fileName)
if nargin==0 % if no inputs, return fileName
try load([mfilename('fullpath') '_filename.mat']); catch; fileName = []; end;
varargout{1} = fileName; return;
end

% if inputs but no file, get
if ~exist(fileName,'file')
% get only fileName
[file,path] = uigetfile('*.mat','Choose the subjects.mat file to use:');
if ~any(file) % if no file chosen, output []
fileName = []; disp('No subjects.mat file chosen.');
else % otherwise output fileName
fileName = fullfile(path,file);
end
end

% output fileName
varargout{1} = fileName;

else % load fileName
tmp = load(fileName); disp(['Loading ' fileName]);

% get tasks
tasks = fieldnames(tmp);
if ~exist('task','var'), 
% choose task
chc = listdlg('PromptString','Select subject array:','SelectionMode','single',...
'ListString',tasks);
if isempty(chc), return; end;
% set task
task = tasks{chc};
end

% output sa and task
varargout{1} = tmp.(task);
varargout{2} = task;
end
% save fileName if not empty
if ~isempty(fileName), save([mfilename('fullpath') '_filename.mat'],'fileName'); end;
