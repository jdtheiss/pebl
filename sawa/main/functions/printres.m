function [hres,fres,outtxt] = printres(varargin)
% [hres,fres,outtxt] = printres(varargin)
% Create Results Figure
% 
% Inputs: 
% one argument input
% title (optional) - title to name results figure when first creating
% 
% two arguments input
% text - text as string to print to results figure 
% hres - handle of text object
% 
% three arguments input
% savepath - fullfile path to save output .txt file
% hres - handle of text object
% 'save' - indicate to save output .txt file
%
% Outputs:
% hres - handle for the text object
% fres - handle for figure
% outtxt - fullfile of saved output .txt file
%
% example:
% hres = printres('title'); % creates results figure named 'title'
% printres('New text', hres); % prints 'New text' to figure
%
% note: this function uses findjobj as well as jScrollPane, but will work
% without
%
% requires: choose_SubjectArray findjobj
%
% Created by Justin Theiss

try
% init outputs
hres = []; fres = []; outtxt = [];

% switch based on number of args
switch nargin
case {0,1} % create figure
% get mfil for saving
try mfil = varargin{1}; catch, mfil = 'Results'; end;

% create figure
fres = figure('Visible','off','Position',[360,500,500,700],...
    'NumberTitle','off','Menubar','none','SelectionType','normal');

% set results
hres = uicontrol('Style','edit','String',[mfil ':'],...
         'Position',[25,50,450,650],'Max',1000,'FontSize',12,...
         'HorizontalAlignment','Left','FontName','Courier New'); 
hsavebutton = uicontrol('Style','pushbutton','String','Save',...
         'Position',[25,25,50,25],'HorizontalAlignment','Center',...
         'Callback',@(x,y)savebutton_Callback(x,y,hres));

% Change units to normalized so components resize automatically.
set([fres,hres,hsavebutton],'Units','normalized');

% Assign name, move gui, and visible
set(fres,'Name',mfil); movegui(fres,'center'); set(fres,'Visible','on');
set(hres,'Tag',mfil); % set tag to mfil for later use

% set SizeChangedFcn and ButtonDownFcn to recreate scrollbar
set(fres,'SizeChangedFcn',{@(x,y)local_jscroll(hres,[])});

case 2 % printing
% Refresh results
prints = varargin{1};

% normal, hres is second varargin
if ishandle(varargin{2}) 
hres = varargin{2};
str = get(hres, 'String'); prints = char(str,prints);

elseif ~isempty(hres) % abnormal, recreating
[hres,fres] = printres(get(hres,'Tag'));

else % otherwise display
disp(prints); return; 
end

% set to string
prints = cellstr(prints);
set(hres, 'String', sprintf('%s\n',prints{:}));

case 3 % savepath, hres, 'save'
savepath = varargin{1}; % file location to save to
hres = varargin{2}; % hres 

% run save callback
if strcmpi(varargin{3},'save'), outtxt = savebutton_Callback([],[],hres,savepath); end;
end

% run local_jscroll
local_jscroll(hres,[]);
end
    
% callback functions
function outtxt = savebutton_Callback(source, eventdata, hres, savepath)
% get string and tag
prints = get(hres,'String'); mfil = get(hres,'Tag');

% edit filename/set filpath to empty
mfil = cell2mat(inputdlg('Enter filename to save:','Filename',1,{mfil}));
if isempty(mfil), return; end;
[~,mfil] = fileparts(mfil);
filpath = [];

% if pressed "save"
if ~exist('savepath','var')
% get fileName
fileName = choose_SubjectArray; 

% if fileName, choose task to save to
if ~isempty(fileName), 
    try [~, task] = choose_SubjectArray(fileName); catch, return; end;
    if ~isempty(task),
        % set filpath
        filpath = fileparts(fileName); 
        filpath = fullfile(filpath, 'Notes');
    end
end

% if no filpath, set using uigetdir
if isempty(filpath)
msg = ['Choose directory to save ' mfil '.txt:']; disp(msg);
filpath = uigetdir(pwd,msg); 
if ~any(filpath), return; end;
task = [];
end

% set savepath
savepath = fullfile(filpath,task,date);
end

% if no dir, mkdir
if ~isdir(savepath), mkdir(savepath); end;

% set prints to cellstr
prints = cellstr(prints); 

% print to txt file
clear ff; ff = dir(fullfile(savepath,[mfil '*']));
if ~isempty(ff), mfil = [mfil '_' num2str(length(ff)+1)]; end;
% write to file
fid = fopen(fullfile(savepath,[mfil '.txt']), 'w');
fprintf(fid, '%s\r\n', prints{:});
fclose(fid); 

% outtxt
outtxt = fullfile(savepath,[mfil '.txt']);

% run local_jscroll
local_jscroll(hres,[]);
return;

function local_jscroll(source,eventdata)
% if no findjobj, return
if ~exist('findjobj','file'), return; end;

% set horizontal scrollbar
try jScrollPane = findjobj(source); catch; return; end;  
jScrollPane = jScrollPane(1);
jViewPort = jScrollPane.getViewport;
jEditbox = jViewPort.getComponent(0); jEditbox.setWrapping(false);
jScrollPane.setHorizontalScrollBarPolicy(30);

% set scrollbar to left
jScrollPane.getHorizontalScrollBar.setValue(0);
clear jScrollPane jViewPort jEditbox;
return;
