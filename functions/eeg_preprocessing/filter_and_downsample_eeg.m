function EEG = filter_and_downsample_eeg(EEG, Parameters)
% EEG = filter_and_downsample_eeg(EEG, Parameters)
%
% EEG is an EEGLAB structure
% Parameters should be a struct with fields: 
%  - .fs (sample rate)
%  - .lp (low pass filter limit)
%  - .hp (high pass filter limit)
%  - .hp_stopband 
%  - .line (frequency of line noise
%
% from iota-neurophys, Sophia Snipes, 2024


% set selected parameters
new_fs = Parameters.fs;
lowpass = Parameters.lp;
highpass = Parameters.hp;
hp_stopband = Parameters.hp_stopband;
line_noise = Parameters.line;


% center each channel to its mean
EEG = center_eeg(EEG);

% low-pass filter
if ~isempty(lowpass)
    EEG = pop_eegfiltnew(EEG, [], lowpass); % this is a form of antialiasing, but it not really needed because usually we use 40hz with 256 srate
end

% notch filter for line noise
if ~isempty(line_noise)
    EEG = line_filter(EEG, line_noise, false);
end

% resample
if isempty(new_fs) || EEG.srate ~= new_fs
    EEG = pop_resample(EEG, new_fs);
end

% high-pass filter
% NOTE: this is after resampling, otherwise crazy slow.
if ~isempty(highpass)
    EEG = highpass_eeg(EEG, highpass, hp_stopband);
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions


function EEG = center_eeg(EEG)

% for data with major DC shifts

Means = mean(EEG.data, 2);
EEG.data = EEG.data - Means;
end
