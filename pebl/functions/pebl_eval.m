function evaled_obj = pebl_eval(obj, opt)
% evaled_obj = pebl_eval(obj, opt)
% Evaluate variables created from pebl_input
% 
% Inputs:
% obj - string, cell array, structure to evaluate/mkdir/spm_select
% opt - (optional) if opt = 'system', option to set "" around filenames (for command line)
% 
% Outputs:
% evaled_obj - evaluated object
%
% Example:
% obj = struct('field1', {'eval(''1'')', fullfile(pwd,'test\')});
% evaled_obj = pebl_eval(obj)
%
% evaled_obj(1) =
%
%     field1: 1
%
% evaled_obj(2) =
% 
%     field1: '/Users/test'
%
% Note: In order to create a new directory, the path should have a backslash
% at the end (e.g., '/User/Test\' or 'C:\Test\').
%
% Created by Justin Theiss

% init vars
if ~exist('opt','var')||isempty(opt), opt = ''; end;
evaled_obj = obj;
if ~iscell(evaled_obj), evaled_obj = {evaled_obj}; end;

% find cells with 'eval'
[C,S] = pebl_getfield(evaled_obj,'fun',@(x)strncmp(x,'eval',4)); 
for x = 1:numel(C), 
    try C{x} = eval(C{x}); catch, return; end; % eval
    evaled_obj = local_mkdir_select(evaled_obj,C{x},S{x},opt); % mkdir/select
end

% find cells with filesep
[C,S] = pebl_getfield(evaled_obj,'fun',@(x)ischar(x) && any(strfind(x,filesep))); 
for x = 1:numel(C),
    evaled_obj = local_mkdir_select(evaled_obj,C{x},S{x},opt); % mkdir/select
end

% if ischar and 'system', output as string
if ischar(obj)&&strcmp(opt,'system')
    evaled_obj = cellstr(evaled_obj); evaled_obj = sprintf('%s ',evaled_obj{:}); % sprintf with ' '
    evaled_obj = strtrim(evaled_obj);
end

% output
if ~iscell(obj)&&iscell(evaled_obj)&&numel(evaled_obj)==1,
    evaled_obj = evaled_obj{1}; 
end;
if isempty(evaled_obj), evaled_obj = []; end;
end

function obj = local_mkdir_select(obj, C, S, opt)

% skip if not char
if ischar(C), 
    % if any "", remove
    C = regexprep(strtrim(C),'["]','');

    % get path,file,ext
    [p,f,e] = fileparts(C);

    % if no path, skip
    if ~isempty(p),   
        % if no ext and doesn't contain wildcard, mkdir
        if isempty(e) && strcmp(C(end), '\'),
            C = C(1:end-1); % remove backslash
            if ~isdir(C), mkdir(C); end; % make new directory
        elseif any(strfind(C,',')) % spm_select
            % get frames
            frames = regexprep(e,'\.\w+,?',''); e = regexprep(e,',.*$','');
            % deal with frames 1:inf as inf
            if any(strfind(frames, 'inf')), frames = 'inf'; end;
            if isempty(frames) % if no frames, get single files
                C = spm_select('FPList',p,['^' regexptranslate('wildcard',[f,e])]);
            else % if frames, get frames
                C = spm_select('ExtFPList',p,['^' regexptranslate('wildcard',[f,e])],eval(frames));    
            end
        end

        % if found cellstr, otherwise set to empty
        if ~isempty(C), C = cellstr(C); else C = {}; end;

        % if opt is 'system', put "" around C
        if strcmp(opt,'system'),
            C = regexprep(C,['.*' filesep '.*'],'"$0"');
            C = regexprep(C,'""','"'); 
        end;

        % set to one if only one cell
        if iscell(C) && numel(C)==1, C = C{1}; end; 
    end
end

% set obj to C using subsasgn
obj = subsasgn(obj, S, C);
end