function [vals,tags,reps] = sawa_getfield(A, irep, itag, refs)
% [values, tags, reps] = sawa_getfield(A, irep, itag);
% Gets values, tags, and reps (string representations) of structures or objects
%
% Inputs:
% A - array, object, or cell array (does not work for numeric handles)
% irep - input string representation of array A
% itag - input regular expression of a tag or component of array A that you
% want to return (default is '.$'). if itag = '', all values will be returned.
% refs - (optional) number of times a field tag can be referenced before
% stopping (see Note2). default is 1
% 
% Outputs:
% values - the returned values from each getfield(A,itag)
% tags - the end tag of the array for value
% reps - string representation of getfield(A,itag)
%
% example:
% sa = struct('ln_k',{{-1.3863},{-2.7474,-2.6552}});
% [values,tags,reps] = sawa_getfield(sa,'sa','ln_k\{\d+\}$')
% vals = 
%     [-1.3863]    [-2.7474]    [-2.6552]
% tags = 
%     '{1}'    '{1}'    '{2}'
% reps = 
%     'sa(1).ln_k{1}'    'sa(2).ln_k{1}'    'sa(2).ln_k{2}'
%
% NOTE: Searching for itag uses regexp (i.e. 'subj.s' will find 'subj_s', 
% and 'subj.*s' will find 'subjFolders' or 'subj_s'). Additionally, itag 
% should use regexp notation (use regexptranslate to automatically input escape characters)
% NOTE2: in order to avoid self-referenceing loops in handles, refs is used
% as the number of times a field tag (e.g. .UserData) may exist in a single
% rep (e.g., .CurrentAxes.UserData.Axes(2).UserData has two refs).
% NOTE3: For handles: unless Parent is included in itag, the .Parent field of handles
% is not used to avoid infinite loop of ".Parent.Children.Parent".
%
% Created by Justin Theiss

% init vars
vals = {}; tags = {}; reps = {};
if ~exist('A','var')||isempty(A), return; end;
if ~exist('irep', 'var')||isempty(irep), irep=''; end;
if ~exist('itag', 'var')||~ischar(itag), itag = '.$'; end;
if ~exist('refs','var')||isempty(refs), refs = 1; end;

% get class of A
if iscell(A)
    % set values
    for x = 1:numel(A), vals{x} = A{x}; end;
    % set tags
    tags = set_tags(size(A),'{}'); 
    % set reps
    reps = strcat(irep,tags); 
elseif ~isnumeric(A)&&(isstruct(A)||any(any(ishandle(A))))
    % set values
    for x = 1:numel(A), vals{x} = A(x); end;
    % set tags
    tags = set_tags(size(A),'()'); 
    % set reps
    reps = strcat(irep,tags);
    % if fnd, return    
    if any(regexp(irep,itag)), return; end;
    % if only 1, get each fld 
    if numel(A)==1,    
    vals = {}; tags = {}; reps = {};
    % get fieldnames
    flds = fieldnames(A); 
    % do not go to parent unless in itag
    if ~any(regexp(itag,'Parent'))&&ishandle(A), flds = flds(~strcmp(flds,'Parent')); end;
    % set vals to A.flds
    for x = 1:numel(flds), 
        vals{x} = A.(flds{x});
    end % set tags
    tags = flds';
    % set reps
    reps = strcat(irep,'.',tags); 
    end
else % anything else, return
    if isempty(itag)||any(regexp(irep,itag))
    % set vals
    vals{1} = A; 
    % set tags
    tags = regexp(irep,'(\.\w+$)?([\{\(]\d+,?\d*[\}\)]$)?','match'); 
    % set reps
    reps{1} = irep; 
    end
    return;
end 

% find matches
fnd = ~cellfun('isempty',regexp(reps,itag)); 

% for each value, run sawa_getfield
for x = find(~fnd), 
    % if multiple references to same field name, skip
    if all(isstrprop(tags{x},'alphanum'))&&numel(regexp(reps{x},['\.' tags{x} '\.'])) > refs, 
        continue; 
    end;
    % run sawa_getfield with vals
    [vals{x},tags{x},reps{x}] = sawa_getfield(vals{x},reps{x},itag,refs);
end;

% expand inner cells
[vals,tags,reps] = local_expandcells(vals,tags,reps);

function tags = set_tags(mn,sep)
% init tags
tags = {''}; 
if ~isnumeric(mn), mn = size(mn); end;
% if all 1 and not cell, return
if all(mn==1)&&~strcmp(sep,'{}'), return; end;
if all(mn>1), % rows,columns
tags = arrayfun(@(x){arrayfun(@(y){[sep(1) num2str(x) ',' num2str(y) sep(2)]},1:mn(2))},1:mn(1));
tags = [tags{:}];
else % rows or columns
tags = arrayfun(@(x){[sep(1) num2str(x) sep(2)]},1:max(mn));    
end
return;

function [vals,tags,reps] = local_expandcells(vals,tags,reps)
% if no inner cells, return
if ~any(cellfun('isclass',tags,'cell')), return; end;
% init vars
tmpvals = {}; tmptags = {}; tmpreps = {};
% expand inner cells
for x = 1:numel(vals)
    if iscell(tags{x}) % expand
    tmpvals = cat(2,tmpvals,vals{x}{:});
    tmptags = cat(2,tmptags,tags{x}{:});
    tmpreps = cat(2,tmpreps,reps{x}{:});
    else % simple cat
    tmpvals = cat(2,tmpvals,vals{x});
    tmptags = cat(2,tmptags,tags{x});
    tmpreps = cat(2,tmpreps,reps{x});
    end
end
% output
vals = tmpvals; tags = tmptags; reps = tmpreps;
return;
