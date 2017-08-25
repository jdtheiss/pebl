function [txt, options] = cmd_help(cmd)
% [txt, options] = cmd_help(cmd)
% Return help documentation string and options for command line functions.
%
% Inputs:
% cmd - string command line function to return help string
%
% Outputs:
% txt - string command line help string
% options - cell array of comand line options
% 
% Example:
% 
% [txt,options] = cmd_help('echo')
% 
% txt =
% 
% ECHO(1)                   BSD General Commands Manual                  ECHO(1)
% 
% NAME
%      echo -- write arguments to the standard output
% 
% SYNOPSIS
%      echo [-n] [string ...]
% 
% DESCRIPTION
%      The echo utility writes any specified operands, separated by single blank
%      (` ') characters and followed by a newline (`\n') character, to the stan-
%      dard output.
% 
%      The following option is available:
% 
%      -n    Do not print the trailing newline character.  This may also be
%            achieved by appending `\c' to the end of the string, as is done by
%            iBCS2 compatible systems.  Note that this option as well as the
%            effect of `\c' are implementation-defined in IEEE Std 1003.1-2001
%            (``POSIX.1'') as amended by Cor. 1-2002.  Applications aiming for
%            maximum portability are strongly encouraged to use printf(1) to
%            suppress the newline character.
% 
%      Some shells may provide a builtin echo command which is similar or iden-
%      tical to this utility.  Most notably, the builtin echo in sh(1) does not
%      accept the -n option.  Consult the builtin(1) manual page.
% 
% EXIT STATUS
%      The echo utility exits 0 on success, and >0 if an error occurs.
% 
% SEE ALSO
%      builtin(1), csh(1), printf(1), sh(1)
% 
% STANDARDS
%      The echo utility conforms to IEEE Std 1003.1-2001 (``POSIX.1'') as
%      amended by Cor. 1-2002.
% 
% BSD                             April 12, 2003                             BSD
% 
% 
% 
% options = 
% 
%     '-n'
%     
% Note: cmd_help will first attempt to get help string from 'man', and if
% this does not work, using cmd -h.
%
% Created by Justin Theiss

% create tmp filename
tmpfile = tempname;
% get help using man command
[~, k] = evalc(['system(''man ' cmd ' >> ' tmpfile ''');']);
if ~k, % use man text
    txt = fileread(tmpfile);
else % try help arguments
    opts = {'h', 'help', '?'};
    for x = 1:numel(opts),
        if ispc, % pc switch
            swtch = '/'; 
        else % mac switch
            swtch = '-'; 
        end
        % eval cmd help
        cmdstr = sprintf('system(''%s %s%s'');', cmd, swtch, opts{x});
        txt{x} = evalc(cmdstr);
    end
    % get max txt
    [~,idx] = sort(cellfun('size', txt, 2));
    txt = txt{idx(end)};
end
% delete tmpfile
delete(tmpfile);
% if nargout for options as well
if nargout == 2, 
    if ispc, % pc
        options = regexp(txt,'\W/\w+','match');
    else % mac, etc.
        options = regexp(txt,'\W[-+]{1,2}\w+','match');
    end
    options = unique(regexprep(options,'[^-+/\w]',''));
end
end