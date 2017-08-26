function [output, s] = struct2gui(s, varargin)
% [output, s] = struct2gui(s, 'Name', Value, ...)
% Create a gui from fields set in a structure array.
%
% Inputs:
% s: structure with fields of uicontrols to set (i.e., uicontrol(s.(field{n})))
% optional structure fields:
% 'order' - order of location in figure [1,1] to [column, row]
%   [default is in order of fieldnames]
% 'size' - size of uicontrol [width, height]
%   [default figure size / (1.5 * number of columns/rows)]
% 'spacing' - spacing between uicontrols/edge of figure
%   [default .2 * figure size / number of columns/rows] 
% optional additional arguments:
% 'wait': boolean to implement wait block until gui is
%   closed
%   [default true]
% 'data': any value to initiate for figure guidata
%   [defualt []]
% 'done_button': boolean to include a done button in bottom right corner 
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
% top left and [2,8] (default) is bottom right. If any orders exceed [2,8]
% then the number of columns/rows will be updated.
% Additionally, a 'size' field can be set for a specific uicontrol in order 
% to only change size but not location. 
% Finally, the default callback is to set the properties of the uicontrol 
% to the guidata in a structure field corresponding to the uicontrols tag 
% (default is style_number).
%
% Example: Change 'edit' to 'test' in gui then press 'btn1'.
% s.push(1:4) = struct('order',{[1,3],[1,4],[2,3],[2,4]},'string',...
%   {'btn1','btn2','btn3','btn4'});
% s.push(1).callback = @(x,y)disp(getfield(getfield(guidata(gcf),'edit'),'String'));
% s.edit = struct('order', [1,2], 'string', 'edit');
% [output, s] = struct2gui(s)
% test
% 
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
if ~isfield(s, 'position') || isempty(s.position),
    s.position = [360, 500, 450, 300];
end

% set done button
if done_button,
    btn_pos(1:2) = s.position(3:4) .* [.85, .01];
    btn_pos(3:4) = s.position(3:4) .* [.15, .1];
    done_btn = uicontrol(f, 'style', 'pushbutton', 'string', 'done',...
                         'position', btn_pos, 'callback',...
                         'set(gcf,''visible'',''off'');');
end

% set positions
positions = local_setpositions(s);
s = local_setdefaults(s, 'position', positions);

% set tags
[~, sub_tag] = pebl_getfield(s, 'expr', '^\.[^\.]+');
tags = cellfun(@(x){regexprep(sub2str(x),'\W','')}, sub_tag);
s = local_setdefaults(s, 'tag', tags);

% set callbacks
callback = @(x,y)guidata(gcf, setfield(guidata(gcf), get(x, 'tag'), get(x)));
s = local_setdefaults(s, 'callback', {callback});

% set uicontrols
f = local_setfields(f, s, {'order','spacing','size'});

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

% reset fonts
set(0,'defaultUicontrolFontSize',defUfont); 
set(0,'defaultAxesFontSize',defAfont);
set(0,'defaultTextFontSize',defTfont); 
end

function positions = local_setpositions(s)

% get number of uicontrols
n_ctrl = sum(cellfun(@(x)isstruct(x) * numel(x), struct2cell(s)));

% get orders to determine columns/rows
tmp = pebl_getfield(s, 'expr', '.*\.order');
sz = max(cat(1, tmp{:}), [], 1);

% set rows and columns;
r = 8; c = max(2, ceil(n_ctrl / r));
if ~isempty(sz) % set to max of orders or rows/columns
    c = max(c, sz(1)); r = max(r, sz(2));
end

% set default order
default_order = num2cell(cat(2,sort(repmat([1:c]',r,1)),repmat([1:r]',c,1)), 2);

% set default spacing
default_spacing = [.2, .2] .* (s.position(3:4) ./ [c, r]);

% set default size
default_size = s.position(3:4) ./ (1.5 * [c, r]);

% set defaults
s = local_setdefaults(s, 'order', default_order);
s = local_setdefaults(s, 'spacing', {default_spacing});
s = local_setdefaults(s, 'size', {default_size});

% get orders, spacings, and sizes
orders = pebl_getfield(s, 'expr', '.*\.order');
spacings = pebl_getfield(s, 'expr', '.*\.spacing');
sizes = pebl_getfield(s, 'expr', '.*\.size');

% if not found, return empty cell
if isempty(orders) || isempty(spacings) || isempty(sizes),
    positions = {};
    return;
end

% calculate locations
positions = cellfun(@(x,y,z){[(x(1)-1) * (y(1) + z(1)), x(2) * (y(2) + z(2)), z]},...
                    orders, spacings, repmat({default_size}, size(orders)));
                
% update locations based on spacing/figure size; append sizes 
positions = cellfun(@(x,y,z){[x(1) + y(1), s.position(4) - y(2), z]},...
                    spacings, positions, sizes);
end

function s = local_setdefaults(s, field, value)

% set index counter
i = 1;
% get each struct of s
c = struct2cell(s);
% for each set value
for n = 1:numel(c),
    if isstruct(c{n}),
        for m = 1:numel(c{n}),
            if ~isfield(c{n}(m), field) || isempty(c{n}(m).(field)),
                c{n}(m).(field) = value{min(end, i)};
                i = i + 1;
            end
        end
    end
end
% set output
s = cell2struct(c, fieldnames(s));
end

function f = local_setfields(f, s, rmflds)

% remove fields and get properties
s = rmfield(s, rmflds(isfield(s, rmflds)));
props = fieldnames(s)';

% for each property, set 
for n = 1:numel(props), 
    % if struct, set figure
    if ~isstruct(s.(props{n})), 
        set(f, props{n}, s.(props{n}));
    elseif ~isempty(s.(props{n})), % uicontrol
        % remove fields
        s.(props{n}) = rmfield(s.(props{n}), rmflds(isfield(s.(props{n}), rmflds)));
        % for each component, set uicontrol
        for m = 1:numel(s.(props{n})),
            s.(props{n})(m).style = props{n}; 
            uicontrol(f, s.(props{n})(m));
        end
    end
end
end