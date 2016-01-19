function [matlabbatch,sts] = sawa_setbatch(matlabbatch,val,idx,rep,m)
% [matlabbatch,sts] = sawa_setbatch(matlabbatch,val,idx,rep,m)
% iteratively set matlabbatch items for a single module (including repeat
% items)
%
% Inputs:
% matlabbatch - the matlab batch structure (can be copied from batch
% editor in "View">"Show .m Code" or saved)
% val - cell array of values to set for each item 
% idx - index of item (its position when viewing in batch editor) as number
% rep - index of repeat parent (e.g., Data/Session for Scans item) as number
% m - module index 
%
% Outputs:
% matlabbatch - the resulting matlabbatch after setting items
% sts - status of items set (0/1 failure/success)
%
% Example:
% matlabbatch{1}.cfg_basicio.call_matlab.inputs{1}.string = '<UNDEFINED>';
% matlabbatch{1}.cfg_basicio.call_matlab.outputs{1}.strtype.s = true;
% matlabbatch{1}.cfg_basicio.call_matlab.fun = '<UNDEFINED>';
% val = {{'test what?','what?','this!'},@strrep};
% idx = [3, 7];
% rep = [2, 0];
% m = 1;
% [matlabbatch,sts] = sawa_setbatch(matlabbatch,val,idx,rep,m);
% matlabbatch{1}.cfg_basicio.call_matlab.inputs{:} = 
%   string: 'test what?'
%   string: 'what?'
%   string: 'this!'
%
% matlabbatch{1}.cfg_basicio.call_matlab.fun = 
%   @strrep
% 
% sts = 
%   [1x3 logical]   [1]
%
% Note: if sts for a repeated item returns 0, the corresponding repeated
% set of items will be removed (e.g., if missing scans for 2nd run, that 
% repeat will be removed). 
% 
% Created by Justin Theiss

% init vars
if ~exist('cfg_util','file'), error('Must set SPM to matlab path.'); end;
if ~exist('val','var'), return; end; if ~iscell(val), val = {val}; end;
if ~exist('idx','var')||isempty(idx), return; end;
if ~exist('rep','var')||isempty(rep), rep = zeros(size(val)); end;
if ~exist('m','var'), m = 1; end;

% initialize job from matlabbatch
cfg_util('initcfg');
[~,cjob,mod_ids] = evalc('cfg_util(''initjob'',matlabbatch)');

% get unique reps
u_rep = unique(rep);
if u_rep(1)==0, u_rep(2:end) = fliplr(u_rep(2:end)); else u_rep = fliplr(u_rep); end;

% for each set of reps
for r = u_rep
    
    % find reps == r
    clear fnd; fnd = find(rep==r);

    % set cells if needed 
    for f = fnd, if ~iscell(val{f}), val{f} = {val{f}}; end; end;
    
    % get min ind of vals if all cell and replicating
    if all(cellfun('isclass',val(fnd),'cell')) && r > 0
    ind = 1:min(cellfun(@(x)numel(x),val(fnd))); 
    else % otherwise set to 1
    ind = 1;
    end
        
    % set cells if needed 
    for f = fnd, if numel(val{f})>numel(ind), val{f} = {val{f}}; end; end;
    
    % set sts
    sts(fnd) = {zeros(size(ind))};
    
    % for each index of set
    for x = ind
        % if replicating set val to ind
        if r > 0 && x > 1, 
        cfg_util('setval',cjob,mod_ids{m},id{r},[0,x-1]); 
        % get updated id, contents2
        [~,~,contents2]=cfg_util('listmod',cjob,mod_ids{m},[],cfg_findspec({{'hidden',false}}),...
        cfg_tropts({{'hidden',true}},1,inf,1,inf,false),{'name'}); 
        % find the appropriate index
        for rr = fnd
        clear newidx;
        newidx = find(ismember(contents2{1}(r+1:end),contents{1}{idx(rr)}));
        newidx = newidx(x); if isempty(newidx), newidx = 0; end;
        idx(rr) = r+newidx;
        end
        end
        
        % for each value at ind in set
        for xx = fnd
        % if emtpy val, skip
        if isempty(val{xx}{x}), continue; end;
 
        % load job and get item ids and contents
        [id,~,contents]=cfg_util('listmod',cjob,mod_ids{m},[],...
        cfg_findspec({{'hidden',false}}),cfg_tropts({{'hidden',true}},1,inf,1,inf,false),...
        {'name','val','labels','values','class','level','all_set','all_set_item','num'});
      
        % set based on type of value
        switch contents{5}{idx(xx)}
        case 'cfg_files' % for files, cellstr
            if ~iscell(val{xx}{x}), val{xx}{x} = cellstr(val{xx}{x}); end;
            if iscellstr(val{xx}{x}), val{xx}{x} = vertcat(val{xx}{x}(:)); end;
        case 'cfg_entry' % for entry, not cell
            if iscell(val{xx}{x}), val{xx}{x} = [val{xx}{x}{:}]; end;
        end

        % set values to matlabbatch
        sts{xx}(x) = cfg_util('setval',cjob,mod_ids{m},id{idx(xx)},val{xx}{x}); 
        end
    end
end

% remove any repeats with sts==0
for r = u_rep(u_rep~=0), 
    for rr = find(~prod(vertcat(sts{rep==r}),1)), 
        cfg_util('setval',cjob,mod_ids{m},id{r},[inf,rr]); 
    end; 
end;
    
% harvest matlabbatch
[~,matlabbatch] = cfg_util('harvest',cjob);