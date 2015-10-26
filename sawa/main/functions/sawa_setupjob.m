function [matlabbatch,itemidx,str] = sawa_setupjob(matlabbatch, itemidx, str)
% [matlabbatch, itemidx, str] = sawa_setupjob(varargin)
% sets up the job using the cfg_ui function
% records matlabbatch, field, tags, and string of the batch editor
%
% Inputs:
% matlabbatch - (optional) matlabbatch to load
% itemidx - (optional) cell array of numeric indices for each item to be set 
% (based on place in display)
% str - (optional) cell array of strings corresponding to the matlabbatch
%
% Outputs:
% matlabbatch - matlabbatch array 
% itemidx - cell array of numeric indices for each item to be set
% str - cell array of strings corresponding to the matlabbatch 
%
% requires: subidx
%
% Created by Justin Theiss


% init vars
if ~exist('spm','file'), error('Must set SPM to matlab path.'); end;
if ~exist('matlabbatch','var'), matlabbatch = {}; end;
if ~exist('itemidx','var'), itemidx = {}; end;
if ~exist('str','var'), str = {}; end;

% prevent matlab from giving warnings when a text entered matches a function
warning('off','MATLAB:dispatcher:InexactCaseMatch');
 
% initcfg
spm_jobman('initcfg'); cfg_util('initcfg');
% open cfg_ui and guidata
h = cfg_ui; handles = guidata(h);
% msg to display in string
chmsg = '----sawa variable----';
% load batch 
if ~isempty(matlabbatch) % if matlabbatch isn't empty, open job
evalc('cfg_util(''initjob'',matlabbatch)'); cfg_ui('local_showjob',h);
% get matlabbatch, chsn, itemidx, etc
[handles,~,str] = getset_string(handles,str,chmsg,[],0);
else % no matlabbatch, choose modules
uiwait(msgbox('Choose/load modules to run. Then click OK.'));
udmodlist = get(handles.modlist,'userdata');
% set initials to empty
names=cell(size(udmodlist.id)); obtype=cell(size(udmodlist.id)); 
itemidx=cell(size(udmodlist.id)); str=cell(size(udmodlist.id));
end

% choose variables to use subject array with
if exist('matlabbatch','var'), defans = 'No'; else defans = 'Yes'; end;
if strcmp(questdlg('Choose variables to be input by sawa?','Variables','Yes','No',defans),'Yes')
choose=1; hm=msgbox('Choose variable, then click OK.');
while choose
[handles,~,str] = getset_string(handles,str,chmsg,hm,choose);
% choose a new variable?
newvar = questdlg('Choose new variable?','New Variable','Yes','No','Remove Previous','Yes');
switch newvar
case 'Yes', choose = 1; hm=msgbox('Choose variable, then click OK.');
case 'No', choose = 0; break;
case 'Remove Previous', choose = 2; hm = msgbox('Choose variable to remove, then click OK.'); 
end
end
end

% Enter variables
% wait while user fills out variables
hm = msgbox('Enter other variables, then click OK.');
% get choices
[handles,itemidx,str] = getset_string(handles,str,chmsg,hm,0);
% get matlabbatch for current job as is
[~,matlabbatch] = cfg_util('harvest',subidx(get(handles.modlist,'userdata'),'.cjob'));
% delete cfg_ui handle
if ishandle(h), delete(h); end;

% getset_string function
function [handles,chsn,str] = getset_string(handles,str,chmsg,hm,choose)    
% if missing choose var, set choose to 1
if ~exist('choose','var'), choose = 1; end;

% if hm is a handle or until m is created
while any(ishandle(hm))||~exist('m','var'), pause(.25); % wait while open
ostr=get(handles.module,'String'); m=get(handles.modlist,'value'); ov=get(handles.module,'value');
if m > numel(str), str{m} = []; end;
if size(get(handles.modlist,'string'),1) < numel(str)
str(m) = []; chsn(m) = [];
else
for m1=1:numel(str), chsn{m1}=find(strcmp(str{m1},chmsg))'; end; 
dif = length(ostr)-length(str{m}); chsn{m}(chsn{m}>ov)=chsn{m}(chsn{m}>ov)+dif;
str{m} = ostr; str{m}(chsn{m}) = {chmsg}; set(handles.module,'String',str{m});
end
end

% get new choices
if choose==1&&~any(chsn{m}==ov), % add choice
chsn{m}=sort(horzcat(chsn{m},ov));
elseif choose==2 % remove choice    
chsn{m}(chsn{m}==ov) = []; 
end

% load module to get ostr, then set new str
cfg_ui('local_showmod',handles.modlist); ostr = get(handles.module,'string');
str{m} = ostr; str{m}(chsn{m}) = {chmsg};   
% set string
if numel(str)<=m &&~isempty(str{m}), set(handles.module,'String',str{m}); end;
return;
