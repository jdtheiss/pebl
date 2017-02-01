function figurefun(func, A, varargin)
% figurefun(FUN, A, 'param1', val1, ...)
% Simulate user interactions with figures such as inputdlg, msgbox, etc. by
% evaluating FUN for graphic objects found with A.
%
% Inputs:
% FUN - cell array of functions to call (default is empty, callback of props object)
% A - cell array of type, value pairs in order to find figure and 
% object (such as a button) as used with findobj. Alternatively, A can be a
% string (default is 'gcf').
% options - timer options to be used as pairs of parameter name and value
% (defualts are 'tag', mfilename, 'ExecutionMode', 'fixedSpacing', 
% 'TimerFcn', @(x,y)wait_fig(x, A, FUN), 'TasksToExecute', 10000). 
% see timer for more information
%
% Outputs:
% None
%
% Example 1: set inputdlg text to "test" and simulate OK press
% figurefun(@(x,y)set(y,'string','test'),{'string',''});
% figurefun('set(h,''UserData'',''OK''); uiresume(h);',{'string','OK'});
% txt = inputdlg
% 
% txt = 
% 
%     'test'
%     
% Example 2: take control of a questdlg to rename title, question, button, 
% and answer returned when button is pressed
% figurefun(@(x,y)set(x,'name','Title'),{'type','figure'});
%   figurefun({@(x,y)set(y,'string','Button'),@(x,y)setappdata(y,'QuestDlgReturnName','Answer')},...
% {'style','pushbutton','string','bla'});
%   figurefun(@(x,y)set(y,'string','Text'),{'string','bla'});
%   txt = questdlg('bla','bla','bla','bla')
% 
% txt =
% 
% Answer
%
% Example 3: Close inputdlg (using gcf) after 3 second delay
% figurefun('uiresume(h);', 'gcf', 'StartDelay', 3);
% txt = inputdlg
% 
% txt = 
% 
%      {}
%      
% Note: If FUN is a function handle, the inputs should be the figure and
% object returned from props (i.e., @(x,y) x is figure and y is object). 
% If FUN is a string, h or hh can be included to be evaluated. Also, if a
% figure requires more time before the function should be evaluated, set
% 'StartDelay' to some number greater than 0.
%
% Created by Justin Theiss

% init vars
if ~exist('func','var')||isempty(func), func = []; end;
if ~exist('A','var')||isempty(A), A = 'gcf'; end;
if ~isempty(func)&&~iscell(func), func = {func}; end;

% setup timer
t = timer('tag',mfilename); 
set(t,'ExecutionMode','fixedSpacing');
set(t,'TimerFcn',@(x,y)wait_fig(x, A, func));
set(t,'TasksToExecute',10000);
if ~isempty(varargin), set(t,varargin{:}); end;
start(t);

% wait function
function wait_fig(t, props, func)
    % get h and hh
    [h, hh] = find_fig(props);
    % h and hh are found
    if ~isempty(h) && ~isempty(hh),
        % evaluate function
        try 
            eval_fig(h, hh, func);
        catch err
            disp(err.message);
        end;
        % stop timer
        stop_timer(t);
    end
end

function [h, hh] = find_fig(props)
    % set showhiddenhandles on
    shh = get(0,'ShowHiddenHandles'); 
    set(0,'ShowHiddenHandles','on');
    % init h and hh
    h = []; hh = [];
    if ischar(props), % evaluate eg 'gcf'
        hh = eval(props); 
        h = hh(strcmp(get(hh,'type'),'figure'));
    else % use findobj
        if ~iscell(props), props = {props}; end;
        hh = findobj(props{:});
        if ~isempty(hh), % get parent of hh
            h = hh(1);
            while ~strcmp(get(h,'type'),'figure'),
                h = get(h,'Parent');
                if h==0, break; end;
            end
        end
    end
    % reset showhiddenhandles
    set(0,'ShowHiddenHandles',shh);
end

function eval_fig(h, hh, func)
    % for each function
    for x = 1:numel(func),
        % if no function, get callback
        if isempty(func{x}),
            % if function handle, evaluate
            if isa(hh,'function_handle'),
                hh(h,[]); 
            elseif ischar(hh),
                eval(hh); 
            end
            % get callback function
            callbackBtn = get(hh,'Callback');
            if ischar(callbackBtn), % set gcbf to h
                callbackBtn = strrep(callbackBtn,'gcbf','h');
                eval(callbackBtn);
            elseif iscell(callbackBtn), % evaluate cell callback
                callbackBtn{1}(hh,[],callbackBtn{2:end});
            else % evaluate callback function
                callbackBtn(hh,[]);
            end
        elseif isa(func{x},'function_handle'), 
            % evaluate function with h
            feval(func{x}, h, hh);
        else % evaluate function
            eval(func{x});
        end
    end
end

function stop_timer(t)
    % if not a timer, return
    if ~isa(t,'timer'), return; end;
    % if running, stop
    if strcmp(get(t,'Running'),'on'), stop(t); end;
    % delete timer
    delete(t);
end
end