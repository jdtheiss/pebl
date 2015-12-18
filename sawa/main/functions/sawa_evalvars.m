function valf = sawa_evalvars(val,opt)
% valf = sawa_evalvars(val,opt)
% Evaluate variables created from sawa_createvars
% 
% Inputs:
% val - string, cell array, structure to evaluate/mkdir/spm_select
% opt - (optional) if opt = 'cmd', option to set "" around filenames (for command line)
% 
% Outputs:
% valf - evaluated val
%
% Example:
% sa = struct('subj',{'test1','test2'},'subjFolders',{'/Users/test1','/Users/test2'})
% batch.folder = 'sa(i).subjFolders{1}/Analysis/';
% batch.files = 'sa(i).subjFolders{1}/Run1/*.nii';
% batch.dti = 'sa(i).subjFolders{1}/DTI/DTI.nii,inf';
% batch.input = 'evalin(''caller'',output{1,1}{s})';
%
% for i = 1:2
% s = i;
% output{1,1}{s} = sa(i).subj;
% valf = sawa_evalvars(batch)
% end
% 
% valf = 
%   folder: '/Users/test1/Analysis/' % makes dir
%    files: {49x1 cell} % returns from /Users/test1/Run1
%      dti: {60x1 cell} % gets 4d frames from /Users/test1/DTI/DTI.nii
%    input: 'test1'
%
% valf = 
%   folder: '/Users/test2/Analysis/' % makes dir
%    files: {49x1 cell} % returns from /Users/test2/Run1
%      dti: {60x1 cell} % gets 4d frames from /Users/test2/DTI.nii
%    input: 'test2' 
% 
% Note: In order to create a new directory, the path should have a file
% separator at the end (e.g., '/User/Test/' or 'C:\Test\').
% 
% Note2: If the 'cmd' option is used, file paths should have "" around them. Furthermore,
% if the 'cmd' options is used and a wildcard is used for files multiple files, 
% the inital wildcard search will be retained with "" around it i.e. "/Volumes/Folder/*.img". 
%
% requires: sawa_evalchar sawa_find 
%
% Created by Justin Theiss

% init vars
valf = val; 
if ~exist('opt','var')||isempty(opt), opt = ''; end;

% if char and 'cmd', split find paths/files and split by spaces
if ischar(val)&&strcmp(opt,'cmd'), 
pathvals = regexp(valf,'"[^"]+"','match'); % get paths/files
valf = regexprep(valf,'"[^"]+"','""'); valf = regexp(valf,'\s','split'); % split by spaces
valf(cellfun(@(x)strcmp(x,'""'),valf)) = pathvals; % add paths/files to valf
valf = regexprep(valf,'["]',''); % remove ""s
valf = valf(~cellfun('isempty',valf)); % remove ''s
valf = strtrim(valf); % remove extra spaces
elseif ~iscell(valf)&&~isstruct(valf) % set to cell if not
    valf = {valf};
end; 

% find cells with sa\([\d\w\]+\)\.
clear vals reps;
[~,vals,~,reps] = sawa_find(@regexp,'sa\([\d\w]+\)\.',valf,'valf',''); 
for x = 1:numel(vals), % sawa_evalchar
    vals{x} = evalin('caller',['sawa_evalchar(''' vals{x} ''');']); 
    valf = local_mkdir_select(valf,vals{x},reps{x},opt); % mkdir/select
end; 

% find cells with 'eval'
clear vals reps;
[~,vals,~,reps] = sawa_find(@strncmp,{'eval',4},valf,'valf',''); 
for x = find(~cellfun('isempty',vals)), 
    vals{x} = eval(vals{x}); % eval
    valf = local_mkdir_select(valf,vals{x},reps{x},opt); % mkdir/select
end

% find cells with filesep
clear vals reps;
[~,vals,~,reps] = sawa_find(@strfind,filesep,valf,'valf',''); 
for x = find(~cellfun('isempty',vals)),
    valf = local_mkdir_select(valf,vals{x},reps{x},opt); % mkdir/select
end

% if ischar and 'cmd', output as string
if ischar(val)&&strcmp(opt,'cmd')
valf = cellstr(valf); valf = sprintf('%s ',valf{:}); % sprintf with ' '
valf = strtrim(valf);
end

% output
if iscell(valf)&&numel(valf)==1, valf = valf{1}; end;
if isempty(valf), valf = []; end;

function valf = local_mkdir_select(valf,val,rep,opt)
% skip if not char
if ischar(val), 
% create ival, in case multi files and wildcard
ival = val;

% if any "", remove
val = regexprep(val,'["]','');

% get path,file,ext
clear p f e frames; [p,f,e] = fileparts(val);

% if no path, skip
if ~isempty(p),   
        
% if no ext and doesn't contain wildcard, mkdir
if isempty(e) && ~any(strfind(val,'*')) && ~any(strfind(val,',')),
if ~isdir(val) && strcmp(val(end), filesep), mkdir(val); end; % make directory

elseif any(strfind(val,'*'))||any(strfind(val,',')) % spm_select
% get frames
frames = regexprep(e,'\.\w+,?',''); e = regexprep(e,',.*$','');

if isempty(frames) % if no frames, get single files
val = spm_select('FPList',p,['^' regexptranslate('wildcard',[f,e])]);
else % if frames, get frames
val = spm_select('ExtFPList',p,['^' regexptranslate('wildcard',[f,e])],eval(frames));    
end
end

% if found cellstr, otherwise set to empty
if ~isempty(val), val = cellstr(val); else val = {}; end;

% if multiple vals and 'cmd', set val to initial val
if numel(val)>1&&strcmp(opt,'cmd'), val = ival; end;

% if opt is 'cmd', put "" around val
if strcmp(opt,'cmd'),
val = regexprep(val,['.*' filesep '.*'],'"$0"'); val = regexprep(val,'""','"'); 
end;

% set to one if only one char
if iscell(val)&&numel(val)==1, val = val{1}; end; 
end
end

% set vals to valf rep
try eval([rep '=val;']); end;

% set valf
if iscell(valf)&&numel(valf)==1, valf = valf{1}; end;
return;
