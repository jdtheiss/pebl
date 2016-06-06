function hobj = settimeleft(varargin)
% hobj = settimeleft(varargin)
% Sets time left display
%
% Inputs:
% i - (optional) current iteration
% iterarray - (optional) numeric array of all iterations
% hobj - (optional) handle for settimeleft obj
% wmsg - (optional) message to update
%
% Outputs:
% hobj - handle for settimeleft obj
%
% Example:
% h = settimeleft; doforloop = 1:4;
% for x = doforloop
% pause(3);
% settimeleft(x, doforloop, h, 'optional text');
% end
% 
% Note: the tag for the hobj is set to SAWA_WAITBAR. Also, the waitbar
% automatically closes once the final iteration has completed (i.e. i =
% iterarray(end)).
%
% Created by Justin Theiss

hobj = {}; % set initial 
if nargin == 0 % set and tic
tic;
hobj = waitbar(0, 'Time Remaining: ');
set(hobj,'Name','Please wait...');
set(hobj,'tag','SAWA_WAITBAR');

else % update
% get vargs
i = varargin{1}; iterarray = varargin{2}; 
if nargin>2, hobj = varargin{3}; else hobj = []; end;
pl = find(ismember(iterarray,i)); % find place in iterarray

% if no hobj
if ~any(ishandle(hobj)),
    tm = timerfind('Name','SAWA_TIMER'); % stop/delete timer
    if ~isempty(tm), stop(tm); delete(tm); clear tm; end;
    hobj = waitbar(pl/numel(iterarray)); % reset
end;

% set msg
if nargin > 3 % update msg
    wmsg = varargin{4};
else % use please wait...
    wmsg = 'Please wait...';
end % set to hobj
try set(hobj,'Name',wmsg); end;

% set time left
if nargin == 5 % if using timer to set time 
t = varargin{5}; set(timerfind('Name','SAWA_TIMER'),'UserData',t-1); 
else % set time based on tic/toc
t = fix(max(toc,.25)*(length(iterarray)-pl)); % get time left
% create timer to count down seconds in between
tm = timerfind('Name','SAWA_TIMER'); % stop/delete previous timers
if ~isempty(tm), stop(tm); delete(tm); clear tm; end;
if fix(t) > 0, % only when t > 0
tm = timer('Name','SAWA_TIMER','TasksToExecute',fix(t),'ExecutionMode','fixedSpacing',...
    'UserData',t,'TimerFcn',@(x,y)settimeleft(i,iterarray,hobj,wmsg,get(x,'UserData')));
start(tm); % start timer
end
end

% convert time for display
h = fix(t/3600); m = mod(fix(t/60),60); s = mod(t,60);
if h < 10, h = ['0' num2str(h)]; end;
if m < 10, m = ['0' num2str(m)]; end;
if s < 10, s = ['0' num2str(s)]; end;
tdisp = strcat(num2str(h),':',num2str(m),':',num2str(s));
wdisp = ['Time Remaining: ' tdisp];

% waitbar
waitbar(pl/numel(iterarray), hobj, wdisp); 

% close waitbar if pl/length == 1
if pl/numel(iterarray)==1,
    if ishandle(hobj), close(hobj); end; % close waitbar
    tm = timerfind('Name','SAWA_TIMER'); % stop/delete timer
    if ~isempty(tm), stop(tm); delete(tm); clear tm; end;
elseif nargin < 5 % otherwise, tic
    tic; 
end
end
