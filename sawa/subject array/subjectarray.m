function [sa, subrun] = subjectarray(cmd,varargin)
% [sa, subrun] = subjectarray(cmd, varargin)
% This is the first step to using the Subject Array and Study Organizer.
%
% Inputs:
% cmd - cellstr array of subfunction(s) to run
% varargin - arguments to pass to subfunction 
% if no inputs, subjectarray will run its gui (see example)
% 
% Outputs (only returned from command prompt call):
% sa - subject array
% subrun - subject indices of sa 
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
% [sa,subrun] = subjectarray('load_sa',struct(fileName,{'/Users/test.mat'},'flds',...
% {{'subj','subjFolders1'}},'subrun',{[2,3]}));
% sa =
% 1x4 struct array with fields:
%
%   subj
%   subjFolders
%   
% subrun = 
%   
%   2   3
%
% requires: make_gui cell2strtable choose_SubjectArray choose_fields funpass
% printres savesubjfile sawa sawa_createvars sawa_dlmread sawa_getfield 
% sawa_setfield sawa_strjoin sawa_subrun sawa_xlsread update_array
% 
% Created by Justin Theiss


%NoSetVars
%NoSetSubrun

% init vars
sa = []; subrun = [];
if ~exist('cmd','var')||isempty(cmd), cmd = []; end;
if isnumeric(cmd), cmd = {'subjectarray_gui'}; varargin = {struct}; end;
if ~iscell(cmd), cmd = {cmd}; end; 
if isempty(varargin), varargin = {struct}; end;

% run chosen cmds
for x = 1:numel(cmd), varargin{1} = feval(cmd{x},varargin{:}); end;

% ouptut sa
funpass(varargin{1},{'sa','subrun'});

% Callback functions
function fp = subjectarray_gui(fp)
% get vars from fp
funpass(fp);

% setup structure for make_gui
structure.name = 'Subject Array';
structure.edit1.string = 'Subject Array Name'; 
structure.edit1.tag = structure.edit1.string;
[structure.push(1:5).string] = deal('Subjects.mat File','Enter Subjects',...
    'Subject Folders','Create New Field','Load/Save');
[structure.push.tag] = deal(structure.push.string);
[structure.push.callback] = deal(@(x,y)guidata(gcf,fileName_Callback(guidata(gcf))),...
    @(x,y)guidata(gcf,createfield_Callback(guidata(gcf),'subj')),...
    @(x,y)guidata(gcf,subjFolders_Callback(guidata(gcf))),...
    @(x,y)guidata(gcf,createfield_Callback(guidata(gcf))),...
    @(x,y)guidata(gcf,loadsavesa_Callback(guidata(gcf))));
structure.text1.string = 'Subject Array Fields'; structure.text1.width = 175;
structure.text1.position = 'right';
structure.listbox.position = 'right'; structure.listbox.tag = [mfilename 'listbox'];
structure.listbox.height = 165; structure.listbox.width = 175;
structure.listbox.callback = @(x,y)guidata(gcf,createfield_Callback(guidata(gcf),get(x,'value')));

% run make_gui
fp = make_gui(structure,struct('data',fp));

% get vars from fp
fp = funpass(fp,who);
return;

function fp = fileName_Callback(fp)
% get vars from fp
funpass(fp);

% choose subjects.mat file
[lfile,lpath] = uigetfile('*.mat','Choose the subjects.mat file to save to (or cancel to create):');
if ~any(lfile), % if none, create
    fileName = fullfile(uigetdir(pwd,'Choose folder to save subjects.mat file into:'),'subjects.mat');
else % otherwise set fileName
    fileName = fullfile(lpath,lfile);
end

% set to tooltipstring
set(findobj('tag','Subjects.mat File'),'tooltipstring',fileName);

% set vars to fp
fp = funpass(fp,who);
return;

function fp = subjFolders_Callback(fp)
% get vars from fp
funpass(fp);

% if no sa, or no subj 
if ~exist('sa','var')||~isfield(sa,'subj')
fp = createfield_Callback(fp,'subj');
funpass(fp);
end

% choose dir and use subj as folders
if strcmp(questdlg('Choose directory and use subject names as subject folders?','Subject Folders','Yes','No','Yes'),'Yes')

% get subjects
if ~exist('subrun','var'), subrun = sawa_subrun(sa); end;
    
% choose maindir    
maindir = uigetdir(pwd,'Choose directory for subject folders:');
if ~any(maindir), return; end;

% set subjFolders
for i = subrun, sa(i).subjFolders{1} = fullfile(maindir,sa(i).subj); end;

% get fields
fields = get(findobj('tag',[mfilename 'listbox']),'string');

% set to listbox
set(findobj('tag',[mfilename 'listbox']),'string',vertcat(fields,'subjFolders{1}'));

else % createfield_Callback
fp = createfield_Callback(fp,'subjFolders{1}');
end

% mkdir for subjFolders
if strcmp(questdlg('Make subject folders?','Subject Folders','Yes','No','No'),'Yes')
for i = subrun % make subjfolders
    if ~isdir(sa(i).subjFolders{1}), mkdir(sa(i).subjFolders{1}); end;
end
end

% set vars to fp
fp = funpass(fp,who);
return;

function fp = createfield_Callback(fp,field)
% get vars from fp
funpass(fp,{'sa','vals','subrun'});

% init vars
if ~exist('fields','var'), fields = get(findobj('tag',[mfilename 'listbox']),'string'); end;
if ~exist('field','var'), field = {}; end;
ecdq = 'edit'; % set initial edit/copy/delete 

% if no field, edit name
if nargin == 1||isnumeric(field), 
if isnumeric(field)&&~isempty(fields)
% set f to field
f = field; 

% get subjs, vals, and display
subjs = sawa_getfield(sa,'','subj$')';
vals = sawa_getfield(sa,'',[regexptranslate('escape',fields{f}) '$'])';
try disp(cell2strtable([subjs,vals],': ')); end;

% copy or delete?
ecdq = questdlg(['Edit, copy, or delete ' fields{f} '?'],'Edit/Copy/Delete','Edit','Copy','Delete','Edit');
if isempty(ecdq), return; end;

else % otherwise set f number of fields + 1
f = numel(fields)+1; fields{f} = 'new field';
end

% edit field
if strcmpi(ecdq,'edit')
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

% if no subrun, choose
if ~exist('vals','var')
if ~isempty(sa)
subrun = sawa_subrun(sa);  
else % otherwise, set subrun to empty
subrun = []; 
end
end

% add subjects? only if not running from command and for 'subj' field
if ~exist('vals','var')&&strcmp(fields{f},'subj') 
if strcmp(questdlg('Add subjects?','Add Subjects','Yes','No','No'),'Yes')
n = str2double(cell2mat(inputdlg('Enter number of subjects to add:')));
if ~isnan(n) % add to sa
subrun = [subrun, numel(sa)+1:numel(sa)+n]; % add to subrun
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
vals = sawa_createvars([fields{f},sub],'',subrun,sa);
if isempty(vals), return; end;
end

% set vals to cell if not cell/matching subrun
if ~iscell(vals)||numel(vals)~=numel(subrun), vals = {vals}; end;

% if field subj, ensure str
if strcmpi(fields{f},'subj'), vals = cellfun(@(x){num2str(x)},vals); end;

% set field
sa(subrun) = sawa_setfield(sa,subrun,fields{f},sub,vals{:});

% if all field empty, remove
if all(cellfun('isempty',sawa_getfield(sa,'',regexptranslate('escape',fields{f}))))
sa = rmfield(sa,fields{f}); fields(f) = []; sub = [];
else % reset fields
fields{f} = strcat(fields{f},sub);
end

% set to listbox
set(findobj('tag',[mfilename 'listbox']),'value',1);
set(findobj('tag',[mfilename 'listbox']),'string',fields); 

% set vars to fp
fp = funpass(fp,{'sa','subrun'});

catch err % if error
    disp(['Error: ' err.message]);
end
return;

function fp = loadsavesa_Callback(fp)
% get vars from fp
funpass(fp);

% load or save
if ~exist('los','var')
los = questdlg('Load or Save Subject Array?','Load or Save','Load','Save','Save');
end % no los, return
if isempty(los), return; end;

% run load_sa or save_sa
if strcmpi(los,'load'), 
    fp = load_sa([]); % load
else % save
    fp = save_sa(struct('sa',sa,'subrun',subrun)); 
end;

% get vars from fp
funpass(fp,{'sa','subrun','task','fileName','saveyn','savefile'});

% if no sa, return
if ~exist('sa','var')||isempty(sa), return; end;

% if no subjs, set 
subjs = sawa_getfield(sa(subrun),'','subj$');

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
fp = funpass(fp,{'sa','subrun','task','fileName'});
return;

function fp = load_sa(fp)
% get vars from fp
funpass(fp,{'fileName','task','subrun','flds'});
    
% choose fileName
if ~exist('fileName','var')
[lfile,lpath] = uigetfile('*.xls*;*.txt;*.mat','Choose file to load subject array from:');
if ~any(lfile), return; end; % if none chosen, return
fileName = fullfile(lpath,lfile);  % set fileName
end

% if subjects.mat file, choose sa
if any(strfind(fileName,'subjects.mat')), 
% choose sa
if ~exist('task','var')
[sa,task] = choose_SubjectArray(fileName);
else % get sa
sa = update_array(task);    
end

% get subjs
if ~exist('subrun','var'), subrun = sawa_subrun(sa); end;
subjs = sawa_getfield(sa(subrun),'','subj$');

% get flds
if ~exist('flds','var'), flds = choose_fields(sa,subrun,'Choose fields to load:'); end;

% set fileName
set(findobj('tag','Subjects.mat File'),'tooltipstring',fileName);

% set task
set(findobj('tag','Subject Array Name'),'string',task);

else % otherwise, load
[~,task,ext] = fileparts(fileName); % switch based on ext

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
sa(1:numel(subjs)) = struct;
sa = sawa_setfield(sa,1:numel(subjs),'subj',[],subjs{:}); % set subj

% choose subrun
if ~exist('subrun','var'), subrun = sawa_subrun(sa); end;

% remove subj from vals and flds
vals = vals(~strcmpi(flds,'subj'));
flds = flds(~strcmpi(flds,'subj'));

% get sub fields
sub = regexprep(flds,'\.?[^\{\(\.]+(.*)','$1');

% get flds
flds = regexprep(flds,'(\.?[^\{\(\.]+).*','$1');

% remove non-word chars
flds = regexprep(flds,'\W','_');

% set fields
for x = 1:numel(vals) 
sa = sawa_setfield(sa,1:numel(vals{x}),flds{x},sub{x},vals{x}{:});  
end

% strcat flds and sub
flds = strcat(flds,sub);

% set subj to flds
flds = {'subj',flds{:}};
end

% set fields to listbox
set(findobj('tag',[mfilename 'listbox']),'string',flds);

% set vars to fp
fp = funpass(fp,{'sa','subrun','task','fileName'});
return;

function fp = save_sa(fp)
% get vars from fp
funpass(fp);

% init vars
if ~exist('fileName','var'), fileName = get(findobj('tag','Subjects.mat File'),'tooltipstring'); end;
if ~exist('task','var'), task = get(findobj('tag','Subject Array Name'),'string'); end;
if isempty(task)||strcmp(task,'Subject Array Name'), task = 'sa'; end;
if ~exist('flds','var'), flds = get(findobj('tag',[mfilename 'listbox']),'string'); end;

% save subject array
if ~exist('saveyn','var')
saveyn = questdlg(['Save Subject Array ' task '?'],'Save Subject Array?','Yes','No','Yes');
end

% set subrun if none
if ~exist('subrun','var'), subrun = 1:numel(sa); end;

% set fileName, if none
if isempty(fileName), fileName = choose_SubjectArray; end;

% save subejct array
if strcmpi(saveyn,'yes'), savesubjfile(fileName,task,sa); end;

% save outputs
if ~exist('savefile','var')
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
% choose fields to save
if ~exist('flds','var')
flds = choose_fields(sa,subrun,['Choose fields to save to ' savefile{x} ' file']);
end
flds = flds(~strcmpi(flds,'subj')); % not subj
subjs = sawa_getfield(sa(subrun),'','subj$')'; % get subjs

% choose file directory
if ~exist('spath','var')||~exist('sfile','var')||x>numel(spath)||x>numel(sfile)
spath{x} = uigetdir(pwd,['Choose path to save ' savefile{x} ' to']);
sfile{x} = cell2mat(inputdlg(['Enter name for ' savefile{x}],'File Name',1,{task}));
if isempty(sfile{x}), sfile{x} = task; end;
end

% get fields
for f = 1:numel(flds),
    vals{f} = sawa_getfield(sa(subrun),'',[regexptranslate('escape',flds{f}) '$'])'; 
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
    for f = 1:numel(flds), eval([flds{f} '= {sa(subrun).(flds{f})}'';']); end;
    save(fullfile(spath{x},sfile{x}),'subj',flds{:}); % save to mat
end
end

% set vars to fp
fp = funpass(fp,{'sa','subrun','task','fileName','savefile','saveyn'});
return;
