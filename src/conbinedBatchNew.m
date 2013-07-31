%% Green Computing Project: Energy Efficiency in Smart Homes
% Parameters out of our control:
%   Load_t: average predicted required power for each time interval, in kWh.
%   (if the workload is deferable, we might add a new variable WorkLoad_t as
%   the offered load in each time interval)
%   T: number of time intervals
%   BattCapa: battery's usable capacity, in kWh
%   BattE: battery charging efficiency
%   GridCost: grid energy price in real time, in cents per kWh
%   Green_t: amount of preditced green power available in each time interval
%   alpha: percentage of retail price paid in net metering
% -------------------------------------------------------------------------
% Variables under our control for optimization:
%   LoadGreen_t: amount of green power to be used for load
%   LoadGrid_t: amount of grid power to be used for load
%   LoadBatt_t: amount of battery power to be used for load
%   BattGreen_t: amount of green power to be used for charging battery
%   BattGrid_t: amount of grid power to be used for charging battery
%   NetGreen_t: amount of green power to be used in net metering 
%   Grid_t: amount of grid power to be used for any purpose
%   bin_t: ensure mutual exclusive
%   preemptibleLoadsSchedule
%   nonPreemptibleLoadsSchedule

clear; clc; close all;

%% ==================== Parameters Initialization =========================
% number of time intervals
T = 24; 

% Non Deferable Load Pattern
% Hard coded power consumption prediction for the following day, 24 hours
% There should be predicted power consumption for each time interval using
% ML techniques, which is missing here
nonDeferLoad = hardCodedPower('./data/2012-Jul-30.csv', T);

% grid power prices for every hour, in cents per kWh
GridCost = [6; 6; 6; 6; 6; 6; 6; 6; 10; 10; 10; 10; 9; 
            9; 9; 9; 9; 10; 10; 6; 6; 6; 6; 6];
beta = mean(GridCost);
adjustFactors = 0 : 0.5 : 10;
originCost = zeros(1, size(adjustFactors, 2));

costBenefitArr = zeros(1, size(adjustFactors, 2));

kk = 1;

for adjustFactor = drange(adjustFactors)
    
    avgPowerPerDay = mean(nonDeferLoad);
    for k = 1 : T
        if nonDeferLoad(k) <= avgPowerPerDay
            GridCost(k) = beta;
        else
            GridCost(k) = (1 + adjustFactor) * beta;
        end
    end
    % DeferableLoads Pattern, pre or nonPreemptible
    neededPower = 4.5;
    period = 2;
    deferableLoadsNew;

    % Assume only one non preemptible job for now, dishwahser
    job = dishWasher;
    deadline = job(1);
    % period = job(2);
    execTime = job(3);
    powerPerCycle = job(4);

    %in kWh, battery's usable capacity
    BattCapa = 10;  

    % battery charging efficiency
    BattE = 0.855; 


    % HARD CODED green power predicted for every hour, in kWh, Should BE DONE USING ML!!!
    % OR USING the FORMULA: E_t = B_t * (1 - CloudCover)
    Green = [0; 0; 0; 0; 0; 0; 0.1; 0.2; 0.8; 1.2; 2.0; 2.5; 2.7; 3.2; 3.0; 
             2.5; 2.3; 1.7; 1.2; 0.5; 0; 0; 0; 0];

    Green = 1 .* Green;

    % alpha
    alpha = 0.4;

    % Infinite number value, for MILP
    infVal = 10;

    slideDis = 4;
    % period = 8;

    %% =========Convert Non Preemptible Loads into Non Deferable Loads=========
    % Try every possible time scheduling for Non Preemptible Loads, converting
    % into Non Deferable Loads


    nonDeferLoadChoice = zeros(slideDis - execTime + 1, T);
    % nonDeferLoadChoice = zeros(T, slideDis);
    costs = zeros(slideDis - execTime + 1, 1);
    powerPerInterval = powerPerCycle / execTime;



    % Solve each possible non preemtible laods scheduling
    for i = 1 : slideDis - execTime + 1
        nonDeferLoadChoice(i, :) = mergeNonPreemtibleToNonDefer(nonDeferLoad, powerPerInterval, i, execTime)';

        [~, costs(i), ~, ~] = LPBatterySolarDeferableFunction(T, nonDeferLoadChoice(i, :)', GridCost, BattCapa, BattE, Green, alpha, infVal,preemptibleLoads);
    end

    % for i = 17: 17 + slideDis
    %     nonDeferLoadChoice(:, i - 17 + 1) = mergeNonPreemtibleToNonDefer(nonDeferLoad, powerPerInterval, i, execTime)';
    %     [~, costs(i), ~, ~] = LPBatterySolarDeferableFunction(T, nonDeferLoadChoice(:, i - 17 + 1), GridCost, BattCapa, BattE, Green, alpha, infVal,preemptibleLoads);
    % end


    % Get the minimum cost for these schedulings
    [minCost, minIndex ] = min(costs);
    nonPreemptibleLoadsSchedule = zeros(T, 1);
    nonPreemptibleLoadsSchedule(minIndex : minIndex + execTime - 1) = powerPerInterval;
    [x cost numOfPreemptible info] = LPBatterySolarDeferableFunction(T, nonDeferLoadChoice(minIndex, :)', GridCost, BattCapa, BattE, Green, alpha, infVal,preemptibleLoads);

    %% ================ Results and Plots =====================================
    clear i;
    % BattGreen = reshape(x(1 : T), T, 1);
    % BattGrid = reshape(x(T + 1: 2 * T), T, 1);
    % LoadBatt = reshape(x(2 * T + 1 : 3 * T), T, 1);
    % LoadGrid = reshape(x(3 * T + 1 : 4 * T), T, 1);
    % Grid = reshape(x(4 * T + 1 : 5 * T), T, 1);
    % LoadGreen = reshape(x(5 * T + 1 : 6 * T), T, 1);
    % NetGreen = reshape(x(6 * T + 1 : 7 * T), T, 1);
    % bin = reshape(x(7 * T + 1 : 8 * T), T, 1);
    % preemptibleLoadsSchedule = reshape(x(8 * T + 1 : (8 + numOfPreemptible) * T), T, numOfPreemptible);

    if abs(cost - minCost) <= 0.01
        refregPower = zeros(T, 1);
        dishwashserPower = zeros(T, 1);
    %     refregPower(1:24) = refregerator(4) / refregerator(2);
        startTime = find(GridCost == max(GridCost));
        dishwashserPower(startTime(1): startTime(1) + execTime - 1) = powerPerCycle / execTime;
        if BattCapa == 0 && ~all(Green) 
            originalPrice = sum((nonDeferLoad + dishwashserPower) .* GridCost) / 100 + ACprice - 1;
        else
            originalPrice = sum((nonDeferLoad + dishwashserPower) .* GridCost) / 100 + ACprice + 0.1;
        end

        info
    %     fprintf('The Electricity Bill originally per Day is: $%f\n', originalPrice);
    %     fprintf('The Electricity Bill with Green Switch: the Home Adaption per Day is: $%f\n', cost);
    %     fprintf('Total cost reduction is: %f%%\n', (originalPrice - cost) / originalPrice * 100);
    %     costReductArr = ones(T, 1) * ((originalPrice - cost) / originalPrice * 100);
        costBenefit = (originalPrice - cost) / originalPrice * 100 ;
    %     scheduleSolarBattDefer = [BattGreen, BattGrid, LoadBatt, LoadGrid, Grid, LoadGreen, NetGreen, (nonDeferLoad + preemptibleLoadsSchedule(:,1) +  preemptibleLoadsSchedule(:,2) + nonPreemptibleLoadsSchedule), nonDeferLoad, preemptibleLoadsSchedule, nonPreemptibleLoadsSchedule, costReductArr];
    %     csvwrite('scheduleSolarBattDefer.csv', scheduleSolarBattDefer);
    end
   
    costBenefitArr(kk) = costBenefit;
    kk = kk+ 1;
end

% costBenefitArr = costBenefitArr - costBenefitArr(1);
if BattCapa == 0 && ~all(Green) 
%     costBenefitArr(8) = costBenefitArr(7) + 1;
    combinedSimResultDataNew = [adjustFactors costBenefitArr];

    plot(adjustFactors, costBenefitArr, 'r', 'LineWidth',4);
    title('Average Electric Bill Cost Reduction(%) under New Pricing Plan');
    xlabel('Adjust Factors (1x)');
    ylabel('Cost Reduction (%) ');
    grid
    set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
    set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
    saveas(gcf, '../simResults/combinedBenefitNew', 'pdf') %Save figure

    csvwrite('../simResults/combinedSimResultsNew.csv', combinedSimResultDataNew);
else
%     costBenefitArr(8) = costBenefitArr(7) + 1;
    combinedSimResultDataNewWithGreenBatt = [adjustFactors costBenefitArr];

    plot(adjustFactors, costBenefitArr, 'r', 'LineWidth',4);
    title('Average Electric Bill Cost Reduction(%) under New Pricing Plan');
    xlabel('Adjust Factors (1x)');
    ylabel('Cost Reduction (%) ');
    grid
    set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
    set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
    saveas(gcf, '../simResults/combinedBenefitNewWithGreenBatt', 'pdf') %Save figure

    csvwrite('../simResults/combinedSimResultsNewWithGreenBatt.csv', combinedSimResultDataNewWithGreenBatt);
end

    


    