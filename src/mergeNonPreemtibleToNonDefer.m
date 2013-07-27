function [ newNonDeferLoad ] = mergeNonPreemtibleToNonDefer( nonDeferLoad, powerPerInterval, startTime, execTime )
%MERGENONPREEMTIBLETONONDEFER Summary of this function goes here
%   Detailed explanation goes here
    newNonDeferLoad = nonDeferLoad;
    for i = startTime : startTime + execTime - 1
        index = mod(i, 24);
        if index == 0
            index = 1;
        end
        newNonDeferLoad(index) = newNonDeferLoad(index) + powerPerInterval;
    end
        
end

