function matlabbatch = sawa_setdeps(prebatch, matlabbatch,m,cjob)
% matlabbatch = sawa_setdeps(prebatch, matlabbatch)
% this function will set dependencies for fields that change (e.g. if a
% dependency is set for Session 1 and new Sessions are added, new
% dependencies will be added to mirror the Sessions added). If however, the
% number available dependencies prior function-filling is greater than the
% number of dependencies set by user, then the user-set dependencies will
% be used instead.
%
% Inputs:
% prebatch - matlabbatch that is set up by user prior to function-filling
% matlabbatch - matlabbatch after function-filling
%
% Outputs:
% matlabbatch - matlabbatch with function-filled data and appropriate deps
%
% Note: This function assumes that cell components (e.g. Sessions) should
% be replicated and non-cell components (e.g. Images to Write) should not 
% be replicated.
%
% requires: sawa_find subidx
%
% Created by Justin Theiss

% if no cfg_util, error
if ~exist('cfg_util','file'), error('Must set SPM to matlab path.'); end;

% load job
[~,cjob1,mod_ids1] = evalc('cfg_util(''initjob'',prebatch)');
if ~exist('m','var'), m = 1:numel(mod_ids1); end;

% get str, dep and sout
[~,str1,~,~,sout1]=cfg_util('showjob',cjob1);
%%%%%%%%
if exist('cjob','var'), newval = cfg_util('getalloutputs',cjob); end;

% for each module
for m = m %1:numel(mod_ids1)
% get str2 sout2 based on updated matlabbatch 
clear cjob2 mod_ids2 str2 sout2;
[~,cjob2,mod_ids2] = evalc('cfg_util(''initjob'',matlabbatch)');
[~,str2,~,~,sout2]=cfg_util('showjob',cjob2);

% find cfg_dep
clear val1 tag1; 
[~,val1,tag1] = sawa_find(@isa,'cfg_dep',prebatch{m},'','.*',1:20);

% for each dep found in prebatch{x}
for x = 1:numel(val1) 
% if no val1{x} continue
if isempty(val1{x}), continue; end;
clear sname n0 n x0 tmp predeps;

% get source name
sname = val1{x}.sname;

% get place at : and place at ' ' for module and sname
n = subidx(strfind(sname,' '),'(end)'); 

% find module and snames that match 
x0 = find(~cellfun('isempty',regexp(sname,strcat(str1,':'))),1);
tmp = sout1{x0};

% find available deps in prebatch
predeps = ~cellfun('isempty',regexp({tmp.sname},regexptranslate('escape',sname(1:n))));

% find available deps in postbatch
clear x0 tmp postdeps; 
x0 = find(~cellfun('isempty',regexp(sname,strcat(str2,':'))),1);
tmp = sout2{x0};
postdeps = ~cellfun('isempty',regexp({tmp.sname},regexptranslate('escape',sname(1:n))));

% if more available than set or pre/post same, use prebatch deps
% if (numel(val1{x}) < numel(find(predeps)))||(numel(find(predeps)) == numel(find(postdeps)))
%      continue; % skip
% end % otherwise don't skip

% get id, contents
[id,~,contents] = cfg_util('listmod',cjob2,mod_ids2{m},[],cfg_findspec({{'hidden',false}}),...
cfg_tropts({{'hidden',true}},1,inf,1,inf,false),...
{'name','val','labels','values','class','level','all_set','all_set_item','num'});

% get appropriate index
i = find(ismember(contents{1},val1{x}.tname),1,'last');

% get parent of indices to replicate
p = find(ismember(contents{5}(1:i),'cfg_repeat'));
p = p(cell2mat(contents{6}(p))<contents{6}{i}); 

% for each newdeps, replicate
for xx = 1:numel(postdeps)
% set repeat if cell
if any(regexp(tag1{x},'\{\d+\}')),
cfg_util('setval',cjob2,mod_ids2{m},id{p},[0,xx-1]);  
end

% get updated id
[id,~,contents] = cfg_util('listmod',cjob2,mod_ids2{m},[],cfg_findspec({{'hidden',false}}),...
cfg_tropts({{'hidden',true}},1,inf,1,inf,false),{'name','class'}); 

% get appropriate index
i = find(ismember(contents{1},val1{x}.tname),1,'last'); 

% set dependency
if nargin==4, 
cfg_util('setval',cjob2,mod_ids2{m},id{i},subsref(newval{x0}(postdeps),val1{x}.src_output));
elseif ~any(regexp(tag1{x},'\{\d+\}')),
cfg_util('setval',cjob2,mod_ids2{m},id{i},sout2{x0}(postdeps)); 
break;
else % if cell
cfg_util('setval',cjob2,mod_ids2{m},id{i},sout2{x0}(xx)); 
end
end

% get matlabbatch
[~,matlabbatch] = cfg_util('harvest',cjob2);
end
end
