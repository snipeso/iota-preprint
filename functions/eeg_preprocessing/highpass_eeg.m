function EEG_filt = highpass_eeg(EEG, high_pass, hp_stopband)
% EEG_filt = highpass_eeg(EEG, high_pass, hp_stopband)
%
% special filter for high-pass filtering; done to have more control over
% the stopband.
%
% from iota-neurophys, Sophia Snipes, 2024

fs = EEG.srate;
StopAtten = 60;
PassRipple = 0.05;

hpFilter = designfilt('highpassfir', 'PassbandFrequency', high_pass, ...
    'StopbandFrequency', hp_stopband, 'StopbandAttenuation', StopAtten, ...
    'PassbandRipple', PassRipple, 'SampleRate', fs, 'DesignMethod', 'kaiser');

EEG_filt = firfilt(EEG, hpFilter.Coefficients);

