clear; close all; clc;

%% 
% grid power prices for every hour, in cents per kWh
GridCost = [6; 6; 6; 6; 6; 6; 6; 6; 10; 10; 10; 10; 9; 
            9; 9; 9; 9; 10; 10; 6; 6; 6; 6; 6];
beta = mean(GridCost);
adjustFactors = 0 : 0.5 : 10;
originCost = zeros(1, size(adjustFactors, 2));

costBenefitArr = zeros(1, size(adjustFactors, 2));
        
%% Job 1, Fixed nonDeferablePower
T = 24;
nonDeferLoad = zeros(T, 1);
mergeData
sss = size(LoadTotal);
sss = sss(2);
price = zeros(3, sss);

% Deferable Load Pattern Model
slidableLoads;
% Assume only one non preemptible job for now, dishwahser
job = clothesDryer;
deadline = job(1);
period = job(2);
execTime = job(3);
powerPerCycle = job(4);

slideDistance = 24 : 24;
costBenifitForDiffSlideDis = zeros(size(slideDistance, 2), 1);
jjj = 1;

kk = 1;

for adjustFactor = drange(adjustFactors)
    for slideDis = slideDistance
        for iii = 1 : sss
            nonDeferLoad = LoadTotal(:, iii);
            avgPowerPerDay = mean(nonDeferLoad);
            for k = 1 : T
                if nonDeferLoad(k) <= avgPowerPerDay
                    GridCost(k) = beta;
                else
                    GridCost(k) = (1 + adjustFactor) * beta;
                end
            end
            slideNew
            price(1, iii) = originalPrice;    
            price(2, iii) = cost;    %cost after optimization
            price(3, iii) = (originalPrice - cost) / originalPrice * 100;  %cost reduction
        end
        totalOriginalPrice = sum(price(1, :));
        totalOptimizedCost = sum(price(2, :));
        avgReduction = (totalOriginalPrice - totalOptimizedCost) / totalOriginalPrice * 100;
        costBenifitForDiffSlideDis(jjj, 1) = avgReduction;
        jjj = jjj + 1;
    end
    jjj = 1;
    costBenefitArr(kk) = costBenifitForDiffSlideDis(jjj, 1);
    kk = kk+ 1;
end


slideSimResultDataNew = [adjustFactors costBenefitArr];

plot(adjustFactors, costBenefitArr, 'r', 'LineWidth',4);
title('Average Electric Bill Cost Reduction(%) under New Pricing Plan');
xlabel('Adjust Factors (1x)');
ylabel('Cost Reduction (%) ');
grid
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/slideBenefitNew', 'pdf') %Save figure

csvwrite('../simResults/slideSimResultsNew.csv', slideSimResultDataNew);