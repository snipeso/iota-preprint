function MaxPeak = select_max_peak(Table, FrequencyRange, BandwidthRange)
%  MaxPeak = select_max_peak(Table, FrequencyRange, BandwidthRange)
%
% selects a single peak within a given band.
%
% from iota-neurophys, Snipes, 2024.

if isempty(Table)
    MaxPeak = [];
    return
end

PeakIdx = Table.Frequency>=FrequencyRange(1) & Table.Frequency<=FrequencyRange(2) & ...
    Table.BandWidth>=BandwidthRange(1) & Table.BandWidth <= BandwidthRange(2);

if nnz(PeakIdx)>1 % if multiple iota peaks
    RangeIndexes = find(PeakIdx); % turn to numbers instead of boolean indexes
    [~, MaxIdx] = max(Table.Power(RangeIndexes)); % find the one corresponding to the highest amplitude peak
    PeakIdx = RangeIndexes(MaxIdx); % make that the iota for the next analyses
elseif nnz(PeakIdx) == 0
    MaxPeak = [];
    return
end

MaxPeak = Table{PeakIdx, {'Frequency', 'Power', 'BandWidth'}};
end