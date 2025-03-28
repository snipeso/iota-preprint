function [BadSegments, BadCh, BadWindows_t, Starts, Ends] = ...
    find_bad_segments(EEG, Window, MinNeighborCorrelation, MaxProportionUniqueCorr, ...
    NotEEGChannels, CorrectCz, MinDataKeep, CorrelationFrequencyRange, AmplitudeThreshold)
% [BadSegments, BadCh, BadWindows_t, Starts, Ends] =  find_bad_segments(EEG, Window, MinNeighborCorrelation, MaxProportionUniqueCorr, NotEEGChannels, CorrectCz, MinDataKeep, CorrelationFrequencyRange, AmplitudeThreshold)
%
% Based on correlations with neighboring channels, identifies bad channels
% and timewindows with artefacts. EEG is an EEGLAB structure. Window is in
% seconds the duration of windows to check for bad segments (~4 s),
% MinNeighborCorrelation is how much each channel should correlate to its
% neighbors before being considered an artefact. NotEEGChannels is channels
% that shouldn't correlate with "neighbors" and so won't be considered for
% the preprocessing anyway. CorectCz is a boolean; because of reference,
% this correlation with neighbor's trick doesn't work so well. so to see
% bad channels around Cz, rereference the data, and use those correlation
% values.
% MinDataKeep is for when you don't want to deal with isolated segments,
% and instead just toss out either the entire channel or the entire
% segment. so here you indicate the minimmum amount of data that is
% artefactual that you would still keep as a segment or channel.
% BadWindows_t is a vector the length of the data to indicate which are bad
% timepoints
%
% From iota-neurophys by Sophia Snipes, 2024

if ~exist("AmplitudeThreshold", 'var')
    AmplitudeThreshold = 500; % maximum microvolts before give up entirely on the channel/window
end

AlternateRef = 16; % different reference to evaluate correlations of channels near the reference
CZPatch = [7 55 106 31 80]; % channels to re-evaluate with different reference

fs = EEG.srate;
[nCh, nPnts] = size(EEG.data);
Chanlocs = EEG.chanlocs;

% filter EEG so correlation not unduely influenced by muscle
if exist('CorrelationFrequencyRange', 'var')
    EEG = pop_eegfiltnew(EEG, CorrelationFrequencyRange(1), []);
    EEG = pop_eegfiltnew(EEG, [], CorrelationFrequencyRange(2));
end

NotEEGChannels = labels2indexes(NotEEGChannels, Chanlocs); % don't consider not-eeg channels when determining noise
AlternateRefEEG = pop_reref(EEG, AlternateRef);
AlternatePatchIndx = labels2indexes(CZPatch, AlternateRefEEG.chanlocs);
PatchIndx = labels2indexes(CZPatch, Chanlocs);



%%% loop through segments of data to find bad windows
Starts = round(1:Window*fs:nPnts);
Ends = round(Starts+Window*fs-1);
Starts(end) = [];
Ends(end) = [];

BadSegments = zeros(nCh, numel(Starts)); % assign for each channel in each segment a 0 for clean and a 1 for artefact and 2 for unforgivable artefact (really high amplitude)

Uniques = nan(1, numel(Starts));
AllSlopes = nan(nCh, numel(Starts));
for Indx_S = 1:numel(Starts)

    % get segment of data
    Data = EEG.data(:, Starts(Indx_S):Ends(Indx_S));

    % Later, I realized the following would be good to do. It's not used in the data for the iota paper, but I will use it later
    
    %%% identify how many unique correlations there are (rounding to 3 decimal points)
    % The logic: when the data is physiological, there shouldn't be
    % channels correlating excessively with a subset of other channels;
    % they should all have different correlations with each other. But when
    % there's a lot of bridging, or the EEG data was completly detatched,
    % then there will be only a small pool of unique correlations.
    %
    % % correlate all channels
    % Correlations = corr_channels(Data, Chanlocs, '');

    % NonNanCorr = Correlations(~isnan(Correlations));
    % Unique = numel(unique(round(NonNanCorr, 3)))/numel(NonNanCorr);
    % Uniques(Indx_S) = Unique;
    % if Unique < MaxProportionUniqueCorr
    %     BadSegments(:, Indx_S) = 1;
    %     continue
    % end

    % correlate to neighbors
    Correlations = corr_channels(Data, Chanlocs, 'Neighbor');

    % remove channels that are not EEG
    Correlations(NotEEGChannels, :) = nan;
    Correlations(:, NotEEGChannels) = nan;

    % if cz reference, redo corr for channels around cz
    if exist("CorrectCz", 'var') && CorrectCz
        if mean(Correlations(AlternateRef, :), 'omitnan') > MinNeighborCorrelation % if the alternative reference is a good channel
            AlternateRefData =  AlternateRefEEG.data(:, Starts(Indx_S):Ends(Indx_S));

            % correlate it
            AlternateCorrelations = corr_channels(AlternateRefData, AlternateRefEEG.chanlocs, 'Neighbor');
            Correlations(PatchIndx, PatchIndx) = AlternateCorrelations(AlternatePatchIndx, AlternatePatchIndx);
        else % if alternative reference is bad, then just give up on the whole epoch
            BadSegments(:, Indx_S) = 1;
            continue
        end
    end

    % find bad channels that aren't correlated
    Worst = find_worst_channels(Correlations, MinNeighborCorrelation);
    BadSegments(Worst, Indx_S) = 1;

    % find segments with crazy high amplitudes
    AbsoluteWorst = any(abs(Data)>AmplitudeThreshold, 2); % if voltage is too crazy high, then it absolutely has to be removed; some bad segments can otherwise be tolerated
    BadSegments(AbsoluteWorst, Indx_S) = 2;
end


%%% only completely remove segments or not
if exist('MinDataKeep', 'var')

    % remove at all costs bad segments with 2s
    AbsoluteBadSegments = remove_channel_or_window(BadSegments==2, 0);

    % remove at all costs bad windows/channels losing more than X% of data
    BadSegments = remove_channel_or_window(BadSegments, MinDataKeep);
    % Fixed: BadSegments = remove_channel_or_window(BadSegments~=0, MinDataKeep);

    BadSegments(AbsoluteBadSegments) = 1;
end

%%% identify all-bad windows and all-bad channels
BadCh = find(all(BadSegments, 2))';

BadWindows_t = true(1, nPnts);
BadWindows = all(BadSegments, 1);

for Indx_S = 1:numel(Starts)
    if ~BadWindows(Indx_S)
        BadWindows_t(Starts(Indx_S):Ends(Indx_S)) = 0;
    end
end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function Worst = find_worst_channels(R, Threshold)

Remaining = R;
Worst = [];

while any(mean(Remaining, 'omitnan')<Threshold)
    [~, Indx] = min(mean(Remaining, 'omitnan'));
    Worst = cat(1, Worst, Indx);

    Remaining(Indx, :) = nan;
    Remaining(:, Indx) = nan;
end
end




