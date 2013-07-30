% Deferable Loads Modeling: [relative deadline in hours, period in hours, 
% excution time in hours, energy per period in kWh]

% Assume period is integer, and can be divisible by T, no residual, and
% deadline is equal to period
ACUsage = [2.615567222 2.632913611 2.675712778 2.733026667 2.823199722 2.894424167 2.500263056 0.000003889 0.000025556 0.000015833 0.000015556 0.000013333 0.000015 0.000016389 0.000015278 0.000025833 0.000046389 0.0001075 0.544014444 0.950451389 0.828965278 1.308807222 2.475633611 2.500856667];
ACUsage = ACUsage ./ 2;
ACCentral = [24, period, ceil(8 * (period / 24)), sum(ACUsage) / (24 / period)];

ACprice = sum(ACUsage)* max(GridCost) / 100;
%refregerator = [2, 2, 1, 0.36];

dishWasher = [24, 24, 2, neededPower];
clothesWasher = [24, 24, 0.8, 7];
clothesDryer = [24, 24, 1.5, 5];
%hahaha = [24, 3, 1.5, 5];

nonPreemptibleLoads = [dishWasher; clothesWasher; clothesDryer];
preemptibleLoads = [ACCentral];