function [matlabbatch, options] = pebl_setbatch(matlabbatch, options, m)
% [matlabbatch, options] = pebl_setbatch(matlabbatch, options, m)
% Set batch parameters for pebl using cfg_ui
%
% Inputs:
% matlabbatch (optional) - cell array of matlabbatch module components (can
%   be saved from cfg_ui)
% options (optional) - cell array of options corresponding to matlabbatch
%   modules
% m (optional) - number corresponding to the module index to load
%
% Outputs:
% matlabbatch - cell array of matlabbatch module components
% options - cell array of substructs of module components for each
%   parameter chosen
%
% Example:
% matlabbatch{1}.spm.util.disp.data = '<UNDEFINED>';
% [matlabbatch, options] = pebl_setbatch(matlabbatch);
% [replicate module]
% [press right arrow on "Image to Display" for both modules]
% [close gui]
%
% matlabbatch = 
% 
%     [1x1 struct]    [1x1 struct]
% 
% 
% options = 
% 
%     [1x5 struct]    []    [1x5 struct]    []
%
% sub2str(options{1})
% 
% ans =
% 
% {1}.spm.util.disp.data
%
% sub2str(options{3})
% 
% ans =
% 
% {2}.spm.util.disp.data
%
% Note: to add a pebl parameter, press the right arrow while selecting the
% item; to remove the item, press the left arrow while selecting the item.
% once all modules/items have been added, close the gui to return outputs.
%
% Created by Justin Theiss

% init vars
if ~exist('cfg_ui','file'), error('Must have cfg_ui.m in matlab path.'); end;
if ~exist('matlabbatch','var'), matlabbatch = {}; end;
if ~iscell(matlabbatch), matlabbatch = {matlabbatch}; end;
if ~exist('options','var')||isempty(options), options = {}; end;
if ~exist('m','var')||isempty(m), m = 1; end;

% please wait message box to be deleted when ready
wait_h = wait_msg;
wait_t = timer('TimerFcn', @(x,y)wait_msg(wait_h),...
    'Period', 0.1, 'ExecutionMode', 'fixedSpacing',...
    'StopFcn', @(x,y)wait_msg(wait_h,'delete'),...
    'ErrorFcn', @(x,y)stop(x));
start(wait_t);

% prevent matlab from giving warnings when a text entered matches a function
warning('off','MATLAB:dispatcher:InexactCaseMatch');
     
% initialize cfg_ui
spm_jobman('initcfg'); cfg_util('initcfg');

% open cfg_ui and get guidata
h = cfg_ui; handles = guidata(h); 

% set closerequestfcn to set to invisible (rather than try to save)
set(h, 'CloseRequestFcn', @(x,y)set(x,'visible','off'));

% set keypress fcn for module
set(findobj(h,'tag','module'), 'KeyPressFcn',...
    @(x,y)guidata(gcf,setfield(guidata(gcf),'kp',y.Key)));

% set tooltipstring
set(findobj(h,'tag','module'), 'ToolTipString',...
    'Press right arrow to set pebl variable, left to remove.');

% remove kp if already exists
if isfield(handles,'kp'), guidata(h,rmfield(handles,'kp')); end;

% load batch 
if ~isempty(matlabbatch)&&~all(cellfun('isempty', matlabbatch)),
    cfg_util('initjob',matlabbatch); 
    set(handles.modlist, 'value', m);
    cfg_ui('local_showjob',h);
end

% convert options to idx
idx = cell(size(matlabbatch));
idx = idx2options(h, matlabbatch, idx, options, 'idx');

% set userdata for h to current item value
m = get(handles.modlist, 'value');
i = get(handles.module, 'value');
str = get(handles.module, 'string');
str_ids = get_ids(h, m, 'str');
% init params.m as 0 to force update on first load
params = struct('m', 0, 'i', i, 'str', {str}, 'str_ids', {str_ids});
set(h, 'userdata', params);

% update with previous options
update_cfg(h, idx);

% close msgbox
stop(wait_t); delete(wait_t);

% set timer
t = timer('TimerFcn', @(x,y)set(x, 'userdata', update_cfg(h, get(x, 'userdata'))),...
    'Period', 0.1, 'UserData', idx, 'ExecutionMode', 'fixedSpacing',...
    'ErrorFcn', @(x,y)stop(x));
start(t);

% wait for h to close
try
    waitfor(h, 'visible', 'off'); 
catch err
    disp(err.message);
end
stop(t);

% get idx from t
idx = get(t, 'userdata');
delete(t);

% harvest matlabbatch
userdata = get(handles.modlist, 'userdata');
[~, matlabbatch] = cfg_util('harvest', userdata.cjob); 

% convert idx to options
options = idx2options(h, matlabbatch, idx, options);

% delete figure
delete(h);
end

function wait_h = wait_msg(wait_h, cmd)

% if no cmd, set to ''
if ~exist('cmd','var'), cmd = ''; end;
if nargin==0, % no nargin, create msgbox
    wait_h = msgbox('Please wait...'); 
elseif nargin==1 && ishandle(wait_h), 
    figure(wait_h); % make figure current
elseif strcmp(cmd,'delete') && ishandle(wait_h), 
    delete(wait_h); % delete msgbox
end
end

function update_str(h, idx)

% msg to display in string
msg = '----pebl parameter----';
handles = guidata(h);
% reload gui
cfg_ui('local_showmod', handles.modlist);
% get string
str = get(handles.module, 'string');
% set msg for item idx
str(idx) = {msg};
% update str
set(handles.module, 'string', str);
end

function [id, types] = get_ids(h, m, opt)

% init ids
id = {}; types = {};
% guidata and get userdata
handles = guidata(h);
userdata = get(handles.modlist, 'userdata');
% if no mod, return
if isempty(userdata.cmod), return; end;
% get ids
[id, ~, types] = cfg_util('listmod', userdata.cjob, userdata.id{m}, [],...
              cfg_findspec({{'hidden',false}}),...
              cfg_tropts({{'hidden',true}},1,inf,1,inf,false), {'class'});
types = types{1};
% if opt is str, output string ids
if exist('opt','var')&&strcmp(opt, 'str'), 
    id = cellfun(@(x){sub2str(x)},id); 
end
end

function idx = update_cfg(h, idx)

% get guidata
handles = guidata(h);
% get item value, string, and userdata
m = get(handles.modlist, 'value');
i = get(handles.module, 'value');
str = get(handles.module, 'string');
params = get(h, 'userdata'); 
% init idx
if m > numel(idx), idx{m} = []; end;
% if key press
if isfield(handles, 'kp'),
    kp = handles.kp;
    % remove kp from handles
    guidata(h, rmfield(handles,'kp'));
    if strcmp(kp,'rightarrow') % add
        idx{m}(end+1) = i;
    elseif strcmp(kp,'leftarrow') % remove
        idx{m}(idx{m}==i) = [];
    else % if up/down, return
        return; 
    end
% if new module, update str_ids
elseif params.m ~= m,
    params.str_ids = get_ids(h, m, 'str'); params.str = str;
% if updated module, update str_ids and indices
elseif numel(params.str) ~= numel(str) || ~all(strcmp(params.str, str)),
    str_ids = get_ids(h, m, 'str');
    idx{m} = cell2mat(cellfun(@(x){find(strcmp(str_ids,x))}, params.str_ids(idx{m})));
    params.str_ids = str_ids; params.str = str;
else % otherwise do not update string
    return;
end
% set params to h 
params.i = i; params.m = m;
set(h, 'userdata', params);
% set idx unique
idx{m} = unique(idx{m});
% update string
update_str(h, idx{m});
end

function [C,S,R] = convert_ids(matlabbatch, m, ids, types)

% init outputs
[C, S, R] = deal({});

% remove first type
types = types(2:end);

% find first level
r = 1;
while numel(struct2sub(matlabbatch{m}, r)) == 1,
    r = r + 1;
    if r > 10, return; end;
end

% get first level of module
[M, S0, R0] = pebl_getfield(matlabbatch{m}, 'r', r); 
Sm = struct2sub(matlabbatch, 1);
M = M{1}; S0 = [Sm{m}, S0{1}]; R0 = [sub2str(Sm{m}), R0{1}];

% remove empty ids
ids(cellfun('isempty',ids)) = [];
% set to only cell substructs
cellids = cellfun(@(x){x(2:2:end)}, ids);

% get first level
[C1,S1,R1] = pebl_getfield(M, 'r', 1);

% set C, S, R for first level
C = cellfun(@(x){subsref(C1, x(1))}, cellids);
S = cellfun(@(x){subsref(S1, x(1))}, cellids);
R = cellfun(@(x){subsref(R1, x(1))}, cellids);

% set each item's value/substruct/string rep
for x = 1:numel(cellids),
    for n = 2:numel(cellids{x}),
        % if branch following repeat, need to ensure (1) is set for single struct
        if strcmp(types{x}, 'cfg_branch') && strcmp(types{max(1,x-1)}, 'cfg_repeat') && numel(C{x})==1,
            % for each with same field
            for m = find(strcmp(R(x:end), R{x-1}))+x-1,
                cellids{m}(n).type = '()';
                C{x} = subsref(C{x}, cellids{m}(n));
                S{m} = [S{m}, cellids{m}(n)];
                R{m} = [R{m}, sub2str(cellids{m}(n))];
                cellids{m}(n) = [];
            end
        else % otherwise get appropriate field
            [C_,S_,R_] = pebl_getfield(C{x}, 'r', 1);
            C{x} = subsref(C_, cellids{x}(n));
            S{x} = [S{x}, subsref(S_, cellids{x}(n))];
            R{x} = [R{x}, subsref(R_, cellids{x}(n))];
        end
    end
end

% prepend with M as first index
C = [{M}, C];
S = [{sub2str('(:)')}, S];
R = [{''}, R];

% prepend each S/R with matlabbatch 
for x = 1:numel(S),
    S{x} = [S0, S{x}];
    R{x} = [R0, R{x}];
end
end

function output = idx2options(h, matlabbatch, idx, options, output_type)
    
% init output_type output, idx
if ~exist('output_type', 'var'), output_type = 'options'; end;
output = {};
idx(end+1:numel(matlabbatch)) = {[]};

% if empty matlabbatch, return empty output
if isempty(matlabbatch)||all(cellfun('isempty',matlabbatch)), return; end;

% for each module, get values, substructs, string reps then set output
for m = 1:numel(matlabbatch),
    % get ids for matlabbatch{m}
    [id, types] = get_ids(h, m);
    % get values, substructs, and string reps
    [C,~,R] = convert_ids(matlabbatch, m, id, types);
    % if output options
    if strcmp(output_type, 'options'),
        if isempty(idx{m}), continue; end;
        for x = idx{m},
            output{end+1} = R{x};
            output{end+1} = C{x};
        end
    else % if output idxs
        if m > numel(output), output{m} = []; end;
        for x = 1:2:numel(options),
            % if struct, convert to str
            if isstruct(options{x}),
                R0 = sub2str(options{x});
                idx = find(strcmp(R, R0));
            % find using regexp if expr
            elseif any(strfind(options{x},'*')),
                idx = find(~cellfun('isempty',regexp(R, options{x})));
            else % find using strcmp
                idx = find(strcmp(R, options{x}));
            end
            if isempty(idx), % if none, try using pebl_getfield
                R0 = strrep(options{x}, '(:)', '(1:100)');
                [~,~,R0] = pebl_getfield(matlabbatch, 'R', R0);
                idx = find(strcmp(R, R0));
            end
            % concatenate and sort
            output{m} = cat(2, output{m}, idx);
            output{m} = sort(output{m});
        end
    end 
end

% set output based on options
if strcmp(output_type, 'options') && ~isempty(output) && ~isempty(options),
    R1 = output(1:2:end);
    for x = 1:2:numel(options),
        if isstruct(options{x}), % if struct, use sub2str
            R0 = sub2str(options{x}); 
            i1 = 2 * find(strcmp(R1, R0), 1) - 1;
        elseif any(strfind(options{x},'*')) % expr use regexp 
            i1 = 2 * find(~cellfun('isempty',regexp(R1, options{x})), 1) - 1;
        else % otherwise pebl_getfield
            R0 = strrep(options{x}, '(:)', '(1:100)');
            [~,~,R0] = pebl_getfield(matlabbatch, 'R', R0);
            i1 = 2 * find(strcmp(R1, R0)) - 1;
        end % set output
        if ~isempty(i1), output(i1:i1+1) = options(x:x+1); end;
    end
end
end