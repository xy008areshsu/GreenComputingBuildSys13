
        
%% =========Convert Non Preemptible Loads into Non Deferable Loads=========
% Try every possible time scheduling for Non Preemptible Loads, converting
% into Non Deferable Loads
nonDeferLoadChoice = zeros(T, slideDis);
costs = zeros(slideDis, 1);
powerPerInterval = powerPerCycle / execTime;

% Solve each possible non preemtible laods scheduling
for i = 17: 17 + slideDis
    nonDeferLoadChoice(:, i - 17 + 1) = mergeNonPreemtibleToNonDefer(nonDeferLoad, powerPerInterval, i, execTime);
    costs(i - 16) = sum(nonDeferLoadChoice(:, i - 16) .* GridCost);
end

% Get the minimum cost for these schedulings
[cost, minIndex ] = min(costs);
cost = cost / 100;

%% =======================Plot Results and Write to File===================
nonDerPrice = sum(nonDeferLoad.*GridCost) / 100;
dryerPrice = 0;
for i = 17 : 17 + execTime - 1
    dryerPrice = dryerPrice + powerPerInterval * GridCost(i) / 100;
end
originalPrice = nonDerPrice + dryerPrice;
% fprintf('The Electricity Bill without Smart Charge per Day is: $%f\n', originalPrice);
% fprintf('The Electricity Bill with Smart Charge Solar-Battery per Day is: $%f\n', cost);
% fprintf('Total cost reduction is: %f%%\n', (originalPrice - cost) / originalPrice * 100);

