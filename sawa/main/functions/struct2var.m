function structure = struct2var(structure,vars)
% struct2var(structure,vars)
% This function allows you to pass variable structures between functions
% easily. If only one input argument is entered, structure will be returned
% as well as variables created from the fields in structure. If two input
% arguments are entered, the structure is updated using the evaluated
% variables in vars.
%
% Inputs:
% -structure - structure array with fields that are the intended variables
% to use
% -vars - cellstr variables to add to structure (who adds current variables 
% except structure and ans) or variables from structure to add to
% workspace. place '~' in front of variables not to pass (see example).
%
% Outputs:
% -structure - structure array with fields updated from entered variables
% -variables - variables evaluated from vars assigned into the caller
% workspace
% 
% Example:
% function structure = TestFunction(inarg1,inarg2)
% structure = struct;
% structure = subfunction1(structure,1,3);
% structure = subfunction2(structure,4,6,2);
%
% function structure = subfunction1(structure,x,y)
% struct2var(structure);
% f = x + y;
% structure=struct2var(structure,who);
%
% function structure = subfunction2(structure,a,b,c)
% struct2var(structure);
% z = f*a*b; r = b/c; 
% structure=struct2var(structure,{'~a','~b','~c'});
%
% structure = 
%
%   x: 1
%   y: 3
%   f: 4
%   z: 96
%   r: 3
% 
% NOTE: To prevent inadvertent errors, it would be best practice
% to clear input variables before the second calling of struct2var.
%
% Created by Justin Theiss

% init vars
if ~exist('structure','var')||isempty(structure), structure = struct; end;
if nargin > 0, strucnam = inputname(1); else strucnam = []; end;
if isempty(strucnam), strucnam = 'structure'; end; 
if ~exist('vars','var'), vars = {}; end; if ~iscell(vars), vars = {vars}; end;
flds = fieldnames(structure)'; if isempty(flds), flds = {}; end;

% switch based on nargout
if nargout==0, 
% get vars not to set
nvars = strrep(vars(strncmp(vars,'~',1)),'~',''); 
vars = vars(~strncmp(vars,'~',1));

% if no vars, set vars to fieldnames
if isempty(vars), vars = flds; end;

% ensure vars are in fieldnames
vars = vars(ismember(vars,flds));

% remove nvars
vars = vars(~ismember(vars,nvars));

% create variables from structure
for x = 1:numel(vars), assignin('caller',vars{x},structure.(vars{x})); end;   
else
% get vars not to set
nvars = strrep(vars(strncmp(vars,'~',1)),'~','');
vars = vars(~strncmp(vars,'~',1));

% if no vars, set vars to who
if isempty(vars), vars = evalin('caller','who;'); end;

% ensure vars are in who
vars = vars(ismember(vars,evalin('caller','who;')));

% remove ans, strucnam, nvars
vars = vars(~ismember(vars,['ans',strucnam,nvars]));

% create structure from variable
for x = 1:numel(vars), structure = setfield(structure,vars{x},evalin('caller',vars{x})); end;
end
