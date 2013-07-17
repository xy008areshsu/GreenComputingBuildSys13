function [x,fval,exitflag,info] = opti_scipasl(file,opts)
%OPTI_SCIPASL Solve a NLP/MINLP using SCIP to Global Optimality using the 
%             AMPL Interface
%
%   min fun(x)                 subject to:     rl <= A*x <= ru
%    x                                         lb <= x <= ub
%                                              cl <= nlcon(x) <= cu
%                                              for i = 1..n: xi in Z
%                                              for j = 1..m: xj in {0,1} [i!=j]
%
%   Full Calling Form:
%     [x,fval,exitflag,info] = opti_scipasl(file,opts)
%
%   x = opti_scipasl(file) solves the AMPL model supplied as 'file'. This
%   must be an AMPL .nl model.
%
%   x = opti_scipasl(file,opts) uses opts to pass optiset options to the
%   solver.
%
%   [x,fval,exitflag,info] = opti_scipasl(...) returns the objective value at
%   the solution, together with the solver exitflag, and an information
%   structure.
%
%   THIS IS A WRAPPER FOR SCIP USING THE MEX INTERFACE
%   See supplied ZIB Academic License

%   Copyright (C) 2012/2013 Jonathan Currie (I2C2)

t = tic;

% Handle missing arguments
if nargin < 2, opts = optiset('warnings','off'); end
if nargin < 1, error('You must supply at least one argument to opti_scipasl'); end

%Setup Printing
opts.display = dispLevel(opts.display);

%Run SCIP
[x,fval,exitflag,stats] = scip(file,opts);

%Assign Outputs
info.BBNodes = stats.BBnodes;
info.BBGap = stats.BBgap;
info.Time = toc(t);
info.Algorithm = 'SCIP: Spatial Branch and Bound using IPOPT and SoPlex [AMPL Interface]';

switch(exitflag)
    case 10
        info.Status = 'Globally Optimal';
        exitflag = 1;
    case {2,3,4,5,6,7,8}
        info.Status = 'Exceeded Iterations / Time / Nodes';
        exitflag = 0;
    case 11
        info.Status = 'Infeasible';
        exitflag = -1;
    case {12,13}
        info.Status = 'Unbounded or Infeasible';
        exitflag = -2;
    case 1
        info.Status = 'User Exited';
        exitflag = -5;
    otherwise
        info.Status = [];
end

function  print_level = dispLevel(lev)
%Return CLP compatible display level
switch(lower(lev))
    case'off'
        print_level = 0;
    case 'iter'
        print_level = 4;
    case 'final'
        print_level = 3;
end