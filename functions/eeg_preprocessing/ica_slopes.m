function Slopes = ica_slopes(EEG, Range)
% Slopes = ica_slopes(EEG, Range)
%
% identifies the slopes of each channel, used especially for detecting
% which components are noise vs EEG. Ranges is a 1 x 2 matrix that
% indicates which range to fit the aperiodic slope
%
% From iota-neurophys, by Snipes, 2024

Window = 4; % in seconds
SmoothFactor = 5; % in Hz

% convert EEG into ICA components
ICA = eeg_getdatact(EEG, 'component', 1:size(EEG.icaweights,1));

% computer spectral power
[Power, Freqs] = simple_power(ICA, EEG.srate, Window); % for components

% smooth it so fooof doesnt have a hard time
Power = smooth_frequencies(Power, Freqs, SmoothFactor);
Power(Power<=0) = min(Power(Power>0)); % make sure all values are positive; sometimes smoothing makes the spectrum dip below 0 a little bit


% run fooof on components
nChannels = size(Power, 1);
disp('getting fooof slopes')
Slopes = nan(nChannels, 1);
for Indx_Ch = 1:nChannels
    try
        Slopes(Indx_Ch) = simple_fooof_fit(Freqs, Power(Indx_Ch, :), Range);
    catch
        Slopes(Indx_Ch)= nan;
        warning('fooof didnt fit!')
    end
end