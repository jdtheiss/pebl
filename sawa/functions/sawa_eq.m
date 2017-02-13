function [C, reps] =  sawa_eq(A,B)
% [C, reps] = sawa_eq(A,B)
% Checks if all components of A and B are equal.
%
% Inputs:
% A - first element
% B - element to compare with A
% 
% Outputs:
% C - true/false all components are equal
% reps - string representations of components that are not equal
%
% Example:
% A = struct('field1',{1},'field2',{2});
% B = struct('field1',{'1'},'field2',{2});
% 
% [C, reps] = sawa_eq(A,B)
% 
% C =
% 
%      0 
%
% reps = 
% 
%     '.field1'   
%
% Note: if a non-struct or non-cell object is input, the returned rep will
% be ''.
%
% requires: sawa_getfield
% Created by Justin Theiss

% set reps
C = true;
reps = {};

% get all values
[Avals,~,Areps] = sawa_getfield(A);
if ~iscell(Avals) && isempty(Avals), Avals = {A}; Areps = {''}; end; 
[Bvals,~,Breps] = sawa_getfield(B);
if ~iscell(Bvals) && isempty(Bvals), Bvals = {B}; Breps = {''}; end;

% check for nan
r = randn(1);
[f_a,s_a] = sawa_getfield(Avals,'fun',@(x)any(isnan(x(:))));
[f_b,s_b] = sawa_getfield(Bvals,'fun',@(x)any(isnan(x(:))));
for x = 1:numel(f_a), f_a{x}(isnan(f_a{x})) = r; Avals = subsasgn(Avals,s_a{x},f_a{x}); end;
for x = 1:numel(f_b), f_b{x}(isnan(f_b{x})) = r; Bvals = subsasgn(Bvals,s_b{x},f_b{x}); end;

% check for function_handles
r = num2str(randn(1));
[f_a,s_a] = sawa_getfield(Avals,'fun',{@isa,'function_handle'});
[f_b,s_b] = sawa_getfield(Bvals,'fun',{@isa,'function_handle'});
for x = 1:numel(f_a), Avals = subsasgn(Avals,s_a{x},[func2str(f_a{x}),r]); end;
for x = 1:numel(f_b), Bvals = subsasgn(Bvals,s_b{x},[func2str(f_b{x}),r]); end;

% check for empty cells
r = randn(1);
[f_a,s_a] = sawa_getfield(Avals,'fun',@(x)isempty(x) && iscell(x));
[f_b,s_b] = sawa_getfield(Bvals,'fun',@(x)isempty(x) && iscell(x));
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
        % get reps with differences
        reps = local_unique(reps, Areps, Breps, ck);
        % update values
        [Avals,Bvals,Areps,Breps] = update_vals_reps(Avals,Bvals,Areps,Breps,reps);
        % if no Areps/Breps, return
        if isempty(Areps) || isempty(Breps), reps = unique([reps,Areps,Breps]); return; end;
    end;
end
end
        
function [Avals,Bvals,Areps,Breps] = update_vals_reps(Avals,Bvals,Areps,Breps,reps)
    % remove vals and reps
    if ~isempty(Areps),
        Avals(ismember(Areps,reps)) = [];
        Areps(ismember(Areps,reps)) = [];
    else % ensure [] for strcmp
        Areps = [];
    end;
    if ~isempty(Breps),
        Bvals(ismember(Breps,reps)) = [];
        Breps(ismember(Breps,reps)) = [];
    else % ensure [] for strcmp
        Breps = [];
    end;
end

function reps = local_unique(reps,Areps,Breps,ck)
    % get unique reps, ensuring ck is same size as Areps or Breps
    if all(size(ck) == size(Areps)), reps = unique([reps,Areps(~ck)]); end;
    if all(size(ck) == size(Breps)), reps = unique([reps,Breps(~ck)]); end;
end
    
    
