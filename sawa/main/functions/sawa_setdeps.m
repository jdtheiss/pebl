function matlabbatch = sawa_setdeps(matlabbatch, cjob, m)
% matlabbatch = sawa_setdeps2(matlabbatch, cjob, m)
% This function will set dependencies for matlabbatch jobs based on
% outputs from previous jobs. 
% 
% Inputs:
% matlabbatch - current matlabbatch job(s) to set dependencies for 
% cjob - (optional) job id from previous matlabbatch job (must be valid)
% m - index of current module to set. default sets all jobs
%
% Outputs:
% matlabbatch - current matlabbatch job(s) with updated dependencies
% 
% Note: If cjob is not valid, dependencies for the current job will be
% replicated to match the number of source output. For example, if four 
% runs are input to a module, any module that depends on it will have four
% dependencies.
%
% requires: sawa_getfield 
% Created by Justin Theiss

% init vars
if ~exist('matlabbatch','var')||isempty(matlabbatch), return; end;
if ~exist('cjob','var')||isempty(cjob), cjob = []; end;
if ~exist('m','var')||isempty(m), m = 1:numel(matlabbatch); end;

% get cjob for matlabbatch
[~,cjob2] = evalc('cfg_util(''initjob'',matlabbatch)');
[~,~,~,deps] = cfg_util('showjob',cjob2);
deps = deps(m);

% for each or chosen module(s)
for m = m(deps), 
% find cfg_deps
[C,S] = sawa_getfield(matlabbatch{m},'func',@isa,'search','cfg_dep');
if isempty(C), continue; end;

% get module source for each val
m0 = unique(cell2mat(cellfun(@(x){cellfun(@(y)y.src_exbranch(2).subs{1},num2cell(x))},C)));

% get outputs (updated after each module is set)
if isempty(cjob)||~any(arrayfun(@(x)cfg_util('isjob_id',x),cjob)),
[~,cjob2] = evalc('cfg_util(''initjob'',matlabbatch)');
[~,~,~,~,outputs] = cfg_util('showjob',cjob2); 

% get src_outputs for current job and expected
srcouts = sawa_getfield([outputs{m0}],'str','.src_output(end).subs','func',@ischar);
tgtouts = sawa_getfield([C{:}],'str','.src_output(end).subs','func',@ischar);

% if same amount, skip module
if sum(ismember(srcouts,tgtouts))==numel(tgtouts), continue; end;

else % otherwise get true outputs
outputs = arrayfun(@(x)cfg_util('getalloutputs',x),cjob);
end

% for each value
for x = 1:numel(C),
% get id, contents
[id,~,contents] = cfg_util('listmod',cjob2,m,[],cfg_findspec({{'hidden',false}}),...
cfg_tropts({{'hidden',true}},1,inf,1,inf,false),{'name','class','level'});

% get appropriate index
i = find(ismember(contents{1},C{x}(1).tname)); 

% get parent of indices to replicate
p = find(ismember(contents{2}(1:i(end)),'cfg_repeat'));
p = p(cell2mat(contents{3}(p))<contents{3}{i(end)});

% get outputs
m0 = unique(cellfun(@(y)y.src_exbranch(2).subs{1},num2cell(C{x}))); 

for y = m0
% find outputs with matching src_output
n0 = [];
if isempty(cjob),
n0 = ismember(sawa_getfield(outputs{y},'str','.src_output(end).subs','func',@ischar),sawa_getfield(C{x},'str','.src_output(end).subs','func',@ischar));
end
if ~isempty(n0), outputs{y} = outputs{y}(n0); end;

% for each matching src_output in outputs{m0}
for z = 1:numel(outputs{y}), 
    % continue if already set dep
    if numel(i) >= z && isa(outputs{y}(z),'cfg_dep'), continue; end;
    % set repeat if cell
    if strcmp(S{x}(end).type,'{}'), 
        cfg_util('setval',cjob2,m,id{p},[0,z-1]);
    else % otherwise set to all
        z = ':';
    end
    
    % get updated id
    [id,~,contents] = cfg_util('listmod',cjob2,m,[],cfg_findspec({{'hidden',false}}),...
    cfg_tropts({{'hidden',true}},1,inf,1,inf,false),{'name','class'});

    % get appropriate index
    i = find(ismember(contents{1},C{x}(min(numel(C{x}),z)).tname));
    
    % set dep with output
    if isa(outputs{y}(z),'cfg_dep'), % set to appropriate number of deps
        cfg_util('setval',cjob2,m,id{i(z)},outputs{y}(z)); 
    elseif isnumeric(z) % set to true output iteratively
        cfg_util('setval',cjob2,m,id{i(z)},subsref(outputs{y}(z),C{x}(min(numel(C{x}),z)).src_output));
    else % set to true output all at once
        tmpout = arrayfun(@(y){subsref(outputs{y}(y),C{x}(min(numel(C{x}),y)).src_output)},1:numel(outputs{y}));
        cfg_util('setval',cjob2,m,id{i(z)},tmpout);
    end
    
    % if xx is ':', break
    if ~isnumeric(z) && strcmp(z,':'), break; end;
end
end
end
% get matlabbatch
[~,matlabbatch] = cfg_util('harvest',cjob2);
end
return;