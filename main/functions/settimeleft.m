function hobj = settimeleft(varargin)
% hobj = settimeleft(varargin)
% sets time left display
%
% Inputs:
% i - (optional) current iteration
% subrun - (optional) numeric array of all iterations
% hobj - (optional) handle for settimeleft obj
% wmsg - (optional) message to update
%
% Outputs:
% hobj - handle for settimeleft obj
%
% Example:
% h = settimeleft;
% for x = doforloop
% \\stuff\\
% settimeleft(x, doforloop, h, 'optional text');
% end
% 
% Note: the tag for the hobj is set to SAWA_WAITBAR. Also, the waitbar
% automatically closes once the final iteration has completed (i.e. i =
% subrun(end)).
% 
% requires: subidx
%
% Created by Justin Theiss


hobj = {}; % set initial
try
if nargin == 0 % set and tic
tic;
hobj = waitbar(0, 'Time Remaining: ');
set(hobj,'Name','Please wait...');
set(hobj,'tag','SAWA_WAITBAR');
else % update
i = varargin{1}; subrun = varargin{2}; 
if nargin>2&&~isempty(varargin{3})% if varargin 3, use as wb
hobj = varargin{3}; 
else % otherwise find
shh = get(0,'ShowHiddenHandles'); set(0,'ShowHiddenHandles','on');
hobj = subidx(findobj('tag','SAWA_WAITBAR'),1); set(0,'ShowHiddenHandles',shh);
end % if still no timeout found, reset
if ~any(ishandle(hobj)), hobj = settimeleft; end;
if nargin == 4 % update msg
    wmsg = varargin{4};
else % use please wait...
    wmsg = 'Please wait...';
end
set(hobj,'Name',wmsg); % create figure figure(wb); 
pl = find(ismember(subrun,i)); % find place in subrun
t = fix(max(toc,.25)*(length(subrun)-pl)); % get time left
h = fix(t/3600); m = mod(fix(t/60),60); s = mod(t,60);
if h < 10, h = ['0' num2str(h)]; end;
if m < 10, m = ['0' num2str(m)]; end;
if s < 10, s = ['0' num2str(s)]; end;
tdisp = strcat(num2str(h),':',num2str(m),':',num2str(s));
wdisp = ['Time Remaining: ' tdisp];
% waitbar
waitbar(pl/numel(subrun), hobj, wdisp);
% close waitbar if pl/length == 1
if pl/numel(subrun)==1&&ishandle(hobj), 
    close(hobj);
else % otherwise, tic
    tic;
end
end
end
