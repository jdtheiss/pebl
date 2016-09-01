function [matlabbatch, itemidx, str] = sawa_setupjob(matlabbatch, itemidx, m)
% [matlabbatch, itemidx, str] = sawa_setupjob(matlabbatch, itemidx, m)
% Opens matlabbatch job using batch editor (cfg_ui) and records items to be 
% used as sawa variables as well as the input user data.
% 
% Inputs:
% matlabbatch - (optional) job to be loaded. default is empty job
% itemidx - (optional) item indices to be set as sawa variables. default is
% empty
% m - (optional) module index to set to initially
% 
% Outputs: 
% matlabbatch - final job returned with user data
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
if ~exist('spm','file'), error('Must set SPM to matlab path.'); end;
if ~exist('matlabbatch','var'), matlabbatch = {}; end;
if ~exist('itemidx','var')||isempty(itemidx), itemidx = {[]}; end;
if ~exist('m','var')||isempty(m)||m>numel(matlabbatch), m = 1; end;
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
evalc('cfg_util(''initjob'',matlabbatch)'); cfg_ui('local_showjob',h);
end;

% get modlist/module
modlist = handles.modlist; module = handles.module;
userdata = modlist.UserData;

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
userdata = modlist.UserData;

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
[~,matlabbatch] = cfg_util('harvest',userdata.cjob); 

% delete cfg_ui
if any(ishandle(h)), delete(h); end;
