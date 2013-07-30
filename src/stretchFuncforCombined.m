function [ cost ] = stretchFuncforCombined( alpha, startTime1 )


slideAndStretchLoad
cost = 0;
%% 
% grid power prices for every hour, in cents per kWh
GridCost = [2.7; 2.4; 2.3; 2.3; 2.3; 2.5; 2.8; 3.4; 3.8; 5; 6.1; 6.8; 7.4; 
            8.2; 10; 10.9; 11.9; 10.1; 9.2; 7; 7; 5.2; 4.2; 3.5];
T = 24;

% newDelta and newPower
newDelta = zeros(1, size(originDelta,2));
newPower = zeros(1, size(originPower, 2));
for i = 1 : numOfPhases
    if e(i) ~= 0
        newDelta(i) = alpha * originDelta(i);
        newPower(i) = originDelta(i) * originPower(i) / newDelta(i);
    else
        newDelta(i) = originDelta(i);
        newPower(i) = originPower(i);
    end
end


for i = 1 : numOfPhases
    while newDelta(i) ~= 0
        if newDelta(i) < ceil(startTime1 + 0.00001) - startTime1
            startTime1  = startTime1 + newDelta(i);
            cost = cost + newDelta(i) * newPower(i) * GridCost(floor(mod(startTime1, T)) + 1);
            newDelta(i) = 0;
        else
            newDelta(i) = newDelta(i) - (ceil(startTime1 + 0.000001) - startTime1); 
            cost = cost + (ceil(startTime1 + 0.000001) - startTime1) * newPower(i) * GridCost(floor(mod(startTime1, T)) + 1); 
            startTime1 = ceil(startTime1 + 0.000001);
        end
    end
end

cost = cost / 100;

end

