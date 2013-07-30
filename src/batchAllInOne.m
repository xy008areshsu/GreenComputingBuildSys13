clear; clc; close all;

%% individual benefit sum
% RTC
sellBatch
benefitRTC = 0;
benefitRTC = costBenifitForDiffAmountGreen + benefitRTC;
csvwrite('benefit',benefitRTC);
shiftBatch;
benefitRTC = load('benefit');
benefitRTC = costBenifitForDiffDutyCycles + benefitRTC;
csvwrite('benefit',benefitRTC);
slideBatch;
benefitRTC = load('benefit');
benefitRTC = costBenifitForDiffSlideDis + benefitRTC;
csvwrite('benefit',benefitRTC);
storageBatch;
benefitRTC = load('benefit');
benefitRTC = costBenifitForDiffCapa + benefitRTC;
csvwrite('benefit',benefitRTC);
strechBatch;
benefitRTC = load('benefit');
benefitRTC = costReduction + benefitRTC;
csvwrite('benefit',benefitRTC);


% TOU
sellBatchTOU
benefitTOU = 0;
benefitTOU = costBenifitForDiffAmountGreen + benefitTOU;
csvwrite('benefitTOU',benefitTOU);
shiftBatchTOU;
benefitTOU = load('benefitTOU');
benefitTOU = costBenifitForDiffDutyCycles + benefitTOU;
csvwrite('benefitTOU',benefitTOU);
slideBatchTOU;
benefitTOU = load('benefitTOU');
benefitTOU = costBenifitForDiffSlideDis + benefitTOU;
csvwrite('benefitTOU',benefitTOU);
storageBatchTOU;
benefitTOU = load('benefitTOU');
benefitTOU = costBenifitForDiffCapa + benefitTOU;
csvwrite('benefitTOU',benefitTOU);
strechBatchTOU;
benefitTOU = load('benefitTOU');
benefitTOU = costReduction + benefitTOU;
csvwrite('benefitTOU',benefitTOU);


%% Combined Benefit
% RTC

conbinedBatch
combinedBenefitRTC = 0;
combinedBenefitRTC = combinedBenefitRTC + costBenefit;
csvwrite('combinedBenefitRTC',combinedBenefitRTC);

% TOU
conbinedBatchTOU
combinedBenefitTOU = 0;
combinedBenefitTOU = combinedBenefitTOU + costBenefit;
csvwrite('combinedBenefitTOU',combinedBenefitTOU);

