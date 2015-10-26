function sa = savesubjfile(fileName, task, sa)
% sa = savesubjfile(fileName, task, sa)
% Saves subjects.mat file and copies previous to backup folder
%
% Inputs:
% fileName - filepath to save subject array
% task - task name to save in subjects.mat file
% sa - subject array to save
%
% Outputs:
% sa - subject array
%
% Note: also creates a "Backup" folder in the same folder as the
% subjects.mat file to save backup subjects.mat files.
% 
% Created by Justin Theiss


try
% copy old file to backup folder
path = fileparts(fileName);
backup = strrep(fileName, path, [path filesep 'Backup']);
if ~isdir([path filesep 'Backup'])
    mkdir([path filesep 'Backup']);
end
% append backup with date in Backup folder
backup = strrep(backup, '.mat', [date '.mat']);
% copy previous subjects.mat file to backup folder
if exist(fileName, 'file')==2
copyfile(fileName, backup);
end
% evaluate the changes to task
eval([task ' = sa']);
% if already a file
if exist(fileName, 'file')==2 
    save(fileName, task, '-append');
else % otherwise create file
    save(fileName, task);
end
% output successful save
sa = 1;
catch
% unsuccessful
disp('Could not save.'); sa = 0;
end
