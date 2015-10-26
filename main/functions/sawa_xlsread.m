function raw = sawa_xlsread(xfil,s)
% raw = sawa_xlsread(xfil)
% This function is mainly used since xlsread does not work consistently
% with .xlsx files on mac. However, this will not slow down the ability the
% functionality on pc or with .xls files. It also simplifies the usual
% [~,~,raw] = xlsread(xfil,s).
%
% Inputs:
% xfil - filename of excel to read all data from
% s - (optional) sheet to pull all raw data from (default is 1)
%
% Outputs:
% raw - the raw cell data from excel page s
%
% Created by Justin Theiss


% init vars
raw = {};
if ~exist('s','var'), s = 1; end; 
if isempty(xfil), return; end;

% get ext
[~,~,ext]=fileparts(xfil);

% if pc or xls, easy way
if ispc||strcmp(ext,'.xls') 
[~,~,raw]=xlsread(xfil,s);
else % if not pc, hard way
for i = 1:26:10000, % search until page of 26 columns is only NaNs
[~,~,raw]=xlsread(xfil,s,[convert_to_xlrange(i) ':' convert_to_xlrange(i+26)]);
if all(cellfun(@(x)any(isnan(x)),raw)), break; end;
end % get raw from that range
[~,~,raw]=xlsread(xfil,s,['A:' convert_to_xlrange(i)]);
n = logical(arrayfun(@(x)~all(cellfun(@(y)any(isnan(y)),raw(:,x))),1:size(raw,2)));
raw = raw(:,n); % return only columns with values 
end

% convert number to xlrange or vice versa
function [rng] = convert_to_xlrange(num)
if isnumeric(num) % convert from column to char
x = 1; rng = []; 
while num > 0, 
tmp = mod(num,26^x); if tmp==0, tmp = 26^x; end;
rng = [char((tmp/26^(x-1))-1+'A') rng]; num = num - tmp; x = x + 1;
end
else % convert from char to column
num = fliplr(double(upper(num))-64);  rng = 0;
for x = 1:numel(num), rng = rng+num(x)*26^(x-1); end;
end
