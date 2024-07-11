function CleanData = remove_bad_aperiodic(Data, Slopes, Intercepts, RangeSlopes, RangeIntercepts)
% removes bad epoch-channels based on aperiodic activity

CleanData = oscip.remove_data_by_intercept(Data, Intercepts, RangeIntercepts(1), RangeIntercepts(2));
CleanData = oscip.remove_data_by_slopes(CleanData, Slopes, RangeSlopes(1), RangeSlopes(2));