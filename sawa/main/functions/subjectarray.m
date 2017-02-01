function [sa, subjs] = subjectarray(cmd,varargin)
% [sa, subjs] = subjectarray(cmd, varargin)
% This is the first step to using the Subject Array and Study Organizer.
%
% Inputs:
% cmd - cellstr array of subfunction(s) to run
% varargin - arguments to pass to subfunction 
% if no inputs, subjectarray will run its gui (see example)
% 
% Outputs (only returned from command prompt call):
% sa - subject array
% subjs - subject indices of sa 
%
% Example1 (no inputs):
% - Subject Array Name: Enter a name for the subject array (e.g., gonogo).
% - Subjects.mat File: This is the file that will hold the subject array.
% You may add a subject array to a previous subjects.mat file or create one.
% - Enter Subjects: Choose subjects/add subjects to subject array.
% - Subject Folders: Choose the main folders for each subject (and
% optionally create them)
% - Create New Field: Create a field for each subject in the subject array
% (e.g., age, group, gender, etc.). 
% - Load/Save Subject Array:
% -- Load Subject Array: Load a previous subjects.mat file or an excel, txt
% or mat file. (Note: excel files should have field names as headers and
% one header must be 'subj' with subject names. txt files should be the
% same with tabs between columns. mat files should contain field names as
% variables with rows corresponding to each subject.) Once loaded, subject
% arrays may be edited.
% -- Save Subject Array: Save the subject array to the chosen subjects.mat
% file. Additionally, you may save the subject array as an excel, txt, or
% mat file in the format as indicated above.
%
% Example2 (with inputs):
% [sa,subjs] = subjectarray('load_sa',struct(fileName,{'/Users/test.mat'},'flds',...
% {{'subj','subjFolders1'}},'subjs',{[2,3]}));
% sa =
% 1x4 struct array with fields:
%
%   subj
%   subjFolders
%   
% subjs = 
%   
%   2   3
%
% requires: make_gui cell2strtable choose_SubjectArray choose_fields struct2var
% printres savesubjfile sawa sawa_createvars sawa_dlmread sawa_getfield 
% sawa_setfield sawa_strjoin sawa_subjs sawa_xlsread
% 
% Created by Justin Theiss

% init vars
sa = []; subjs = [];
if ~exist('cmd','var')||isempty(cmd), cmd = []; end;
if isnumeric(cmd), cmd = {'subjectarray_gui'}; varargin = {struct}; end;
if ~iscell(cmd), cmd = {cmd}; end; 
if isempty(varargin), varargin = {struct}; end;

% run chosen cmds
for x = 1:numel(cmd), varargin{1} = feval(cmd{x},varargin{:}); end;

% ouptut sa
struct2var(varargin{1},{'sa','subjs'});

% Callback functions
function fp = subjectarray_gui(fp)
% get vars from fp
struct2var(fp);

% setup structure for make_gui
structure.name = 'subject array';
structure.edit1.string = 'subject array name'; 
structure.edit1.tag = structure.edit1.string;
[structure.push(1:5).string] = deal('subjects.mat file','enter subjects',...
    'subject folders','create new field','load/save');
[structure.push.tag] = deal(structure.push.string);
[structure.push.callback] = deal(@(x,y)guidata(gcf,fileName_Callback(guidata(gcf))),...
    @(x,y)guidata(gcf,createfield_Callback(guidata(gcf),'subj')),...
    @(x,y)guidata(gcf,subjFolders_Callback(guidata(gcf))),...
    @(x,y)guidata(gcf,createfield_Callback(guidata(gcf))),...
    @(x,y)guidata(gcf,loadsavesa_Callback(guidata(gcf))));
structure.text1.string = 'subject array fields'; structure.text1.width = 175;
structure.text1.position = 'right';
structure.listbox.position = 'right'; structure.listbox.tag = [mfilename 'listbox'];
structure.listbox.height = 165; structure.listbox.width = 175;
structure.listbox.callback = @(x,y)guidata(gcf,createfield_Callback(guidata(gcf),get(x,'value')));

% run make_gui
fp = make_gui(structure,struct('data',fp));

% get vars from fp
fp = struct2var(fp,who);
return;

function fp = fileName_Callback(fp)
% get vars from fp
struct2var(fp);

% choose subjects.mat file
disp('Choose the subjects.mat file to save to (or cancel to create)');
[lfile,lpath] = uigetfile('*.mat','Choose the subjects.mat file to save to (or cancel to create):');
if ~any(lfile), % if none, create
    disp('Choose folder to save subjects.mat file into');
    fileName = fullfile(uigetdir(pwd,'Choose folder to save subjects.mat file into:'),'subjects.mat');
else % otherwise set fileName
    fileName = fullfile(lpath,lfile);
end

% set to tooltipstring
set(findobj('tag','subjects.mat file'),'tooltipstring',fileName);

% set vars to fp
fp = struct2var(fp,who);
return;

function fp = subjFolders_Callback(fp)
% get vars from fp
struct2var(fp);

% if no sa, or no subj 
if ~exist('sa','var')||~isfield(sa,'subj')
    fp = createfield_Callback(fp,'subj');
    struct2var(fp);
end

% choose dir and use subj as folders
if strcmp(questdlg('Use subject names as subject folders?','Subject Folders'),'Yes'),
    % get subjects
    if ~exist('subjs','var'), subjs = sawa_subjs(sa); end;

    % choose maindir   
    disp('Choose directory for subject folders');
    maindir = uigetdir(pwd,'Choose directory for subject folders:');
    if ~any(maindir), return; end;

    % set subjFolders
    for i = subjs, sa(i).subjFolders{1} = fullfile(maindir,sa(i).subj); end;

    % get fields
    fields = get(findobj('tag',[mfilename 'listbox']),'string');

    % set to listbox
    set(findobj('tag',[mfilename 'listbox']),'string',unique(vertcat(fields,'subjFolders{1}')));

else % createfield_Callback
    fp = createfield_Callback(fp,'subjFolders{1}');
end

% mkdir for subjFolders
if strcmp(questdlg('Make subject folders?','Subject Folders'),'Yes'),
    for i = subjs % make subjfolders
        if ~isdir(sa(i).subjFolders{1}), mkdir(sa(i).subjFolders{1}); end;
    end
end

% set vars to fp
fp = struct2var(fp,who);
return;

function fp = createfield_Callback(fp,field)
% get vars from fp
struct2var(fp,{'sa','vals','subjs'});

% init vars
if ~exist('fields','var'), fields = get(findobj('tag',[mfilename 'listbox']),'string'); end;
if ~exist('field','var'), field = {}; end;
ecdq = 'edit'; % set initial edit/copy/delete 

% if no field, edit name
if nargin == 1||isnumeric(field), 
    if isnumeric(field)&&~isempty(fields),
        % set f to field
        f = field; 

        % get subjs, vals, and display
        subjs = {sa.subj}';
        tmpvals = sawa_getfield(sa,'expr',regexptranslate('escape',['.' fields{f}]))';
        try disp(cell2strtable([subjs,tmpvals],': ')); end; clear tmpvals;

        % copy or delete?
        ecdq = questdlg(['Edit, copy, or delete ' fields{f} '?'],'Edit/Copy/Delete','Edit','Copy','Delete','Edit');
        if isempty(ecdq), return; end;

    else % otherwise set f number of fields + 1
        f = numel(fields)+1; fields{f} = 'new field';
    end

    % edit field
    if strcmpi(ecdq,'edit'),
        fields{f} = cell2mat(inputdlg('Edit field name:','Field Name',1,fields(f)));
    end
else % get fields
    f = find(strcmp(fields,field)); % find f

    % if not found, add to fields
    if isempty(f), f = numel(fields)+1; fields{end+1} = field; end;
end

try
% if no field, return
if isempty(fields{f}), return; end;

% create sa as empty if not existing
if ~exist('sa','var'), sa = []; end; 

% if no subjs, choose
if ~exist('vals','var')
    if ~isempty(sa)
        subjs = sawa_subjs(sa);  
    else % otherwise, set subjs to empty
        subjs = []; 
    end
end

% add subjects? only if not running from command and for 'subj' field
if ~exist('vals','var')&&strcmp(fields{f},'subj') 
    if strcmp(questdlg('Add subjects?','Add Subjects','Yes','No','No'),'Yes')
        n = str2double(cell2mat(inputdlg('Enter number of subjects to add:')));
        if ~isnan(n) % add to sa
            subjs = [subjs, numel(sa)+1:numel(sa)+n]; % add to subjs
        end
    end
end

% if sa empty, set to struct
if isempty(sa), sa = struct; end;

% get sub fields
sub = regexprep(fields{f},'\.?[^\{\(\.]+(.*)','$1');

% copy/delete
if strcmpi(ecdq,'copy')
    fields{end+1} = fields{f}; f = numel(fields);
    if isempty(sub) % get number of copies
        n = sum(strncmp(fields,fields{f},numel(fields{f})));
        fields{f} = [fields{f} '_' num2str(n)];
    else % add to cell
        n = str2double(regexp(sub,'\d+','match'));
        n = n+1;
        sub = regexprep(sub,'\d+',num2str(n));
    end
elseif strcmpi(ecdq,'delete') 
    % set sub to () from {}
    sub = regexprep(sub,{'\{','\}'},{'(',')'});
    vals = []; % set vals to empty
end

% get field only
fields{f} = regexprep(fields{f},'(\.?[^\{\(\.]+).*','$1');

% remove non-word chars
fields{f} = regexprep(fields{f},'\W','_');

% create vars
if ~exist('vals','var')
    vals = sawa_createvars([fields{f},sub],'',subjs,sa);
    if isempty(vals), return; end;
end

% set vals to cell if not cell/matching subjs
if ~iscell(vals)||numel(vals)~=numel(subjs), vals = {vals}; end;

% if field subj, ensure str
if strcmpi(fields{f},'subj'), vals = cellfun(@(x){num2str(x)},vals); end;

% set field
sa = sawa_setfield(sa,'idx',subjs,'field',['.' fields{f} sub],'vals',vals);

% if all field empty, remove
if all(cellfun('isempty',sawa_getfield(sa,'expr',regexptranslate('escape',['.' fields{f}]))))
    sa = rmfield(sa,fields{f}); fields(f) = []; sub = [];
else % reset fields
    fields{f} = strcat(fields{f},sub);
end

% set to listbox
set(findobj('tag',[mfilename 'listbox']),'value',1);
set(findobj('tag',[mfilename 'listbox']),'string',unique(fields)); 

% set vars to fp
fp = struct2var(fp,{'sa','subjs'});

catch err % if error
    disp(['Error: ' err.message]);
end
return;

function fp = loadsavesa_Callback(fp)
% get vars from fp
struct2var(fp);

% load or save
if ~exist('los','var')
    los = questdlg('Load or Save Subject Array?','Load or Save','Load','Save','Save');
end % no los, return
if isempty(los), return; end;

% run load_sa or save_sa
if strcmpi(los,'load'), 
    if isfield(fp,'fileName'), fp = rmfield(fp,'fileName'); end;
    fp = load_sa(fp); % load
else % save
    fp = save_sa(struct('sa',sa,'subjs',subjs)); 
end;

% get vars from fp
struct2var(fp,{'sa','subjs','task','fileName','saveyn','savefile'});

% if no sa, return
if ~exist('sa','var')||isempty(sa), return; end;

% if no subjs, set 
subjs = {sa(subjs).subj}';

% print results
hres = printres(mfilename); 
printres(['Subject Array name: ' task],hres);
printres(['Location: ' fileName],hres);

if strcmpi(los,'load') % loaded
    printres(['Subject Array loaded from: ' fileName],hres);
elseif strcmpi(los,'save') % saved
    printres(['Subject Array ' task ' saved: ' saveyn],hres);
    printres(['Subject Array files saved: ' sawa_strjoin(savefile,'\n')],hres);
end

% print fields and subjects
printres(['Subject Array fields: ' sawa_strjoin(fieldnames(sa),'\n')],hres);
printres(['Subjects: ' sawa_strjoin(subjs,'\n')],hres);

% set vars to fp
fp = struct2var(fp,{'sa','subjs','task','fileName'});
return;

function fp = load_sa(fp)
% get vars from fp
struct2var(fp,{'fileName','task','subjs','flds'});
    
% choose fileName
if ~exist('fileName','var')
    disp('Choose file to load subject array from');
    [lfile,lpath] = uigetfile('*.xls*;*.txt;*.mat','Choose file to load subject array from:');
    if ~any(lfile), return; end; % if none chosen, return
    fileName = fullfile(lpath,lfile);  % set fileName
end

% if subjects.mat file, choose sa
if any(strfind(fileName,'subjects.mat')), 
    % choose sa
    if ~exist('task','var'),
        sa = load(filename);
        saflds = fieldnames(sa);
        chc = listdlg('PromptString','Select Task:','ListString',saflds,'SelectionMode','single');
        if isempty(chc), error('Must select a task'); end;
        task = saflds{chc};
    end
    
% get sa
sa = getfield(load(fileName), task); 
  
% get subjs
if ~exist('subjs','var'), subjs = sawa_subjs(sa); end;
subjs = {sa(subjs).subj}';

% get flds
if ~exist('flds','var'), flds = choose_fields(sa,subjs,'Choose fields to load:'); end;

% set fileName
set(findobj('tag','subjects.mat file'),'tooltipstring',fileName);

% set task
set(findobj('tag','subject array name'),'string',task);

else % otherwise, load
    % if task, get current array
    if exist('task','var'), sa = getfield(load(fileName), task); else sa = struct; end;
    presubjs = {sa.subj}';

    [~,~,ext] = fileparts(fileName); % switch based on ext
    % switch file ext
    switch ext(1:4)
    case '.xls' % excel
        raw = sawa_xlsread(fileName);
        for x = 1:numel(raw(1,:))
            vals{x} = raw(2:end,x);
        end
    case '.txt' % txt
        raw = sawa_dlmread(fileName,'\t'); 
        for x = 1:numel(raw(1,:))
            vals{x} = raw(2:end,x);
        end
    case '.mat' % mat
        raw = load(fileName); 
        if ~exist('flds','var'), flds = fieldnames(raw); end;
        for x = 1:numel(flds)
            vals{x} = raw.(flds{x});
        end 
    otherwise % other
        delim = cell2mat(inputdlg(['Enter delimiter for ' fileName]));
        raw = sawa_dlmread(fileName,delim); 
        for x = 1:numel(raw(1,:))
            vals{x} = raw(2:end,x);
        end
    end

    % if flds does not exist, set to raw(1,:)
    if ~exist('flds','var'), flds = raw(1,:); end;

    % get subjs
    subjs = vals{strcmpi(flds,'subj')};

    % set subjs to sa
    newsubs = find(~ismember(subjs,presubjs));
    newi = numel(sa)+1:numel(sa)+numel(newsubs);
    sa = sawa_setfield(sa,'idx',newi,'field','.subj','vals',subjs(newsubs)); 

    % choose subjs
    subjs = sawa_subjs(sa);

    % remove subj from vals and flds
    vals = vals(~strcmpi(flds,'subj'));
    flds = flds(~strcmpi(flds,'subj'));

    % choose fields
    fldchc = listdlg('PromptString','Choose fields to load:','ListString',flds);
    if isempty(fldchc), return; end;

    % get sub fields
    sub = regexprep(flds,'\.?[^\{\(\.]+(.*)','$1');

    % get flds
    flds = regexprep(flds,'(\.?[^\{\(\.]+).*','$1');

    % remove non-word chars
    flds = regexprep(flds,'\W','_');

    % get subject indices for subjs
    clear newi; newi = cellfun(@(x){find(strcmp(subjs,x))},{sa(subjs).subj}');
    newi = [newi{:}];

    % set fields
    for x = fldchc 
        sa = sawa_setfield(sa,'idx',subjs,'field',['.' flds{x} sub{x}],'vals',vals{x}(newi));  
    end
    sa = sa(subjs);

    % strcat flds and sub
    flds = strcat(flds,sub);

    % get original fields
    oflds = get(findobj('tag',[mfilename 'listbox']),'string');

    % set subj to flds
    flds = {'subj',flds{fldchc},oflds{:}};
end

% set fields to listbox
set(findobj('tag',[mfilename 'listbox']),'string',unique(flds));

% set vars to fp
fp = struct2var(fp,{'sa','subjs','task','fileName'});
return;

function fp = save_sa(fp)
% get vars from fp
struct2var(fp);

% init vars
if ~exist('fileName','var'), fileName = get(findobj('tag','subjects.mat file'),'tooltipstring'); end;
if ~exist('task','var'), task = get(findobj('tag','subject array name'),'string'); end;
if isempty(task)||strcmp(task,'subject array name'), task = 'sa'; end;
if ~exist('flds','var'), flds = get(findobj('tag',[mfilename 'listbox']),'string'); end;

% save subject array
if ~exist('saveyn','var')
    saveyn = questdlg(['Save Subject Array ' task '?'],'Save Subject Array?','Yes','No','Yes');
end

% set fileName, if none
if isempty(fileName), fileName = choose_SubjectArray; end;

% save subejct array
if strcmpi(saveyn,'yes'), savesubjfile(fileName,task,sa); end;

% save outputs
if ~exist('savefile','var'),
    savefile = {'Excel','Text','Mat'};
    chc = listdlg('PromptString',{'Choose file(s) to save subject array to:',''},...
        'ListString',savefile);
    savefile = savefile(chc);
% set output vars to cell if not already
elseif ~iscell(savefile)&&~isempty(savefile) 
    savefile = {savefile}; spath = {spath}; sfile = {sfile};
end

% for each output type
for x = 1:numel(savefile)
    % choose subjects to save
    subjs = sawa_subjs(sa);

    % choose fields to save
    if ~exist('flds','var')
        flds = choose_fields(sa,subjs,['Choose fields to save to ' savefile{x} ' file']);
    end
    flds = flds(~strcmpi(flds,'subj')); % not subj
    subjs = {sa(subjs).subj}'; % get subjs

    % choose file directory
    if ~exist('spath','var')||~exist('sfile','var')||x>numel(spath)||x>numel(sfile)
        disp(['Choose path to save ' savefile{x}]);
        spath{x} = uigetdir(pwd,['Choose path to save ' savefile{x}]);
        sfile{x} = cell2mat(inputdlg(['Enter name for ' savefile{x}],'File Name',1,{task}));
        if isempty(sfile{x}), sfile{x} = task; end;
    end

    % get fields
    for f = 1:numel(flds),
        vals{f} = sawa_getfield(sa(subjs),'expr',regexptranslate('escape',['.' flds{f}]))'; 
    end

    % set to raw
    raw(:,1) = vertcat('subj',subjs);
    for f = 1:numel(flds), raw(:,f+1) = vertcat(flds{f},vals{f}); end;

    % switch type of savefile
    switch lower(savefile{x})
    case 'excel' % excel
        % set file ext
        if ~any(strfind(sfile{x},'.xls')), sfile{x} = [sfile{x} '.xlsx']; end;
        if ispc, 
            xlswrite(fullfile(spath{x},sfile{x}),raw,1); % xlswrite for pc
        else % for mac, use xlwrite
            if exist('xlwrite','file') % xlwrite
                xlwrite(fullfile(spath{x},sfile{x}),raw,1);
            else % disp error
                disp(['Could not create ' fullfile(spath{x},sfile{x}) '. Requires xlwrite']);
            end; 
        end 
    case 'text' % txt
        % set file ext
        if ~any(strfind(sfile{x},'.txt')), sfile{x} = [sfile{x} '.txt']; end;
        % output
        raw = cell2strtable(raw,'\t'); raw = cellstr(raw);
        % save to txt file
        fid = fopen(fullfile(spath{x},sfile{x}),'w'); 
        fprintf(fid,'%s\r\n',raw{:});
        fclose(fid);
    case 'mat' % mat
        % set file ext
        if ~any(strfind(sfile{x},'.mat')), sfile{x} = [sfile{x} '.mat']; end;
        % evaluate flds
        subj = subjs;
        flds = regexprep(flds,'(\.?[^\{\(\.]+).*','$1'); % remove sub
        for f = 1:numel(flds), eval([flds{f} '= {sa(subjs).(flds{f})}'';']); end;
        save(fullfile(spath{x},sfile{x}),'subj',flds{:}); % save to mat
    end
end

% set vars to fp
fp = struct2var(fp,{'sa','subjs','task','fileName','savefile','saveyn'});
return;
