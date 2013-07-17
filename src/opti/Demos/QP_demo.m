%% OPTI Toolbox Quadratic Program Demo
%
% This file contains a number of QP problems and demonstrates how to 
% solve them using the OPTI Toolbox. You should read and complete
% Basic_demo.m & LP_demo.m BEFORE running the below examples.
%
%   Copyright (C) 2011 Jonathan Currie (I2C2)

%% Determing which Solver to Use
% OPTI Toolbox comes with a number of QP solvers, thus to determine which
% ones are available on your system you can type:

checkSolver('QP')

%% Problem 1
% This is a simple two decision variable QP which will use for the next 
% few examples

%Problem
H = [1 -1; -1 2];           %Objective Function (min 1/2x'Hx + f'x)
f = -[2 6]';
A = [1 1; -1 2; 2 1];       %Linear Inequality Constraints (Ax <= b)
b = [2; 2; 3];
lb = [0;0];                 %Bounds on x (lb <= x <= ub)    

%% Example 1 - Basic Setup
% Building an QP problem is very similar to an LP, except just add the
% H argument for the problem quadratic objective

Opt = opti('H',H,'f',f,'ineq',A,b,'lb',lb)

%% Example 1 - Solving the Problem
%Call solve to solve the problem

[x,fval,exitflag,info] = solve(Opt)   

%% Example 2 - Alternative Setup Strategies
% Naming of arguments, as well as pairing is flexible when using optiprob

Opt = opti('hess',H,'f',f,'ineq',A,b,'lb',lb); %hess = H

% OR
Opt = opti('H',H,'grad',f,'ineq',A,b,'lb',lb); %grad = f

%OR
Opt = opti('qp',H,f,'ineq',A,b,'lb',lb);

%% Example 3 - Plotting the Solution
% Several problem types have a default plot command available IF the
% problem contains two variables.

plot(Opt)

%% Problem 2
% An unconstrained QP (effectively solving -H\f)

%Problem
H = [1 -1; -1 2];
f = -[2 6]';

%% Example 4 - Solving an unconstrained QP

Opt = opti('hess',H,'grad',f);

[x,fval,exitflag,info] = solve(Opt)

%% Example 5 - Indefinite QP
% OPTI QP solvers only solve Positive Definite problems. However you can
% have a go with indefinite problems, but you may only get a local
% solution.

%Problem
H = [0 -2; -2 0];           %Objective Function (min 1/2x'Hx + f'x)
f = [0 0]';
lb = [-0.5;-0.5];           %Bounds on x (lb <= x <= ub)   
ub = [1;1];

% Options
opts = optiset('solver','clp');

% Create OPTI Object
Opt = opti('qp',H,f,'bounds',lb,ub,'options',opts)

% Solve the Indefinite QP
[x,f] = solve(Opt)

plot(Opt,2)
