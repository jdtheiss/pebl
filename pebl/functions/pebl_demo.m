function output = pebl_demo(demo)
% output = pebl_demo(demo)
% Run demo for pebl
%
% Inputs:
% demo (optional) - demo to run for pebl. see below for list of available demos.
%   [default 'general']
% 
% Outputs:
% output - output from demo
%
% Available demos: 'default', 'hello_world', 'matlabbatch', 'add_path',
%   'study_array', 'iterations', 'add_function', 'set_options', 'verbose',
%   'function_list', 'load_save_run'
%
% Note: type help pebl_demo>name_demo to learn more about the demo
% (e.g., help pebl_demo>default_demo to learn about the 'default' demo).
% Also, any demo other than 'default' can be run as a "command line" demo
% by adding "cmd" to the end (e.g., 'hello_world_cmd').
%
% Created by Justin Theiss

% init demo
if ~exist('demo','var') || isempty(demo), demo = 'default'; end;

% ensure pebl is not open
delete(findobj('name','pebl'));

% ensure no spaces
demo = regexprep(demo, '\s', '_');

% check for command line demo
if regexp(demo, '_cmd$', 'once'), 
    demo = regexprep(demo, '_cmd$', '');
    cmd = true;
else
    cmd = false;
end

% feval demo
output = feval(str2func([demo, '_demo']), cmd);

% stop timers
if ~isempty(timerfind),
    stop(timerfind);
    delete(timerfind);
end
end

function output = default_demo(cmd)
% default demo
% This demo will open the pebl gui and allow the user to learn more about
% each button. Hovering the mouse over a button will display descriptive
% information including the appropriate demo to run.

% no command line demo
if cmd, disp('No command line demo found.'); end;

% opening message
figurefun(@(x,y)uiwait(msgbox(['Welcome to pebl! Hover your mouse'...
         ' over buttons to learn more information.'])), {'name','pebl'});
% add path/environment message
figurefun(@(x,y)set(y, 'tooltipstring', sprintf(['This allows you to add'...
         ' paths for matlab functions or set environment\n'...
         ' variables (such as PATH) for command line functions.\n'...
         ' Try pebl_demo(''add_path'') for more information.'])),...
         {'string', 'add path/environment'});
% study array message
figurefun(@(x,y)set(y, 'tooltipstring', sprintf(['This allows you to create'...
         ' a study array to set subject variables and paths\n'...
         ' for use in the pipeline. Try pebl_demo(''study_array'')'...
         ' for more information.'])), {'string', 'study array'});
% iterations message
figurefun(@(x,y)set(y, 'tooltipstring', sprintf(['This allows you to control'...
         ' the number of loops, sequence of functions,\n'...
         ' or iterations to be run in the pipeline.\n'...
         ' Try pebl_demo(''iterations'') for more information'])),...
         {'string', 'iterations'});
% add function message
figurefun(@(x,y)set(y, 'tooltipstring', sprintf(['This allows you to add new'...
         ' matlab, command line, or matlabbatch functions to the pipeline.\n'...
         ' Try pebl_demo(''add_function'') for more information.'])),...
         {'string', 'add function'});
% set options message
figurefun(@(x,y)set(y, 'tooltipstring', sprintf(['This allows you to set the'...
         ' options for each function in the pipeline.\n'...
         ' Try pebl_demo(''set_options'') for more information.'])),...
         {'string', 'set options'});
% verbose message
figurefun(@(x,y)set(y, 'tooltipstring', sprintf(['This allows you to set the'...
         ' display options when running the pipeline.\n'...
         ' Try pebl_demo(''verbose'') for more information.'])),...
         {'string', {'verbose output', 'quiet output', 'save output'}});
% listbox message
figurefun(@(x,y)set(y, 'tooltipstring', sprintf(['This is the space where'...
         ' pipeline functions are listed.\n'...
         ' Try pebl_demo(''function_list'') for more information.'])),...
         {'style', 'listbox'});
% load/save/run message
figurefun(@(x,y)set(y, 'tooltipstring', sprintf(['This allows you to load,'...
         ' save, or run a pipline.\n'...
         ' Try pebl_demo(''load_save_run'') for more information'])),...
         {'string', {'load','save','run'}});
% open pebl
output = input('Type pebl then press enter\n');
end

function output = add_path_demo(cmd)
% add path demo
% This demo will show you how to add paths or set environment variables for
% your pipeline. Sometimes you will need to add the path for a matlab or
% command line function using @addpath or @setenv, respectively. Other
% times you may want to set an environment variable to use when calling
% command line functions.

% set params for demo
params = struct('funcs', {{'echo'}}, 'options', {{'$test_var'}});
% get initial test_var
test_var = getenv('test_var');

if cmd, % command line
help('pebl>add_path');
params = input('Enter pebl(''add_path'', params, @setenv, {''test_var'', ''test''})\n');
output = input('Enter pebl(''run_params'', params)\n');
else % gui
help('pebl_demo>add_path_demo');
% click add path/environment
figurefun(@(x,y)uiwait(msgbox('Click add path/environment')), {'name','pebl'});
% select @setenv
figurefun(@(x,y)uiwait(msgbox('Select setenv')),...
         {'string', 'add path/environment','value',1});
% enter test_var
figurefun(@(x,y)uiwait(msgbox('Enter test_var')), {'name','Name'});
% select String and enter test
figurefun(@(x,y)uiwait(msgbox('Select String and enter test')),...
         {'string', {'Choose method to set setenv input','',''}});
% open pebl
output = pebl('load_editor', params);
end

% reset test_var
setenv('test_var', test_var);
end

function output = study_array_demo(cmd)
% study array demo
% This demo will show how to create a study array that can be used as
% variable inputs in a pipeline.

% set params for demo
params = struct('funcs', {{@disp}}, 'options', {{@()'output{1}{end}(n).age'}},...
                'iter', {{[],1:3}});

if cmd, % command line
help('pebl>study_array');
params = input(['Enter pebl(''study_array'',params,struct(''subj'','...
              '{''s1'',''s2'',''s3''},''age'',{20,19,25}))\n']);
output = input('Enter pebl(''run_params'', params)\n');
else % gui
% click study array
figurefun(@(x,y)uiwait(msgbox('Click study array')), {'name','pebl'});
% click add subjects
figurefun(@(x,y)uiwait(msgbox('Click add subjects')), {'name','study array'});
% select String
figurefun(@(x,y)uiwait(msgbox('Select String')), {'string','add subjects','value',1});
% enter subj1, subj2, subj3
figurefun(@(x,y)uiwait(msgbox('Enter subj1, subj2, subj3 on separate lines')),...
         {'string', 'Set subj'});
% create new field
figurefun(@(x,y)uiwait(msgbox('Click create new field')), {'string',{'subj'}});
% enter group
figurefun(@(x,y)uiwait(msgbox('Enter age as field name')),...
         {'string','create new field','value',1});
% select String
figurefun(@(x,y)uiwait(msgbox('Select Number')),...
         {'string',{'Choose method to set age','',''}});
% enter control, patient, control
figurefun(@(x,y)uiwait(msgbox('Enter 20, 19, 25 on separate lines')),...
         {'string','Set age'});
% click done
figurefun(@(x,y)uiwait(msgbox('Click done')), {'string',{'age','subj'}});
% open pebl
output = pebl('load_editor', params);
end
end

function output = iterations_demo(cmd)
% iterations demo
% This demo will show how to set the number of loops, sequence of
% functions, and sequence of iterations for a pipeline. The 'loop' variable
% controls how many times an entire pipeline is looped; the 'seq' variable
% controls the order in which functions are run; and the 'iter' variable
% controls the order of iterations (if any) inputs should be used per
% function. The 'iter' variable can be [] (default), a range of numbers, or
% inf to run all iterations. Setting 'iter' to [] will assume that the
% inputs do not include iterations and will be run as is. If you are using
% iterations, the input to iterate should be a vertical cell array such
% that the first iteration corresponds to the first cell (e.g.,
% {'hello';'world';'!'} has 3 possible iterations).

% set params for demo
params = struct('funcs', {{@disp, @disp}}, 'options', {{{'1';'2';'3'}, {'test'}}});

if cmd, % command line
help('pebl>set_iter');
params = input(['Enter pebl(''set_iter'', params, {''loop'', ''seq'', ''iter''},'...
              ' {2, [1,2,2], {inf,[]}})\n']);
output = input('Enter pebl(''run_params'', params)\n');
else % gui
help('pebl_demo>iterations_demo');
% click iterations
figurefun(@(x,y)uiwait(msgbox('Click iterations')), {'name','pebl'});
% select all
figurefun(@(x,y)uiwait(msgbox('Select all fields')), {'string','iterations','value',1});
% enter 2
figurefun(@(x,y)uiwait(msgbox('Enter 2')), {'name','loop'});
% enter [1,2,2]
figurefun(@(x,y)uiwait(msgbox('Enter [1,2,2]')), {'name','seq'});
% enter {inf, []}
figurefun(@(x,y)uiwait(msgbox('Enter {inf, []}')), {'name','iter'});
% open pebl
output = pebl('load_editor', params);
end
end

function output = add_function_demo(cmd)
% add function demo
% This demo shows how to add a function to the pipeline. Functions can be
% one of three basic types:
%   matlab function - anything that begins with @
%   command line function - functions typically run using @system
%   matlabbatch - this will load the matlabbatch gui
%
% To learn more about using matlabbatch, try pebl_demo('matlabbatch').

% set params for demo
params = struct('verbose', true);

if cmd, % command line
help('pebl>add_function');
params = input('Enter pebl(''add_function'', params, 1, @rand)\n');
output = input('Enter pebl(''run_params'', params)\n');
else % gui
help('pebl_demo>add_function_demo');     
% click add function
figurefun(@(x,y)uiwait(msgbox('Click add function')), {'name','pebl'});
% enter @disp
figurefun(@(x,y)uiwait(msgbox('Enter @rand')), {'string','add function','value',1});
% open pebl
output = pebl('load_editor', params);
end
end

function output = set_options_demo(cmd)
% set options demo
% This demo shows how to set options that will be input to a function. When
% using the gui, there are several methods to set the options for an input:
%   String - a string or cellstring array
%   Number - numeric arrays or cell array of numberic arrays
%   Evaluate - evaluates any expression per line
%   Index - sets an array index then allows you to choose a new method
%   Structure - creates structure array with each field set by new method
%   Choose File - choose file(s) using @spm_select
%   Choose Directory - choose directory(ies) using @spm_select
%   Function - set input to the output of a function using @pebl_feval
%   Workspace Variable - set input to a workspace variable
%   Batch Dependency - set input to a dependency of a batch module
%   Preceding functions - set input to output of preceding function

% set params for demo
params = struct('funcs', {{@disp}}, 'options', {{{}}});

if cmd, % command line
help('pebl>set_options');
params = input('Enter pebl(''set_options'', params, 1, {''test''})\n');
output = input('Enter pebl(''run_params'', params)\n');
else % gui
help('pebl_demo>set_options_demo');      
% click set options
figurefun(@(x,y)uiwait(msgbox('Click set options')), {'name','pebl'});
% select add
figurefun(@(x,y)uiwait(msgbox('Select add')), {'string','set options','value',1});
% select varargin
figurefun(@(x,y)uiwait(msgbox('Select varargin')), {'string',{'Choose options to add:'}});
% select String and enter test
figurefun(@(x,y)uiwait(msgbox('Select String and enter test')),...
         {'string',{'Choose method to set varargin','',''}});
% select No
figurefun(@(x,y)uiwait(msgbox('Select No')), {'name','New variable'});
% open pebl
output = pebl('load_editor', params);
end
end

function output = verbose_demo(cmd)
% verbose demo
% This demo shows how to set the display options for a pipeline. There are
% four options:
%   normal display (default),
%   verbose display,
%   quiet dispaly,
%   or save display to .txt file.
% The normal display option prints to the command window only what would
% typically be shown (e.g., @disp will still display in command window). 
% The verbose display option prints to the command window the function and
% inputs being called, any normal displays, and the outputs from the
% function call.
% The quiet display option prevents anything from being printed in the
% command window.
% The save display option will set display option to verbose and save any
% command window text to a .txt file.

% set params for demo
params = struct('funcs', {{@disp}}, 'options', {{'test'}});

if cmd, % command line
help('pebl>print_options');
params = input('Enter pebl(''print_options'', params, ''print_type'', ''off'')\n');
output = input('Enter pebl(''run_params'', params)\n');
else % gui
help('pebl_demo>verbose_demo');
% select quiet output
figurefun(@(x,y)uiwait(msgbox('Select quiet output from verbose output dropdown menu')),...
         {'name','pebl'});
% open pebl
output = pebl('load_editor', params);
end
end

function output = function_list_demo(cmd)
% function list demo
% This demo shows how to copy, edit, delete, get help, or insert functions.
% When using the gui, right click on a function in the function list to
% choose one of these options. When using the command line, you can use one
% of the following subfunctions:
%   pebl('copy_function', params, idx)
%   pebl('delete_function', params, idx)
%   pebl('add_function', params, idx, func)
%   pebl('get_help', funcs, idx)
%   pebl('insert_function', params, idx)

if cmd, % command line
params = input('Enter pebl(''add_function'', [], 1, @disp)\n');
help('pebl>copy_function');
params = input('Enter pebl(''copy_function'', params, 1)\n');
params = input('Enter pebl(''add_function'', params, 1, ''echo'')\n');
help('pebl>insert_function');
params = input('Enter pebl(''insert_function'', params, 1, @disp)\n');
help('pebl>delete_function');
output = input('Enter pebl(''delete_function'', params, 3)\n');
help('pebl>get_help');
helpstr = input('Enter pebl(''get_help'', ''echo'')\n');
disp(helpstr{1});
else % gui
help('pebl_demo>function_list_demo');
% click add function and enter @disp
figurefun(@(x,y)uiwait(msgbox('Click add function and enter @disp')), {'name','pebl'});
% right click @disp
figurefun(@(x,y)uiwait(msgbox('Right click disp in function list')), {'string',{'disp'}});
% select copy
figurefun(@(x,y)uiwait(msgbox('Select copy')), {'string',{'Choose option:'}});
% right click first @disp, edit to echo
figurefun(@(x,y)uiwait(msgbox('Right click first disp then select edit and enter echo')),...
         {'string',{'disp','disp'}});
% right click echo, insert @disp
figurefun(@(x,y)uiwait(msgbox('Right click echo then select insert and enter @disp')),...
         {'string',{'echo','disp'}});
% right click last @disp, delete @disp
figurefun(@(x,y)uiwait(msgbox('Right click last disp then select delete')),...
         {'string',{'disp','echo','disp'}});
% right click echo, help
figurefun(@(x,y)uiwait(msgbox('Right click echo then select help')),...
         {'string',{'disp','echo'}});
% open pebl
output = pebl;
end
end

function output = load_save_run_demo(cmd)
% load/save/run demo
% This demo shows how to load, save, and run parameters. 
% When using gui, choose load/save/run from the dropdown menu in the bottom
% right corner. When using command line, use the following functions:
%   pebl('load_params', params, file)
%   pebl('save_params', params, file)
%   pebl('run_params', params)

if cmd, % command line
help('pebl>save_params');
params = input('Enter struct(''funcs'', @disp, ''options'', {{''test''}})\n');
params = input('Enter pebl(''save_params'', params, ''disp_test.mat'')\n');
help('pebl>load_params');
params = input('Enter pebl(''load_params'', [], ''disp_test.mat'')\n');
help('pebl>run_params');
output = input('Enter pebl(''run_params'', params)\n');
else % gui
help('pebl_demo>load_save_run_demo');
% click add function and enter @disp
figurefun(@(x,y)uiwait(msgbox('Click add function and enter @disp')), {'name','pebl'});
% click set options
figurefun(@(x,y)uiwait(msgbox('Click set options')), {'string',{'disp'}});
% select string and enter test
figurefun(@(x,y)uiwait(msgbox('Select String then enter test')),...
         {'string',{'Choose method to set varargin','',''}});
% select No then save from dropdown menu
figurefun(@(x,y)uiwait(msgbox('Select No, then select save from load dropdown menu')),...
         {'string', 'Add new variable?'});
% save as disp_test.mat
figurefun(@(x,y)uiwait(msgbox('Save file as disp_test.mat')),...
         {'string', {'load','save','run'}, 'value', 2});
% open pebl
output = pebl;
end
end

function output = hello_world_demo(cmd)
% hello world demo
% This demo shows how to run the iconic hello world! command iteratively.

if cmd, % command line
% input each command
params = input('Enter pebl(''add_function'', [], 1, @disp)\n');
params = input('Enter pebl(''set_options'', params, 1, {''hello'';''world'';''!''})\n');
params = input('Enter pebl(''set_iter'', params, ''iter'', 1:3)\n');
output = input('Enter pebl(''run_params'', params)\n'); 
else % gui
help('pebl_demo>hello_world_demo');
% click add function and enter @disp
figurefun(@(x,y)uiwait(msgbox('Click add function and enter @disp')), {'name','pebl'});
% click set options
figurefun(@(x,y)uiwait(msgbox('Click set options')), {'string', {'disp'}});
% select string
figurefun(@(x,y)uiwait(msgbox('Select String')),...
         {'string', {'Choose method to set varargin','',''}});
% enter hello, world, !
figurefun(@(x,y)uiwait(msgbox('Enter hello, world, ! on separate lines')),...
         {'string', 'Set varargin'});
% click iterations
figurefun(@(x,y)uiwait(msgbox('Select No, then click iterations')),...
         {'string', 'Add new variable?'});
% select iter
figurefun(@(x,y)uiwait(msgbox('Select iter')), {'string',{'loop','seq','iter'}});
% enter 1:3, then run
figurefun(@(x,y)uiwait(msgbox(['Enter 1:3 then select run from the load'...
         ' dropdown menu'])),{'name', 'iter'});
% click done
figurefun(@(x,y)uiwait(msgbox('Click done')),...
         {'string', {'load','save','run'}, 'value', 3});
% open pebl
output = pebl;
end
end

function output = matlabbatch_demo(cmd)
% matlabbatch demo
% This demo shows how to use the matlabbatch gui with pebl.
% Adding matlabbatch modules to a pipeline is acheived by selecting modules
% in the matlabbatch gui (after adding 'matlabbatch' to the pipeline). 
% Then you can choose variables within each module that will be pipeline
% variables by highlighting them and pressing the right arrow on the
% keyboard. To remove a pipeline variable, press the left arrow while it is
% highlighted.
% The options for matlabbatch functions are composed of a string
% representation of the matlabbatch variable and a cell to set for that
% variable. When setting options, the string representation will appear
% before a "parameter" option. In most cases you will only need to set the
% paramter option and not change the string representation.
%
% Note: this demo requires SPM which is free to download from 
% http://www.fil.ion.ucl.ac.uk/spm/

% display help
help('pebl_demo>matlabbatch_demo');

% no command line demo
if cmd, disp('No command line demo found.'); end;
% if no spm, error
if isempty(which('spm')), error('Cannot run demo without SPM downloaded'); end;

% get current directory
curdir = pwd;
% click add function
figurefun(@(x,y)uiwait(msgbox('Click add function and enter matlabbatch')),...
         {'name','pebl'});
% add SPM>Utils>Display image
figurefun(@(x,y)uiwait(msgbox('Select SPM>Util>Display Image')),...
         {'string','No Current Module'});
% select Image to Display
figurefun(@(x,y)uiwait(msgbox(['With Image to Display highlighted, press the right'...
         ' arrow key. Then close the Batch Editor'])),...
         {'string','Current Module: Display Image'});
% click set options
figurefun(@(x,y)uiwait(msgbox('Click set options')), {'string',{'matlabbatch'}});
% select parameter
figurefun(@(x,y)uiwait(msgbox('Select parameter')), {'string',{'Choose options to edit:'}});
% select choose file
figurefun(@(x,y)uiwait(msgbox('Select Choose File')),...
         {'string',{'Choose method to set parameter','',''}});
% select file
figurefun(@(x,y)uiwait(msgbox('Select avg152T1.nii or other image file to display')),...
         {'name','Select file for parameter'});
% select No then run
figurefun(@(x,y)uiwait(msgbox('Select No then select run from the load dropdown menu')),...
         {'name','New variable'});
% change to spm/canonical directory
cd(fullfile(fileparts(which('spm')), 'canonical'));
% open pebl
output = pebl;
% return to previous directory
cd(curdir);
end