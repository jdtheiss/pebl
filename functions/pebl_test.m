function pebl_test(func, verbose)
% pebl_test(FUN, verbose)
% Test pebl functions. If test fails or does not exist, an error will be thrown.
% 
% Inputs:
% FUN - string/cellstr functions to test (default is all in current folder)
% verbose - true/false to display function as it's being tested (default True)
%
% Outputs:
% None
%
% Example:
% pebl_test('pebl_feval', false)
%
% Note: FUN must be a string and not a function handle.
% 
% Created by Justin Theiss

% init vars
if ~exist('func','var'), 
    func = dir(fullfile(fileparts(mfilename('fullpath')), '*.m')); 
    func = cellfun(@(x){x(1:end-2)},{func.name}); 
end;
if ~iscell(func), func = {func}; end;
if ~exist('verbose','var')||isempty(verbose), verbose = true; end;

% set random seed generator
S = rng;
rng('default');

% remove mfilename from functions
nfunc = {'pebl_demo', 'pebl_xlsread', 'studyarray', mfilename};
func = func(~ismember(func,nfunc));

% prepend 'test_' to each function
func = cellfun(@(x){['test_', x]}, func);

% for each function, test 
for x = 1:numel(func),
    % display if verbose
    if verbose, disp(func{x}); end;
    % run test
    feval(func{x});
end

% reset random seed generator
rng(S);
end

function test_any2str
    outputs1 = {'test1','''test2''','3','test4: 4'};
    outputs2 = any2str('test1',{'test2'},3,struct('test4',4));
    assert(all(strcmp(outputs1,outputs2)));
end

function test_cell2strtable
    outputs1 = sprintf('test1\ttest2\ntest3\ttest4\ttest5');
    outputs2 = cell2strtable([{'test1','test2',''};{'test3','test4','test5'}],'\t');
    assert(strcmp(outputs1,outputs2));
end

function test_choose_fields
    sa = struct('test1',1,'test2',2);
    outputs1 = {'test1'};
    figurefun({@(x,y)setappdata(0,'ListDialogAppData__',struct('value',1,'selection',1)),...
        @(x,y)delete(x)}, {'style','listbox'},'StartDelay',1);
    outputs2 = choose_fields(sa);
    assert(all(strcmp(outputs1,outputs2)));
end

function test_cmd_help
    txt1 = sprintf('/bin/bash: test_fail: command not found\n');
    txt2 = cmd_help('test_fail');
    n1 = {'-n'};
    [~, n2] = cmd_help('echo');
    assert(strcmp(txt1,txt2));
    assert(all(strcmp(n1,n2)));
end

function test_collapse_array
    C1 = {'test1','test2','test3'};
    idx1 = {[1,2],[3,4],5};
    [C2, idx2] = collapse_array({'test1','test1','test2','test2','test3'});
    assert(all(strcmp(C1,C2)));
    assert(all(cell2mat(idx1)==cell2mat(idx2)));
end

function test_common_str
    outputs1 = 'test';
    outputs2 = common_str({'01test02','03test','test04'});
    assert(strcmp(outputs1,outputs2));
end

function test_figurefun
    outputs1 = {'test'};
    figurefun({@(x,y)set(y,'string','test'), @(x,y)set(x,'UserData','OK'),...
        @(x,y)uiresume(x)},{'style','edit'},'StartDelay',1);
    outputs2 = inputdlg;
    assert(all(strcmp(outputs1,outputs2)));
end

function test_genstr
    str1 = {'''str''','[2.5]','{''cell''}','struct(''field'', {''value''})'};
    str2 = cellfun(@(x){genstr(x)}, {'str', 2.5, {'cell'}, struct('field','value')});
    assert(all(strcmp(str1,str2)));
end

function test_getargs
    outputs1 = {'outArgs','inArgs'};
    outputs2 = getargs(@getargs);
    assert(all(strcmp(outputs1,outputs2)));
end

function test_pebl
    outputs1 = {'echo','strcmp','matlabbatch'};
    outputs2 = pebl('local_getfunctions',{'echo',@strcmp,{'test'}});
    assert(all(strcmp(outputs1,outputs2)));
    outputs3 = {'-n'};
    outputs4 = pebl('local_getoptions','echo',{'-n'},'current');
    outputs5 = {'varargin'};
    outputs6 = pebl('local_getoptions',@strcmp,{'test'},'add');
    assert(all(strcmp(outputs3,outputs4)));
    assert(all(strcmp(outputs5,outputs6)));
    outputs7 = struct('loop', 2, 'seq', [], 'iter', 1:2);
    outputs8 = pebl('set_iter',[],{'loop','seq','iter'}, {2,[],1:2});
    assert(pebl_eq(outputs7,outputs8));
    tmp = getenv('test');
    outputs9 = struct('env',{{{'setenv','test','test'}}});
    outputs10 = pebl('add_path',[],@setenv,{'test','test'});
    setenv('test',tmp);
    assert(pebl_eq(outputs9,outputs10));
    outputs11 = {cmd_help('echo'),help('strcmp'),''};
    outputs12 = pebl('get_help',{'echo',@strcmp,''});
    assert(all(strcmp(outputs11,outputs12)));
    params = pebl('add_function',[],1,@minus);
    params = pebl('set_options',params,1,{10,5});
    params.verbose_arg = false; params.wait_bar = false;
    params = pebl('run_params', params);
    outputs13 = minus(10, 5);
    outputs14 = params.output{1}{1};
    assert(outputs13==outputs14);
end

function test_pebl_cat
    outputs1 = [{'test1','test2'};{'test3',[]}];
    outputs2 = pebl_cat(1,{'test1','test2'}, 'test3');
    assert(pebl_eq(outputs1,outputs2));
end

function test_pebl_input
    outputs1 = 'test1';
    figurefun({@(x,y)setappdata(0,'ListDialogAppData__',struct('value',1,'selection',1)),...
        @(x,y)delete(x)}, {'style','listbox'},'StartDelay',1);
    figurefun({@(x,y)set(y,'string','test1'),@(x,y)set(x,'UserData','OK'),...
        @(x,y)uiresume(x)},{'style','edit'},'StartDelay',3);
    outputs2 = pebl_input;
    assert(strcmp(outputs1,outputs2));
end

function test_pebl_dlmread
    file = [tempname, '.txt'];
    str = 'test1|test2\ntest3|test4';
    fid = fopen(file, 'w');
    fprintf(fid, str);
    fclose(fid);
    outputs1 = [{'test1','test2'};{'test3','test4'}];
    outputs2 = pebl_dlmread(file, '\|');
    delete(file);
    assert(all(strcmp(outputs1(:),outputs2(:))));
end

function test_pebl_eq
    C1 = 0;
    reps1(:,1) = {'.test1'; '.test3'; '.test2{[1]}'};
    reps1(:,2) = {'.test1'; '.test3'; '.test2_{[1]}'};
    test1 = struct('test1',1,'test2',{{2}},'test3','3');
    test2 = struct('test1',2,'test2_',{{2}},'test3','3 ');
    [C2, reps2] = pebl_eq(test1,test2);
    assert(C1==C2);
    assert(all(strcmp(reps1(:),reps2(:))));
end

function test_pebl_feval
    outputs1 = {1;2;};
    outputs2 = pebl_feval(@str2double, {'1';'2'}, 'iter', 1:2);
    assert(all(cellfun(@(x,y)x==y,outputs1,outputs2{1})));
end

function test_pebl_find
    fnd1 = [1, 0];
    C1 = {1};
    S1 = {substruct('.','test1')};
    reps1 = {'.test1'};
    [fnd2, C2, S2, reps2] = pebl_find(@eq,1,struct('test1',1,'test2',2));
    assert(all(fnd1==fnd2));
    assert(all(cellfun(@(x,y)x==y,C1,C2)));
    assert(pebl_eq(S1,S2));
    assert(all(strcmp(reps1,reps2)));
end

function test_pebl_getfield
    C1 = {1};
    S1 = {substruct('.','test1')};
    reps1 = {'.test1'};
    [C2, S2, reps2] = pebl_getfield(struct('test1',1),'expr','\.test1$');
    assert(all(cellfun(@(x,y)x==y,C1,C2)));
    assert(pebl_eq(S1,S2));
    assert(all(strcmp(reps1,reps2)));
end

function test_pebl_insert
    outputs1 = 'te_st';
    outputs2 = pebl_insert([],'test',3,'_');
    assert(strcmp(outputs1,outputs2));
end

function test_pebl_search
    outputs1 = {[mfilename('fullpath'), '.m']};
    outputs2 = pebl_search(fileparts(mfilename('fullpath')),...
        [mfilename, '\.m$'],'dir','n_levels',0);
    outputs3 = {[mfilename('fullpath'), '.m']};
    outputs4 = pebl_search(fileparts(mfilename('fullpath')),...
        'test_pebl_search','\.m$','n_levels',0);
    assert(all(strcmp(outputs1,outputs2)));
    assert(all(strcmp(outputs3,outputs4)));
end

function test_pebl_setfield
    sa = struct('test1',1,'test2', 2);
    outputs1 = struct('test1',3,'test2',2);
    outputs2 = pebl_setfield(sa, 'R', '.test1', 'C', 3);
    assert(pebl_eq(outputs1,outputs2));
end

function test_pebl_setbatch
    matlabbatch1{1}.spm.util.disp.data = '<UNDEFINED>';
    options1 = {};
    figurefun(@(x,y)close(x),{'type','figure'},'StartDelay',30);
    [matlabbatch2, options2] = pebl_setbatch(matlabbatch1);
    assert(pebl_eq(matlabbatch1,matlabbatch2));
    assert(pebl_eq(options1,options2));
end

function test_pebl_strjoin
    outputs1 = 'test1, test2, test3';
    outputs2 = pebl_strjoin({'test1','test2','test3'}, ', ');
    assert(strcmp(outputs1,outputs2));
end

function test_pebl_subjs
    sa = struct('subj',{'Sub1','Sub2','Sub3'},'age',{1,2,3});
    outputs1 = 2;
    figurefun({@(x,y)setappdata(0,'ListDialogAppData__',struct('value',1,'selection',2)),...
        @(x,y)delete(x)}, {'style','listbox'}, 'StartDelay', 1);
    figurefun(@(x,y)delete(x), {'string','Cancel'}, 'StartDelay', 3);
    outputs2 = pebl_subjs(sa);
    assert(outputs1==outputs2);
end

function test_settimeleft
    h = settimeleft; 
    assert(isgraphics(h));
    for x = 1:3, settimeleft(x, 1:3, h, 'test'); end;
    assert(~isgraphics(h));
end

function test_struct2gui
    outputs1 = 'test1';
    figurefun(@(x,y)close(x),{'string','done'},'StartDelay',1);
    outputs2 = struct2gui(struct('name','test'), 'data', 'test1');
    assert(strcmp(outputs1,outputs2));
end

function test_struct2sub
    outputs1{1} = substruct('{}',{1},'.','test1','.','test2','()',{1},'.','test3');
    outputs1{2} = substruct('{}',{1},'.','test1','.','test2','()',{2},'.','test3');
    C{1}.test1.test2(2).test3 = 'test';
    outputs2 = struct2sub(C);
    assert(pebl_eq(outputs1,outputs2));
end

function test_struct2var
    outputs1 = 'test1';
    struct2var(struct('outputs2','test1'),'outputs2');
    assert(strcmp(outputs1,outputs2));
end

function test_subidx
    outputs1 = {'test'};
    outputs2 = subidx({'test'},'(1)');
    assert(all(strcmp(outputs1,outputs2)));
end

function test_sub2str
    outputs1 = '{[1]}.test1([2]).test2';
    S = substruct('{}',{1},'.','test1','()',{2},'.','test2');
    outputs2 = sub2str(S);
    assert(strcmp(outputs1,outputs2));
    outputs3 = substruct('{}',{1,2},'.','test1','.','test2','()',{1});
    str = '{1,2}.test1.test2(1)';
    outputs4 = sub2str(str);
    assert(pebl_eq(outputs3,outputs4));
end

function test_switchcase
    r = randn(1);
    switch gt(r, 1)
        case true
            output1 = 'greater';
        case false
            output1 = 'lesser';
        otherwise
            output1 = 'error';
    end
    output2 = switchcase(gt(r, 1), true, 'greater', false, 'lesser', 'otherwise', 'error');
    assert(strcmp(output1, output2));
end

function test_update_var
    file1 = [tempname, '.txt'];
    fid = fopen(file1, 'w');
    str = 'test_str = '';\ntest_num = 0;\ntest_logic = false;';
    fprintf(fid, str);
    fclose(fid);
    str1 = sprintf('test_str = ''test1'';\ntest_num = [1];\ntest_logic = [true];');
    [str2, file2] = update_var(file1, 'test_str', 'test1', 'test_num', 1, 'test_logic', true);
    delete(file1);
    assert(strcmp(str1,str2));
    assert(strcmp(file1,file2));
end