clear; close all; clc;

%% 
% grid power prices for every hour, in cents per kWh
GridCost = [2.7; 2.4; 2.3; 2.3; 2.3; 2.5; 2.8; 3.4; 3.8; 5; 6.1; 6.8; 7.4; 
            8.2; 10; 10.9; 11.9; 10.1; 9.2; 7; 7; 5.2; 4.2; 3.5];
 
% HARD CODED green power predicted for every hour, in kWh, Should BE DONE USING ML!!!
% OR USING the FORMULA: E_t = B_t * (1 - CloudCover)
GreenOriginal = [0; 0; 0; 0; 0; 0; 0.1; 0.2; 0.8; 1.2; 2.0; 2.5; 2.7; 3.2; 3.0; 
         2.5; 2.3; 1.7; 1.2; 0.5; 0; 0; 0; 0];
 
% alpha
alpha = 0.4;

infVal = 10;

        
%% Job 
T = 24;
Load = zeros(T, 1);
mergeData
sss = size(LoadTotal);
sss = sss(2);
price = zeros(3, sss);
amounts = 0 : 0.05: 1;    % in percentage of Green
costBenifitForDiffAmountGreen = zeros(size(amounts, 2), 1);
jjj = 1;


for amount = amounts
    for iii = 1 : sss
        Load = LoadTotal(:, iii);
        Green = GreenOriginal .* amount;
        sell
        price(1, iii) = originalPrice;    
        price(2, iii) = cost;    %cost after optimization
        price(3, iii) = (originalPrice - cost) / originalPrice * 100;  %cost reduction
    end
    totalOriginalPrice = sum(price(1, :));
    totalOptimizedCost = sum(price(2, :));
    avgReduction = (totalOriginalPrice - totalOptimizedCost) / totalOriginalPrice * 100;
    costBenifitForDiffAmountGreen(jjj, 1) = avgReduction;
    jjj = jjj + 1;
end


sellSimResultData = [amounts' costBenifitForDiffAmountGreen];

plot(amounts', costBenifitForDiffAmountGreen, 'r', 'LineWidth',2);
title('Average Electric Bill Cost Reduction(%) with Different Amount of Green Energy');
xlabel('Amount of Green Energy');
ylabel('Cost Reduction (%) ');
grid
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/sellBenefit', 'pdf') %Save figure

csvwrite('../simResults/sellSimResults.csv', sellSimResultData);