load(fullfile(CacheDir, CacheName),  'AllSpectra',  'Frequencies', 'Metadata')


Spectra = AllSpectra(isnan(Metadata.AlphaFrequency), :);
AllTable = table();
MissedIotas = {};
Met = Metadata(isnan(Metadata.AlphaFrequency), :);

for RowIdx = 1:size(Spectra, 1)
    Table = all_peak_parameters(Frequencies, Spectra(RowIdx, :), [3 50], Met(RowIdx, 1:4), RowIdx, .98, .2);
    AllTable = [AllTable; Table];

    if ~(isempty(Table)) & any(Table.Frequency<=35 & Table.Frequency>25)
        MissedIotas = cat(1, MissedIotas, Met.EID(RowIdx));
    end
end

figure
Axes = plot_periodicpeaks(AllTable, [3 50], [0 12], [5 21], true, PlotProps);


function Table = all_peak_parameters(Freqs, MeanPower, FittingFrequencyRange, MetadataRow, TaskIdx, MinRSquared, MaxError)

% set up new row
MetadataRow.Frequency = nan;
MetadataRow.BandWidth = nan;
MetadataRow.Power = nan;
MetadataRow.TaskIdx = TaskIdx;

% fit fooof
[~, ~, ~, PeriodicPeaks, ~, ~, ~] = oscip.fit_fooof(MeanPower, Freqs, FittingFrequencyRange, MaxError, MinRSquared);

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

