function [x,fval,exitflag,info,Opt] = opti_quadprog(H,f,A,b,Aeq,beq,lb,ub,opts)
%OPTI_QUADPROG Solve a QP using an OPTI QP Solver (Matlab Overload)
%
%   [x,fval,exitflag,info] = opti_quadprog(H,f,A,b,Aeq,beq,lb,ub) solves 
%   the quadratic program min 1/2x'Hx + f'x where A,b are the inequality 
%   constraints, Aeq,beq are the equality constraints and lb,ub are the 
%   bounds.
%
%   [x,fval,exitflag,info] = opti_quadprog(H,...,ub,opts) allows the user 
%   to specify optiset options. This includes specifying a solver via the
%   'solver' field of optiset.
%
%   [x,...,info,Opt] = opti_quadprog(H,...) returns the internally built
%   OPTI object.

%   Copyright (C) 2011 Jonathan Currie (I2C2)


% Handle missing arguments
if nargin < 9, opts = optiset; end 
if nargin < 8, ub = []; end
if nargin < 7, lb = []; end
if nargin < 6, beq = []; end
if nargin < 5, Aeq = []; end
if nargin < 4, error('You must supply at least 4 arguments to opti_quadprog'); end

%Build OPTI Object
Opt = opti('qp',H,f,'ineq',A,b,'eq',Aeq,beq,'bounds',lb,ub,'options',opts);

%Solve
[x,fval,exitflag,info] = solve(Opt);
