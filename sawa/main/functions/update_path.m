function new_fil = update_path(fil,mfil,filvar)
% update_path(fil,mfil)
% This function will update a filepath (fil) for the .m file entered (i.e.
% mfilename('fullpath'))
%
% Inputs:
% fil - file path or folder path as a variable (see example)
% mfil - mfilename('fullpath') for the .m file to edit
% filvar (optional) - if fil is a cellstr (e.g., fil{1} = '';) then filvar
% should be the str representation of fil (i.e. filvar = 'fil';)
% 
% Outputs:
% new_fil - the updated file/folder path
% 
% Example:
% test_dir = 'C:\Program Files\Deleted Folder\SomeProgram';
% mfil = 'C:\Program Files\sawa\Test\SomeScript';
% update_path(test_dir,mfil);
% The script "SomeScript" will now have been rewritten with the updated
% path for test_dir
% 
% NOTE: within the script file (mfil), fil must be defined as follows:
% fil = 'filepath';
% If the single quotes and semicolon are missing, update_path will not work.
% Furthermore, if there are multiple "fil = 'filepath';", only the first
% will be used.
% 
% Created by Justin Theiss


new_fil = fil; 
if ~exist('filvar','var'), filvar = inputname(1); end;
if ~isdir(fil)&&exist(fil,'file')~=2
filfold = questdlg('Choose file or folder?','File or Folder','File','Folder','Folder');
if strcmp(filfold,'Folder') % if no ext, get folder
new_fil = uigetdir(pwd,['Choose the folder location for ' filvar ':']);
elseif strcmp(filfold,'File') % otherwise get file
[fl,pth] = uigetfile('*',['Choose the file loacation for ' filvar ':']);
new_fil = fullfile(pth,fl);
end
if ~exist('mfil','var'), return; end; % no mfil, return
% if no ext for mfil, set to .m
[~,~,ext] = fileparts(mfil); if isempty(ext), mfil = [mfil '.m']; end;
tmpstr = fileread(mfil); findstr = regexp(tmpstr,['[^\n]*' filvar '\s?=\s?''[^'']*'';'],'match');
tmpstr = strrep(tmpstr,findstr{1},[filvar ' = ''' new_fil ''';']);
fid = fopen(mfil,'w'); fwrite(fid,tmpstr); fclose(fid);    
end
