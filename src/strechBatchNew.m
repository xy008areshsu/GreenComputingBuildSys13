clear; clc; close all
alphas = 4 : 0.5 : 4;
adjustFactors = 0 : 0.5 : 6;
originCost = zeros(1, size(adjustFactors, 2));

costArr = zeros(1, size(adjustFactors, 2));
minCost = inf(1, size(alphas, 2));
minAlpha = zeros(1, size(alphas, 2));
i = 1;
k = 1;

for adjustFactor = drange(adjustFactors)
    for alpha = drange(alphas)
        for j = 1: 0.5 : alpha
            cost = stretchFuncNew(j, adjustFactor);
            if cost < minCost(i)
                minCost(i) = cost;
                minAlpha(i) = j;
            end
        end
        i = i + 1;
    end
    i = 1;
    costArr(k) = minCost(i);
    originCost(k) = stretchFuncNew(1, adjustFactor);
    k = k + 1;
end
    
% originCost = stretchFuncNew(1, 0);
costReduction = ((originCost - costArr) ./ originCost) .* 100;

stretchSimResultDataNew = [adjustFactors' costReduction'];

plot(adjustFactors', costReduction', 'r', 'LineWidth',4);
% title('Average Electric Bill Cost Reduction(%) under New Pricing Plan');
xlabel('alpha (1x)');
ylabel('Cost Reduction (%) ');
grid
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/stretchBenefitNew', 'pdf') %Save figure

csvwrite('../simResults/stretchSimResultsNew.csv', stretchSimResultDataNew);