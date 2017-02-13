# sawa
subject array and wrapper automation
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

IntroductionThe main components of sawa are the subject array and wrapper automationfunctionalities. The subject array consists of a structural array that cancontain subject-specific information to be utilized in wrapping functions,especially useful for maintaining information for separate studies. Meanwhile,wrapper automation allows users to create complex pipelines withunix/C/matlab/batch utility commands by passing variables from one function tothe next. At its simplest, sawa is an organizational tool that can maintainup-to-date information as well as record inputs/outputs for analyses. However,sawa is built to feed information from the subject array to a pipeline ofvarious types of functions. As such, sawa provides users the ability to performcomplex analyses using subject data and pass variables between SPM, AFNI, FSL,etc., or any unix/C/matlab commands.With wrapper automation for batch utility, command line, and matlab functions,users can build simple pipelines for repeat analyses and combine batch, matlab,or command line functions. The batch editor directly uses the matlab batchutility system (https://sourceforge.net/p/matlabbatch/wiki/Home/), which allowsusers to directly choose variables that will be filled by the subject array orother functions/variables. When using a command-line function, sawaautomatically displays help information and provides potential command switches.When using matlab functions, sawa again displays help information and allowsusers to select inputs. Where applicable, users are able to select outputs toreturn from the function that can then be entered to a later function. Theinputs and outputs for each iteration and function are then printed when theuser runs the pipeline.Installationsawa is available for download and is updated on github(https://github.com/jdtheiss/sawa). After you have downloaded the zipped filefolder and moved it to your desired location, go into the “sawa/main/functions”folder and run sawa('setup') from the command prompt. In addition to setting the"functions" directory to your matlab path, the 'setup' command will also runtests on all of the sawa functions. If any errors are thrown ensure you areusing the most up-to-date version. Assuming all tests pass, you may beginusing sawa using its graphical user interface (GUI) or from the command prompt.