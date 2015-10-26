function spmver = choose_spm(spmver)
% choose_spm
% This function will allow choosing between multiple SPM versions
%
% Inputs:
% spmver - (optional) string spm version to set
% 
% Outputs:
% spmver - spmver in use (or empty if failed)
%
% example:
% spmver = choose_spm('spm12');
%
% Created by Justin Theiss

% initvars
warning('off');
if ~exist('spmver','var'), spmver = ''; end;
% choose spm version
if exist('spm','file') 
    % get current path, and search for other spm's
    spmpath = fileparts(which('spm'));
    d = dir(fullfile(fileparts(spmpath),'spm*'));
    if numel(d) > 1&&isempty(spmver) % if multiple spm's
    chc = listdlg('PromptString','Choose spm to use:','ListString',{d.name},'SelectionMode','single');
    if ~isempty(chc), spmver = d(chc).name; end; % get spmver
    end
    % switch versions
    if ~isempty(spmver) && ~strcmpi(spm('ver'),spmver) 
    spm_rmpath; % remove path
    evalin('base','clear classes;'); % clear classes for cfg_ui
    spmpath = fullfile(fileparts(spmpath),spmver); % change spmpath
    k = addspmpath(spmpath); % add spmpath
    spm_jobman('initcfg'); cfg_util('initcfg'); % reinitialize 
    else % if already using 
    k = 1;
    end
else % spm doesn't exist
    k = addspmpath;
end
% display spm to use
if k, disp(['Using ' spmver '...']); else spmver = []; end;

% add spmpath
function k = addspmpath(spmpath)
if ~exist('spmpath','var'), spmpath = ''; end;
k = 1;
if ~isdir(spmpath) % not directory, choose
    spmpath = uigetdir(pwd,'Choose path to spm:');
    if ~any(spmpath), disp('Must download spm first.'); k = 0; return; end;
    addpath(spmpath);
else % is directory, addpath
    addpath(spmpath);
end
