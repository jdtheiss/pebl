function [matlabbatch,chngidx,sts] = sawa_setbatch(matlabbatch,val,itemidx,rep,m)
% [matlabbatch,chngidx,sts]=sawa_setbatch(matlabbatch,val,itemidx,rep,m)
% Set matlabbatch structure items to vals.
%
% Inputs:
% matlabbatch - batch job
% val - values to set to itemidx in matlabbatch
% itemidx - item index corresponding to the list in module.contents{1}
% rep - index of the cfg_repeat item to repeat for itemidx (if applicable)
% m - index of module to set
%
% Outputs:
% matlabbatch - current batch structure for matlabbatch cfg system
% chngidx - number indicating change from itemidx (i.e. from replicating
% module components)
% sts - numeric array of 1/0 for status of whether each component was set
%
% Created by Justin Theiss


% init vars
if ~exist('cfg_util','file'), error('Must set SPM to matlab path.'); end;
if ~exist('val','var'), return; end; if ~iscell(val), val = {val}; end;
if ~exist('itemidx','var')||isempty(itemidx), return; end;
if ~exist('rep','var')||isempty(rep), rep = 0; end;
if ~exist('m','var'), m = 1; end;
if ~exist('ind','var'), ind = 0; end;
sts = zeros(size(val));

% if no rep but multiple vals, set to val to {val}
if rep==0&&numel(val)>0, val = {val}; end;

% record previous itemidx in case change
tmpidx = itemidx; chngidx = 0;
% initial job from matlabbatch
cfg_util('initcfg');
[~,cjob,mod_ids] = evalc('cfg_util(''initjob'',matlabbatch)');

% for each cell in val
for x = 1:numel(val)
if isempty(val{x}), continue; else ind = ind+1; end; % if empty val, skip
% load job and get item ids and contents
[id,~,contents]=cfg_util('listmod',cjob,mod_ids{m},[],...
cfg_findspec({{'hidden',false}}),cfg_tropts({{'hidden',true}},1,inf,1,inf,false),...
{'name','val','labels','values','class','level','all_set','all_set_item','num'});

% replicate if rep is indicated
if rep > 0, 
% check if already created
[~,~,contents2]=cfg_util('listmod',cjob,mod_ids{m},id{rep},cfg_findspec({{'name',contents{1}{itemidx}}}),...
cfg_tropts({{'hidden',true}},1,inf,1,inf,false),{'name'});
if ~any(1:numel(contents2{1})==ind)&&any(strcmp(contents2{1},contents{1}{itemidx}))
% set val to ind if not already
cfg_util('setval',cjob,mod_ids{m},id{rep},[0,ind-1]);  
end
% get updated id, contents2
[id,~,contents2]=cfg_util('listmod',cjob,mod_ids{m},[],cfg_findspec({{'hidden',false}}),...
cfg_tropts({{'hidden',true}},1,inf,1,inf,false),{'name'}); 
% find the appropriate index
newidx = find(ismember(contents2{1}(rep+1:end),contents{1}{itemidx}));
newidx = newidx(ind);
if isempty(newidx), newidx = 0; end;
itemidx = rep+newidx; 
% record difference
chngidx = itemidx-tmpidx; 
end

% set based on type of value
switch contents{5}{itemidx}
case 'cfg_files' % for files, cellstr
    if ~iscell(val{x}), val{x} = cellstr(val{x}); end;
case 'cfg_entry' % for entry, not cell
    if iscell(val{x}), val{x} = [val{x}{:}]; end;
end

% set values to matlabbatch
sts(x) = cfg_util('setval',cjob,mod_ids{m},id{itemidx},val{x}); 
end

% harvest matlabbatch
[~,matlabbatch] = cfg_util('harvest',cjob);
