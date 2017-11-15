import os
import numpy as np
import sys
import cStringIO
import re
import scipy.io as sio
import copy

def cell2strtable(celltable, delim='\t'):
    ''' convert a cell table into a string table that can be printed nicely

        Parameters:
        celltable - array-like, ndarray with rows and columns in desired order
        delim - str, delimter to combine columns of celltable
            [default = '\\t' (strictly 4 spaces)]

        Returns:
        strtable - str, string version of celltable that prints as table

        Example:
        celltable = np.array([['Column 1 Title','Column 2 Title',''],
        ['Row 2 Column 1 is longer...','Row 2 Column 2','Extra Column!']])
        delim='\t'
        strtable = cell2strtable(celltable, delim)
        print(strtable)
        Column 1 Title                 Column 2 Title
        Row 2 Column 1 is longer...    Row 2 Column 2    Extra Column!
    '''
    # change \t to 4 spaces
    if delim == '\t':
        delim = '    '
    # check that celltable is ndarray and object
    if type(celltable) != np.ndarray:
        celltable = np.array([celltable], dtype=np.object)
    elif celltable.dtype != np.object: # copy as np.object
        celltable = copy.deepcopy(celltable).astype(np.object)
    else: # copy as is
        celltable = copy.deepcopy(celltable)
    # if len(shape) == 1, reshape
    if len(celltable.shape)==1:
        celltable = np.reshape(celltable, (1,celltable.shape[0]))
    # convert all to string
    for i,x in enumerate(celltable.ravel()):
        celltable.ravel()[i] = np.str(x)
    # get max length in each column
    max_len = []
    for x in celltable.transpose():
        max_len.append(np.max([len(y) for y in x]))
    # pad each column with zeros
    for i,r in enumerate(celltable):
        for ii,c in enumerate(r):
            if len(c) < max_len[i]:
                spaces = ''.join([' ' for n in range(max_len[ii]-len(c))])
                celltable[i][ii] = c + spaces
    # join strings with delim
    strtable = []
    if len(celltable.shape) > 1:
        for r in range(celltable.shape[0]):
            strtable.append(delim.join(celltable[r]))
        strtable = '\n'.join(strtable)
    else:
        strtable = delim.join(celltable)
    return strtable

def py2mat(A, filename, variable):
    ''' load from or save to matlab format

        Parameters:
        A - object, object to save (set to None if loading from filename)
        filename - str, file to load from or save to
        variable - str, variable name to load or save

        Returns:
        A - object, object converted from file or converted to matlab format

        Example:
        A = {0: {'spm': {'temporal': {'st': {'nslices': {0: 28},
          'prefix': {0: u'a'},
          'refslice': {0: 1},
          'scans': {0: {0: u'<UNDEFINED>'}},
          'so': {0: 1, 1: 3, 2: 5, 3: 7, 4: 9, 5: 11, 6: 13, 7: 15, 8: 17,
           9: 19, 10: 21, 11: 23, 12: 25, 13: 27, 14: 2, 15: 4, 16: 6,
           17: 8, 18: 10, 19: 12, 20: 14, 21: 16, 22: 18, 23: 20, 24: 22,
           25: 24, 26: 26, 27: 28},
          'ta': {0: 1.9285714285714286},
          'tr': {0: 2}}}}}}

    '''
    # load from filename
    if A==None:
        # init out
        out = np.array([], np.object)
        # load filename as matlab dtype
        A = sio.loadmat(filename, mat_dtype=True)
        A = A[variable]
        # get substructs of A
        S0 = struct2sub(A)
        # for each level, get dtype
        S1 = np.empty(len(S0), dtype=np.object).tolist()
        cell = np.zeros(len(S0), dtype=np.bool).tolist()
        for i,S_ in enumerate(S0):
            S1[i] = []
            cell[i] = []
            for n in range(1, len(S_)):
                A_ = subsref(A, S_[:n])
                # cell index
                if A_.dtype == np.object:
                    # set single index
                    if A_.ndim == 1:
                        S1[i].append(S_[n])
                        cell[i].append(copy.deepcopy(S1[i]))
                    # set cell array
                    elif A_.shape[0] > 1:
                        S1[i].append(S_[n])
                        cell[i].append(copy.deepcopy(S1[i]))
                # field name
                elif A_.dtype.names != None:
                    # set fieldname
                    if A_.ndim == 0:
                        S1[i].append(A_.dtype.names[S_[n]])
                    # set noncell array
                    elif A_.shape[0] > 1:
                        S1[i].append(S_[n])
                elif A_.ndim > 0 and A_.shape[0] > 1:
                    S1[i].append(S_[n])
        # set values
        for S0_, S1_ in zip(S0, S1):
            item = subsref(A, S0_)
            out = subsasgn(out, S1_, item, list)
        # set cells as numpy arrays
        for C_ in cell:
            # first cell is implied
            for c in C_[1:]:
                out = subsasgn(out, c, np.array([subsref(out, c)], np.object))
    else: # copy A
        A = copy.deepcopy(A)
        # get substructs for A at each level
        S0 = struct2sub(A, dict_out=True)
        # set additional dimension for matlab
        for k in S0.keys():
            for S_ in S0[k]:
                A_ = subsref(A, S_)
                # if list without following or preceding list, set extra dim
                if type(A_)==list and type(subsref(A, S_[:-1]))!=list and \
                    type(A_[0])!=list:
                    A = subsasgn(A, S_, [A_])
                    S0 = struct2sub(A, dict_out=True)
        # set dicts as arrays with dtype
        l = S0.keys()
        l.reverse()
        for k in l:
            for S_ in S0[k]:
                A_ = subsref(A, S_)
                # set dict to array with keys as dtype
                if type(A_) == dict:
                    A = subsasgn(A, S_, np.array([tuple(A_.values())],
                        np.dtype([(k, np.object) for k in A_.keys()])))
                    S0 = struct2sub(A, dict_out=True)
        # set out to dict using variable
        out = {variable: A}
        # save mat
        sio.savemat(filename, out)
    return out

def subsref(A, S):
    ''' return value from A using references in S

        Parameters:
        A - object, object to return value from
        S - list, indices/fields to reference to obtain value from A (see Example)

        Returns:
        value - any, value to index from A using S

        Example:
        A = {0: {'test': [9,8,7]}}
        S = [0, 'test', 1]
        value = subsref(A, S)
        value =
        8
    '''
    # copy S
    S = list(S)
    # copy A
    value = copy.deepcopy(A)
    # for each substruct, get value
    for S_ in S:
        if type(S_) == str and re.match('.*:.*', S_) != None:
            value = eval('value[{S_}]'.format(S_=S_))
        else:
            value = value[S_]
    return value

def subsasgn(A, S, C, append_type=None):
    ''' set value in A using reference in S

        Parameters:
        A - object, object to set value
        S - list, indices/fields to reference when setting value
        C - any, value to set in A at reference S
        append_type - type, type of iterable to append if needed (e.g., list)
            [default is None, sets to type(A)]

        Returns:
        A - object, updated object with value set at reference S

        Example:
        A = {0: {'spm': {'util': {'disp': {'data': '<UNDEFINED>'}}}}}
        S = [0, 'spm', 'util', 'disp', 'data']
        C = './mri/anatomical.nii'
        subsasgn(A, S, C)
        A =
        {0: {'spm': {'util': {'disp': {'data': './mri/anatomical.nii'}}}}}

        Note: Only tested for dict, list, and ndarray. If S == [], A is set to C
    '''
    # copy A
    A = copy.deepcopy(A)
    value = A
    # set default for setting new index
    if append_type == None:
        def_val = type(A)([])
    else:
        def_val = append_type([])
    # ensure def_val has ndim > 0
    if type(def_val).__module__ == np.__name__ and def_val.ndim == 0:
        def_val = np.array([None], dtype=A.dtype)
    # for each level in S, index value
    for i,S_ in enumerate(S):
        # add new key to dict
        if type(value) == dict and S_ not in value.keys():
            value[S_] = copy.deepcopy(def_val)
        # set value to dict and add key with new value type(A)
        elif type(value) != dict and type(S_) == str:
            value = {}
            value[S_] = copy.deepcopy(def_val)
        # append list
        elif type(value) == list and S_ >= len(value):
            for _ in range(S_ - len(value) + 1):
                value.append(copy.deepcopy(def_val))
        # append ndarray with None
        elif type(value).__module__ == np.__name__:
            if value.ndim == 0:
                value = np.array([value])
            if S_ >= len(value):
                for _ in range(S_ - len(value) + 1):
                    value = np.append(value, None)
        # if None, set as list
        elif value == None:
            value = []
            for _ in range(S_ - len(value) + 1):
                value.append([])
        # set value to A at current substruct
        if i > 0 and len(S[:i]) > 0:
            exec('A' + sub2str(S[:i]) + '= value')
        else:
            A = value
        # evaluate : string
        if type(S_) == str and re.match('.*:.*', S_) != None:
            value = eval('value[{S_}]'.format(S_=S_))
        else: # index value using S_
            value = value[S_]
    # set complete reference to C
    if len(S) > 0:
        exec('A' + sub2str(S) + '= C')
    else: # simple set
        A = C
    return A

def sub2str(S):
    ''' convert a "substruct" to a "string representation" or vice versa

    Parameters:
    S - list or str, substruct/string representation to convert

    Returns:
    S - list or str, converted substruct/string representation

    Example 1:
    S = [0, 'field1', 0, 'field2', 1]
    str_rep = sub2str(S)
    str_rep =
    '[0]["field1"][0]["field2"][1]'

    Example 2:
    str_rep = '["field1"]["field2"][4]'
    S = sub2str(str_rep)
    S =
    ['field1', 'field2', 4]
    '''
    # copy S
    if type(S) != str:
        S = list(S)
    # init output
    out = []
    # if str, output array
    if type(S) == str:
        S = re.split('[\[\]]', S)
        S = [S for S in S if S != '']
        for S_ in S:
            if S_.isdigit():
                out.append(int(S_))
            else:
                out.append(re.sub('"', '', S_))
    else: # if array, output str
        if not np.iterable(S):
            S = [S,]
        for S_ in S:
            if type(S_) == str:
                out.append('"' + S_ + '"')
            else:
                out.append(str(S_))
        out = '[' + ']['.join(out) + ']'
    return out

def struct2sub(A, r=np.inf, dict_out=False):
    ''' return all "substructs" from A through levels r

    Parameters:
    A - object, object to return substructs from
    r - number, number of levels to search when obtaining substructs. Returns
        substruct lists with maximum length of r + 1 (0 is first level)
        [default is np.inf, i.e. all levels of A]
    dict_out - bool, return each level list of substruct as dict with keys
        corresponding to levels
        [default is False]

    Returns:
    S - list, list of substructs for each value in A through levels r

    Example:
    A = {'test': {0: 12, 1: '2'}, 'test2': 3}
    r = 1
    S =
    [['test', 0], ['test', 1], ['test2']]
    '''
    # copy A
    A = copy.deepcopy(A)
    # get substruct based on type
    S = {0: []}
    if type(A) == dict:
        S[0] = [[S_] for S_ in A.keys()]
    elif type(A) == list or type(A) == tuple:
        S[0] = [[S_] for S_ in range(len(A))]
    elif type(A).__module__ == np.__name__:
        if A.ndim > 0 or type(A) == np.void:
            A = list(A)
            S[0] = [[S_] for S_ in range(len(A))]
    # ensure list is not empty
    if len(S[0]) == 0:
        S[0] = [[],]
    # # if r is zero, return
    if r == 0:
        return S[0]
    # for each level, get struct2sub and append to previous
    r_ = 0
    while r_ < r:
        S[r_+1] = []
        for S0 in S[r_]:
            for S1 in struct2sub(subsref(A, S0), 0):
                S[r_+1].append(S0 + S1)
            if len(struct2sub(subsref(A, S0), 0)) == 0:
                S[r_+1].append(S[r_])
        if S[r_] == S[r_+1]:
            S.pop(r_+1, None)
            break
        else:
            r_ += 1
    if dict_out: # return dict
        return S
    else: # return S at level r_
        return S[r_]

def pebl_getfield(A, S=None, R=None, expr=None, fun=None, r=np.inf):
    ''' get values from object, A, using substructs or string representations

        Parameters:
        A - object, object to return values from
        Options:
        S - list, substruct to get value from A
            [defualt is None]
        R - list or str, string representation to get value from A
            [default is None]
        expr - str, expression to search string representations to get value
            from A
            [default is None]
        fun - dict, dict containing function to search for values within A. keys
            within the dict should contain 'fun', and integers corresponding to
            argument index (see Example 2). Each C will be input as the argument
            not contained in the dict keys (i.e. at index 0 for Example 2).
            [default is None]
        r - int, number of level to search within A (each level is field or
            index reference)
            [default is np.inf]

        Returns:
        C - list, values returned from A
            (i.e. C[0] == subsref(A, S[0]) or eval('A' + R[0]))
        S - list, substructs used to return values from A
        R - list, string representations used to return values from A

        Example 1:
        A = {0: {'spm': {'util': {'disp': {'data': '<UNDEFINED>'}}}}}
        expr = '.*\["disp"]'
        C, S, R = pebl_getfield(A, expr=expr)
        C =
        array([{'data': '<UNDEFINED>'}], dtype=object)
        S =
        [[0, 'spm', 'util', 'disp']]
        R =
        ['[0]["spm"]["util"]["disp"]']

        Example 2:
        A = {'test1': {0: 3}, 'test2': [2,3,4,5], 'test3': []}
        fun = {'fun': np.equal, 1: 3}
        C, S, R = pebl_getfield(A, fun=fun)
        C =
        array([3, 3], dtype=object)
        S =
        [['test1', 0], ['test2', 1]]
        R =
        ['["test1"][0]', '["test2"][1]']
    '''
    # if S exists, get copy
    if S != None:
        if type(S)!=list or type(S[0])!=list:
            S = [S,]
        else:
            S = list(S)
    else: # get substructs of A
        S = []
        if not np.iterable(r):
            r = [r,]
        for rr in r:
            S = S + struct2sub(A, rr)
    # if R exists, update S
    if R != None:
        if not np.iterable(R):
            R = [R,]
        else:
            R = list(R)
        S = []
        for R_ in R:
            S.append(sub2str(R_))
    else: # if R doesnt exist, set from S
        R = []
        for S_ in S:
            R.append(sub2str(S_))
    # find R using regex
    if expr != None:
        tmp = list(R)
        R = []
        # copy expr
        if type(expr) == str:
            expr = [expr,]
        else:
            expr = list(expr)
        for e in expr:
            m = [re.findall(e, R_) for R_ in tmp]
            m = np.unique([m[0] for m in m if len(m) > 0])
            R = np.append(R, m)
        R = np.unique(R).tolist()
    # update S
    S = []
    for R_ in R:
        S.append(sub2str(R_))
    # use subsref to get values
    C = []
    for S_ in S:
        C.append(subsref(A, S_))
    # search using function
    if fun != None:
        # copy fun
        if type(fun) != dict:
            fun = {'fun': fun}
        else:
            fun = dict(fun)
        # set fnd array of false
        fnd = np.zeros(len(C), dtype=np.bool)
        # get key positions for function call
        key_ns = [k for k in fun.keys() if type(k) == int]
        key_rng = range(np.max(key_ns)+1)
        c_idx = [k for k in key_rng if k not in key_ns]
        if len(c_idx) == 0:
            c_idx = np.max(key_ns)+1
        else:
            c_idx = c_idx[0]
        # for each C_ evalutate function
        for i, C_ in enumerate(C):
            # set c_idx to C_
            fun[c_idx] = C_
            # set args for input
            args = [fun[k] for k in key_rng]
            # evaluate function
            tmp = fun['fun'](*args)
            if tmp == NotImplemented:
                fnd[i] = False
            else:
                fnd[i] = tmp
        # set to true indices
        C = np.array(C, dtype=np.object)[fnd].tolist()
        S = np.array(S, dtype=np.object)[fnd].tolist()
        R = np.array(R, dtype=np.object)[fnd].tolist()
    # return C, S, R
    return C, S, R

def pebl_setfield(A, C, S=None, R=None, expr=None, fun=None, r=np.inf):
    ''' set values in object, A, using substructs or string representations

        Parameters:
        A - object, object to set values
        C - list, list of values to set in A
        S - list, substructs referencing location to set values in A
            [default is None]
        R - list, string representations referencing location to set values in A
            [default is None]
        expr - str, expression to search R in order to set values in A
            [defualt is None]
        fun - dict, dict to find locations in A to set values
            [defualt is None]
        r - int, number of levels in A to search if S or R are not set directly
            [default is np.inf]

        Returns:
        A - object, updated object with values set

        Note:
        See pebl_getfield for further description on Parameters.

        Example:
        A = {0: {'test1': [1,2,3]}}
        S = [0, 'test1', -1]
        C = []
    '''
    # init C
    if type(C) != list: # make iterable
        C = [C,]
    else: # copy
        C = list(C)
    # if no S and no R, set from A using pebl_getfield
    if S==None and R==None:
        _, S, R = pebl_getfield(A, expr=expr, fun=fun, r=r)
    # check for S and R separately
    if R==None:
        R = []
    elif type(R) == str: # set as iterable
        R = [R,]
    else: # copy
        R = list(R)
    if S==None:
        S = []
        for R_ in R:
            S.append(sub2str(R_))
    elif type(S)!=list or type(S[0])!=list: # make iterable
        S = [S,]
    else: # copy
        S = list(S)
    # set C based on S
    if type(C) != list or len(C)==1 or len(S) == 1:
        C = np.repeat([C], len(S)).tolist()
    elif len(C) != len(S):
        C = C[:np.min([len(C),len(S)])]
        S = S[:np.min([len(C),len(S)])]
    # init R for output
    R = []
    for C_, S_ in zip(C, S):
        # update R
        R.append(sub2str(S_))
        # set A
        A = subsasgn(A, S_, C_)
    return A

def pebl_search(folder, expr, ftype, n_levels=np.inf, verbose=False):
    ''' search a folder, subfolders, and files for expr

        Parameters:
        folder - str, folder to begin search
        expr - str, expression to search within folders/files
        ftype - str, file type to narrow search (or 'dir' to search folders)
        n_levels - int, number of directory levels to search
            [default is np.inf]
        verbose - bool, print folder/file currrently being searched
            [default is False]

        Returns:
        files - list, fullpath files that contained expression in name or text

        Example 1:
        folder = os.curdir
        expr = 'utils.*'
        ftype = 'dir'
        files = pebl_search(folder, expr, ftype)
        files =
        ['/pebl/pebl/functions/utils.py',
        '/pebl/pebl/functions/utils.pyc']

        Example 2:
        folder = os.curdir
        expr = 'def pebl_search'
        ftype = '.*\.py$'
        files = pebl_search(folder, expr, ftype)
        files =
        ['/pebl/pebl/functions/utils.py']
    '''
    # init files output
    files = np.array([])
    # set folder to fullpath
    folder = os.path.abspath(folder)
    # get names of files/folders in folder
    names = os.listdir(folder)
    # get indices of directories
    dir_tf = np.array([os.path.isdir(os.path.join(folder,n)) for n in names],
        dtype=np.bool)
    # regex for ftype matches
    matches = [re.match(ftype, n) for n in names]
    ftype_tf = np.array([m != None for m in matches], dtype=np.bool)
    # find files to search
    file_tf = np.invert(dir_tf) * ftype_tf
    # if dir, search files for expr
    if ftype == 'dir':
        fnd = np.array([re.match(expr, n) != None for n in names], dtype=np.bool)
        for i in np.where(fnd)[0]:
            files = np.append(files, os.path.join(folder,names[i]))
    else: # for each file, search text for expr
        for i in np.where(file_tf)[0]:
            if verbose:
                print('Searching {name}'.format(name=names[i]))
            with open(os.path.join(folder,names[i]), 'r') as f:
                txt = f.read()
            if len(re.findall(expr, txt)) > 0:
                files = np.append(files, os.path.join(folder,names[i]))
    # search additional levels
    if n_levels > 0 and np.any(dir_tf):
        for i in np.where(dir_tf)[0]:
            if verbose:
                print('Searching {dir}'.format(dir=names[i]))
            files = np.append(files, pebl_search(os.path.join(folder,names[i]),
                expr, ftype, n_levels=n_levels-1, verbose=verbose))
    # return files as list
    return files.tolist()
