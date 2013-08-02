sellRTC = load('../simResults/sellSimResults.csv');
sellTOU = load('../simResults/sellSimResultsTOU.csv');
shiftRTC = load('../simResults/shiftSimResults.csv');
shiftTOU = load('../simResults/shiftSimResultsTOU.csv');
slideRTC = load('../simResults/slideSimResults.csv');
slideTOU = load('../simResults/slideSimResultsTOU.csv');
storeRTC = load('../simResults/storageSimResults.csv');
storeTOU = load('../simResults/storageSimResultsTOU.csv');
stretchRTC = load('../simResults/stretchSimResults.csv');
stretchTOU = load('../simResults/stretchSimResultsTOU.csv');
sellNew = load('../buildsys13-scheduling/graphs/sell/sellSimResultsNew.csv');
shiftNew = load('../buildsys13-scheduling/graphs/shift/shiftSimResultsNew.csv');
slideNew = load('../buildsys13-scheduling/graphs/slide/slideSimResultsNew.csv');
storeNew = load('../buildsys13-scheduling/graphs/store/storageSimResultsNew.csv');
stretchNew = load('../buildsys13-scheduling/graphs/stretch/stretchSimResultsNew.csv');
combinedNew = load('../buildsys13-scheduling/graphs/combined/combinedSimResultsNew.csv');
combinedNewBattGreen = load('../buildsys13-scheduling/graphs/combined/combinedSimResultsNewWithGreenBatt.csv');


figure 
plot(sellRTC(:, 1), sellRTC(:, 2), 'r', 'LineWidth',4);
hold
plot(sellTOU(:, 1), sellTOU(:, 2), 'b', 'LineWidth',4);
grid
xlabel('Renewable Energy (1x)');
ylabel('Electric Bill Cost Reduction (%)');
legend('RTP', 'TOU')
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/sellBenefitCombined', 'pdf') %Save figure

figure 
plot(shiftRTC(:, 1), shiftRTC(:, 2), 'r', 'LineWidth',4);
hold
plot(shiftTOU(:, 1), shiftTOU(:, 2), 'b', 'LineWidth',4);
grid
xlabel('Duty Cycle for a Shiftable Load (hours)');
ylabel('Electric Bill Cost Reduction (%)');
legend('RTP', 'TOU')
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/shiftBenefitCombined', 'pdf') %Save figure

figure 
plot(slideRTC(:, 1), slideRTC(:, 2), 'r', 'LineWidth',4);
hold
plot(slideTOU(:, 1), slideTOU(:, 2), 'b', 'LineWidth',4);
grid
xlabel('Slide Distance for a Slidable Load (hours)');
ylabel('Electric Bill Cost Reduction (%)');
legend('RTP', 'TOU')
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/slideBenefitCombined', 'pdf') %Save figure

figure 
plot(storeRTC(:, 1), storeRTC(:, 2), 'r', 'LineWidth',4);
hold
plot(storeTOU(:, 1), storeTOU(:, 2), 'b', 'LineWidth',4);
grid
xlabel('Battery Capacity (kwh)');
ylabel('Electric Bill Cost Reduction (%)');
legend('RTP', 'TOU')
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/storeBenefitCombined', 'pdf') %Save figure

figure 
plot(stretchRTC(:, 1), stretchRTC(:, 2), 'r', 'LineWidth',4);
hold
plot(stretchTOU(:, 1), stretchTOU(:, 2), 'b', 'LineWidth',4);
grid
xlabel('Stretch Factor (1x)');
ylabel('Electric Bill Cost Reduction (%)');
legend('RTP', 'TOU')
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/stretchBenefitCombined', 'pdf') %Save figure


RTP = load('benefit');
TOU = load('benefitTOU');
combinedRTP = load('combinedBenefitRTC');
combinedTOU = load('combinedBenefitTOU');
figure 
benefits = [11 21 21 39 14 87 23 145];
bar(benefits);
grid;
set(gca,'XTickLabel',{'combinedTOU', 'combinedTOUwithBattGreen', 'combinedRTP', 'combinedRTPwithBattGreen', 'SummedTOU', 'SummedTOUwithBattGreen', 'SummedRTP', 'SummedRTPwithBattGreen'})
ylabel('Electric Bill Cost Reduction (%)');
xticklabel_rotate;
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/combinedBarGraph', 'pdf') %Save figure


figure 
plot(combinedNew(1, :), combinedNew(2, :), 'r', 'LineWidth',4);
hold
plot(combinedNewBattGreen(1, :), combinedNewBattGreen(2, :), 'b', 'LineWidth',4);
grid
xlabel('alpha (1x)');
ylabel('Electric Bill Cost Reduction (%)');
legend('without Battery and Green', 'with Battery and Green', 'Location','South')
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/CombinedNew', 'pdf') %Save figure