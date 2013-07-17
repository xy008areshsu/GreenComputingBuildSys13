%% ALL NONLINEAR VERSION
clc
clear
% Objective & Gradient
 fun = @(x) (1-x(1))^2 + 100 *(x(2)-x(1)^2)^2;
 grad = @(x)[2*x(1)-400*x(1)*(x(2)-x(1)^2)-2,200*x(2)-200*x(1)^2];
 
 % Constraints
A = [-1 1; 1 1];
rl = [-Inf;5];
ru = [-1;5];
lb = [0;0]; ub = [4;4];

% Nonlinear Constraint, Jacobian & Structure
 nlcon = @(x) A*x;
 nljac = @(x) sparse(A);
 jacstr = @() sparse(A~=0);        

% Starting Guess
 x0 = [2;2];

% Build Function Structure
 funcs.objective = fun;
 funcs.gradient = grad;
 funcs.constraints = nlcon;
 funcs.jacobian = nljac;
 funcs.jacobianstructure = jacstr;

% Build Options Structure
 opts.lb = lb;
 opts.ub = ub;
 opts.cl = rl;
 opts.cu = ru;
 opts.ipopt.hessian_approximation = 'limited-memory';

% Call IPOPT
[x,output] = ipopt(x0,funcs,opts)


%% ALL LINEAR VERSION
clc
clear all
% Objective & Gradient
 fun = @(x) (1-x(1))^2 + 100 *(x(2)-x(1)^2)^2;
 grad = @(x)[2*x(1)-400*x(1)*(x(2)-x(1)^2)-2,200*x(2)-200*x(1)^2];
 
 % Constraints
A = [-1 1; 1 1];
rl = [-Inf;5];
ru = [-1;5];
lb = [0;0]; ub = [4;4];

% Starting Guess
 x0 = [2;2];

% Build Function Structure
 funcs.objective = fun;
 funcs.gradient = grad;

% Build Options Structure
 opts.lb = lb;
 opts.ub = ub;
 opts.A = sparse(A);
 opts.rl = rl;
 opts.ru = ru;
 opts.ipopt.hessian_approximation = 'limited-memory';

% Call IPOPT
[x,output] = ipopt(x0,funcs,opts)

%% NL INEQ, LIN EQ
clc
clear all
% Objective & Gradient
 fun = @(x) (1-x(1))^2 + 100 *(x(2)-x(1)^2)^2;
 grad = @(x)[2*x(1)-400*x(1)*(x(2)-x(1)^2)-2,200*x(2)-200*x(1)^2];
 
 % Constraints
Aeq = [1 1];
rl = 5;
ru = 5;
lb = [0;0]; ub = [4;4];

% Nonlinear Constraint, Jacobian & Structure
 A = [-1 1];
 nlcon = @(x) [A]*x;
 nljac = @(x) sparse([A]);
 jacstr = @() sparse([A]~=0); 
 cl = -Inf;
 cu = -1;

% Starting Guess
 x0 = [2;2];

% Build Function Structure
 funcs.objective = fun;
 funcs.gradient = grad;
 funcs.constraints = nlcon;
 funcs.jacobian = nljac;
 funcs.jacobianstructure = jacstr;

% Build Options Structure
 opts.lb = lb;
 opts.ub = ub;
 opts.A = sparse(Aeq);
 opts.rl = rl;
 opts.ru = ru;
 opts.cl = cl;
 opts.cu = cu;
 opts.ipopt.hessian_approximation = 'limited-memory';

% Call IPOPT
% for i = 1:1000
    [x,output] = ipopt(x0,funcs,opts)
% end

%% NL EQ, LIN INEQ
clc
clear all
% Objective & Gradient
 fun = @(x) (1-x(1))^2 + 100 *(x(2)-x(1)^2)^2;
 grad = @(x)[2*x(1)-400*x(1)*(x(2)-x(1)^2)-2,200*x(2)-200*x(1)^2];
 
 % Constraints
A = [-1 1];
rl = -Inf;
ru = -1;
lb = [0;0]; ub = [4;4];

% Nonlinear Constraint, Jacobian & Structure
 Aeq = [1 1];
 nlcon = @(x) [Aeq]*x;
 nljac = @(x) sparse([Aeq]);
 jacstr = @() sparse([Aeq]~=0); 
 cl = 5;
 cu = 5;

% Starting Guess
 x0 = [2;2];

% Build Function Structure
 funcs.objective = fun;
 funcs.gradient = grad;
 funcs.constraints = nlcon;
 funcs.jacobian = nljac;
 funcs.jacobianstructure = jacstr;

% Build Options Structure
 opts.lb = lb;
 opts.ub = ub;
 opts.A = sparse(A);
 opts.rl = rl;
 opts.ru = ru;
 opts.cl = cl;
 opts.cu = cu;
 opts.ipopt.hessian_approximation = 'limited-memory';

% Call IPOPT
% for i = 1:1000
    [x,output] = ipopt(x0,funcs,opts)
% end

%% HESSIAN MODIFICATION FOR LAMBDA
clc
clear
f = @(x) x(1)*x(4)*sum(x(1:3)) + x(3);
g = @(x) [ x(1)*x(4) + x(4)*sum(x(1:3))
                x(1)*x(4)
                x(1)*x(4) + 1
                x(1)*sum(x(1:3)) ];
c = @(x) [ prod(x); sum(x.^2) ];      
j = @(x) [ prod(x)./x'; 2*x' ];

cl = [25;40];
cu = [Inf;40];

H = @(x,sigma,lambda) sigma*[ 2*x(4)             0      0   0;
                              x(4)               0      0   0;
                              x(4)               0      0   0;
                              2*x(1)+x(2)+x(3)  x(1)  x(1)  0 ] + ...
                   lambda(1)*[   0          0         0         0;
                              x(3)*x(4)     0         0         0;
                              x(2)*x(4) x(1)*x(4)     0         0;
                              x(2)*x(3) x(1)*x(3) x(1)*x(2)     0  ] + ...
         		   lambda(2)*diag([2 2 2 2]);

lb = ones(4,1);
ub = 5*ones(4,1);     

A = [1 0 0 0];
rl = 1.5;
ru = 1.5;

x0 = [1 5 5 1]';
opts = optiset('display','iter');               

Opt = opti('fun',f,'grad',g,'hess',H,'nl',c,cl,cu,'nljac',j,'lin',A,rl,ru,'bounds',lb,ub,'options',opts)  

[x,fval,exitflag,info]= solve(Opt,x0)

%%
clc
%Objective
obj = @(x) (1-x(1))^2 + 100 *(x(2)-x(1)^2)^2;
% Constraints
A = [-1 1]; 
b = -1;
Aeq = [1 1]; 
beq = 5; 
lb = [0;0]; ub = [4;4];
% Solve
x0 = [2;2];
opts = optiset('solver','ipopt','display','iter');
Opt = opti('obj',obj,'ndec',2,'bounds',lb,ub,'ineq',A,b,'eq',Aeq,beq,'options',opts)
[x,fval,ef,info] = solve(Opt,x0)
%Plot
% plot(Opt,[],1)

%%


% Objective & Gradient
fun = @(x) -sum(x);
grad = @(x) [-1 -1 -1 -1];

% Linear constraints
n = 4;
A = randn(n,4);
rl = zeros(n,1);
ru = zeros(n,1);

% Nonlinear Constraint, Jacobian & Structure 
nlcon = @(x) x(:).^4; 
nljac = @(x) sparse(diag(4*x(:).^3)); 
jacstr = @() speye(4); 
cl = [-inf;-inf;-inf;-inf]; 
cu = [1;1;1;1];

% Starting Guess
x0 = [0;0;0;0];
% Build Function Structure
funcs.objective = fun;
funcs.gradient = grad;
funcs.constraints = nlcon;
funcs.jacobian = nljac;
funcs.jacobianstructure = jacstr;

% Build Options Structure
lb = [-10;-10;-10;-10]; 
ub = [40;40;40;40]; 
opts.lb = lb; 
opts.ub = ub; 
opts.rl = rl; 
opts.ru = ru; 
opts.cl = cl; 
opts.cu = cu; 
opts.A = sparse(A); 
opts.ipopt.hessian_approximation = 'limited-memory';

% Call IPOPT
[x,output] = ipopt(x0,funcs,opts)
