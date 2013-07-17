function [x,fval,exitflag,info] = opti_bonmin(nlprob,x0)
%OPTI_BONMIN Solve a MINLP using BONMIN
%
%   [x,fval,exitflag,info] = opti_bonmin(nlprob,x0) solvers the MI nonlinear
%   program min f(x) subject to linear and nonlinear constraints using
%   BONMIN. nlprob is supplied in nl opti format (i.e. from convert(optiObj))
%   and x0 is the initial solution guess.
%
%   THIS IS A WRAPPER FOR BONMIN
%   See supplied Eclipse Public License

%   Copyright (C) 2011 Jonathan Currie (I2C2)

t = tic;
%Check required fields
if(~isfield(nlprob,'funcs') || ~isfield(nlprob,'options'))
    error('You must use convert(optiObj) or solve(optiObj) to generate a problem structure for this function');
end
%Ensure we have a starting guess
if(~exist('x0','var') || isempty(x0))
    if(isfield(nlprob,'x0') && ~isempty(nlprob.x0))
        x0 = nlprob.x0;
    else
        error('You must supply x0 to use bonmin!');
    end
end

% Run BONMIN build based on Cplex selection
if(isfield(nlprob.options.bonmin,'milp_solver') && strcmpi(nlprob.options.bonmin.milp_solver,'Cplex'))
    cplx = true;
    [x,output] = bonminCplex(x0,nlprob.funcs,nlprob.options);
else
    cplx = false;
    [x,output] = bonmin(x0,nlprob.funcs,nlprob.options);
end

%Collect Results
fval = nlprob.funcs.objective(x);
info.Iterations = output.iter;
info.Nodes = output.nodes;
info.AbsGap = abs(output.bestobj-fval);
info.RelGap = abs(output.bestobj-fval)/(1e-1 + abs(fval));
info.Time = toc(t);
%Default option if removed
if(~isfield(nlprob.options.bonmin,'algorithm'))
    nlprob.options.bonmin.algorithm = 'b-bb';
end

switch(nlprob.options.bonmin.algorithm)
    case 'b-bb'
        info.Algorithm = 'BONMIN: Branch & Bound using IPOPT & CBC';
    case 'b-oa'
        if(cplx)
            info.Algorithm = 'BONMIN: Outer Approximation using IPOPT & CPLEX';
        else
            info.Algorithm = 'BONMIN: Outer Approximation using IPOPT & CBC';
        end
    case 'b-qg'
        info.Algorithm = 'BONMIN: Quesada & Grossman Outer Approximation using IPOPT & CBC';
    case 'b-hyb'
        if(cplx)
            info.Algorithm = 'BONMIN: Hybrid Outer Approximation and Branch & Cut using IPOPT & CPLEX';
        else
            info.Algorithm = 'BONMIN: Hybrid Outer Approximation and Branch & Cut using IPOPT & CBC';
        end
    case 'b-ecp'
        info.Algorithm = 'BONMIN: Outer Approximation based on FilMINT using IPOPT & CBC';
    case 'b-ifp'
        if(cplx)
            info.Algorithm = 'BONMIN: Iterated Feasibility Pump using IPOPT & CPLEX';
        else
            info.Algorithm = 'BONMIN: Iterated Feasibility Pump using IPOPT & CBC';
        end
end

switch(output.status)
    case {0,2}
        info.Status = 'Optimal';
        exitflag = 1;
    case -1 %not sure if we have this one...
        info.Status = 'Exceeded Iterations';
        exitflag = 0;
    case 1
        info.Status = 'Infeasible';
        exitflag = -1;
    case 3
        info.Status = 'Unbounded or Infeasible';
        exitflag = -2;
    otherwise        
        info.Status = 'BONMIN Error';
        exitflag = -3;
end
        
