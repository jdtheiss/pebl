function filename = sawa_screencapture(hfig,filename,ext)
% filename = sawa_screencapture(hfig,filename,ext)
% This function simply screencaptures a figure using the hgexport function.
% 
% Inputs:
% hfig - (optional) figure handle to screen capture default is gcf
% filename - (optional) filepath and name to save. default is
% get(hfig,'Name')
% ext - (optional) extension type to save as (e.g. 'png') default is ext of
% filename
%
% Outputs:
% filename - fullpath filename if successful, otherwise []
%
% Example:
% uicontrol(figure,'style','text','string','this is a test','position',[100,100,100,100])
% filename = sawa_screencapture(gcf,'output','png')
% filename = 
%
% /Applications/sawa/output.png
% 
% Created by Justin Theiss

% init vars
if ~exist('hfig','var')||isempty(hfig), hfig = gcf; end;
if ~exist('filename','var')||isempty(filename), filename = get(hfig,'Name'); end;
if isempty(filename), return; end;
if ~exist('ext','var')||isempty(ext), [~,~,ext] = fileparts(filename); end;
if isempty(ext), return; end;

% if ext includes '.', remove
if strncmp(ext,'.',1), ext = ext(2:end); end;

% get filename without ext
[fpath,ffile] = fileparts(filename); 
if isempty(fpath), fpath = pwd; end;
filename = fullfile(fpath,ffile);

try % hgexport
hgexport(hfig,filename,hgexport('factorystyle'),'Format',ext);
filename = [filename '.' ext];
catch % if error, filename = []
    filename = [];
end