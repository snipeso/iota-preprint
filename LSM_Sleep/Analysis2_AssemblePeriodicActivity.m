% runs fooof on all wake recordings, and gets basic numbers that allow
% comparisons. updates metadata table, and creates big table of all
% detected peaks.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = LSMParameters();
Paths = Parameters.Paths;
Channels = Parameters.Channels;
Task = Parameters.Tasks{1};
Participants = Parameters.Participants;

Bands = struct();
Bands.Theta = [4 8];
Bands.Alpha = [8 12];
Bands.Sigma = [12 16];
Bands.Beta = [16 25];
Bands.Iota = [25 35];
BandLabels = fieldnames(Bands);
nBands = numel(BandLabels);

BandwidthRange = [.5 4];

FittingFrequencyRange = [3 50];
NoiseSmoothSpan = 5;
NoiseFittingFrequencyRange = [20 100];
MaxError = .1;
MinRSquared = .98;
MaxBadChannels = 50;

RangeSlopes = [0 3.5];
RangeIntercepts = [0 4];

SourceName = 'Minimal'; nFrequencies = 513;
SourcePower = fullfile(Paths.Final, 'EEG', 'Power', '20sEpochs', SourceName);

CacheDir = Paths.Cache;
CacheName = ['PeriodicParameters_', SourceName, '.mat'];

if ~exist(CacheDir, 'dir')
    mkdir(CacheDir)
end

%%%%%%%%%%%%%
%%% Set up blanks
nParticipants = numel(Participants); % this does not consider tasks

PeriodicPeaks = table();

AllSpectra = nan(nParticipants, nFrequencies);
AllPeriodicSpectra = nan(nParticipants, 192);

CustomTopographies = nan(nParticipants, nBands, 123);
LogTopographies = CustomTopographies;
PeriodicTopographies = CustomTopographies;

for BandIdx = 1:nBands
    Metadata.([BandLabels{BandIdx}, 'Frequency']) = nan(nParticipants, 1);
    Metadata.([BandLabels{BandIdx}, 'Power'])= nan(nParticipants, 1);
end

ColumnNames = Metadata.Properties.VariableNames;
DSM_IDs = [find(contains(ColumnNames, 'DSM_')), find(contains(ColumnNames, '_isCurrent')), find(strcmp(ColumnNames, 'Diagnosis'))];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run

for RecordingIdx = 1:nParticipants

    Participant = Metadata.EID{RecordingIdx};
    Filepath = fullfile(SourcePower, [Participant, '_', Task, '.mat']);

    if ~exist(Filepath, 'file')
        continue
    end

    % load in data
    load(Filepath,  'SmoothPower', 'Frequencies', 'Chanlocs', 'PeriodicPower', 'FooofFrequencies', 'Slopes', 'Intercepts')

    SmoothPowerNoEdge = SmoothPower;
    PeriodicPowerNoEdge = PeriodicPower;
    %%% Get periodic peaks

    % remove edge channels
    SmoothPowerNoEdge(labels2indexes(Channels.Edge, Chanlocs), :, :) = nan;
    PeriodicPowerNoEdge(labels2indexes(Channels.Edge, Chanlocs), :, :) = nan;

    % remove data based on aperiodic activity
    SmoothPowerNoEdge = remove_bad_aperiodic(SmoothPowerNoEdge, Slopes, Intercepts, RangeSlopes, RangeIntercepts, MaxBadChannels);
    PeriodicPowerNoEdge = remove_bad_aperiodic(PeriodicPowerNoEdge, Slopes, Intercepts, RangeSlopes, RangeIntercepts, MaxBadChannels);

    %  average power
    MeanPower = squeeze(mean(mean(SmoothPowerNoEdge, 1, 'omitnan'), 2, 'omitnan'))'; % its important that the channels are averaged first!

    % check if the data is too low after 100 Hz (means that its from the
    % few recordings that weren't sampled at 500 Hz, so remove)
    if MeanPower(ReferenceIdx) < PowerThreshold
        warning(['Skipping ', Participant, ' because wrong sampling rate'])
        continue
    end

    % find all peaks in average power spectrum
    Table = all_peak_parameters(Frequencies, MeanPower, FittingFrequencyRange, Metadata(RecordingIdx, [1:4, DSM_IDs]), RecordingIdx, MinRSquared, MaxError);
    PeriodicPeaks = cat(1, PeriodicPeaks, Table);

    % repeat for full spectrum
    MeanSmoothPower = oscip.smooth_spectrum(MeanPower, Frequencies, NoiseSmoothSpan);

    NoiseTable = all_peak_parameters(Frequencies, MeanSmoothPower, NoiseFittingFrequencyRange, Metadata(RecordingIdx, [1:4, DSM_IDs]), RecordingIdx, .9, .2);
    NoisePeriodicPeaks = cat(1, NoisePeriodicPeaks, NoiseTable);

    %%% get mean spectra
    AllSpectra(RecordingIdx, :) = MeanPower;
    AllPeriodicSpectra(RecordingIdx, :) = squeeze(mean(mean(PeriodicPowerNoEdge, 1, 'omitnan'), 2, 'omitnan'))';


    %%% get topographies & custom peaks
    for BandIdx = 1:nBands

        % standard range
        Range = dsearchn(Frequencies', Bands.(BandLabels{BandIdx})');
        LogTopographies(RecordingIdx, BandIdx, 1:numel(Chanlocs)) = ...
            squeeze(mean(mean(log10(SmoothPower(:, :, Range(1):Range(2))), 3, 'omitnan'), 2, 'omitnan'));

        Range = dsearchn(FooofFrequencies', Bands.(BandLabels{BandIdx})');
        PeriodicTopographies(RecordingIdx, BandIdx, 1:numel(Chanlocs)) = ...
            squeeze(mean(mean(PeriodicPower(:, :, Range(1):Range(2)), 3, 'omitnan'), 2, 'omitnan'));

        % custom topography
        Peak = select_max_peak(Table, Bands.(BandLabels{BandIdx}), BandwidthRange);

        if ~isempty(Peak)
            CustomRange = dsearchn(FooofFrequencies', [Peak(1)-Peak(3)/2; Peak(1)+Peak(3)/2]);
            CustomTopographies(RecordingIdx, BandIdx, 1:numel(Chanlocs)) = ...
                squeeze(mean(mean(PeriodicPower(:, :, CustomRange(1):CustomRange(2)), 3, 'omitnan'), 2, 'omitnan'));

            % save peak information to metadata
            Metadata.([BandLabels{BandIdx}, 'Frequency'])(RecordingIdx) = Peak(1);
            Metadata.([BandLabels{BandIdx}, 'Power'])(RecordingIdx) = Peak(2);
        end

    end

    disp([num2str(RecordingIdx), '/', num2str(nParticipants)])
end

save(fullfile(CacheDir, CacheName), 'Metadata', 'PeriodicPeaks', 'NoisePeriodicPeaks', ...
    'Chanlocs', 'CustomTopographies', 'LogTopographies', 'PeriodicTopographies', ...
    'AllSpectra', 'AllPeriodicSpectra', 'Frequencies', 'FooofFrequencies', 'Bands')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function Table = all_peak_parameters(Freqs, Power, FittingFrequencyRange, MetadataRow, TaskIdx, MinRSquared, MaxError)
% fits fooof on power, saves relevant information

% set up new row
MetadataRow.Frequency = nan;
MetadataRow.BandWidth = nan;
MetadataRow.Power = nan;
MetadataRow.TaskIdx = TaskIdx;

% fit fooof
[~, ~, ~, PeriodicPeaks, ~, ~, ~] = oscip.fit_fooof(Power, Freqs, FittingFrequencyRange, MaxError, MinRSquared);

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



function MaxPeak = select_max_peak(Table, FrequencyRange, BandwidthRange)
% selects a single peak for each band

if isempty(Table)
    MaxPeak = [];
    return
end

PeakIdx = Table.Frequency>=FrequencyRange(1) & Table.Frequency<=FrequencyRange(2) & ...
    Table.BandWidth>=BandwidthRange(1) & Table.BandWidth <= BandwidthRange(2);

if nnz(PeakIdx)>1 % if multiple iota peaks
    RangeIndexes = find(PeakIdx); % turn to numbers instead of boolean indexes
    [~, MaxIdx] = max(Table.Power(RangeIndexes)); % find the one corresponding to the highest amplitude peak
    PeakIdx = RangeIndexes(MaxIdx); % make that the iota for the next analyses
elseif nnz(PeakIdx) == 0
    MaxPeak = [];
    return
end

MaxPeak = Table{PeakIdx, {'Frequency', 'Power', 'BandWidth'}};
end