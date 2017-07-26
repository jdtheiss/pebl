function str = genstr(obj, split)
% str = genstr(obj, split)
% Generate a string that can be evaluated to create object
%
% Inputs:
% obj - any object (e.g., char, cell, number, etc.)
% split (optional) - regexp by which to split string into a single
% column (e.g., ',' or '[,;]')
%
% Outputs:
% str - a string representation of obj that can be evaluated to create obj
%
% Example 1: generate string representation of cell array
% A = {{'test',1}; {'test2', 2}};
% str = genstr(A)
%
% str =
% 
% [{{'test', [1]}}; {{'test2', [2]}}]
% 
% Example 2: generate string representation of structure array
% A = struct('test',{1,2}, 'test2', {'ex1', ex2'});
% str = genstr(A)
%
% str =
% 
% struct('test', {[1], [2]}, 'test2', {'ex1', 'ex2'})
% 
% Example 3: generate string representation of array with 4 dimensions
% A = cat(4, 1, nan, 2, 3, uint8(4));
% str = genstr(A)
%
% str =
% 
% cat(4, uint8([1]), uint8([0]), uint8([2]), uint8([3]), uint8([4]))
% 
% Example 4: generate string representation of Simulink.NumericType
% A = uint(2);
% str = genstr(A, '([^,]+,){4}')
% 
% str =
% 
% pebl_setfield(Simulink.NumericType, 'R', {'.DataTypeMode', '.Signedness',...
%  '.SignednessBool', '.WordLength', '.FixedExponent', '.FractionLength',...
%  '.Slope', '.SlopeAdjustmentFactor', '.Bias', '.DataTypeOverride',...
%  '.IsAlias', '.Description', '.DataScope', '.HeaderFile'},...
%  'C', {'Fixed-point: binary point scaling', 'Unsigned', [false],...
%  [2], [0], [0], [1],...
%  [1], [0], 'Inherit', [false],...
%  '', 'Auto', ''})
% 
% Note: if the class is an object that is not readily known, genstr will
% attempt return the string beginning with 'pebl_setfield(' in order to
% allow multiple fields to be set upon evaluation (as in Example 4). 
% Also note, that exact number may differ due to rounding errors.
%
% Created by Justin Theiss

% if number of rows > 1, use ; to separate each row
if numel(size(obj)) == 2 && size(obj, 1) > 1,
    for x = 1:size(obj,1),
        str{x} = genstr(obj(x,:));
    end
    str = sprintf('%s; ', str{:});
    str = str(1:end-2);
    str = ['[', str, ']'];
% if number of dimensions > 2, use cat
elseif numel(size(obj)) > 2,
    idx = repmat(':,', 1, numel(size(obj)) - 1);
    for x = 1:size(obj, numel(size(obj))),
        str{x} = genstr(eval(['obj(', idx, num2str(x), ')']));
    end
    str = sprintf('%s, ', str{:});
    str = str(1:end-2);
    str = sprintf('cat(%d, %s)', numel(size(obj)), str);
% if multiple graphics
elseif numel(obj) > 1 && all(isgraphics(obj)),
    for x = 1:numel(obj),
        str{x} = genstr(obj(x));
    end
    str = sprintf('%s, ', str{:});
    str = str(1:end-2);
    str = ['[', str, ']'];
else % switch class
    switch class(obj),
        case {'double','single'} % numeric arrays
            str = sprintf('%0.5g, ', obj);
            str = str(1:end-2);
            str = ['[', str, ']'];
        case 'logical' % logical arrays
            for x = 1:numel(obj),
                if obj(x), str{x} = 'true'; else str{x} = 'false'; end;
            end
            str = sprintf('%s, ', str{:});
            str = str(1:end-2);
            str = ['[', str, ']'];
        case 'char' % strings
            str = sprintf('''%s''', obj);
        case 'cell' % cell arrays
            str = cellfun(@(x){genstr(x)}, obj);
            if isempty(str), str = {''}; end;
            str = sprintf('%s, ', str{:});
            str = str(1:end-2);
            str = ['{', str, '}'];
        case 'struct' % structural arrays
            flds = fieldnames(obj);
            str(1:2:numel(flds)*2) = flds;
            for x = 1:2:numel(str),
                str{x+1} = genstr({obj.(str{x})});
                str{x} = genstr(str{x});
            end
            str = sprintf('%s, ', str{:});
            str = str(1:end-2);
            str = ['struct(', str, ')'];
        case 'function_handle' % function handles
            str = sprintf('@%s', func2str(obj));
            str = regexprep(str, '^@@', '@');
        case {'int8','uint8','int16','uint16','int32','uint32','int64','uint64'} % integers
            str = sprintf('%s(%s)', class(obj), genstr(double(obj)));
        otherwise % otherwise, class(obj)
            try % attempt to get fieldnames
                if isgraphics(obj), % if graphics
                    flds = fieldnames(set(obj));
                    flds(strcmp(flds,'Parent')) = [];
                    flds(strcmp(flds,'Children')) = [];
                else % otherwise get normal fieldnames
                    flds = fieldnames(obj); 
                end
                f = true; 
            catch % if failes, set f to false
                f = false;
            end
            if f, % if fieldnames, create as struct
                if size(flds,1) > 1, flds = flds'; end;
                % get number of indices
                n = numel(obj); R = {}; C = {}; 
                for x = 1:numel(flds), 
                    % get values at obj field
                    C = cat(2, C, {obj.(flds{x})});
                    % create field with appropriate indices
                    R = cat(2, R, strcat('(', arrayfun(@(x){num2str(x)},1:n), ').', flds{x}));
                end
                str = sprintf('pebl_setfield(%s, ''R'', %s, ''C'', %s)',...
                    class(obj), genstr(R), genstr(C));
            else % get string as details(obj)
                str = evalc('details(obj)');
                str = regexprep(str,{'^\s+','\s+$'},'');
                str = sprintf('%s(%s)', class(obj), str);
            end
    end
end
% split into column using split
if exist('split','var'),
    str = regexprep(str, split, '$0...\n');
end
end