%% Model a slidable and stretchable load, here this load is the dish washer
e = [0 1 0 1 0 0];  % 1 means it is elastic phase, 0 otherwise
originPower = [0.1 2 0.1 2 0.25 0.1];    % power per phase, in kw
originDelta = [0.25 0.25 0.75 0.25 0.25 0.25];  % duration time per phase, in hours
startTime = 17;  % original starting time of the load
execTime = sum(originDelta);
powerPerCycle = sum(originPower);

numOfPhases = size(e, 2);

dishwasher = [24 24 execTime powerPerCycle];
