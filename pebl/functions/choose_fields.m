function flds = choose_fields(sa,subjs,msg)
% flds = choose_fields(sa, subrun, msg)
% Choose string represntations of fields from study array
% 
% Inputs:
% sa - study array (default will have user choose study array)
% subrun - subjects to choose fields from (default is all indices of sa)
% msg - message (default is 'Choose fields:')
%
% Outputs:
% flds - cellstr of string representations of study array field choices
% (see example)
%
% Example:
% sa = struct('age',{{10,12},{11,13},{8,10},{11,15}});
% subrun = 1:4;
% msg = 'Choose study array field to use:';
% flds = choose_fields(sa,subrun,msg);
% [chose 'age' field]
% [chose indices '1' and '2']
% 
% flds = 
% 
%     'age{1}'
%     'age{2}'
%
% requires: pebl_subjs
%
% Created by Justin Theiss


% init vars
flds = {}; 
if ~exist('sa','var')||isempty(sa), [subjs,sa]=pebl_subjs; end;
if ~exist('subjs','var')||isempty(subjs), subjs = 1:numel(sa); end;
if ~exist('msg','var'), msg = 'Choose fields:'; end;
if ~iscell(msg), msg = {msg}; end;

% get fields
flds = fieldnames(sa);

% choose fields
chc =  listdlg('PromptString',[msg,{''}],'ListString',flds);
flds = flds(chc);

% choose subfields
for f = 1:numel(flds)
    % if cell, choose cells
    if all(cellfun('isclass',{sa(subjs).(flds{f})},'cell')),
        r = listdlg('PromptString',{['Choose subcells from ' flds{f} ':'],'',''},...
            'ListString',{num2str([1:min(cellfun('size',{sa(subjs).(flds{f})},2))]')});
        % if chosen
        if ~isempty(r)
            flds{f} = strcat(flds{f},arrayfun(@(x){['{' num2str(x) '}']},r));
        end
    % if struct, choose fields
    elseif all(cellfun('isclass',{sa(subjs).(flds{f})},'struct'))
        % get subflds
        clear subflds subsa tmp;
        subflds = cellfun(@(x){fieldnames(x)},{sa(subjs).(flds{f})});
        subflds = unique(vertcat(subflds{:}));
        % set subsa
        subsa = struct; tmp = {sa(subjs).(flds{f})};
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
if any(cellfun('isclass',flds,'cell')), flds = [flds{:}]'; end;
