function params = subjectarray(cmd,varargin)
% params = subjectarray(cmd, varargin)
% This is the first step to using the Subject Array and Study Organizer.
%
% Inputs:
% cmd - cellstr array of subfunction(s) to run
% varargin - arguments to pass to subfunction 
% if no inputs, subjectarray will run its gui (see example)
% 
% Outputs (only returned from command prompt call):
% params - structure array with fields:
%   sa - subject array
%   task - string task name
%   filename - name of file subject array loaded/saved
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
% [sa,subjs] = subjectarray('load_sa',struct(filename,{'/Users/test.mat'},'flds',...
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
% printres savesubjfile sawa sawa_input sawa_dlmread sawa_getfield 
% sawa_setfield sawa_strjoin sawa_subjs sawa_xlsread update_array
% 
% Created by Justin Theiss

% init vars
if ~exist('cmd','var')||isempty(cmd), cmd = []; end;
if isnumeric(cmd), cmd = {'subjectarray_gui'}; varargin = {struct}; end;
if ~iscell(cmd), cmd = {cmd}; end; 
if isempty(varargin), varargin = {struct}; end;

% run chosen cmds
for x = 1:numel(cmd), varargin{1} = feval(cmd{x},varargin{:}); end;

% set varargin to params as output
params = varargin{1};

% remove subjectarrayname field if exists
if isfield(params,'subjectarrayname'), 
    params = rmfield(params,'subjectarrayname'); 
end
end

% Callback functions
function params = subjectarray_gui(params)
% params = subjectarray_gui(params)
% Open gui to create subject array.

% setup structure for make_gui
s.name = 'subject array';
s.edit = struct('string','subject array name','tag','subject array name','order',[1,2]);
[s.push(1:4).string] = deal('add subjects','create new field','load','save');
[s.push.tag] = deal(s.push.string);
[s.push.callback] = deal(@(x,y)guidata(gcf,createfield(guidata(gcf),'subj')),...
    @(x,y)guidata(gcf,createfield(guidata(gcf))),...
    @(x,y)guidata(gcf,load_sa(guidata(gcf))),...
    @(x,y)guidata(gcf,save_sa(guidata(gcf))));
push_order = arrayfun(@(x){[1,x]}, 3:6);
[s.push.order] = deal(push_order{:});
s.text = struct('string','subject array fields','size',[165,25],'order',[2,2]);
s.listbox = struct('order',[2,6],'tag',[mfilename 'listbox'],'size',[165,120]);
s.listbox.callback = @(x,y)guidata(gcf,createfield(guidata(gcf),get(x,'value')));

% run struct2gui
params = struct2gui(s,'data',params);
end

function params = createfield(params, field, vals)
% params = createfield(params, field, vals)
% Create field to add to subject array with vals.
% If no field or vals, these will be input by user.

% get vars from params
struct2var(params,{'sa','subjs'});

% init vars
if ~exist('flds','var'), flds = get(findobj('tag',[mfilename, 'listbox']),'string'); end;
if ~exist('field','var'), field = cell2mat(inputdlg('Enter field name:')); end;

% create sa as empty if not existing
if ~exist('sa','var'), sa = struct; end; 

% if not setting subj, choose subjects
if strcmp(field,'subj'),
    subjs = [];
elseif ~exist('subjs','var'),
    subjs = sawa_subjs(sa);  
end

% create vars
if ~exist('vals','var')
    vals = sawa_input('variable', field, 'iter', subjs, 'array', sa);
    if isempty(vals), return; end;
end

% set subjs if field is subj
if strcmp(field,'subj'),
    subjs = 1:numel(vals);
end

% set field
if ~isempty(subjs), 
    R = strcat('(', arrayfun(@(x){num2str(x)}, subjs), ').', field);
else
    R = ['.', field];
end
sa = sawa_setfield(sa,'R',R,'C',vals);

% add to flds
flds{end+1} = field;

% set to listbox
set(findobj('tag',[mfilename 'listbox']),'value',1);
set(findobj('tag',[mfilename 'listbox']),'string',unique(flds)); 

% set vars to params
params = struct2var(params,{'sa','subjs'});
end

function params = load_sa(params, filename, task)
% params = load_sa(params, filename, task)
% Load subject array structure from one of following files:
%   *.mat
%   *.xls*
%   *.txt
%
% If no filename, @uigetfile is called.
% If no task, @listdlg is called to choose task (for subjects.mat file).

% choose filename
if ~exist('filename','var')
    disp('Choose file from which to load subject array:');
    [lfile,lpath] = uigetfile('*.xls*;*.txt;*.mat','Choose file from which to load subject array:');
    if ~any(lfile), return; end;
    filename = fullfile(lpath,lfile); 
end

% get file extension
[~,tmp,ext] = fileparts(filename);
    
% switch file ext
switch ext(1:4)
    case '.xls' % excel
        raw = sawa_xlsread(filename);
    case '.txt' % txt
        raw = sawa_dlmread(filename,'\t'); 
    case '.mat' % mat
        % choose task
        if ~exist('task','var'),
            tasks = fieldnames(load(filename));
            chc = listdlg('PromptString','Choose task:','ListString',tasks,...
                'selectionmode','single');
            if isempty(chc), return; end;
            task = tasks{chc};
        end
        % get structure
        tmp = load(filename, task);
        sa = tmp.(task);
        % get flds
        flds = fieldnames(sa);
    otherwise % other
        delim = cell2mat(inputdlg(['Enter delimiter for ' filename]));
        raw = sawa_dlmread(filename,delim); 
end

% if raw, set flds and vals
if exist('raw','var'),
    flds = raw(1,:); vals = cell(size(raw,1)-1, size(raw,2));
    for f = 1:numel(flds),
        vals{f} = cellfun(@(x){eval(x)}, raw(2:end, f));
    end
end

% set task
if ~exist('task','var'), task = tmp; end;

% create sa
if ~exist('sa','var'),
    sa = struct;
    for n = 1:numel(flds),
        R = strcat('(', arrayfun(@(x){num2str(x)}, 1:numel(vals{n})), ').', flds{n});
        sa = sawa_setfield(sa, 'R', R, 'C', vals{n});
    end
end

% set filename
set(findobj('tag','subjects.mat file'),'tooltipstring',filename);

% set task
set(findobj('tag','subject array name'),'string',task);

% set fields to listbox
set(findobj('tag',[mfilename 'listbox']),'string',unique(flds));

% set vars to params
params = struct2var(params,{'sa','task','filename'});
end

function params = save_sa(params, filename, task)
% params = save_sa(params, filename, task)
% Save subject array to filename with task name.
% Filename can be one of following types:
%   *.mat
%   *.xls*
%   *.txt
%
% If no filename or task, these will be set by user.

% if no sa field, assume sa
if ~isfield(params,'sa'),
    sa = params; params = struct;
else
    struct2var(params);
end

% init vars
if ~exist('filename','var'), 
    disp('Choose file to save subject array:');
    filename = uiputfile('*.xls*;*.txt;*.mat','Choose file to save subject array:');
end

% get extension
[~,tmp,ext] = fileparts(filename);

% set task
if ~exist('task','var'),
    if ~exist('subjectarrayname','var'),
        task = tmp; 
    else
        task = subjectarrayname.String;
    end
end

% get fields
flds = fieldnames(sa);
for f = 1:numel(flds),
    vals{f} = sawa_getfield(sa,'expr',['.*\.' flds{f} '$'])'; 
    vals{f} = cellfun(@(x){genstr(x)}, vals{f});
    raw(:,f) = vertcat(flds{f},vals{f});
end

% switch type of savefile
switch ext(1:4),
    case '.xls' % excel
        if ispc, 
            xlswrite(filename,raw,1); % xlswrite for pc
        else % for mac, use xlwrite
            if exist('xlwrite','file') % xlwrite
                xlwrite(filename,raw,1);
            else % disp error
                disp(['Could not create ' filename '. Requires xlwrite']);
            end; 
        end 
    case '.txt' % txt
        % save to txt file
        fid = fopen(filename,'w'); 
        for x = 1:size(raw,1),
            fprintf(fid,'%s\t',raw{x,:});
            fprintf(fid,'\n');
        end
        fclose(fid);
    case '.mat' % mat
        eval([task '= sa;']);
        if exist(filename,'file'),
            save(filename,task,'-append');
        else
            save(filename,task);
        end
end

% print saved
disp([filename ' saved with task: ' task]);

% set vars to params
params = struct2var(params,{'sa','task','filename'});
end
