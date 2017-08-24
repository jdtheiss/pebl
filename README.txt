# pebl
pipeline editor between languages
  -version 3-

MIT License

Copyright (c) 2017 Justin Theiss

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Introduction
pebl allows users to create pipelines for automated analysis using different
languages. Outputs can be passed from one command to the next e.g. from
a unix command to a matlab command to a python command. pebl also allows use
of the matlabbatch modules as well.

Installation
pebl is available for download and is updated on github
(https://github.com/jdtheiss/pebl). After you have downloaded the zipped file
folder and moved it to your desired location, go into the “pebl/functions”
folder and run pebl('setup') from the command prompt. In addition to setting the
"functions" directory to your matlab path, the 'setup' command will also run
tests on all of the pebl functions. If any errors are thrown ensure you are
using the most up-to-date version. Assuming all tests pass, you may begin
using pebl by its graphical user interface (GUI) or from the command prompt.
To get interactive examples on how to use pebl, see pebl_demo.
