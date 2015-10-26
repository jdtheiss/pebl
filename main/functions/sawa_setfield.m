function structure = sawa_setfield(structure,idx,field,sub,varargin)
% structure = sawa_setfield(structure,idx,field,sub,varargin)
% Set fields for structure indices
%
% Inputs:
% structure- input structure
% idx - indices of structure to set (or create)
% field- field to set for structure array
% sub (optional) string representation of subfields/subcells to set 
% (e.g., '.anotherfield' or '{2}').
% varargin- value(s) to add to structure.field(sub). if one varargin, all
% idx set to varargin{1}, else each idx set to respective varargin.
% 
% Outputs:
% structure - output structure with set fields
%
% example: set second "age" cell for subjects 2:4 to 12
% sa(2:4) = sawa_setfield(sa,2:4,'age','{2}',12);
% example 2: set mask.Grey.dimension, mask.White.dimension, mask.CSF.dimension, 
% to 32, 5, 5 respectively
% field = 'mask'; sub = strcat('.Setup.',{'Grey','White','CSF'},'.dimension'); val = {32,5,5};
% batch = sawa_setfield(batch,1,field,sub,val{:});
%
% Note: neither the structure string rep nor any cells/periods should be included in field 
% (i.e., field = 'field', NOT field = 'structure.field.subfield{1}').
%
% Created by Justin Theiss


% init vars
if ~exist('idx','var')||isempty(idx), idx = 1:numel(structure); end;
if ~exist('field','var'), field=[]; end;
if strncmp(field,'.',1), field = field(2:end); end; 
if ~exist('sub','var')||isempty(sub),sub=''; end; 
if iscell(structure)||~isstruct(structure), s='{}'; else s='()'; end
if isempty(varargin), varargin{1} = {[]}; end;

% if field, set if needed
if ~isempty(field)
% remove non-allowable from field
field = regexprep(field,'[^\w\.\{\}\(\)]','_');
% if not field in struct, set field 
if ~iscell(structure) && ~isfield(structure,field),
evalin('caller',['[' inputname(1) '.' field ']=deal([]);']);    
end % add period before 
field = ['.' field]; 
elseif any(idx > numel(structure)) % if not using field and idx greater than struct
for x = find(idx > numel(structure)), % set structure empty for idx > numel
    eval(['structure{' num2str(x) '}=[];']); 
end
end

% create reps for each struct
rep = strcat('structure',s(1),arrayfun(@(x){num2str(x)},idx),s(2),field);
rep = strcat(rep,sub); % set sub to reps
if numel(varargin)==1, n = '1'; else n = 'x'; end; % if one varargin, set each 
for x = 1:numel(rep), % for each rep, if set already set empty
    set = 1; try evalc(rep{x}); catch; set = 0; end; 
    if set && iscell(eval(rep{x})), eval([rep{x} '={[]};']); 
    elseif set, eval([rep{x} '=[];']); end; 
    % set rep to varargin
    if isempty(eval(['varargin{' n '}']))&&~iscell(eval(['varargin{' n '}']))
    try eval([rep{x} '=[];']); end; % try to remove
    else % set 
    eval([rep{x} '=varargin{' n '};']); 
    end
end

% set output
structure = structure(idx);
