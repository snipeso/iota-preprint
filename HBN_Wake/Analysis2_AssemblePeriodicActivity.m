% runs fooof on all wake recordings, and gets basic numbers that allow
% comparisons. updates metadata table, and creates big table of all
% detected peaks.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = HBNParameters();
Paths = Parameters.Paths;
Channels = Parameters.Channels;
Task = Parameters.Tasks{1};

Bands = struct();
Bands.Theta = [4 7];
Bands.Alpha = [8 13];
Bands.LowBeta = [14 17];
Bands.HighBeta = [17 25];
Bands.Gamma = [38 48];
Bands.Iota = [25 35];
BandLabels = fieldnames(Bands);
nBands = numel(BandLabels);

BandwidthRange = [.5 4];

FittingFrequencyRange = [3 50];
NoiseSmoothSpan = 5;
NoiseFittingFrequencyRange = [20 100];
MaxError = .1;
MinRSquared = .98;
MinCleanChannels = 80;

RangeSlopes = [0 3.5];
RangeIntercepts = [0 4];


SourceName = 'Clean'; ReferenceIdx = 513; PowerThreshold = 10^-10; % The last two are little hacks to exclude recordings that had the wrong sampling rate (it wasn't many, but I noticed too late)
% SourceName = 'Unfiltered'; ReferenceIdx = 600; PowerThreshold = 10^-5;
SourcePower = fullfile(Paths.Final, 'EEG', 'Power', '20sEpochs', SourceName);

CacheDir = Paths.Cache;
CacheName = ['PeriodicParameters_', SourceName, '.mat'];

if ~exist(CacheDir, 'dir')
    mkdir(CacheDir)
end

load(fullfile(Paths.Metadata, 'MetadataHBN.mat'), 'Metadata')
Files = list_filenames(SourcePower);
Files(~contains(Files, '.mat')) = [];
Participants = extractBefore(Files, '_RestingState');
Metadata(~ismember(Metadata.EID, Participants), :) = [];
Metadata = one_row_each(Metadata, 'EID');


%%%%%%%%%%%%%
%%% Set up blanks
nRecordings = size(Metadata, 1); % this does not consider tasks

PeriodicPeaks = table();
NoisePeriodicPeaks = table();

AllSpectra = nan(nRecordings, 1);
AllPeriodicSpectra = nan(nRecordings, 1);

CustomTopographies = nan(nRecordings, nBands, 123);
LogTopographies = CustomTopographies;
PeriodicTopographies = CustomTopographies;

for BandIdx = 1:nBands % does this first so that blanks have NaNs instead of 0s
    Metadata.([BandLabels{BandIdx}, 'Frequency']) = nan(nRecordings, 1);
    Metadata.([BandLabels{BandIdx}, 'Power'])= nan(nRecordings, 1);
end

ColumnNames = Metadata.Properties.VariableNames;
DSM_IDs = [find(contains(ColumnNames, 'DSM_')), find(contains(ColumnNames, '_isCurrent')), find(strcmp(ColumnNames, 'Diagnosis'))];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run

for RecordingIdx = 1:nRecordings

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
    SmoothPowerNoEdge = remove_bad_aperiodic(SmoothPowerNoEdge, Slopes, Intercepts, RangeSlopes, RangeIntercepts, MinCleanChannels);
    PeriodicPowerNoEdge = remove_bad_aperiodic(PeriodicPowerNoEdge, Slopes, Intercepts, RangeSlopes, RangeIntercepts, MinCleanChannels);

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
    AllSpectra(RecordingIdx, 1:numel(MeanPower)) = MeanPower;
    AllPeriodicSpectra(RecordingIdx, 1:size(PeriodicPowerNoEdge, 3)) = ...
        squeeze(mean(mean(PeriodicPowerNoEdge, 1, 'omitnan'), 2, 'omitnan'))';


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

    disp([num2str(RecordingIdx), '/', num2str(nRecordings)])
end

save(fullfile(CacheDir, CacheName), 'Metadata', 'PeriodicPeaks', 'NoisePeriodicPeaks', ...
    'Chanlocs', 'CustomTopographies', 'LogTopographies', 'PeriodicTopographies', ...
    'AllSpectra', 'AllPeriodicSpectra', 'Frequencies', 'FooofFrequencies', 'Bands')

