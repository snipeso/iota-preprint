function CleanData = remove_bad_aperiodic(Data, Slopes, Intercepts, RangeSlopes, RangeIntercepts, MaxBadChannels)
% removes bad epoch-channels based on aperiodic activity. Data is a Channel
% x Epoch x Frequency matrix. Slopes and Intercepts are Channel x Epoch.
% RangeSlopes and RangeIntercepts are like so: [0 3]. MaxBadChannels is the
% number of bad channels acceptable before the whole epoch is removed. 
%
% From iota-preprint, Snipes, 2024.

CleanData = oscip.remove_data_by_intercept(Data, Intercepts, RangeIntercepts(1), RangeIntercepts(2));
CleanData = oscip.remove_data_by_slopes(CleanData, Slopes, RangeSlopes(1), RangeSlopes(2));

% remove epochs where too many channels are missing
BadEpochs = sum(isnan(squeeze(CleanData(:, :, 1)))) > MaxBadChannels;

CleanData(:, BadEpochs, :) = nan;