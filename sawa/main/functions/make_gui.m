function d = make_gui(structure,opt)
% data = make_gui(structure)
% This function will create a gui based on a "structure" of gui properties
% structure should be a cell array of structures corresponding to number of
% "pages" for the gui
% 
% Inputs:
% structure - each structure cell should contain the following fields:
% - "name" - the name/title of the corresponding "page"
% - "position" - position of figure (pixel units)
% - uicontrol fields - uicontrol properties (e.g., edit, pushbutton) to use with subfields
% corresponding to properties (e.g., tag, string, position, callback; see example)
% opt (optional) - struct option to be used 
% - data - structure to set to guidata for use with callbacks etc.
% - nowait - does not wait for figure to be closed (also prevents setting guidata)
% - nodone - prevents "done" button (still able to be closed)
%
% Outputs: 
% d - structure of fields set from guidata (see example)
%
% Example:
%
% INPUT:
% structure{1}.name = 'Info';
% structure{1}.edit.tag = 'age_edit';
% structure{1}.edit.string = 'Enter Age';
% % structure{1}.edit.position = [100,250,100,25];
% structure{1}.pushbutton.string = 'Calculate Birth Year';
% % structure{1}.pushbutton.position = [100,225,200,25];
% structure{1}.pushbutton.callback = {@(x,y)disp(2015-str2double(get(findobj('tag','age_edit'),'string')))};
% structure{2}.edit.string = 'Enter Name';
% structure{2}.edit(2).tag = 'food_edit';
% structure{2}.edit(2).string = 'Favorite Food';
%
% FUNCTION:
% d = make_gui(structure);
%
% OUTPUT:
% d.age_edit = '24';
% d.gui_2_edit_1 = 'Justin';
% d.food_edit = 'smores';
%
% Note: if no 'callback' is listed, the default callback creates a variable
% (name = tag or 'gui_#_type_#') which is stored in the guidata of the gcf.
%
% Note2: if no 'position' properties are included for a "page", the objects
% will be distributed starting at the top left corner
%
% Note3: if 'nodone' is used, data will be an empty structure (or equal to
% the opt.guidata)
%
% Created by Justin Theiss

% init vars 
if ~exist('structure','var')||isempty(structure), return; end;
if ~iscell(structure), structure = {structure}; end;
if ~exist('data','var'), d = struct; end;
if ~exist('opt','var'), opt = struct; end;

% get/set defaults
defUfont = get(0,'defaultUicontrolFontSize'); defAfont = get(0,'defaultAxesFontSize');
defTfont = get(0,'defaultTextFontSize'); 
set(0,'defaultUicontrolFontSize',12); set(0,'defaultAxesFontSize',12);
set(0,'defaultTextFontSize',12); 

% for each structure, initialize
for i = 1:numel(structure)
% set initial figure and name
f{i} = figure('visible','off','numbertitle','off','menubar','none','resize','off');
if isfield(structure{i},'name'), set(f{i},'name',structure{i}.name); end; % set name
end

% set properties
for i = 1:numel(f)
% set tag
set(f{i},'tag',['make_gui_' num2str(i)]);

% set position, if field
if isfield(structure{i},'position'), 
    set(f{i},'units','pixels','position',structure{i}.position); 
else % set position otherwise
    set(f{i},'units','pixels','position',[360,500,450,300]); 
end; % set figure position to structure
structure{i}.position = get(f{i},'position'); 

% create position for next/done/prev
next_pos = round([structure{i}.position(3)*.777,structure{i}.position(4)*.067,75,25]); 
prev_pos = round([structure{i}.position(3)*.111,structure{i}.position(4)*.067,75,25]); 

% if a next structure, set "next" button
if numel(structure) > i
hpage(1) = uicontrol(f{i},'style','pushbutton','string','next',...
    'position',next_pos,'Callback',{@(x,y)nextbutton_Callback(x,y,f)});
elseif ~isfield(opt,'nodone') % "done" button
hpage(3) = uicontrol(f{i},'style','pushbutton','string','done','position',next_pos,...
    'Callback',{@(x,y)donebutton_Callback(x,y,f)}); 
end

% if previous structure, set "previous" button
if i-1 > 0 && numel(structure) > i-1
hpage(2) = uicontrol(f{i},'style','pushbutton','string','previous',...
    'position',prev_pos,'Callback',{@(x,y)prevbutton_Callback(x,y,f)});
end

% set closerequestfcn to donebutton_Callback
set(f{i},'CloseRequestFcn',@(x,y)donebutton_Callback(x,y,f));

% set other properties from structure
hprop=[]; lprop=[]; rprop=[]; flds=fieldnames(structure{i}); flds(strcmpi(flds,'name'))=[];
for x0 = 1:numel(flds)
for x1 = 1:numel(structure{i}.(flds{x0}))
try 
% remove trailing digits (for more precise placement of controls)
hprop(end+1) = uicontrol(f{i},'style',regexprep(flds{x0},'\d+$','')); % create uicontrol

% if no position field or 'right'/'left', set default position
if ~isfield(structure{i}.(flds{x0}),'position')||ischar(structure{i}.(flds{x0})(x1).position)
try side_chc = structure{i}.(flds{x0})(x1).position; catch, side_chc = 'left'; end;

% if multiple left controls, get previous height
lprop(end+1) = hprop(end);
if numel(lprop)-1>0, ht_pos = get(lprop(end-1),'position'); ht_pos = ht_pos(2); else ht_pos = structure{i}.position(4)*.92; end;

% set relative position
side_pos = round([structure{i}.position(3)*.111,ht_pos-(25+structure{i}.position(4)*.0364),150,25]); % left position

% if too many or chosen, set to right side
if side_pos(2)<0||strcmp(side_chc,'right'), 
rprop(end+1)=hprop(end); lprop(end)=[]; side_pos(1) = round(structure{i}.position(3)*.5); % right left

% if multiple right controls, get previous height
if numel(rprop)-1>0, ht_pos = get(rprop(end-1),'position'); ht_pos = ht_pos(2); else ht_pos = structure{i}.position(4)*.92; end;
side_pos(2) = round(ht_pos-(25+structure{i}.position(4)*.0364)); % right bottom
end

% set position
set(hprop(end),'position',side_pos); 
end

% set width, if needed
if isfield(structure{i}.(flds{x0})(x1),'width')&&~isempty(structure{i}.(flds{x0})(x1).width) 
tmp_pos = get(hprop(end),'position'); tmp_pos(3) = structure{i}.(flds{x0})(x1).width;
set(hprop(end),'position',tmp_pos); clear tmp_pos; 
end

% set height, if needed
if isfield(structure{i}.(flds{x0})(x1),'height')&&~isempty(structure{i}.(flds{x0})(x1).height)
tmp_pos = get(hprop(end),'position'); tmp_pos(4) = structure{i}.(flds{x0})(x1).height;
tmp_pos(2) = tmp_pos(2)-tmp_pos(4)+25; % adjust for new height
set(hprop(end),'position',tmp_pos); clear tmp_pos;
end

% if no callback, set changes to guidata
if ~isfield(structure{i}.(flds{x0})(x1),'callback')||isempty(structure{i}.(flds{x0})(x1).callback)
% set fieldname based on tag/default
if isfield(structure{i}.(flds{x0})(x1),'tag'), 
    tagname = regexprep(structure{i}.(flds{x0})(x1).tag,'\W','_');
else % set default
    tagname = ['gui_' num2str(i) '_' flds{x0} '_' num2str(x1)];
end
% record string to output
if strncmp(flds{x0},'edit',4)||strncmp(flds{x0},'text',4), 
structure{i}.(flds{x0})(x1).callback = @(x,y)guidata(gcf,setfield(guidata(gcf),tagname,get(x,'string')));
else % otherwise record value to output
structure{i}.(flds{x0})(x1).callback = @(x,y)guidata(gcf,setfield(guidata(gcf),tagname,get(x,'value')));
end
end

% get subfields
subflds = fieldnames(structure{i}.(flds{x0})(x1));
for x2 = 1:numel(subflds) % set parameters based on subfields
try set(hprop(end),subflds{x2},structure{i}.(flds{x0})(x1).(subflds{x2})); end;
end % x2
end % try
end % x1
end % x0
end % i

% set guidata
if isfield(opt,'data'), guidata(f{1},opt.data); end;

% set visible
set(f{1},'visible','on');

% wait until done
if ~isfield(opt,'nowait'), 
    uiwait(f{1}); 
    % get guidata from timer
    t = timerfind('Tag','make_gui_timer');
    d = get(t,'UserData');
    stop(t); delete(t);
end;

% reset defaults
set(0,'defaultUicontrolFontSize',defUfont); set(0,'defaultAxesFontSize',defAfont);
set(0,'defaultTextFontSize',defTfont); 
    
% next, previous, and done callbacks
function nextbutton_Callback(source,eventdata,f)
% get current i
i = get(gcf,'tag'); i = str2double(regexprep(i,'make_gui_',''))+1; 
% set guidata
guidata(f{i},guidata(gcf));
% set off
set(gcf,'visible','off');
% turn next on
set(f{i},'visible','on'); 
return;

function prevbutton_Callback(source,eventdata,f)
% get current i
i = get(gcf,'tag'); i = str2double(regexprep(i,'make_gui_',''))-1; 
% set guidata
guidata(f{i},guidata(gcf));
% set off
set(gcf,'visible','off'); 
% turn previous on
set(f{i},'visible','on'); 
return;

function donebutton_Callback(source,eventdata,f)
% get guidata
d = guidata(gcf);
% create timer
t = timer('Tag','make_gui_timer','TimerFcn',@(x,y)[],'ExecutionMode','fixedSpacing',...
    'TasksToExecute',inf,'UserData',d); 
start(t);
% close f
for i = 1:numel(f), delete(f{i}); end;
return;
