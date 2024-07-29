% runs fooof on all sleep recordings, and gets basic numbers that allow
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
Task = Parameters.Task;
Session = Parameters.Session;
Participants = Parameters.Participants;

Bands = struct();
Bands.Theta = [4 8];
Bands.Alpha = [8 12];
Bands.Sigma = [12 16];
Bands.Beta = [16 25];
Bands.Iota = [25 35];
BandLabels = fieldnames(Bands);
nBands = numel(BandLabels);

Stages = -3:1:1;
StageLabels = {'N3', 'N2', 'N1', 'W', 'R'};
nStages = numel(Stages);

BandwidthRange = [.5 4];

FittingFrequencyRange = [3 50];
NoiseSmoothSpan = 5;
NoiseFittingFrequencyRange = [20 100];
MaxError = .1;
MinRSquared = .98;
MaxBadChannels = 50;

RangeSlopes = [0 5];
RangeIntercepts = [0 5]; % reeeeally generous

SourceName = 'Minimal';
SourcePower = fullfile(Paths.Final, 'EEG', 'Power', '20sEpochs', Task, SourceName);

CacheDir = Paths.Cache;
CacheName = ['PeriodicParameters_', Task, '_', SourceName, '.mat'];

if ~exist(CacheDir, 'dir')
    mkdir(CacheDir)
end

%%%%%%%%%%%%%
%%% Set up blanks

nParticipants = numel(Participants);

PeriodicPeaks = table();

AllSpectra = nan(nParticipants, nStages, 1);
AllPeriodicSpectra = nan(nParticipants, nStages, 1);

CustomTopographies = nan(nParticipants, nStages, nBands, 123);
LogTopographies = CustomTopographies;
PeriodicTopographies = CustomTopographies;

CenterFrequencies = nan(nParticipants, nStages, nBands);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run

for ParticipantIdx = 1:nParticipants

    Participant = Participants{ParticipantIdx};
    Filepath = fullfile(SourcePower, [Participant, '_', Task, '_' Session, '.mat']);

    if ~exist(Filepath, 'file')
        continue
    end

    % load in data
    load(Filepath,  'SmoothPower', 'Frequencies', 'Chanlocs', 'PeriodicPower', 'FooofFrequencies', 'Slopes', 'Intercepts', 'Scoring')

    SmoothPowerNoEdge = SmoothPower;
    PeriodicPowerNoEdge = PeriodicPower;


    %%% Get periodic peaks

    % remove edge channels
    SmoothPowerNoEdge(labels2indexes(Channels.Edge, Chanlocs), :, :) = nan;
    PeriodicPowerNoEdge(labels2indexes(Channels.Edge, Chanlocs), :, :) = nan;

    % remove data based on aperiodic activity
    SmoothPowerNoEdge = remove_bad_aperiodic(SmoothPowerNoEdge, Slopes, Intercepts, RangeSlopes, RangeIntercepts, MaxBadChannels);
    PeriodicPowerNoEdge = remove_bad_aperiodic(PeriodicPowerNoEdge, Slopes, Intercepts, RangeSlopes, RangeIntercepts, MaxBadChannels);


    for StageIdx = 1:nStages

        StageEpochs = Scoring==Stages(StageIdx);

        %%% average power
        MeanPower = squeeze(mean(mean(SmoothPowerNoEdge(:, StageEpochs, :), 1, 'omitnan'), 2, 'omitnan'))'; % its important that the channels are averaged first!

        AllSpectra(ParticipantIdx, StageIdx, 1:numel(MeanPower)) = MeanPower;
        AllPeriodicSpectra(ParticipantIdx, StageIdx, 1:size(PeriodicPowerNoEdge, 3)) = squeeze(mean(mean(PeriodicPowerNoEdge(:, StageEpochs, :), 1, 'omitnan'), 2, 'omitnan'))';


        % find all peaks in average power spectrum
       MetadataRow = table(string(Participant), StageLabels(StageIdx), 'VariableNames', {'Participants', 'Stages'}');
       Table = all_peak_parameters(Frequencies, MeanPower, FittingFrequencyRange, MetadataRow, StageIdx, MinRSquared, MaxError);
       PeriodicPeaks = cat(1, PeriodicPeaks, Table);

        %%% get topographies & custom peaks
        for BandIdx = 1:nBands

            % standard range
            Range = dsearchn(Frequencies', Bands.(BandLabels{BandIdx})');
            LogTopographies(ParticipantIdx, StageIdx, BandIdx, 1:numel(Chanlocs)) = ...
                squeeze(mean(mean(log10(SmoothPower(:, :, Range(1):Range(2))), 3, 'omitnan'), 2, 'omitnan'));

            Range = dsearchn(FooofFrequencies', Bands.(BandLabels{BandIdx})');
            PeriodicTopographies(ParticipantIdx, StageIdx, BandIdx, 1:numel(Chanlocs)) = ...
                squeeze(mean(mean(PeriodicPower(:, :, Range(1):Range(2)), 3, 'omitnan'), 2, 'omitnan'));

            % custom topography
            Peak = select_max_peak(Table, Bands.(BandLabels{BandIdx}), BandwidthRange);

            if ~isempty(Peak)
                CustomRange = dsearchn(FooofFrequencies', [Peak(1)-Peak(3)/2; Peak(1)+Peak(3)/2]);
                CustomTopographies(ParticipantIdx, StageIdx, BandIdx, 1:numel(Chanlocs)) = ...
                    squeeze(mean(mean(PeriodicPower(:, :, CustomRange(1):CustomRange(2)), 3, 'omitnan'), 2, 'omitnan'));

                % save peak information to metadata
                CenterFrequencies(ParticipantIdx, StageIdx, BandIdx) = Peak(1);
            end
        end
    end

    disp([num2str(ParticipantIdx), '/', num2str(nParticipants)])
end

save(fullfile(CacheDir, CacheName), 'CenterFrequencies', 'PeriodicPeaks', 'StageLabels',  ...
    'Chanlocs', 'CustomTopographies', 'LogTopographies', 'PeriodicTopographies', ...
    'AllSpectra', 'AllPeriodicSpectra', 'Frequencies', 'FooofFrequencies', 'Bands')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions




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