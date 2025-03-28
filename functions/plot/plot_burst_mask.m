function plot_burst_mask(EEG, BandRange, CriteriaSet, YGap, PlotProps)

SampleRate = EEG.srate;


DataNarrowband = cycy.utils.highpass_filter(EEG.data, SampleRate, BandRange(1)); % if you want, you can specify other aspects of the filter; see function
DataNarrowband = cycy.utils.lowpass_filter(DataNarrowband, SampleRate, BandRange(2));
EEGNarrowband = EEG;
EEGNarrowband.data = DataNarrowband;

Band1 = struct();
Band1.Iota = BandRange;

Bursts = cycy.detect_bursts_all_channels(EEG, EEGNarrowband, Band1, ...
    CriteriaSet, true);
Mask = cycy.utils.mask_bursts(EEG.data, Bursts);

PlotProps.Color.Generic = PlotProps.Color.Maps.Linear(128, :);
plot_eeg(Mask, SampleRate, YGap, PlotProps)