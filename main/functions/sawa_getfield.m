function [vals,tags,reps] = sawa_getfield(A, irep, itag)
% [values, tags, reps] = sawa_getfield(A, irep, itag);
% Gets values, tags, and reps (string representations) of structures or objects
%
% Inputs:
% A - array, object, or cell array
% irep - input string representation of array A
% itag - input regular expression of a tag or component of array A that you
% want to return (default is '.$'). if itag = '', all values will be returned.
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
% NOTE2: For handles: unless Parent is included in itag, the .Parent field of handles
% is not used to avoid infinite loop of ".Parent.Children.Parent".
%
% requires: sawa_cat
%
% Created by Justin Theiss


% init vars
vals = {}; tags = {}; reps = {};
if ~exist('A','var')||isempty(A), return; end;
if ~exist('irep', 'var')||isempty(irep), irep=''; end;
if ~exist('itag', 'var')||~ischar(itag), itag = '.$'; end;

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
    clear vals tags reps;
    % get fieldnames
    if ~isnumeric(A), % non-numeric handles/structs
        flds = fieldnames(A); 
    else % numeric handles 
        flds = fieldnames(get(A)); 
    end; 
    % do not go to parent unless in itag
    if ~any(regexp(itag,'Parent'))&&ishandle(A), flds = flds(~strcmp(flds,'Parent')); end;
    % set vals to A.flds
    for x = 1:numel(flds), 
        if ~isnumeric(A) % non-numeric handles/structs
            vals{x} = A.(flds{x}); 
        else % numeric handles
            vals{x} = get(A, flds{x}); 
        end; 
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
    tags = regexp(irep,'(\.\w+$)?([\{\(]\d+[\}\)]$)?','match'); 
    % set reps
    reps{1} = irep; 
    end
    return;
end 

% if any matches, return
fnd = ~cellfun('isempty',regexp(reps,itag)); 

% for each value, run sawa_getfield
for x = find(~fnd), [vals{x},tags{x},reps{x}] = sawa_getfield(vals{x},reps{x},itag); end;

% output
if any(cellfun('isclass',vals,'cell')), 
    vals = sawa_cat(2,vals{:}); tags = sawa_cat(2,tags{:}); reps = sawa_cat(2,reps{:}); 
end;

function tags = set_tags(mn,sep)
% init tags
tags = {''}; 
% if all 1 and not cell, return
if all(mn==1)&&~strcmp(sep,'{}'), return; end;
if all(mn>1), % rows,columns
tags = arrayfun(@(x){arrayfun(@(y){[sep(1) num2str(x) ',' num2str(y) sep(2)]},1:mn(2))},1:mn(1));
tags = [tags{:}];
else % rows or columns
tags = arrayfun(@(x){[sep(1) num2str(x) sep(2)]},1:max(mn));    
end
return;
