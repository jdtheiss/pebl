function [array, filename, task] = studyarray(cmd,varargin)
% [array, filename, task] = studyarray(cmd, varargin)
% Create a structural array containing study information (e.g., subject
% folder/file locations, demographic information, etc.)
%
% Inputs:
% cmd - cellstr array of subfunction(s) to run
% varargin - arguments to pass to subfunction 
% if no inputs, studyarray will run its gui (see example)
% 
% Outputs (only returned from command prompt call):
% array - study array
% task - string task name
% filename - name of file study array loaded/saved
%
% Example:
% array = studyarray('createfield', struct, 'subj', {'S1','S2','S3'});
% array = studyarray('createfield', struct('array',array), 'age', {21, 25, 33});
% [array,filename,task] = studyarray('savearray', struct('array',array),...
%                                    fullfile(pwd,'test.mat'), 'test')
% 
% array = 
% 
% 1x3 struct array with fields:
% 
%     subj
%     age
% 
% 
% filename =
% 
% /Users/test.mat
% 
% 
% task =
% 
% test
%
% Created by Justin Theiss

% init vars
if ~exist('cmd','var')||isempty(cmd), cmd = []; end;
if isnumeric(cmd), cmd = {'studyarray_gui'}; varargin = {struct}; end;
if ~iscell(cmd), cmd = {cmd}; end; 
if isempty(varargin), varargin = {struct}; end;

% run chosen cmds
for x = 1:numel(cmd), varargin{1} = feval(cmd{x},varargin{:}); end;

% set varargin to params as output
params = varargin{1};
C = pebl_getfield(params, 'R', {'.array', '.filename', '.task'});
[array, filename, task] = deal(C{:});
end

% Callback functions
function params = studyarray_gui(params)
% params = studyarray_gui(params)
% Open gui to create study array.

% setup structure for make_gui
s.name = 'study array';
s.edit = struct('string','study array name','tag','study array name','order',[1,2]);
[s.push(1:4).string] = deal('add subjects','create new field','load','save');
[s.push.tag] = deal(s.push.string);
[s.push.callback] = deal(@(x,y)guidata(gcf,createfield(guidata(gcf),'subj')),...
    @(x,y)guidata(gcf,createfield(guidata(gcf))),...
    @(x,y)guidata(gcf,loadarray(guidata(gcf))),...
    @(x,y)guidata(gcf,savearray(guidata(gcf))));
push_order = arrayfun(@(x){[1,x]}, 3:6);
[s.push.order] = deal(push_order{:});
s.text = struct('string','study array fields','size',[165,25],'order',[2,2]);
s.listbox = struct('order',[2,6],'tag',[mfilename 'listbox'],'size',[165,120]);
s.listbox.callback = @(x,y)guidata(gcf,createfield(guidata(gcf),get(x,'value')));

% run struct2gui
params = struct2gui(s,'data',params);
end

function params = createfield(params, field, vals)
% params = createfield(params, field, vals)
% Create field to add to study array with vals.
% If no field or vals, these will be input by user.

% get vars from params
struct2var(params,{'array','subjs'});

% init vars
if ~exist('flds','var'), flds = get(findobj('tag',[mfilename, 'listbox']),'string'); end;
if ~exist('field','var'), field = cell2mat(inputdlg('Enter field name:')); end;

% create array as empty if not existing
if ~exist('array','var'), array = struct; end; 

% if not setting subj, choose subjects
if strcmp(field,'subj'),
    subjs = [];
elseif ~exist('subjs','var') && nargin < 3,
    subjs = pebl_subjs(array);  
else % otherwise set to all subjects
    subjs = 1:numel(array);
end

% create vars
if ~exist('vals','var')
    vals = pebl_input('variable', field, 'iter', subjs, 'array', array);
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
array = pebl_setfield(array,'R',R,'C',vals);

% add to flds
flds{end+1} = field;

% set to listbox
set(findobj('tag',[mfilename 'listbox']),'value',1);
set(findobj('tag',[mfilename 'listbox']),'string',unique(flds)); 

% set vars to params
params = struct2var(params,{'array','subjs'});
end

function params = loadarray(params, filename, task)
% params = loadarray(params, filename, task)
% Load study array structure from one of following files:
%   *.mat
%   *.xls*
%   *.txt
%
% If no filename, @uigetfile is called.
% If no task, @listdlg is called to choose task (for studyarray.mat file).

% choose filename
if ~exist('filename','var')
    disp('Choose file from which to load study array:');
    [lfile,lpath] = uigetfile('*.xls*;*.txt;*.mat','Choose file from which to load study array:');
    if ~any(lfile), return; end;
    filename = fullfile(lpath,lfile); 
end

% get file extension
[~,tmp,ext] = fileparts(filename);
    
% switch file ext
switch ext(1:4)
    case '.xls' % excel
        raw = pebl_xlsread(filename);
    case '.txt' % txt
        raw = pebl_dlmread(filename,'\t'); 
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
        array = tmp.(task);
        % get flds
        flds = fieldnames(array);
    otherwise % other
        delim = cell2mat(inputdlg(['Enter delimiter for ' filename]));
        raw = pebl_dlmread(filename,delim); 
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

% create array
if ~exist('array','var'),
    array = struct;
    for n = 1:numel(flds),
        R = strcat('(', arrayfun(@(x){num2str(x)}, 1:numel(vals{n})), ').', flds{n});
        array = pebl_setfield(array, 'R', R, 'C', vals{n});
    end
end

% set filename
set(findobj('tag','studyarray.mat file'),'tooltipstring',filename);

% set task
set(findobj('tag','study array name'),'string',task);

% set fields to listbox
set(findobj('tag',[mfilename 'listbox']),'string',unique(flds));

% set vars to params
params = struct2var(params,{'array','task','filename'});
end

function params = savearray(params, filename, task)
% params = savearray(params, filename, task)
% Save study array to filename with task name.
% Filename can be one of following types:
%   *.mat
%   *.xls*
%   *.txt
%
% If no filename or task, these will be set by user.

% if no array field, assume array
if ~isfield(params,'array'),
    array = params; params = struct;
else
    struct2var(params);
end

% init vars
if ~exist('filename','var'), 
    disp('Choose file to save study array:');
    filename = uiputfile('*.xls*;*.txt;*.mat','Choose file to save study array:');
end

% get extension
[~,tmp,ext] = fileparts(filename);

% set task
if ~exist('task','var'),
    if ~exist('studyarrayname','var'),
        task = tmp; 
    else
        task = studyarrayname.String;
    end
end

% get fields
flds = fieldnames(array);
for f = 1:numel(flds),
    vals{f} = pebl_getfield(array,'expr',['.*\.' flds{f} '$'])'; 
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
        eval([task '= array;']);
        if exist(filename,'file'),
            save(filename,task,'-append');
        else
            save(filename,task);
        end
end

% print saved
disp([filename ' saved with task: ' task]);

% set vars to params
params = struct2var(params,{'array','task','filename'});
end
