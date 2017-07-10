function [output, S] = struct2gui(S, varargin)
% [output, S] = struct2gui(S, 'Name', Value, ...)
% Create a gui from fields set in a structure array.
%
% Inputs:
% S: structure, fields corresponding to uicontrols to set (i.e., each field
% could be set as uicontrol(S.(field{n})))
% 'wait': (optional), true/false to implement wait block until gui is
% closed
% 'data': (optional), any value to initiate for figure guidata
%
% Outputs:
% output: guidata from figure
% S: updated structure array after setting defaults
%
% Note: Each field in S should contain a structure with fields
% corresponding to uicontrol options (.e.g, S.push(1).string = 'button1').
% In order to make setting the position easier, an 'order' field can be set
% that will correspond to the relative position of an object where [1,1] is
% top left and [2,8] is bottom right. Additionally, a 'size' field can be
% set for a specific uicontrol in order to only change size but not
% location. Finally, the default callback is to set the properties of the
% uicontrol to the guidata in a structure field corresponding to the
% uicontrols tag (default is style_number).
%
% Example: Change 'edit' to 'test' in gui then press 'btn1'.
% S.push(1:4) = struct('order',{[1,3],[1,4],[2,3],[2,4]},'string',...
%   {'btn1','btn2','btn3','btn4'});
% S.push(1).callback = @(x,y)disp(getfield(getfield(guidata(gcf),'edit'),'String'));
% S.edit = struct('order', [1,1], 'string', 'edit');
% [output, S] = struct2gui(S)
% test
% output = 
% 
%     edit: [1x1 struct]
% 
% 
% S = 
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
if ~isfield(S, 'position'),
    S.position = [360,500,450,300];
end

% set done button
btn_pos(1:2) = S.position(3:4) .* [.85, .01];
btn_pos(3:4) = S.position(3:4) .* [.15, .1];
done_btn = uicontrol(f, 'style', 'pushbutton', 'string', 'done',...
    'position', btn_pos,'callback', 'set(gcf,''visible'',''off'');');

% get fields then set uicontrols
S = local_setdefaults(S);
f = local_setfields(f, S);

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
    set(done_btn, 'callback', 'closereq');
    set(f, 'visible', 'on');
    output = [];
end
end

function S = local_setdefaults(S)
% get fields and values to be input to local_setfields

    % init position
    if ~isfield(S, 'position') || isempty(S.position),
        S.position = [360,500,450,300]; 
    end
    % get n of uicontrols and needed columns
    uictrls = sawa_getfield(S,'fun', @(x)isa(x,'struct'), 'r', 1);
    n = sum(cellfun(@(x)numel(x), uictrls));
    % set rows and columns;
    r = 8; c = max(2, ceil(n / r));
    % init spacing and size
    if ~isfield(S, 'spacing') || isempty(S.spacing),
        spacing = [.2, .2] .* (S.position(3:4) ./ [c, r]);
    else
        spacing = S.spacing;
    end
    default_size = S.position(3:4) ./ (1.5 * [c, r]);
    % create location function and default size
    loc_fun = @(x)[spacing(1) + (spacing(1) + default_size(1)) * (x(1)-1),...
        S.position(4) - (spacing(2) + default_size(2)) * x(2)];
    % get fields without position and set to 0s
    [~, sub_pos] = sawa_getfield(S, 'expr', '^\.[^\.]+', 'fun',...
        @(x)isstruct(x)&&~isfield(x,'position')||isempty(x.position));
    S = sawa_setfield(S, 'S', sub_pos, 'append', '.position', 'C', zeros(1,4)); 
    % init default order
    default_order = cat(2,sort(repmat([1:c]',r,1)),repmat([1:r]',c,1));
    % get orders
    [orders, sub_order] = sawa_getfield(S, 'expr', '.*\.order$', 'fun', @(x)~isempty(x));
    set = cellfun(@(x)find(arrayfun(@(y)all(default_order(y,:)==x),...
        1:size(default_order,1))), orders);
    default_order = arrayfun(@(x){default_order(x,:)}, 1:size(default_order,1));
    % set locations for orders
    locs = cellfun(@(x){loc_fun(x)}, default_order);
    % set position locations
    [S, sub_order] = sawa_setfield(S, 'S', sub_order, 'remove', true); 
    S = sawa_setfield(S, 'S', sub_order, 'append', '.position(1:2)', 'C', locs(set));
    locs(set) = [];  
    % set unset locations
    if ~isempty(locs), 
        [~, sub_pos] = sawa_getfield(S, 'expr', '.*\.position$', 'fun', @(x)all(x(1:2)==0));
        S = sawa_setfield(S, 'S', sub_pos, 'append', '(1:2)', 'C', locs(1:numel(sub_pos)));
    end
    % set position sizes
    [sizes, sub_size] = sawa_getfield(S, 'expr', '.*\.size$');
    [S, sub_size] = sawa_setfield(S, 'S', sub_size, 'remove', true);
    S = sawa_setfield(S, 'S', sub_size, 'append', '.position(3:4)', 'C', sizes);
    % set unset sizes
    [~, sub_size] = sawa_getfield(S, 'expr', '.*\.position$', 'fun', @(x)all(x(3:4)==0));
    S = sawa_setfield(S, 'S', sub_size, 'append', '(3:4)', 'C', default_size);
    % set tags as style_number
    [~, sub_tag] = sawa_getfield(S, 'expr', '^\.[^\.]+', 'fun',... 
        @(x)isstruct(x)&&~isfield(x,'tag')||isempty(x.tag));
    S = sawa_setfield(S, 'S', sub_tag, 'append', '.tag', 'C',...
        cellfun(@(x){regexprep(sub2str(x),'[\.\(\)\{\}]','')}, sub_tag));
    % set get(x) as callback
    callback = @(x,y)guidata(gcf, setfield(guidata(gcf), regexprep(get(x,'tag'),'\W',''), get(x)));
    [~, sub_cb] = sawa_getfield(S, 'expr', '^\.[^\.]+', 'fun',...
        @(x)isstruct(x)&&~isfield(x, 'callback')||isempty(x.callback));
    S = sawa_setfield(S, 'S', sub_cb, 'append', '.callback', 'C', callback);
end

function f = local_setfields(f, S)
% set uicontrols for f with fields, values, defaults

fields = fieldnames(S);
for n = 1:numel(fields), 
    if ~isstruct(S.(fields{n})), % main fields
        set(f, fields{n}, S.(fields{n}));
    elseif ~isempty(S.(fields{n})), % uicontrol
        for m = 1:numel(S.(fields{n})),
            S.(fields{n})(m).style = fields{n};
            uicontrol(f, S.(fields{n})(m));
        end
    end
end
end