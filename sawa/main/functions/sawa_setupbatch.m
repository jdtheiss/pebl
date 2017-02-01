function [matlabbatch, options, itemidx, str] = sawa_setupbatch(matlabbatch, preopts, itemidx, m)
% [matlabbatch, options, itemidx, str] = sawa_setupjob(matlabbatch, preopts, itemidx, m)
% Opens matlabbatch job using batch editor (cfg_ui) and records items to be 
% used as sawa variables as well as the input user data.
% 
% Inputs:
% matlabbatch - (optional) job to be loaded. default is empty job
% preopts - (optional) - pairs of substruct and value corresponding to each
% previously chosen item
% itemidx - (optional) item indices to be set as sawa variables. default is
% empty
% m - (optional) module index to set to initially
% 
% Outputs: 
% matlabbatch - final job returned with user data
% options - pairs of substruct and value corresponding to each chosen item
% itemidx - item indices to be set as sawa variables
% str - string of cfg_ui display for chosen modules
% 
% Example:
% [matlabbatch, itemidx, str] = sawa_setupjob;
% [choose "Call MATLAB function" from BasicIO tab]
% [choose "New: String" from Inputs]
% [press right arrow to set item as sawa variable]
% [enter @disp into "Function to be called"]
% [close the Batch Editor]
%
% matlabbatch{1} = 
%   cfg_basicio: [1x1 struct]
% options = 
%     [1x7 struct]    '<UNDEFINED>'
% itemidx =
%   [3]
% str{1} = 
%   'Help on: Call MATLAB function                            ...'
%   'Inputs                                                   ...'
%   '----sawa variable----'
%   'Outputs                                                  ...'
%   'Function to be called                                    ...'
%
% Note: each item index relates to its index in the display (i.e., itemidx
% 3 relates to str{1}{3}).
%
% Created by Justin Theiss

% init vars
if ~exist('cfg_ui','file'), error('Must have cfg_ui.m in matlab path.'); end;
if ~exist('matlabbatch','var'), matlabbatch = {}; end;
if ~exist('preopts','var')||isempty(preopts), preopts = {}; end;
if ~exist('itemidx','var')||isempty(itemidx), itemidx = {[]}; end;
if ~exist('m','var')||isempty(m)||m>numel(matlabbatch), m = 1; end;
options = {};
str = {[]};

% prevent matlab from giving warnings when a text entered matches a function
warning('off','MATLAB:dispatcher:InexactCaseMatch');
     
% initialize cfg_ui
spm_jobman('initcfg'); cfg_util('initcfg');

% open cfg_ui and get guidata
h = cfg_ui; handles = guidata(h); 

% set closerequestfcn to set to invisible (rather than try to save)
set(h,'CloseRequestFcn',@(x,y)set(x,'visible','off'));

% set keypress fcn for module
set(findobj(h,'tag','module'),'KeyPressFcn',@(x,y)guidata(gcf,setfield(guidata(gcf),'kp',y.Key)));

% set tooltipstring
set(findobj(h,'tag','module'),'ToolTipString','Press right arrow to set sawa variable, left to remove.');

% remove kp if already exists
if isfield(handles,'kp'), guidata(h,rmfield(handles,'kp')); end;

% msg to display in string
imsg = '----sawa variable----';

% load batch 
if ~isempty(matlabbatch) % if matlabbatch isn't empty, open job
    cfg_util('initjob',matlabbatch); cfg_ui('local_showjob',h);
end;

% get modlist/module
modlist = handles.modlist; module = handles.module;
userdata = get(modlist,'UserData');

% set modlist value
set(modlist,'value',m); 
clear m;

% init om and ostr
om = 0; ostr = {};

% while cfg_ui figure is visible
while strcmp(get(h,'visible'),'on')
% pause to allow changes
pause(.1);

% get new str, m and item index
nstr = get(module,'string'); m = get(modlist,'value'); 
nmods = cell2mat(userdata.id); i = get(module,'value');

% refresh module/get ostr if module change (or first)
if om~=m
cfg_ui('local_showmod',modlist); ostr = get(module,'string');
om = get(modlist,'value'); omods = cell2mat(userdata.id);
end

% if new module, set str to empty
str(1:numel(nmods)>numel(str)) = {[]};
itemidx(1:numel(nmods)>numel(itemidx)) = {[]}; 

% if removed module, remove str and itemidx
if numel(nmods) < numel(omods),
    str(~ismember(omods,nmods)) = [];
    itemidx(~ismember(omods,nmods)) = [];
    omods = nmods;
end

% get difference between nstr and ostr
dif = numel(nstr)-numel(ostr);

% for each itemidx, find new position
if dif ~= 0 
for x = 1:numel(itemidx{m})
    try
    n = itemidx{m}(x); % actual index
    % find matches in nstr of previous position and dif
    fnd = find(strcmp(nstr([n,n+dif]), ostr{n}));
    % if none found, remove; elseif in 2nd spot, move
    if isempty(fnd) % not found 
        itemidx{m}(x) = 0; % remove
    elseif all(fnd==2), % found in new spot 
        itemidx{m}(x) = n + dif; % move
    end
    end
end

% remove 0s from itemidx
itemidx{m}(itemidx{m}==0) = [];

% set ostr to nstr to update change
ostr = nstr;
end

% refresh guidata for keypress
handles = guidata(h); 

% get modlist/module
modlist = handles.modlist; module = handles.module;
userdata = get(modlist,'UserData');

% if keypress
if isfield(handles,'kp')
    if strcmp(handles.kp,'rightarrow') % add itemidx
        itemidx{m} = unique(horzcat(itemidx{m},i));
    elseif strcmp(handles.kp,'leftarrow') % remove itemidx
        itemidx{m}(itemidx{m}==i) = [];
    end
    % reset kp in guidata
    guidata(h,rmfield(handles,'kp'));
    % refresh module
    cfg_ui('local_showmod',modlist); 
    nstr = get(module,'string');
end

% set itemidx
str{m} = nstr;
str{m}(itemidx{m}) = {imsg};

% set str to handles
set(module,'string',str{m});
end

% get matlabbatch for current job as is
[~,matlabbatch] = cfg_util('harvest', userdata.cjob); 
% get options
if ~isempty(matlabbatch),
    for m = 1:numel(itemidx),
        [id,~,contents] = cfg_util('listmod', userdata.cjob, m, [], ...
            cfg_findspec({{'hidden',false}}),...
            cfg_tropts({{'hidden',true}},1,inf,1,inf,false),{'name','class'});
        for x = itemidx{m},
            % get tag and val
            [tag, val] = cfg_util('harvest', userdata.cjob, m, id{x});
            % search for position in names
            i = find(find(strcmp(contents{1},contents{1}{x}))==x);
            % set expression of module/tag to search
            exprtag = ['\{', num2str(m), '\}.*\.', tag];
            % get subsasgn struct
            [~,S] = sawa_getfield(matlabbatch,'expr',exprtag,'fun',@(x)sawa_eq(x,val));
            % ensure i is within numel of S
            i = min(numel(S), i);
            % set S or tag
            if ~isempty(S), % set substruct (with cell if needed)
                if strcmp(contents{2}{x},'cfg_files') && ~strcmp(S{i}(end).type,'{}'),
                    options{end+1} = [S{i}, struct('type','{}','subs',{{i}})];
                else % set standard);
                    options{end+1} = S{i};
                end
            else % set tag
                options{end+1} = ['\{', num2str(m), '\}.*\.', tag];
            end
            % set value
            options{end+1} = val;
        end
    end
end

% if any preopts, set to preopts
if ~isempty(options) && ~isempty(preopts),
    % find common items between options and preopts
    ia = cellfun(@(x){sawa_find(@sawa_eq, x, options(1:2:end))}, preopts(1:2:end));
    ib = find(cellfun(@(x)any(x), ia));
    ia = cellfun(@(x)find(x), ia(ib));
    % set to inputs rather than structures
    ia = ia * 2; ib = ib * 2;
    % set options to preopts for found items
    options(ia) = preopts(ib);
end

% delete cfg_ui
if any(ishandle(h)), delete(h); end;
