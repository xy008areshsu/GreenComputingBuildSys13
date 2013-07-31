clear; clc; close all
alphas = 0 : 0.5 : 15;

minCost = inf(1, size(alphas, 2));
minAlpha = zeros(1, size(alphas, 2));
i = 1;

for alpha = drange(alphas)
    for j = 1: 0.5 : alpha
        cost = stretchFuncTOU(j);
        if cost < minCost(i)
            minCost(i) = cost;
            minAlpha(i) = j;
        end
    end
    i = i + 1;
end
    
originCost = stretchFuncTOU(1);
costReduction = ((originCost - minCost) ./ originCost) .* 100;

stretchSimResultDataTOU = [alphas' costReduction'];

plot(alphas', costReduction', 'r', 'LineWidth',2);
title('Average Electric Bill Cost Reduction(%) with Different Stretching Factors');
xlabel('Stretching Factors');
ylabel('Cost Reduction (%) ');
grid
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/stretchBenefitTOU', 'pdf') %Save figure

csvwrite('../simResults/stretchSimResultsTOU.csv', stretchSimResultDataTOU);