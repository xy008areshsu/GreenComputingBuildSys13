function displayOPTI(O)
%Display OPTI Problem Information
%
%   Called By OPTI Class

%   Copyright (C) 2011 Jonathan Currie (I2C2)

%Distribute Structure Variables;
prob = O.prob;
opts = O.opts;
sizes = prob.sizes;
nineq = sizes.nineq;
neq = sizes.neq;
nbnds = sizes.nbnds;
nqc = sizes.nqc;
nsdcone = sizes.nsdcone;
nnlineq = sizes.nnlineq;
nnleq = sizes.nnleq;
nsos1 = sizes.nsos1;
nsos2 = sizes.nsos2;
sense = prob.sense;

%Types of constraints
lin = 'rl <= Ax <= ru';
linineq = 'Ax <= b';
lineq = 'Aeqx = beq';
bnds = 'lb <= x <= ub';
quad = 'qrl <= x''Qx + l''x <= qru';
sdp = 'F1*x1 + F2*x2 + ... + Fn*xn - F0 >= 0 [PSD]';
sos1 = 'x in SOS1';
sos2 = 'x in SOS2';
nlineq = 'c(x) <= d';
nleq = 'ceq(x) = deq';
nl = 'cl <= c(x) <= cu';
str1 = ' s.t. '; 
str2 = '      '; 

%**************** Title ****************%
disp('------------------------------------------------------');
switch(prob.type)
    case 'SLE'
        disp('System of Linear Equations (SLE)');
        disp(' Ax = b');
    case 'LP'
        disp('Linear Program (LP) Optimization');
        if(sense==1); disp(' min  f''x'); else disp(' max  f''x'); end
        if(~isempty(prob.rl))
            fprintf('%s%s\n',str1,lin); str1 = str2;
        else
            if(nineq),  fprintf('%s%s\n',str1,linineq); str1 = str2; end            
        end
        if(neq && ~isempty(prob.beq)),    fprintf('%s%s\n',str1,lineq); str1 = str2; end
        if(nbnds),  fprintf('%s%s\n',str1,bnds); end
    case 'MILP'
        disp('Mixed Integer Linear Program (MILP) Optimization');
        if(sense==1); disp(' min  f''x'); else disp(' max  f''x'); end
        if(~isempty(prob.rl))
            fprintf('%s%s\n',str1,lin); str1 = str2;
        else
            if(nineq),  fprintf('%s%s\n',str1,linineq); str1 = str2; end
        end
        if(neq && ~isempty(prob.beq)),    fprintf('%s%s\n',str1,lineq); str1 = str2; end
        if(nbnds),  fprintf('%s%s\n',str1,bnds); end        
        if(sizes.nint || sizes.nbin)
            disp('      xi = Integer / Binary');
        end
        if(nsos1),   fprintf('%s%s\n',str1,sos1); end
        if(nsos2),   fprintf('%s%s\n',str1,sos2); end
    case 'BILP'
        disp('Binary Integer Linear Program (BILP) Optimization');
        if(sense==1); disp(' min  f''x'); else disp(' max  f''x'); end
        if(~isempty(prob.rl))
            fprintf('%s%s\n',str1,lin); str1 = str2;
        else
            if(nineq),  fprintf('%s%s\n',str1,linineq); str1 = str2; end
        end
        if(neq && ~isempty(prob.beq)),    fprintf('%s%s\n',str1,lineq); str1 = str2; end
        if(nbnds),  fprintf('%s%s\n',str1,bnds); end
        disp('      xb = Binary');
    case 'QP'
        if(prob.iscon)
            disp('Quadratic Program (QP) Optimization');
            if(sense==1); disp(' min  1/2x''Hx + f''x'); else disp(' max  1/2x''Hx + f''x'); end            
            if(~isempty(prob.rl))
                fprintf('%s%s\n',str1,lin); str1 = str2;
            else
                if(nineq),  fprintf('%s%s\n',str1,linineq); str1 = str2; end
            end
            if(neq && ~isempty(prob.beq)),    fprintf('%s%s\n',str1,lineq); str1 = str2; end
            if(nbnds),  fprintf('%s%s\n',str1,bnds); end
        else
            disp('Unconstrained Quadratic Program (UQP)');
            if(sense==1); disp(' min  1/2x''Hx + f''x'); else disp(' max  1/2x''Hx + f''x'); end
        end
    case 'QCQP'
        disp('Quadratically Constrained Quadratic Program (QCQP) Optimization');
        if(sense==1); disp(' min  1/2x''Hx + f''x'); else disp(' max  1/2x''Hx + f''x'); end
        if(~isempty(prob.rl))
            fprintf('%s%s\n',str1,lin); str1 = str2;
        else
            if(nineq),  fprintf('%s%s\n',str1,linineq); str1 = str2; end
        end
        if(neq && ~isempty(prob.beq)),    fprintf('%s%s\n',str1,lineq); str1 = str2; end
        if(nqc),    fprintf('%s%s\n',str1,quad); str1 = str2; end
        if(nbnds),  fprintf('%s%s\n',str1,bnds); end
    case 'MIQP'
        disp('Mixed Integer Quadratic Program (QP) Optimization');
        if(sense==1); disp(' min  1/2x''Hx + f''x'); else disp(' max  1/2x''Hx + f''x'); end
        if(~isempty(prob.rl))
            fprintf('%s%s\n',str1,lin); str1 = str2;
        else
            if(nineq),  fprintf('%s%s\n',str1,linineq); str1 = str2; end
        end
        if(neq && ~isempty(prob.beq)),    fprintf('%s%s\n',str1,lineq); str1 = str2; end
        if(nbnds),  fprintf('%s%s\n',str1,bnds); end    
        disp('      xi = Integer / Binary');
    case 'MIQCQP'
        disp('Mixed Integer Quadratically Constrained Quadratic Program (MIQCQP) Optimization');
        if(sense==1); disp(' min  1/2x''Hx + f''x'); else disp(' max  1/2x''Hx + f''x'); end
        if(~isempty(prob.rl))
            fprintf('%s%s\n',str1,lin); str1 = str2;
        else
            if(nineq),  fprintf('%s%s\n',str1,linineq); str1 = str2; end
        end
        if(neq && ~isempty(prob.beq)),    fprintf('%s%s\n',str1,lineq); str1 = str2; end
        if(nqc),    fprintf('%s%s\n',str1,quad); str1 = str2; end
        if(nbnds),  fprintf('%s%s\n',str1,bnds); end    
        disp('      xi = Integer / Binary');
    case 'SDP'
        disp('Semidefinite Program (SDP) Optimization');
        if(sense==1); disp(' min  f''x'); else disp(' max  f''x'); end
        if(~isempty(prob.rl))
            fprintf('%s%s\n',str1,lin); str1 = str2;
        else
            if(nineq),  fprintf('%s%s\n',str1,linineq); str1 = str2; end            
        end
        if(neq && ~isempty(prob.beq)),    fprintf('%s%s\n',str1,lineq); str1 = str2; end
        if(nsdcone),    fprintf('%s%s\n',str1,sdp); str1 = str2; end
        if(nbnds),  fprintf('%s%s\n',str1,bnds); end
    case 'UNO'
        disp('Unconstrained Nonlinear Optimization (UNO)');
        if(sense==1); disp(' min  f(x)'); else disp(' max  f(x)'); end
    case 'SNLE'
        disp('System of Nonlinear Equations (SNLE)');
        disp(' F(x) = 0');
    case 'NLS'
        disp('Nonlinear Least Squares (NLS)');
        if(~isempty(prob.xdata))
            if(sense==1)
                disp(' min sum[( F(x,xdata) - ydata ).^2]');
            else
                disp(' max sum[( F(x,xdata) - ydata ).^2]');
            end
        else
            if(sense==1)
                disp(' min sum[( F(x) - ydata ).^2]');
            else
                disp(' max sum[( F(x) - ydata ).^2]');
            end
        end
        if(nineq),  fprintf('%s%s\n',str1,linineq); str1 = str2; end
        if(neq && ~isempty(prob.beq)),    fprintf('%s%s\n',str1,lineq); str1 = str2; end
        if(nbnds),  fprintf('%s%s\n',str1,bnds); end        
    case 'NLP'
        disp('Nonlinear Program (NLP) Optimization');
        if(sense==1); disp(' min  f(x)'); else disp(' max  f(x)'); end
        if(~isempty(prob.rl))
            fprintf('%s%s\n',str1,lin); str1 = str2;
        else
            if(nineq),  fprintf('%s%s\n',str1,linineq); str1 = str2; end
        end
        if(neq && ~isempty(prob.beq)),    fprintf('%s%s\n',str1,lineq); str1 = str2; end
        if(nbnds),  fprintf('%s%s\n',str1,bnds); str1 = str2; end
        if(~isempty(prob.nlrhs))
            if(nnlineq),fprintf('%s%s\n',str1,nlineq); str1 = str2; end
            if(nnleq),  fprintf('%s%s\n',str1,nleq); end
        elseif(~isempty(prob.cl))
            fprintf('%s%s\n',str1,nl);
        end
    case 'MINLP'
        disp('Mixed Integer Nonlinear Program (MINLP) Optimization');
        if(sense==1); disp(' min  f(x)'); else disp(' max  f(x)'); end
        if(~isempty(prob.rl))
            fprintf('%s%s\n',str1,lin); str1 = str2;
        else
           if(nineq),  fprintf('%s%s\n',str1,linineq); str1 = str2; end
        end
        if(neq && ~isempty(prob.beq)),    fprintf('%s%s\n',str1,lineq); str1 = str2; end
        if(nbnds),  fprintf('%s%s\n',str1,bnds); str1 = str2; end
        if(~isempty(prob.nlrhs))
            if(nnlineq),fprintf('%s%s\n',str1,nlineq); str1 = str2; end
            if(nnleq),  fprintf('%s%s\n',str1,nleq); end
        elseif(~isempty(prob.cl))
            fprintf('%s%s\n',str1,nl);
        end
        disp('      xi = Integer / Binary');
end

%**************** Properties ****************%
disp('------------------------------------------------------');
disp('   Problem Properties: ')
if(isempty(sizes.ndec))
    fprintf('# Decision Variables:     Cannot Determine\n');   
else
    if(~isempty(prob.H) && issparse(prob.H))
        fprintf('# Decision Variables:      %3d [%d nz]\n',sizes.ndec,nnz(prob.H)); %QP Hessian
    else
        fprintf('# Decision Variables:      %3d\n',sizes.ndec);
    end
end
if(strcmpi(prob.type,'SLE'))
    fprintf('               LHS A:      %d x %d [%d nz]\n',size(prob.A,1),size(prob.A,2),nnz(prob.A));
    fprintf('               RHS b:      %d x 1\n',length(prob.b));
elseif(prob.iscon)
    fprintf('# Constraints:             %3d\n',sizes.ncon);
    if(nineq)
        if(~issparse(prob.A) || ~isempty(prob.rl))
            fprintf('  # Linear Inequality:     %3d\n',sizes.nineq);
        else
            fprintf('  # Linear Inequality:     %3d [%d nz]\n',sizes.nineq,nnz(prob.A));
        end
    end
    if(neq)
        if(~issparse(prob.Aeq))
            fprintf('  # Linear Equality:       %3d\n',sizes.neq);
        else
            fprintf('  # Linear Equality:       %3d [%d nz]\n',sizes.neq,nnz(prob.Aeq));
        end
    end
    if(nqc)
        if(~issparse(prob.Q))
            fprintf('  # Quadratic Constraints: %3d\n',sizes.nqc);
        else 
            fprintf('  # Quadratic Constraints: %3d [%d nz]\n',sizes.nqc,nnz(prob.Q));
        end
    end
    if(nsdcone)
        if(~issparse(prob.sdcone))
            fprintf('  # Semidefinite Cones:    %3d\n',sizes.nsdcone);
        else 
            fprintf('  # Semidefinite Cones:    %3d [%d nz]\n',sizes.nsdcone,nnz(prob.sdcone));
        end
    end
    if(sizes.nbnds)
        fprintf('  # Bounds:                %3d\n',sizes.nbnds);
    end
    
    if(sizes.nbin)
        fprintf('  # Binary Variables:      %3d\n',sizes.nbin);
    end
    if(sizes.nint)
        fprintf('  # Integer Variables:     %3d\n',sizes.nint);
    end
    if(nsos1)
        fprintf('  # SOS1:                  %3d\n',sizes.nsos1);
    end
    if(nsos2)
        fprintf('  # SOS2:                  %3d\n',sizes.nsos2);
    end
    
    % IF SPARSE

    if(sizes.nnlineq)
        fprintf('  # Nonlinear Inequality:  %3d\n',sizes.nnlineq);
    end
    if(sizes.nnleq)
        fprintf('  # Nonlinear Equality:    %3d\n',sizes.nnleq);
    end
end

disp('------------------------------------------------------');

%**************** Solver ****************%
disp('  Solver Parameters:')
if(prob.ampl.useASL)
    fprintf('Solver:                    %s [Using AMPL Interface]\n',upper(opts.solver));    
else
    if(strcmpi(opts.solver,'nlopt'))
        fprintf('Solver:                    %s with %s\n',upper(opts.solver),upper(nloptSolver(O.nlprob.options.algorithm)));
    else
        fprintf('Solver:                    %s\n',upper(opts.solver));
    end

    if(any(strcmpi(prob.type,{'SNLE','NLS','NLP','UNO','MINLP'})) && isa(prob.fun,'function_handle'))
        if(prob.numdif.grad), fnd = ' [numdiff]'; else fnd = ''; end
        %Get solver info
        info = optiSolverInfo(opts.solver,prob.type,O.nlprob,opts);
        if(info.der1 || (strcmpi(opts.solver,'matlab') && strcmpi(prob.type,'NLP'))) %matlab is optional
            derstr = 'Not Supplied'; 
        else
            derstr = 'Not Required'; 
        end
        if(isempty(prob.f))
            f = derstr;
        elseif(length(func2str(prob.f)) > 60)
            f = ['@(x) ...' fnd];
        else
            f = [func2str(prob.f) fnd];
        end              
        if(prob.numdif.hess), Hnd = ' [numdiff]'; else Hnd = ''; end       
        %Check if solver can use second derivs & not vector function
        if(info.der2 && ~any(strcmpi(prob.type,{'snle','nls'}))) 
            if(isempty(prob.H))
                H = derstr;
            elseif(length(func2str(prob.H)) > 60)
                H = ['@(x) ...' Hnd];
            else
                H = [func2str(prob.H) Hnd];
            end
            if(isempty(prob.Hstr))
                Hs = derstr;
            else
                Hs = 'Supplied';
            end
        else
            H = []; Hs = [];
        end
        if(~isempty(prob.nlcon))
            if(prob.numdif.jac), jnd = ' [numdiff]'; else jnd = ''; end
            if(isempty(prob.nljac))
                j = derstr;
            elseif(length(func2str(prob.nljac)) > 60)
                j = ['@(x) ...' jnd];
            else
                j = [func2str(prob.nljac) jnd];
            end
            if(isempty(prob.nljacstr))
                js = derstr;
            else
                js = 'Supplied';
            end
        else
            j = []; js = [];
        end

        fprintf('Objective Gradient:        %s\n',f);
        if(~isempty(j)), fprintf('Constraint Jacobian:       %s\n',j); end
        if(~isempty(js)), fprintf('Jacobian Structure:        %s\n',js); end
        if(~isempty(H)), fprintf('Lagrangian Hessian:        %s\n',H); end
        if(~isempty(Hs)), fprintf('Hessian Structure:         %s\n',Hs); end
    end
end

disp('------------------------------------------------------');

end