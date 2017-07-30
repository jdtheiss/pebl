function [output, s] = struct2gui(s, varargin)
% [output, s] = struct2gui(s, 'Name', Value, ...)
% Create a gui from fields set in a structure array.
%
% Inputs:
% s: structure, fields corresponding to uicontrols to set (i.e., each field
% could be set as uicontrol(s.(field{n})))
% 'wait': (optional), true/false to implement wait block until gui is
%   closed
%   [default true]
% 'data': (optional), any value to initiate for figure guidata
%   [defualt []]
% 'done_button': (optional), true/false to include a done button in bottom
%   right corner 
%   [default true]
%
% Outputs:
% output: guidata from figure
% s: updated structure array after setting defaults
%
% Note: Each field in s should contain a structure with fields
% corresponding to uicontrol options (.e.g, s.push(1).string = 'button1').
% In order to make setting the position easier, an 'order' field can be set
% that will correspond to the relative position of an object where [1,1] is
% top left and [2,8] is bottom right. Additionally, a 'size' field can be
% set for a specific uicontrol in order to only change size but not
% location. Finally, the default callback is to set the properties of the
% uicontrol to the guidata in a structure field corresponding to the
% uicontrols tag (default is style_number).
%
% Example: Change 'edit' to 'test' in gui then press 'btn1'.
% s.push(1:4) = struct('order',{[1,3],[1,4],[2,3],[2,4]},'string',...
%   {'btn1','btn2','btn3','btn4'});
% s.push(1).callback = @(x,y)disp(getfield(getfield(guidata(gcf),'edit'),'String'));
% s.edit = struct('order', [1,1], 'string', 'edit');
% [output, s] = struct2gui(s)
% test
% output = 
% 
%     edit: [1x1 struct]
% 
% 
% s = 
% 
%         push: [1x4 struct]
%         edit: [1x1 struct]
%     position: [360 500 450 300]
%
% Created by Justin Theiss

% init vars
arrayfun(@(x)assignin('caller',varargin{x},varargin{x+1}),1:2:numel(varargin));
if ~exist('wait','var'), wait = true; end;
if ~exist('data','var'), data = []; end;
if ~exist('done_button','var'), done_button = true; end;

% get/set defaults
defUfont = get(0,'defaultUicontrolFontSize'); 
defAfont = get(0,'defaultAxesFontSize');
defTfont = get(0,'defaultTextFontSize'); 
set(0,'defaultUicontrolFontSize',12); 
set(0,'defaultAxesFontSize',12);
set(0,'defaultTextFontSize',12); 

% init figure as hidden
f = figure('visible','off','numbertitle','off','menubar','none',...
    'resize','off','units','pixels','tag',mfilename);

% set position field
if ~isfield(s, 'position'),
    s.position = [360,500,450,300];
end

% set done button
if done_button,
    btn_pos(1:2) = s.position(3:4) .* [.85, .01];
    btn_pos(3:4) = s.position(3:4) .* [.15, .1];
    done_btn = uicontrol(f, 'style', 'pushbutton', 'string', 'done',...
        'position', btn_pos,'callback', 'set(gcf,''visible'',''off'');');
end

% get fields then set uicontrols
s = local_setdefaults(s);
f = local_setfields(f, s);

% set data to gcf
guidata(f, data);

% wait until closed
if wait,
    set(f, 'closereq', 'set(gcf,''visible'',''off'');');
    set(f, 'visible', 'on');
    waitfor(f, 'visible', 'off');
    output = guidata(f);
    delete(f);
else % otherwise make visible
    if done_button,
        set(done_btn, 'callback', 'closereq');
    end
    set(f, 'visible', 'on');
    output = [];
end
end

function s = local_setdefaults(s)
% get fields and values to be input to local_setfields

    % init position
    if ~isfield(s, 'position') || isempty(s.position),
        s.position = [360,500,450,300]; 
    end
    % get n of uicontrols and needed columns
    uictrls = pebl_getfield(s,'fun', @(x)isa(x,'struct'), 'r', 1);
    n = sum(cellfun(@(x)numel(x), uictrls));
    % set rows and columns;
    r = 8; c = max(2, ceil(n / r));
    % init spacing and size
    if ~isfield(s, 'spacing') || isempty(s.spacing),
        spacing = [.2, .2] .* (s.position(3:4) ./ [c, r]);
    else
        spacing = s.spacing;
    end
    default_size = s.position(3:4) ./ (1.5 * [c, r]);
    % create location function and default size
    loc_fun = @(x)[spacing(1) + (spacing(1) + default_size(1)) * (x(1)-1),...
        s.position(4) - (spacing(2) + default_size(2)) * x(2)];
    % get fields without position and set to 0s
    [~, sub_pos] = pebl_getfield(s, 'expr', '^\.[^\.]+', 'fun',...
        @(x)isstruct(x)&&~isfield(x,'position')||isempty(x.position));
    s = pebl_setfield(s, 'S', sub_pos, 'append', '.position', 'C', zeros(1,4)); 
    % init default order
    default_order = cat(2,sort(repmat([1:c]',r,1)),repmat([1:r]',c,1));
    % get orders
    [orders, sub_order] = pebl_getfield(s, 'expr', '.*\.order$', 'fun', @(x)~isempty(x));
    set = cellfun(@(x)find(arrayfun(@(y)all(default_order(y,:)==x),...
        1:size(default_order,1))), orders);
    default_order = arrayfun(@(x){default_order(x,:)}, 1:size(default_order,1));
    % set locations for orders
    locs = cellfun(@(x){loc_fun(x)}, default_order);
    % set position locations
    [s, sub_order] = pebl_setfield(s, 'S', sub_order, 'remove', true); 
    set_locs = locs(set); 
    if numel(set_locs) == 1, set_locs = set_locs{1}; end;
    s = pebl_setfield(s, 'S', sub_order, 'append', '.position(1:2)', 'C', set_locs);
    locs(set) = [];  
    % set unset locations
    if ~isempty(locs), 
        [~, sub_pos] = pebl_getfield(s, 'expr', '.*\.position$', 'fun', @(x)all(x(1:2)==0));
        unset_locs = locs(1:numel(sub_pos)); 
        if numel(unset_locs) == 1, unset_locs = unset_locs{1}; end;
        s = pebl_setfield(s, 'S', sub_pos, 'append', '(1:2)', 'C', unset_locs);
    end
    % set position sizes
    [sizes, sub_size] = pebl_getfield(s, 'expr', '.*\.size$');
    [s, sub_size] = pebl_setfield(s, 'S', sub_size, 'remove', true);
    if numel(sizes) == 1, sizes = sizes{1}; end;
    s = pebl_setfield(s, 'S', sub_size, 'append', '.position(3:4)', 'C', sizes);
    % set unset sizes
    [~, sub_size] = pebl_getfield(s, 'expr', '.*\.position$', 'fun', @(x)all(x(3:4)==0));
    s = pebl_setfield(s, 'S', sub_size, 'append', '(3:4)', 'C', default_size);
    % set tags as style_number
    [~, sub_tag] = pebl_getfield(s, 'expr', '^\.[^\.]+', 'fun',... 
        @(x)isstruct(x)&&~isfield(x,'tag')||isempty(x.tag));
    tags = cellfun(@(x){regexprep(sub2str(x),'[\.\(\)\{\}]','')}, sub_tag);
    if numel(tags) == 1, tags = tags{1}; end;
    s = pebl_setfield(s, 'S', sub_tag, 'append', '.tag', 'C', tags);
    % set get(x) as callback
    callback = @(x,y)guidata(gcf, setfield(guidata(gcf), regexprep(get(x,'tag'),'\W',''), get(x)));
    [~, sub_cb] = pebl_getfield(s, 'expr', '^\.[^\.]+', 'fun',...
        @(x)isstruct(x)&&~isfield(x, 'callback')||isempty(x.callback));
    s = pebl_setfield(s, 'S', sub_cb, 'append', '.callback', 'C', callback);
end

function f = local_setfields(f, s)
% set uicontrols for f with fields, values, defaults

fields = fieldnames(s);
for n = 1:numel(fields), 
    if ~isstruct(s.(fields{n})), % main fields
        set(f, fields{n}, s.(fields{n}));
    elseif ~isempty(s.(fields{n})), % uicontrol
        for m = 1:numel(s.(fields{n})),
            s.(fields{n})(m).style = fields{n}; 
            uicontrol(f, s.(fields{n})(m));
        end
    end
end
end