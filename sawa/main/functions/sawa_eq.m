function C =  sawa_eq(A,B)
% C = sawa_eq(A,B)
% Checks if all components of A and B are equal.
%
% Inputs:
% A - first element
% B - element to compare with A
% 
% Outputs:
% C - true/false all components are equal
%
% Example:
% A = struct('field1',{1},'field2',{2});
% B = struct('field1',{'1'},'field2',{'2'});
% 
% C = sawa_eq(A,B)
% 
% C =
% 
%      0 
%
% requires: sawa_getfield
% Created by Justin Theiss

% first test eq
try C = all(eq(A(:),B(:))); return; catch, C = false; end;

% get all values
[Avals,~,Areps] = sawa_getfield(A,'rep','');
[Bvals,~,Breps] = sawa_getfield(B,'rep','');

% check for same number of values
if numel(Avals)~=numel(Bvals), return; end;

% check for same reps
if ~all(strcmp(Areps,Breps)), return; end;

% get classes
Aclass = cellfun(@(x){class(x)}, Avals);
Bclass = cellfun(@(x){class(x)}, Bvals);

% check for same classes
if ~all(strcmp(Aclass,Bclass)), return; end;

% check for all same size
if ~all(cellfun(@(x,y)numel(size(x))==numel(size(y))&&all(size(x)==size(y)),Avals,Bvals)),
    return;
end

% return for all eq Avals, Bvals 
C = all(cellfun(@(x,y)all(eq(x(:),y(:))),Avals,Bvals));

