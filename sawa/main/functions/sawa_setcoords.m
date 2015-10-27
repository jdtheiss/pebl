function k = sawa_setcoords(hfig,coords)
% k = sawa_setspmcoords(hfig,coords)
% This function will change the coordinates for the spm based axes in
% figure hfig using coordinates coords.
%
% Inputs:
% hfig - (optional) figure with spm axes. default is gcf
% coords - (optional) coordinates to change to. default is global max
%
% Outputs:
% k - 0/1 for failure/success
% Example:
% 

% init vars
k = 0;
if ~exist('hfig','var')||isempty(hfig), hfig = gcf; end;
if ~exist('coords','var')||isempty(coords), coords = []; end;

% find hMIPax
h = findobj(hfig,'-regexp','Tag','hMIPax'); 

% set callback
if isempty(coords) % global max
try spm_mip_ui('Jump',h,'glmax'); k = 1; end;
else % set to coordinates
try spm_mip_ui('SetCoords',coords); k = 1; end;
try spm_orthviews('SetCoords',coords); k = 1; end;
end