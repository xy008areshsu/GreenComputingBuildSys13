
        
%% =========Convert Non Preemptible Loads into Non Deferable Loads=========
% Try every possible time scheduling for Non Preemptible Loads, converting
% into Non Deferable Loads
nonDeferLoadChoice = zeros(T, slideDis);
costs = zeros(slideDis, 1);
powerPerInterval = powerPerCycle / execTime;
[~, startTime] = max(GridCost);

% Solve each possible non preemtible laods scheduling
for i = startTime: startTime + slideDis
    nonDeferLoadChoice(:, i - startTime + 1) = mergeNonPreemtibleToNonDefer(nonDeferLoad, powerPerInterval, i, execTime);
    costs(i - startTime + 1) = sum(nonDeferLoadChoice(:, i - startTime + 1) .* GridCost);
end

% Get the minimum cost for these schedulings
[cost, minIndex ] = min(costs);
cost = cost / 100;

%% =======================Plot Results and Write to File===================
nonDerPrice = sum(nonDeferLoad.*GridCost) / 100;
dryerPrice = 0;
for i = startTime : startTime + execTime - 1      %WORST CASE original price is the load running during the most expensive time regions
    dryerPrice = dryerPrice + powerPerInterval * GridCost(startTime) / 100;
end
originalPrice = nonDerPrice + dryerPrice;
% fprintf('The Electricity Bill without Smart Charge per Day is: $%f\n', originalPrice);
% fprintf('The Electricity Bill with Smart Charge Solar-Battery per Day is: $%f\n', cost);
% fprintf('Total cost reduction is: %f%%\n', (originalPrice - cost) / originalPrice * 100);

