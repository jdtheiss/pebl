function flds = choose_fields(sa,subrun,msg)
% flds = choose_fields(sa, subrun, msg)
% Choose string represntations of fields from subject array
% 
% Inputs:
% sa - subject array (default will have user choose subject array)
% subrun - subjects to choose fields from (default is all indices of sa)
% msg - message (default is 'Choose fields:')
%
% Outputs:
% flds - cellstr of string representations of subject array field choices
% (see example)
%
% Example:
% sa = struct('age',{{10,12},{11,13},{8,10},{11,15}});
% subrun = 1:4;
% msg = 'Choose subject array field to use:';
% flds = choose_fields(sa,subrun,msg);
% [chose 'age' field]
% [chose indices '1' and '2']
% flds = 
%   'age{1}'   'age{2}'
%
% requires: sawa_subrun
%
% Created by Justin Theiss


% init vars
flds = {}; 
if ~exist('sa','var')||isempty(sa), [subrun,sa]=sawa_subrun; end;
if ~exist('subrun','var')||isempty(subrun), subrun = 1:numel(sa); end;
if ~exist('msg','var'), msg = 'Choose fields:'; end;
if ~iscell(msg), msg = {msg}; end;

% get fields
flds = fieldnames(sa);

% choose fields
chc =  listdlg('PromptString',{msg{:},''},'ListString',flds);
flds = flds(chc);

% choose subfields
for f = 1:numel(flds)

% if cell, choose cells
if all(cellfun('isclass',{sa(subrun).(flds{f})},'cell')) 
r = listdlg('PromptString',{['Choose subcells to include from '...
    flds{f} ':'],'',''},'ListString',{num2str([1:min(cellfun('size',{sa(subrun).(flds{f})},2))]')});

% if chosen
if ~isempty(r)
flds{f} = strcat(flds{f},arrayfun(@(x){['{' num2str(x) '}']},r));
end

% if struct, choose fields
elseif all(cellfun('isclass',{sa(subrun).(flds{f})},'struct'))
    % get subflds
    clear subflds subsa tmp;
    subflds = cellfun(@(x){fieldnames(x)},{sa(subrun).(flds{f})});
    subflds = unique(vertcat(subflds{:}));
    % set subsa
    subsa = struct; tmp = {sa(subrun).(flds{f})};
    for x = 1:numel(tmp), % for each subrun
        for xx = 1:numel(subflds), % for each subflds
            if isfield(tmp{x},subflds{xx}), % set 
                subsa(x).(subflds{xx}) = tmp{x}.(subflds{xx});
            else % set empty
                subsa(x).(subflds{xx}) = [];
            end
        end
    end
    % run choose_fields with subsa
    flds{f} = strcat(flds{f},'.',choose_fields(subsa,[],msg));
end
end

% output as horzcat
if any(cellfun('isclass',flds,'cell')), flds = vertcat(flds{:}); end;
