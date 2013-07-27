%% Green Computing Project: Energy Efficiency in Smart Homes
% Parameters out of our control:
%   Load_t: average predicted required power for each time interval, in kWh.
%   (if the workload is deferable, we might add a new variable WorkLoad_t as
%   the offered load in each time interval)
%   T: number of time intervals
%   GridCost: grid energy price in real time, in cents per kWh
%   Green_t: amount of preditced green power available in each time interval
%   alpha: percentage of retail price paid in net metering
% -------------------------------------------------------------------------
% Variables under our control for optimization:
%   LoadGreen_t: amount of green power to be used for load
%   LoadGrid_t: amount of grid power to be used for load
%   NetGreen_t: amount of green power to be used in net metering 
%   Grid_t: amount of grid power to be used for any purpose
%   bin_t: ensure mutual exclusive



%% ==================== Parameters Initialization =========================
% number of time intervals
%T = 24; 

% Hard coded power consumption prediction for the following day, 24 hours
% There should be predicted power consumption for each time interval using
% ML techniques, which is missing here
%Load = load('../dataset/070112.csv');



%% ===========================Separate Bounds==============================
% lowerBounds(:, 1) = Grid;        T
% lowerBounds(:, 2) = LoadGrid;   2T 
% lowerBounds(:, 3) = LoadGreen;  3T
% lowerBounds(:, 4) = NetGreen;   4T
% lowerBounds(:, 5) = bin; ensure mutual exclusive 5T
lowerBounds = zeros(T, 5);

% upperBounds(:, 1) = Grid;        T
% upperBounds(:, 2) = LoadGrid;   2T 
% upperBounds(:, 3) = LoadGreen;  3T
% upperBounds(:, 4) = NetGreen;   4T
% upperBounds(:, 5) = bin; ensure mutual exclusive 5T
upperBounds = Inf(T, 5);
upperBounds(:, 5) = 1;    % bin is either 0 or 1, Mixed Integer LP

% unroll into vectors: 
% 1:24 = Grid;
% 25:48 = LoadGrid;
% 49:72 = LoadGreen;
% 73: 96 = NetGreen;
% 97: 120 = bin;
lowerBounds = lowerBounds(:);
upperBounds = upperBounds(:);



%% ====================Linear Inequality Constraints======================
% T = 24 time intervals, linear inequality matrix and vector A*x <= b, 
% 4 * T = 96 inequality constraints, 
% 5 * T = 120 varibles: see above
A = zeros(4 * T, 5 * T);
b = zeros(4 * T, 1);


% The renewable power, Green_t, may be used to run the LoadGreen_t, and/or net metering(NetGreen_t):
% LoadGreen_t + NetGreen_t <= Green_t, 
for i = 1 : T
    A(i, i + T) = 1;             % LoadGreen_t
    A(i, i + 3 * T) = 1;             % NetGreen_t
    b(i) = Green(i);                 % Green_t
end

% A trick for mutual excusive: given X >= 0 => Y = 0 or vice versa: 
% X <= bin * infinity   => X - Inf * bin <= 0
% bin <= X * infinity   => -Inf * X + bin_t <= 0
% Y <= (1 - bin) * infinity   => Y + Inf * bin <= Inf

%we cannot draw from the grid to power the load at the same time as doing
%net metering
%given LoadGrid_t >= 0, NetGreen_t should = 0 or vice versa
%LoadGrid_t - inf * bin_t <= 0: Constraints 241 to 264
for i = T + 1 : 2 * T
    A(i, i - T + 2 * T) = 1;        % LoadGrid_t 
    A(i, i - T + 4 * T) = -infVal;     % -inf * bin_t
    b(i) = 0;
end

% -inf * LoadGrid_t + bin_t <= 0: Constraints 265 to 288
for i = 2 * T + 1 : 3 * T
    A(i, i - 2 * T + 2 * T) = -infVal;    % -inf * LoadGrid_t
    A(i, i - 2 * T + 4 * T) = 1;       % bint_t
    b(i) = 0;
end

% NetGreen_t + Inf * bin_t <= inf; Constraints 289 to 312
for i = 3 * T + 1 : 4 * T
    A(i, i - 3 * T + 3 * T) = 1;          % NetGreen_t
    A(i, i - 3 * T + 4 * T) = infVal;        % Inf * bin_t
    b(i) = infVal;
end


clear i j;


%% =========================Linear Equality Constraints====================
% T = 24 time intervals, linear equality matrix and vector Aeq*x = beq, 
% 2 * T = 48 equality constraints, 
% 5 * T = 120 varibles: see above
Aeq = zeros(2 * T, 5 * T);
beq = zeros(2 * T, 1);

% Two sources can be used to power the house, LoadGreen_t, LoadGrid_t
% : LoadGrid_t + LoadGreen_t = Load_t,
% constraints 1 to 24
for i = 1 : T
    Aeq(i, i + 2 * T) = 1;                  % LoadGrid_t
    Aeq(i, i + T) = 1;                  % LoadGreen_t
    beq(i) = Load(i);                       % Load_t
end

% The grid can be used to power the load:
% LoadGrid_t - Grid_t = 0, constraints 25 to 48
for i = T + 1 : 2 * T
    Aeq(i, i - T + 2 * T) = 1;              % LoadGrid_t
    Aeq(i, i - T ) = -1;             % Grid_t
    beq(i) = 0;                             
end


clear i;
        

%% ========================Objective Function(Minimize)====================
% objective function: Total electricity cost: m = sum(GridCost_t * Grid_t 
% - alpha * GridCost_t * NetGreen_t), minimize it
f = zeros(5 * T, 1); 

for i = 1 : T
    f(i) = GridCost(i);          % GridCost_t * Grid_t
    f(i + 3 * T) = -alpha * GridCost(i); % -alpha * GridCost_t * NetGreen_t
end

clear i;

%% =======================LP Solver ======================================
% Indices of x which are considered to be integers, here bin_t should be
% integers either 0 or 1, and bin_t is in indices from 7*T + 1 to 8*T
xtype = 3 * T + 1 : 4 * T;  
Opt = opti('f', f, 'ineq', A, b, 'eq', Aeq, beq, 'bounds', lowerBounds, upperBounds, 'xtype', xtype);
[x,cost,exitflag,info] = solve(Opt);
info
%[x cost] = MILP(f, A, b, Aeq, beq, lowerBounds, upperBounds, xtype, 0.01);
Grid = reshape(x(1 : T), T, 1);
LoadGreen = reshape(x(T + 1: 2 * T), T, 1);
LoadGrid = reshape(x(2 * T + 1 : 3 * T), T, 1);
NetGreen = reshape(x(3 * T + 1 : 4 * T), T, 1);
bin = reshape(x(4 * T + 1 : 5 * T), T, 1);
cost = cost / 100;     % convert from cents to dollars

%% =======================Plot Results and Write to File===================
originalPrice = sum(Load.*GridCost) / 100;
fprintf('The Electricity Bill orginally per Day is: $%f\n', originalPrice);
fprintf('The Electricity Bill with LP Solar-Battery per Day is: $%f\n', cost);
fprintf('Total cost reduction is: %f%%\n', (originalPrice - cost) / originalPrice * 100);