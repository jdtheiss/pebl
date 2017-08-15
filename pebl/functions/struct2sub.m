function S = struct2sub(C, r)
% S = struct2sub(C, r)
% Generate substruct from cell/structure.
%
% Inputs:
% C - cell/structure array
% r - recursion limit/number of levels (also numel(S))
%
% Outputs:
% S - cell array of substructs (see substruct)
%
% Example 1:
% matlabbatch{1}.spm.util.disp.data = '<UNDEFINED>';
% S = struct2sub(matlabbatch)
%
% S = 
% 
%     [1x5 struct]
%
% Example 2:
% matlabbatch{1}.spm.util.disp.data = '<UNDEFINED>';
% S = struct2sub(matlabbatch, 2)
%
% S = 
% 
%     [1x2 struct]
%
% Created by Justin Theiss

% init recursion limit
if ~exist('r','var')||isempty(r), r = inf; end;
if r == 0, S = {substruct('()', repmat({':'}, 1, numel(size(C))))}; return; end;

% get S0 and initialize S
S0 = local_gensub(C);
S = cell(size(S0));

% if number of recursions > r, return (avoid loop errors)
dbs = dbstack; recs = numel(find(strcmp({dbs.name},mfilename))); 
if recs > r, return; end; 

% for each new structure, find next level
for n = find(cellfun('isclass',S0,'struct')), 
    % if subsref(C, S0{n}) can be performed
    if local_checkref(C, S0{n}),
        S{n} = cellfun(@(x){cat(2, S0{n}, x)}, struct2sub(subsref(C, S0{n}), r));
    else % otherwise set to S0
        S{n} = S0{n};
    end
end

% if any subcells, collapse
if any(cellfun('isclass',S,'cell')),
    S = [S{:}]; 
end
end

function k = local_checkref(C, S)
% k = local_checkref(C, S)
% Check that subsref(C, S) can be performed

k = true;
try
    C = subsref(C, S);
catch
    k = false;
end
end

function S = local_gensub(C)
% S = local_gensub(C)
% Generate substruct for structure C

% get type
if iscell(C) && ~isempty(C),
    type = '{}'; 
elseif numel(C) > 1, 
    type = '()';
else
    type = '.';
end;
% check for fieldnames
try 
    f = ~isempty(fieldnames(C));
catch
    f = iscell(C) && ~isempty(C); 
end
if ~f, S = {[]}; return; end;
% if . type, set to fieldnames
if strcmp(type,'.'), 
    S = cellfun(@(x){substruct(type,x)}, fieldnames(C)); 
else % otherwise set to index
    n = num2cell(size(C)); 
    idx = [1:sub2ind(size(C), n{:})]';
    [n{1:numel(n)}] = ind2sub(size(C), idx);
    if size(C,1)==1 && numel(n)==2, 
        n = n(:,2); 
    end;
    n = num2cell([n{:}]);
    S = arrayfun(@(x){substruct(type,n(x,:))}, 1:size(n,1));
end
% return horizontal cell array
S = S(:)';
end