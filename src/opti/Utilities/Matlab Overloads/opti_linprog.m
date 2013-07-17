function [x,fval,exitflag,info,Opt] = opti_linprog(f,A,b,Aeq,beq,lb,ub,opts)
%OPTI_LINPROG Solve a LP using an OPTI LP Solver (Matlab Overload)
%
%   [x,fval,exitflag,info] = opti_linprog(f,A,b,Aeq,beq,lb,ub) solves the 
%   linear program min f'x where A,b are the inequality constraints, 
%   Aeq,beq are the equality constraints and lb,ub are the bounds.
%
%   [x,fval,exitflag,info] = opti_linprog(f,...,ub,opts) allows the user to
%   specify optiset options. This includes specifying a solver via the
%   'solver' field of optiset.
%
%   [x,...,info,Opt] = opti_linprog(f,...) returns the internally built
%   OPTI object.

%   Copyright (C) 2011 Jonathan Currie (I2C2)


% Handle missing arguments
if nargin < 8, opts = optiset; end 
if nargin < 7, ub = []; end
if nargin < 6, lb = []; end
if nargin < 5, beq = []; end
if nargin < 4, Aeq = []; end
if nargin < 3, error('You must supply at least 3 arguments to opti_linprog'); end

%Build OPTI Object
Opt = opti('f',f,'ineq',A,b,'eq',Aeq,beq,'bounds',lb,ub,'options',opts);

%Solve
[x,fval,exitflag,info] = solve(Opt);
