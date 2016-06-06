function savedvars = sawa_setvars(mfil,savedvars)
% savedvars = setvars(mfil)
% Set variables for running multiple functions in GUI for either
% scripts or .mat functions
%
% Inputs:
% mfil - filename of function to set variables for
%
% Outputs:
% savedvars - fullfile path for savedvars.mat file containing variables
%
% Example:
% function something = test_function(vars)
% %NoSetSubrun
%
% %PQ
% f = cell2mat(inputdlg('enter the value for f:'));
% %PQ
% end
%
% Note: put %NoSetVars in function to keep from setting variables,
% put %NoSetSubrun to not choose subjects to run. Also, for
% scripts/fucntions, any variables placed between two "%PQ"s will be saved
% (see example).
%
% requires: funpass sawa_editor sawa_subrun
%
% Created by Justin Theiss

    
% set svars struct
svars = struct;

% if no mfil, choose
if nargin == 0, 
disp('Choose function to set variables for');
[tmpfil,tmppath]=uigetfile({'*.m';'*.mat'},'Choose function to set variables for:');
mfil = fullfile(tmppath,tmpfil); clear tmpfil tmppath;
end

% get nam, ext
[~,nam,ext] = fileparts(mfil);

% enter savedvars filename
if ~exist('savedvars','var')||isempty(savedvars),
savedvars = fullfile(fileparts(fileparts(which('sawa'))),'jobs');
nam = cell2mat(inputdlg('Enter the name for the saved variables file:',...
    'Name for Saved Variables File',1,{[nam '_savedvars']}));
if isempty(nam), return; end; savedvars = fullfile(savedvars,[nam '.mat']);
end

% if .m file
if strcmp(ext,'.m')
% get file text
filetext = fileread(mfil);
% search for %NoSetVars
dontrun = '[^\n]*%NoSetVars[^\n]*';
nosubrun = '[^\n]*%NoSetSubrun[^\n]*';
dorun = '[^\n]*%SetVars[^\n]*';

% determine if can be run for setvars
if any(regexp(filetext,dontrun))
    savedvars = [];
    return
end

% set savedvars variable
if ~any(regexp(filetext,nosubrun))
    [subrun,sa,task,fileName] = sawa_subrun(sa, subrun);
elseif any(regexp(filetext,dorun))
    sa={}; task = ''; subrun = []; fileName = ''; 
end

% run function and save variables
if any(regexp(filetext,dorun))
    % if mpath, addpath mpath
    [mpath,mfil] = fileparts(mfil); if ~isempty(mpath), addpath(mpath); end;
    sv = -1; % setvars
    savedvars = fullfile(fileparts(fileparts(which('sawa'))),'jobs',[mfil '_savedvars.mat']);
    savedvars = cell2mat(inputdlg('Enter the name for the saved variables file:',...
        'Name for Saved Variables File',1,{savedvars}));
    feval(mfil,sv,savedvars,sa,subrun,task,fileName); % eval function
    return;
end

% evaluate text
svars = eval_text(svars,filetext);

% clear vars except those set to svars struct
clearvars -except svars;

% get vars from svars, clear svars
funpass(svars); clear svars;

% save variables
try save(savedvars); catch, savedvars = []; disp(['Could not save variables for ' mfil]); end;
else % .mat file
fp = sawa_editor('load_sawafile',mfil,0,savedvars); fp.sv = 1; % set sv to 1
save(savedvars,'fp');
end
return;

% eval_text (uses odd-looking variables to avoid issues with vars called)
function svars = eval_text(svars,f____)
% get vars from svars
funpass(svars);
% search for %PQ
e____ = '%PQ'; pq____ = regexp(f____,e____);
for l____ = 1:2:length(pq____)
    eval(f____(pq____(l____):pq____(l____+1))); % eval function
end
clear f____ e____ pq____ l____
% pass vars to et struct
svars = funpass(svars,who);
return;
