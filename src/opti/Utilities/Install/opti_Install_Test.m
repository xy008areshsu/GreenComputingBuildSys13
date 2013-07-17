function ok = opti_Install_Test(verb)
% Installation Test File
%
% A collection of tests to verify the installation of the toolbox has been
% successful. 

%   Copyright (C) 2012 Jonathan Currie (I2C2)

% 14/3/12 Changed to Rel Error Check

%Set Verbosity
if(nargin < 1)
    verb = 1; %default show all messages
end

%Set default ok
ok = 1;

fprintf('\nChecking OPTI Toolbox Installation:\n');

%% TEST 1 - Check Main Paths
if(verb); fprintf('Checking Paths...                '); end
paths = {'@opti','Utilities','Plots','Help','Solvers'};
len = length(paths);
for i = 1:len
    pass = exist(paths{i},'dir');
    if(~pass)
        fprintf('\nFailed Path Check on %s\n',paths{i});
        ok = 0;
        return
    end
end
if(verb); fprintf('Ok\n'); end

%% Setup tests to run
tests = {'lp','milp','qp','miqp','sdp','nls','nlp','minlp'};
tres = ones(size(tests));

%Loop for each test set
for t = 1:length(tests)    
    load([tests{t} '_test_results']); %load pre solved results 
    probs = eval([tests{t} '_tprob']);
    sols = eval([tests{t} '_sval']);
    msolvers = checkSolver(tests{t}); 
    ind = strcmpi(msolvers,'MATLAB'); msolvers(ind) = [];    
    ind = strcmpi(msolvers,'GMATLAB'); msolvers(ind) = [];
    %Check and remove solvers for certain problems
    if(strcmpi(tests{t},'nlp')) %not deterministic
        ind = strcmpi(msolvers,'NLOPT'); msolvers(ind) = [];
        ind = strcmpi(msolvers,'PSWARM'); msolvers(ind) = [];
        ind = strcmpi(msolvers,'SCIP'); msolvers(ind) = []; %problems with trig functions
    elseif(strcmpi(tests{t},'lp'))
        ind = strcmpi(msolvers,'DSDP'); msolvers(ind) = []; %no good with equalities
        ind = strcmpi(msolvers,'SEDUMI'); msolvers(ind) = []; %no good with neq = nvar & seg faults on incorrect binaries
    elseif(strcmpi(tests{t},'sdp'))
        ind = strcmpi(msolvers,'SEDUMI'); msolvers(ind) = []; %seg faults on incorrect binaries
    end            
    noS = length(msolvers); 
    if(noS == 0)
        continue;
    end    
    noP = length(probs);
    if(verb); fprintf('Checking %5s Solver Results... ',upper(tests{t})); end
    for i = 1:noS
        for j = 1:noP
            Opt = opti(probs{j},optiset('solver',msolvers{i},'warnings','off'));
            [~,fval] = solve(Opt);
            if(sols(j) == 0)
                if(abs(fval-sols(j)) > 1e-4)
                    fprintf('\nFailed %s Result Check on Test %d, Solver: %s',tests{t},j,msolvers{i});
                    tres(t) = 0;
                end
            else
                if(abs((fval-sols(j))/fval) > 1e-4) 
                    fprintf('\nFailed %s Result Check on Test %d, Solver: %s',tests{t},j,msolvers{i});
                    tres(t) = 0;
                end
            end
        end
    end
    if(verb && tres(t)); fprintf('Ok\n'); else fprintf('\n\n'); end 
end

%% Final
if(ok && all(tres))
    ok = 1;
    fprintf('\nToolbox Checked Out Ok! - Enjoy\n');
else
    ok = 0;
    fprintf('\nThere was an error during post installation checks, please ensure your download was not corrupted!\n');
end

end

