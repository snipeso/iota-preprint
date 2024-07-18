load('D:\Data\AllWake\Preprocessed\Power\MAT\Providence\Oddball\P168_Providence_Session1_mor_Oddball_n_3.mat')

EEGMain = EEG;
P = HBNParameters();

Spread = 0; % how many times more the main component has to be larger than the next largest component ("Spread" is a reference to the italian term "spread" referring to the difference between the yields of italian and german bonds)
SlopeRange = [8 30];
MuscleSlopeMin = .5;
ChopEdge = 2; % in seconds, cut off these many seconds at the beginning and end of recordings
WindowLength = 3; % s, bad time windows
RemoveComps = [2, 3, 4, 6]; % 1:Brain, 2:Muscle, 3:Eye, 4:Heart, 5:Line Noise, 6:Channel Noise, 7:Other
MinTime = 60; % minimum time to keep data in seconds
MinNeighborCorrelation = .3;
MinChannels = 25; % maximum number of channels that can be removed
CorrelationFrequencyRange = [4 40];
MaxPorportionUniqueCorr = .02; % the minimum number of unique correlation values across channels when rounding correlations to 3 decimal points
NotEEGChannels = [49, 56, 107, 113, 126, 127];

% EEGLAB preprocessing
MinCorrelation =    0.500; % their defaults. Somehow, the function for finding bad channels without using channel locations worked a lot better
NoLocsChannelCritExcluded =    0.1000; % their defaults
MinDataKeep =  0.3000; %  this should be between .1 or .3, with smaller being stricter cleaning
WindowCriteriaTolerances = [-Inf, 12]; % their defaults
ChannelCriteriaMaxBadTime = 0.5000;
MaxAmplitude = 150;


% convert to double (for ICA)
EEG.data = double(EEG.data);

% remove bad channels and really bad timepoints
[~, BadChannels, BadWindows_t] = find_bad_segments(EEG, WindowLength, MinNeighborCorrelation, ...
    MaxPorportionUniqueCorr, NotEEGChannels, true, MinDataKeep, CorrelationFrequencyRange);

BadWindows_t(1:ChopEdge*EEG.srate) = 1;
BadWindows_t(end-ChopEdge*EEG.srate:end) = 1;

% adjust metadata
EEG.data(:, BadWindows_t) = [];
EEG.pnts = size(EEG.data, 2);
EEG = eeg_checkset(EEG);

            FlatChannels = find_flat_channels(EEG);

            % save info of which are bad channels
            EEG.badchans = unique([BadChannels, FlatChannels]);

% remove really bad channels
EEG = pop_select(EEG, 'nochannel', EEG.badchans);

% remove bad timepoints
EEG = clean_artifacts(EEG, ...
    'FlatlineCriterion', 'off', ...
    'Highpass', 'off', ...
    'ChannelCriterion', 'off', ...
    'LineNoiseCriterion', 'off', ...
    'BurstRejection', 'off',...
    'BurstCriterion', 'off', ...
    'BurstCriterionRefMaxBadChns', 'off', ...
    'WindowCriterion', .1); % quite strict

