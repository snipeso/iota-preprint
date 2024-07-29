function Table = all_peak_parameters(Freqs, Power, FittingFrequencyRange, MetadataRow, TaskIdx, MinRSquared, MaxError)
% fits fooof on power, saves relevant information

% set up new row
MetadataRow.Frequency = nan;
MetadataRow.BandWidth = nan;
MetadataRow.Power = nan;
MetadataRow.TaskIdx = TaskIdx;

% fit fooof
[~, ~, ~, PeriodicPeaks, ~, ~, ~] = oscip.fit_fooof(Power, Freqs, FittingFrequencyRange, MaxError, MinRSquared);

PeriodicPeaks = oscip.exclude_edge_peaks(PeriodicPeaks, FittingFrequencyRange); % exclude any bursts that extend beyond the edges of the investigated range

if isempty(PeriodicPeaks)
    Table = table();
    return
end

Table = repmat(MetadataRow, size(PeriodicPeaks, 1), 1);
Table.Frequency = PeriodicPeaks(:, 1);
Table.Power = PeriodicPeaks(:, 2);
Table.BandWidth = PeriodicPeaks(:, 3);
end
