clear; close all; clc;

%% 
% grid power prices for every hour, in cents per kWh, TOU
c = [6; 6; 6; 6; 6; 6; 6; 6; 10; 10; 10; 10; 9; 
            9; 9; 9; 9; 10; 10; 6; 6; 6; 6; 6];
        
        GridCost = c;
        
%% Job 1, Fixed nonDeferablePower
T = 24;
Load = zeros(T, 1);
neededPower = 4;
period = 24;
mergeData
sss = size(LoadTotal);
sss = sss(2);
price = zeros(3, sss);
Capa = 10:5:10;
costBenifitForDiffCapa = zeros(size(Capa, 2), 1);
jjj = 1;


for C = Capa
    for iii = 1 : sss
        Load = LoadTotal(:, iii);
        storageTOU
        price(1, iii) = originalPrice;    
        price(2, iii) = cost;    %cost after optimization
        price(3, iii) = (originalPrice - cost) / originalPrice * 100;  %cost reduction
    end
    totalOriginalPrice = sum(price(1, :));
    totalOptimizedCost = sum(price(2, :));
    avgReduction = (totalOriginalPrice - totalOptimizedCost) / totalOriginalPrice * 100;
    costBenifitForDiffCapa(jjj, 1) = avgReduction;
    jjj = jjj + 1;
end


storageSimResultDataTOU = [Capa' costBenifitForDiffCapa];

plot(Capa', costBenifitForDiffCapa, 'r', 'LineWidth',2);
title('Average Electric Bill Cost Reduction(%) with Different Battery Capacities');
xlabel('Battery Capacity (kWh)');
ylabel('Cost Reduction (%) ');
grid
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/storageBenefitTOU', 'pdf') %Save figure

csvwrite('../simResults/storageSimResultsTOU.csv', storageSimResultDataTOU);

        