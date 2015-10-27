function closedlg(figprops,btnprops,timeropts)
% closedlgs(figprops,btnprops)
% This function will set a timer object to wait until a certain
% dialog/message/object is found using findobj and will then perform a
% callback function based on button chosen.
% 
% Inputs: 
% -figprops -(optional) object properties that would be used with findobj
% (e.g., a cellstr like {'-regexp','name','SPM.*'}), a string to be
% evaluated (e.g., 'findobj'), or a figure handle. Default is 'findobj' 
% -btnprops -(optional) button properties that would be used with findobj,
% an index of button (for questdlg) to be pressed, or the button handle. 
% Default is 0 which gets the CloseRequestFcn.
% -timeropts -(optional) timer options to set (see timer help doc) in a
% cellstr (e.g., {'TasksToExecute',Inf,'Period',0.001})
%
% Example:
% closedlg('findobj',{'string','stop'});
% cfg_util('runserial',matlabbatch);
% 
% The above example would create a timer that would press the stop button
% if a dialog box such as SPM's overwrite warning were to appear. 
%
% NOTE: The default taskstoexecute is 10000 (which is approx 10000 seconds)
% and the default stopfcn is @(x,y)stop_timer(x) which will delete the
% timer after the taskstoexecute.
%
% Created by Justin Theiss

% init vars
if ~exist('figprops','var')||isempty(figprops), figprops = 'findobj'; end;
if ~exist('btnprops','var')||isempty(btnprops), btnprops = 0; end;
if ~exist('timeropts','var'), timeropts = []; end;
% create timer to close_fig after wait_fig
t = timer('tag',mfilename); set(t,'ExecutionMode','fixedSpacing');
set(t,'TimerFcn',@(x,y)wait_fig(x,figprops,btnprops));
set(t,'TasksToExecute',10000); % set to 10000 (seconds)
set(t,'StopFcn',@(x,y)stop_timer(x)); % set stopfcn to delete timer
if ~isempty(timeropts), set(t,timeropts{:}); end; % set timer opts
try start(t); end;

% wait_fig
function wait_fig(t,figprops,btnprops)
% get h and hh
[h,hh] = find_fig(figprops,btnprops); 
% if found, seek and destroy next
if ~isempty(h)&&~isempty(hh), 
% close figure
close_fig(figprops,btnprops);  
% stop timer
stop_timer(t);
end
return;

% find figure and button
function [h,hh]=find_fig(figprops,btnprops)
% set showhiddenhandles on
shh = get(0,'ShowHiddenHandles'); set(0,'ShowHiddenHandles','on');
% init h and hh
h = []; hh = [];
% find figure (or set to findobj)
if ischar(figprops) % eval then get figures
    h = eval(figprops); h = h(strcmp(get(h,'type'),'figure'));
else % find obj then figure
    if iscell(figprops), h = findobj(figprops{:}); else h = findobj(figprops); end
    if ~isempty(h)
    h = h(1);
    while ~strcmp(get(h,'type'),'figure')
    h = get(h,'Parent'); if h==0, break; end;    
    end
    end
end
% get button object
if isnumeric(btnprops) % find using index
switch btnprops
    case 1
        hh = findobj(h,'tag','Btn1');    
    case 2
        hh = findobj(h,'tag','Btn2');    
    case 3
        hh = findobj(h,'tag','Btn3');
    otherwise 
        hh = get(h,'CloseRequestFcn'); 
end
elseif iscell(btnprops)||any(ishandle(btnprops)) % find using prop, val
   if iscell(btnprops), hh = findobj(h,btnprops{:}); else hh = findobj(h,btnprops); end;
end 
if ~isempty(hh)&&any(ishandle(hh)), hh = hh(1); end;
% if found hh, get associated h
if any(ishandle(hh)),
h = get(hh,'Parent');
while ~strcmp(get(h,'type'),'figure')
h = get(h,'Parent'); 
if h == 0, h = []; break; end; % root
end
end; 
set(0,'ShowHiddenHandles',shh);
return;

% close figure
function close_fig(figprops,btnprops)
% get h and hh
[h,hh] = find_fig(figprops,btnprops); 
% if hh is a closereq function, call and return
if isa(hh,'function_handle'), 
    hh(h,[]); return;
elseif ischar(hh), 
    eval(hh); return; 
end;
% set current object to btn
set(h,'CurrentObject',hh);
% get callbackBtn and callback
callbackBtn = get(hh,'Callback');
if ischar(callbackBtn)
    callbackBtn = strrep(callbackBtn,'gcbf','h'); 
    eval(callbackBtn);
else
    callbackBtn(hh,[]);
end
return;

% stop timer
function stop_timer(t)
if ~isa(t,'timer'), return; end; % if not timer, return
if strcmp(get(t,'Running'),'on'), stop(t); end; % if running, stop
delete(t); % delete
return;
