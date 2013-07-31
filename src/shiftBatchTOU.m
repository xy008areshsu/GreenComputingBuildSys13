clear; close all; clc;

%% 
% grid power prices for every hour, in cents per kWh
GridCost = [6; 6; 6; 6; 6; 6; 6; 6; 10; 10; 10; 10; 9; 
            9; 9; 9; 9; 10; 10; 6; 6; 6; 6; 6];
        
%% Job 1, Fixed nonDeferablePower
T = 24;
nonDeferLoad = zeros(T, 1);
neededPower = 4;
mergeData
sss = size(LoadTotal);
sss = sss(2);
price = zeros(3, sss);
periods = [1 2 3 4 6 8 12 24];
costBenifitForDiffDutyCycles = zeros(size(periods, 2), 1);
jjj = 1;


for period = periods
    for iii = 1 : sss
        nonDeferLoad = LoadTotal(:, iii);
        shiftTOU
        price(1, iii) = originalPrice;    
        price(2, iii) = cost;    %cost after optimization
        price(3, iii) = (originalPrice - cost) / originalPrice * 100;  %cost reduction
    end
    totalOriginalPrice = sum(price(1, :));
    totalOptimizedCost = sum(price(2, :));
    avgReduction = (totalOriginalPrice - totalOptimizedCost) / totalOriginalPrice * 100;
    costBenifitForDiffDutyCycles(jjj, 1) = avgReduction;
    jjj = jjj + 1;
end


shiftSimResultDataTOU = [periods' costBenifitForDiffDutyCycles];

plot(periods', costBenifitForDiffDutyCycles, 'r', 'LineWidth',2);
title('Average Electric Bill Cost Reduction(%) with Different Shiftable Load Periods');
xlabel('Shiftable Load Period (h)');
ylabel('Cost Reduction (%) ');
grid
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/shiftBenefitTOU', 'pdf') %Save figure

csvwrite('../simResults/shiftSimResultsTOU.csv', shiftSimResultDataTOU);