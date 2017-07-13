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
% Note: In order to create a new directory, the path should have a backslash
% at the end (e.g., '/User/Test\' or 'C:\Test\').
%  
% requires: sawa_getfield 
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
    valf = valf(~cellfun('isempty',valf)); % remove ''s
    valf = strtrim(valf); % remove extra spaces
elseif ~iscell(valf)&&~isstruct(valf) % set to cell if not
    valf = {valf};
end; 

% find cells with 'eval'
clear vals S; 
[C,S] = sawa_getfield(valf,'fun',@(x)strncmp(x,'eval',4)); 
for x = 1:numel(C), 
    try C{x} = eval(C{x}); catch, return; end; % eval
    valf = local_mkdir_select(valf,C{x},S{x},opt); % mkdir/select
end

% find cells with sa\([\d\w\]+\)\.
clear vals S;
[C,S] = sawa_getfield(valf,'fun',@(x)ischar(x)&&regexp(x,'sa\([\d\w]+\)\.')); 
for x = 1:numel(C), % evalchar
    C{x} = evalin('caller',['local_evalchar(''' C{x} ''');']); 
    valf = local_mkdir_select(valf,C{x},S{x},opt); % mkdir/select
end; 

% find cells with filesep
clear vals S; 
[C,S] = sawa_getfield(valf,'fun',@(x)ischar(x)&&any(strfind(x,filesep))); 
for x = 1:numel(C),
    valf = local_mkdir_select(valf,C{x},S{x},opt); % mkdir/select
end

% if ischar and 'cmd', output as string
if ischar(val)&&strcmp(opt,'cmd')
    valf = cellstr(valf); valf = sprintf('%s ',valf{:}); % sprintf with ' '
    valf = strtrim(valf);
end

% output
if ~iscell(val)&&iscell(valf)&&numel(valf)==1,
    valf = valf{1}; 
end;
if isempty(valf), valf = []; end;
return;

function out = local_evalchar(str,expr)
% init expr/out
if ~exist('expr','var'), expr = 'sa\([\w\d]+\)\.'; end;
out = str; if ~ischar(out)||size(out,1)>1, return; end;

% find match for expr
m = regexp(out,expr); 
if isempty(m), return; else m = [m, numel(out)+1]; end; 
mstr = arrayfun(@(x){out(m(x):m(x+1)-1)},1:numel(m)-1); % separate based on matches
mstr = regexprep(mstr,'[/*+-]',''); % remove math chars to avoid eval problems

% for each found match, eval
for x = 1:numel(mstr),
    set = 0; meval{x} = {};
    while ~set % until set, remove end char
        try meval{x} = evalin('caller',mstr{x}); set = 1; catch; mstr{x} = mstr{x}(1:end-1); end;
        if isempty(mstr{x}), break; end; % if removed all chars
    end; 
end

% output
% if all char, strrep matches
if all(cellfun('isclass',meval,'char')), 
    % strrep each match
    for x = 1:numel(mstr), out = strrep(out,mstr{x},num2str(meval{x})); end;
else % otherwise output match evals
    out = meval;
end
if iscell(out)&&numel(out)==1, out = out{1}; end;
return;

function valf = local_mkdir_select(valf,val,S,opt)
try
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
        if isempty(e) && ~any(strfind(val,',')),
            if strcmp(val(end), '\'), 
                val = val(1:end-1); % remove backslash
                if ~isdir(val), mkdir(val); end; % make new directory
            end
        elseif any(strfind(val,',')) % spm_select
            % get frames
            frames = regexprep(e,'\.\w+,?',''); e = regexprep(e,',.*$','');
            % deal with frames 1:inf as inf
            if any(strfind(frames, 'inf')), frames = 'inf'; end;
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
end

% set vals to valf
try valf = subsasgn(valf,S,val); end;
return;
