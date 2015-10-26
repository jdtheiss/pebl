function savepath = sawa_savebatchjob(savedir, jobname, matlabbatch)
% savepath = sawa_savebatchjob(savedir, jobname, matlabbatch)
% Save Batch Job
%
% Inputs:
% savedir - directory to save batch file 
% jobname - name of job (as savedir/jobs/jobname) to save batch file
% matlabbatch - matlabbatch file to save
%
% Outputs:
% savepath - fullpath of saved matlabbatch file
%
% Created by Justin Theiss


% save matlabbatch to jobs folder
savedir = fullfile(savedir,'jobs',jobname); if ~isdir(savedir), mkdir(savedir); end;
savepath = [jobname '_' date]; js = dir(fullfile(savedir,[savepath '*.mat']));
if ~isempty(js)
savepath = fullfile(savedir,[savepath '_' num2str(numel(js)+1) '.mat']);
else
savepath = fullfile(savedir,[savepath '.mat']);
end
save(savepath, 'matlabbatch');
end
