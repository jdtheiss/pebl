function [C, reps] =  pebl_eq(A, B)
% [C, reps] = pebl_eq(A, B)
% Checks if all components of A and B are equal.
%
% Inputs:
% A - first element
% B - element to compare with A
% 
% Outputs:
% C - true/false all components are equal
% reps - columns (A, B) with string representations indicating components
% that were not equal
%
% Example:
% A = struct('field1',{1},'field2',{2});
% B = struct('field1',{'1'},'field2',{2});
% 
% [C, reps] = pebl_eq(A,B)
% 
% C =
% 
%      0 
%
% reps = 
% 
%     '.field1'    '.field1'  
%
% Note: if a non-struct or non-cell object is input, the returned rep will
% be unreliable.
%
% requires: pebl_getfield
% Created by Justin Theiss

% init C, reps
C = true;
reps = {};

% if empty, number or string, set genstr
Acell = false; Bcell = false;
if isempty(A)||isnumeric(A)||ischar(A), A = {A}; Acell = true; end;
if isempty(B)||isnumeric(B)||ischar(B), B = {B}; Bcell = true; end;

% get all values
[Avals,~,Areps] = pebl_getfield(A);
if Acell, Areps = {''}; end; 
[Bvals,~,Breps] = pebl_getfield(B);
if Bcell, Breps = {''}; end;

% check for nan
r = randn(1);
[f_a,s_a] = pebl_getfield(Avals,'fun',@(x)any(isnan(x(:))));
[f_b,s_b] = pebl_getfield(Bvals,'fun',@(x)any(isnan(x(:))));
for x = 1:numel(f_a), f_a{x}(isnan(f_a{x})) = r; Avals = subsasgn(Avals,s_a{x},f_a{x}); end;
for x = 1:numel(f_b), f_b{x}(isnan(f_b{x})) = r; Bvals = subsasgn(Bvals,s_b{x},f_b{x}); end;

% check for function_handles
r = num2str(randn(1));
[f_a,s_a] = pebl_getfield(Avals,'fun',{@isa,'function_handle'});
[f_b,s_b] = pebl_getfield(Bvals,'fun',{@isa,'function_handle'});
for x = 1:numel(f_a), Avals = subsasgn(Avals,s_a{x},[func2str(f_a{x}),r]); end;
for x = 1:numel(f_b), Bvals = subsasgn(Bvals,s_b{x},[func2str(f_b{x}),r]); end;

% check for empty cells
r = randn(1);
[f_a,s_a] = pebl_getfield(Avals,'fun',@(x)isempty(x) && iscell(x));
[f_b,s_b] = pebl_getfield(Bvals,'fun',@(x)isempty(x) && iscell(x));
for x = 1:numel(f_a), Avals = subsasgn(Avals,s_a{x},r); end;
for x = 1:numel(f_b), Bvals = subsasgn(Bvals,s_b{x},r); end;

% comparison functions
cmp_funs = {@(v1,v2,r1,r2)ismember(r1,r2),... % compare reps unsorted
            @(v1,v2,r1,r2)ismember(r2,r1),... % compare reps unsorted (opposite comparison)
            @(v1,v2,r1,r2)strcmp(r1,r2),... % compare reps in order
            @(v1,v2,r1,r2)cellfun(@(x,y)strcmp(class(x),class(y)),v1,v2),... % compare classes
            @(v1,v2,r1,r2)cellfun(@(x,y)numel(size(x))==numel(size(y))&&all(size(x)==size(y)),v1,v2),... % compare size
            @(v1,v2,r1,r2)cellfun(@(x,y)all(eq(x(:),y(:))),v1,v2)}; % compare all items
        
% compare number of vals, reps, classes, size, items
for f = 1:numel(cmp_funs),
    % get comparison
    ck = cmp_funs{f}(Avals, Bvals, Areps, Breps);
    if isempty(ck), ck = false; end;
    % set C
    C = C && all(ck);
    % return if not C and only one output
    if nargout==1 && ~C, 
        return; 
    else
        % update vals and reps
        [Avals, Bvals] = local_update(Avals, Bvals, ck);
        [Areps, Breps, reps0] = local_update(Areps, Breps, ck);
        if ~isempty(reps0), reps = pebl_cat(1, reps0, reps); end;
        % if no Areps/Breps, return
        if isempty(Areps) || isempty(Breps), return; end;
    end
end
end
        
function [A, B, reps] = local_update(A, B, ck)
    % get unique reps, ensuring ck is same size as Areps or Breps
    if all(size(ck) == size(A)), A0 = A(~ck); A(~ck) = []; else A0 = {}; end;
    if all(size(ck) == size(B)), B0 = B(~ck); B(~ck) = []; else B0 = {}; end;
    % concatenate removed reps from A/B
    if nargout == 3, reps = pebl_cat(2, A0(:), B0(:)); end;
end