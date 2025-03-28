function Bursts = burst_detection(EEG, BandRange, CriteriaSet)

SampleRate = EEG.srate;

DataNarrowband = cycy.utils.highpass_filter(EEG.data, SampleRate, BandRange(1)); % if you want, you can specify other aspects of the filter; see function
DataNarrowband = cycy.utils.lowpass_filter(DataNarrowband, SampleRate, BandRange(2));
EEGNarrowband = EEG;
EEGNarrowband.data = DataNarrowband;

Band1 = struct();
Band1.Iota = BandRange;

Bursts = cycy.detect_bursts_all_channels(EEG, EEGNarrowband, Band1, ...
    CriteriaSet, false);