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
C = false;
reps = {};

% first test eq
if nargout==1, try C = all(eq(A(:),B(:))); return; end; end;

% get all values
[Avals,~,Areps] = sawa_getfield(A,'rep','');
if ~iscell(Avals) && isempty(Avals), Avals = {A}; Areps = {''}; end;
[Bvals,~,Breps] = sawa_getfield(B,'rep','');
if ~iscell(Bvals) && isempty(Bvals), Bvals = {B}; Breps = {''}; end;

% check for same number of values
if nargout==1,
    if numel(Avals)~=numel(Bvals), return; end;
elseif numel(Avals) > numel(Bvals),
    reps = [reps,Areps(~ismember(Areps,Breps))];
elseif numel(Bvals) > numel(Avals),
    reps = [reps,Breps(~ismember(Breps,Areps))];
end
reps = unique(reps);

% remove reps
[Avals,Bvals,Areps,Breps] = update_vals_reps(Avals,Bvals,Areps,Breps,reps,nargout);

% check for same reps
C = strcmp(Areps,Breps);
if nargout==1 && ~all(C),
    C = false; return;
else
    reps = unique([reps,Areps(~C),Breps(~C)]);
end;
    
% get classes
Aclass = cellfun(@(x){class(x)}, Avals);
Bclass = cellfun(@(x){class(x)}, Bvals);

% check for same classes
C = strcmp(Aclass,Bclass);
if nargout==1 && ~all(C), 
    C = false; return;
else
    reps = unique([reps,Areps(~C),Breps(~C)]);
end

% remove reps
[Avals,Bvals,Areps,Breps] = update_vals_reps(Avals,Bvals,Areps,Breps,reps,nargout);

% check for all same size
C = cellfun(@(x,y)numel(size(x))==numel(size(y))&&all(size(x)==size(y)),Avals,Bvals);
if nargout==1 && ~all(C),
    C = false; return;
else
    reps = unique([reps,Areps(~C),Breps(~C)]);
end

% remove reps
[Avals,Bvals,Areps,Breps] = update_vals_reps(Avals,Bvals,Areps,Breps,reps,nargout);

% return for all eq Avals, Bvals 
C = cellfun(@(x,y)all(eq(x(:),y(:))),Avals,Bvals);
if nargout==1, 
    C = all(C);
else % retun reps
    reps = unique([reps,Areps(~C),Breps(~C)]);
    C = isempty(reps);
end

function [Avals,Bvals,Areps,Breps] = update_vals_reps(Avals,Bvals,Areps,Breps,reps,n)
% if only returning C, return
if n==1, return; end;
% remove vals and reps
Avals(ismember(Areps,reps)) = [];
Bvals(ismember(Breps,reps)) = [];
Areps(ismember(Areps,reps)) = [];
Breps(ismember(Breps,reps)) = [];
return;


