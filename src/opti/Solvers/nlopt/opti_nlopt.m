function [x,fval,exitflag,info] = opti_nlopt(nlprob,x0)
%OPTI_NLOPT Solve a NLP using NLOPT
%
%   [x,fval,exitflag,info] = opti_nlopt(nlprob,x0) solvers the nonlinear
%   program min f(x) subject to linear and nonlinear constraints using
%   NLOPT. nlprob is supplied in nl opti format and x0 is the initial solution guess.
%
%   THIS IS A WRAPPER FOR NLOPT
%   See supplied Lesser GNU Public License

%   Copyright (C) 2011 Jonathan Currie (I2C2)

t = tic;

%Check required fields
if(~isfield(nlprob,'options') || ~isfield(nlprob.options,'algorithm'))
    error('You must use convert(optiObj) or solve(optiObj) to generate a problem structure for this function');
end
%Ensure we have a starting guess
if(~exist('x0','var') || isempty(x0))
    if(isfield(nlprob,'x0') && ~isempty(nlprob.x0))
        x0 = nlprob.x0;
    else
        error('You must supply x0 to use nlopt!');
    end
end

% Run NLOPT
[x, fval, retcode, fevals] = nlopt(nlprob,x0);

%Collect Results
info.FuncEvals = fevals;
info.Time = toc(t);
if(nlprob.alg_prop.subopt)
    info.Algorithm = ['NLOPT: ' nloptSolver(nlprob.options.algorithm) ' with ' nloptSolver(nlprob.options.local_optimizer.algorithm)];
else
    info.Algorithm = ['NLOPT: ' nloptSolver(nlprob.options.algorithm)];
end

switch(retcode)
    case {1,2,3,4}
        info.Status = 'Optimal';
        exitflag = 1;
    case 5
        info.Status = 'Exceeded Function Evaluations';
        exitflag = 0;
    case 6
        info.Status = 'Exceeded Maximum Time';
        exitflag = 0;
    case -1
        info.Status = 'Infeasible';
        exitflag = -1;
    case -2
        info.Status = 'Incorrect Arguments';
        exitflag = -2;
    case -5
        info.Status = 'User Exit';
        exitflag = -5;
    otherwise        
        info.Status = 'NLOPT Error';
        exitflag = -3;
end
