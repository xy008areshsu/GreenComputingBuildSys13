%% MKL Numerical Jacobian Install for OPTI Toolbox
% Supplied binaries are built from MKL 10.3 Release 11

%   Copyright (C) 2011 Jonathan Currie (I2C2)

% This file will help you compile the Intel Math Kernel Library (MKL) 
% djacobi function for use with MATLAB. NOTE you must NOT link the threaded
% MKL libraries as the MATLAB callback function is not thread safe!

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010
% - Intel Math Kernel Library 10.3 

% To recompile you will need to get / do the following:

% 1) Get and Install Intel MKL
% http://software.intel.com/en-us/articles/intel-mkl/

% 2) MKL JAC MEX Interface
% The MKL JAC MEX Interface is a simple MEX interface I wrote to use this
% function and is supplied in the Utilities\NumDiff folder.

% 6) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the MKL JAC MEX file. Once you have completed all 
% the above steps, simply run this file to compile! You MUST BE in the 
% base directory of OPTI!

clear mklJac

% Modify below function if it cannot find Intel MKL on your system.
mkl_link = opti_FindMKL('seq'); %NOTE sequential only build!

fprintf('\n------------------------------------------------\n');
fprintf('MKL JAC MEX FILE INSTALL\n\n');

%Get MKL Includes & MKL Libraries (for DJACOBI)
post = mkl_link;

%CD to Source Directory
cdir = cd;
cd 'Utilities/Differentiation/Numerical/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims mklJac.c';
try
    eval([pre post])
    movefile(['mklJac.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:mkljac','Error Compiling MKL JAC!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');
