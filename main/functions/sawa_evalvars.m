function valf = sawa_evalvars(val)
% valf = sawa_evalvars(val,subrun,sa)
% Evaluate variables created from sawa_createvars
% 
% Inputs:
% val - string, cell array, structure to evaluate/mkdir/spm_select
% 
% Outputs:
% valf - evaluated val
%
% Example:
% sa = struct('subj',{'test1','test2'},'subjFolders',{'/Users/test1','/Users/test2'})
% batch.folder = 'sa(i).subjFolders{1}/Analysis';
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
%   folder: '/Users/test1/Analysis % makes dir
%    files: {49x1 cell} % returns from /Users/test1/Run1
%      dti: {60x1 cell} % gets 4d frames from /Users/test1/DTI/DTI.nii
%    input: 'test1'
%
% valf = 
%   folder: '/Users/test2/Analysis % makes dir
%    files: {49x1 cell} % returns from /Users/test2/Run1
%      dti: {60x1 cell} % gets 4d frames from /Users/test2/DTI.nii
%    input: 'test2' 
%
% Note: if val is a string with file separators, valf will be a string with
% "" around the files (i.e. for command line purposes).
%
% requires: sawa_evalchar sawa_find sawa_strjoin
%
% Created by Justin Theiss

% init vars
valf = val; 

% if char, split find paths/files and split by spaces
if ischar(val) 
if ispc, % pc patters for folders/files
    pat = {'(\S+(\\\S[^\\]+)+\\)\s','(\S+(\\\S[^\\]+)+\.\S+)'}; 
else % mac patterns for folders/files
    pat = {'(\S+(/\S[^/]+)+/)\s','(\S+(/\S[^/]+)+\.\S+)'}; 
end
valf = [valf ' ']; % add space to end
valf = regexprep(valf,pat,{'"$1" ',' "$1"'}); % put "" around paths/files
clear tmpval; tmpval = regexp(valf,'".+"','match'); % get paths/files
valf = regexprep(valf,'".+"',''); valf = regexp(valf,'\s','split'); % split by spaces
valf = [valf,tmpval]; % add paths/files to end of valf
valf = regexprep(valf,'["]',''); % remove ""s
valf = valf(~cellfun('isempty',valf)); % remove ''s
% remove spaces on both ends
valf = strtrim(valf); 
end

% find cells with sa\([\d\w\]+\)\.
clear vals reps;
[~,vals,~,reps] = sawa_find(@regexp,'sa\([\d\w]+\)\.',valf,'valf','');
for x = 1:numel(vals), % sawa_evalchar
    vals{x} = evalin('caller',['sawa_evalchar(''' vals{x} ''');']); 
    valf = local_mkdir_select(valf,vals{x},reps{x}); % mkdir/select
end

% find cells with 'eval'
clear vals reps;
[~,vals,~,reps] = sawa_find(@strncmp,{'eval',4},valf,'valf',''); 
for x = find(~cellfun('isempty',vals)), 
    vals{x} = eval(vals{x}); % eval
    valf = local_mkdir_select(valf,vals{x},reps{x}); % mkdir/select
end

% find cells with filesep
clear vals reps;
[~,vals,~,reps] = sawa_find(@strfind,filesep,valf,'valf','');
for x = find(~cellfun('isempty',vals)), 
    valf = local_mkdir_select(valf,vals{x},reps{x}); % mkdir/select
end

% if ischar, output as string
if ischar(val)
if ispc, % pc patters for folders/files
    pat = {'(\w:(\\\S[^\\]+)+\\)\s','(\w:(\\\S[^\\]+)+\.\S+)'}; 
else % mac patterns for folders/files
    pat = {'((/\S[^/]+)+/)\s','\s((/\S[^/]+)+\.\S+)'}; 
end
valf = sawa_strjoin(valf,' '); valf = [valf ' ']; % strjoin with ' '
valf = regexprep(valf,pat,{'"$1" ',' "$1"'}); % put "" around paths with space
end

% output
if iscell(valf)&&numel(valf)==1, valf = valf{1}; end;
if isempty(valf), valf = []; end;

function valf = local_mkdir_select(valf,val,rep)
% skip if not char
if ischar(val),
% get path,file,ext
clear p f e frames; [p,f,e] = fileparts(val);

% if no path, skip
if ~isempty(p),   
    
% if no ext and doesn't contain wildcard, mkdir
if isempty(e) && ~any(strfind(val,'*')) && ~any(strfind(val,','))
if ~isdir(val), mkdir(val); end; % make directory

% add filesep to end
if ~strcmp(val(end), filesep), val = [val filesep]; end;

% if any wildcard, spm_select
elseif any(strfind(val,'*'))||any(strfind(val,',')), 
% get frames
frames = regexprep(e,'\.\w+,?',''); e = regexprep(e,',.*$','');

if isempty(frames) % if no frames, get single files
val = spm_select('FPList',p,regexptranslate('wildcard',[f,e]));
else % if frames, get frames
val = spm_select('ExtFPList',p,regexptranslate('wildcard',[f,e]),eval(frames));    
end

% if found cellstr, otherwise return
if ~isempty(val), val = cellstr(val); else return; end;

% if multi files for a char val, return (for command line)
if numel(val) > 1 && evalin('caller','ischar(val)'), return; end;

% set to one if only one char
if iscell(val)&&numel(val)==1, val = val{1}; end;
end
end
end

% set vals to valf rep
try eval([rep '=val;']); end;

% set valf
if iscell(valf)&&numel(valf)==1, valf = valf{1}; end;
return;
