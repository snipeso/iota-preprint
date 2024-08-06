function plot_burst_mask(EEG, Range, YGap, PlotProps)

SampleRate = EEG.srate;
CriteriaSet = struct();

CriteriaSet.MonotonicityInAmplitude = 0.9;
CriteriaSet.AmplitudeConsistency = .3; % left and right cycles should be of similar amplitude
CriteriaSet.isTruePeak = 1;
CriteriaSet.isProminent = 1;
CriteriaSet.MinCyclesPerBurst = 4;
CriteriaSet.ShapeConsistency = .4;
CriteriaSet.FlankConsistency = .4;


DataNarrowband = cycy.utils.highpass_filter(EEG.data, SampleRate, Range(1)); % if you want, you can specify other aspects of the filter; see function
DataNarrowband = cycy.utils.lowpass_filter(DataNarrowband, SampleRate, Range(2));
EEGNarrowband = EEG;
EEGNarrowband.data = DataNarrowband;

Band1 = struct();
Band1.Iota = Range;

Bursts = cycy.detect_bursts_all_channels(EEG, EEGNarrowband, Band1, ...
    CriteriaSet, true);
Mask = cycy.utils.mask_bursts(EEG.data, Bursts);


% PlotProps.Color.Generic = PlotProps.Color.Maps.Linear(128, :);
PlotProps.Color.Generic = [222 67 117]/255;

plot_eeg(Mask, SampleRate, YGap, PlotProps)