function plot_burst_mask(EEG, BandRange, CriteriaSet, YGap, PlotProps)

SampleRate = EEG.srate;

Bursts = burst_detection(EEG, BandRange, CriteriaSet);
Mask = cycy.utils.mask_bursts(EEG.data, Bursts);

PlotProps.Color.Generic = PlotProps.Color.Maps.Linear(128, :);
plot_eeg(Mask, SampleRate, YGap, PlotProps)