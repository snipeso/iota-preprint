% Assembles data from power and specparam of each individual.
%
% from iota-neurophys, Snipes, 2024.

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
EpochLength = Parameters.EpochLength;
Format = Parameters.Format;

Bands = Parameters.Bands;
BandLabels = fieldnames(Bands);
nBands = numel(BandLabels);

StageIndexes = -3:1:1;
StageLabels = {'N3', 'N2', 'N1', 'W', 'R'};
nStages = numel(StageIndexes);

FittingFrequencyRange = Parameters.FOOOF.FittingFrequencyRange;
MaxError = Parameters.FOOOF.MaxError;
MinRSquared = Parameters.FOOOF.MinRSquared;
MinCleanChannels = 128-numel(Channels.notEEG)-Parameters.MinChannels; % comes out to 97, to match wake analysis
MinMinutes = Parameters.MinTime/60;

RangeSlopes = [0 5];
RangeIntercepts = [0 5]; % reeeeally generous

SourcePower = fullfile(Paths.Final, 'EEG', 'Power', '20sEpochs', Task, Format);

CacheDir = Paths.Cache;
CacheName = ['PeriodicParameters_', Task, '_', Format, '.mat'];

if ~exist(CacheDir, 'dir')
    mkdir(CacheDir)
end

%%%%%%%%%%%%%
%%% Set up blanks

nParticipants = numel(Participants);

PeriodicPeaksTable = table();

AllSpectra = nan(nParticipants, nStages, 1);
AllPeriodicSpectra = nan(nParticipants, nStages, 1);

CustomTopographies = nan(nParticipants, nStages, nBands, numel(Channels.TopoPlot));
LogTopographies = CustomTopographies;
PeriodicTopographies = CustomTopographies;

CenterFrequencies = nan(nParticipants, nStages, nBands);
StageMinutes = nan(nParticipants, nStages);
CustomPeakSettings = oscip.default_settings();
CustomPeakSettings.PeakBandwidthMin = .5;
CustomPeakSettings.PeakBandwidthMax = 12;
CustomPeakSettings.DistributionBandwidthMax = 12;
Settings.MinPeaksInPeak = 100;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run


for ParticipantIdx = 1:nParticipants

    Participant = Participants{ParticipantIdx};
    Filepath = fullfile(SourcePower, [Participant, '_', Task, '_' Session, '.mat']);

    if ~exist(Filepath, 'file')
        continue
    end

    % load in data
    load(Filepath,  'SmoothPower', 'Frequencies', 'Chanlocs', 'PeriodicPower', 'FooofFrequencies', 'Slopes', 'Intercepts', 'Scoring', 'PeriodicPeaks')

    MainEEGChannels = labels2indexes(Channels.NotEdge, Chanlocs);
    TopoChannels = labels2indexes(Channels.TopoPlot, Chanlocs);

    %%% Get periodic peaks

    % remove data based on aperiodic activity
    SmoothPower = remove_bad_aperiodic(SmoothPower, Slopes, Intercepts, RangeSlopes, RangeIntercepts, MinCleanChannels);
    PeriodicPower = remove_bad_aperiodic(PeriodicPower, Slopes, Intercepts, RangeSlopes, RangeIntercepts, MinCleanChannels);

    for StageIdx = 1:nStages

        StageEpochs = Scoring==StageIndexes(StageIdx);
        Minutes = nnz(any(~isnan(PeriodicPower(:, StageEpochs, 1)), 1))*EpochLength/60;

        if Minutes < MinMinutes
            StageMinutes(ParticipantIdx, StageIdx) = nan;
            disp(['not enough minutes in ', num2str(StageIdx), ' ', Participant])
            continue
        else
            StageMinutes(ParticipantIdx, StageIdx) = Minutes;
        end

        %%% average power
        MeanPower = squeeze(mean(mean(SmoothPower(MainEEGChannels, StageEpochs, :), 1, 'omitnan'), 2, 'omitnan'))'; % its important that the channels are averaged first!

        AllSpectra(ParticipantIdx, StageIdx, 1:numel(MeanPower)) = MeanPower;
        AllPeriodicSpectra(ParticipantIdx, StageIdx, 1:size(PeriodicPower, 3)) = squeeze(mean(mean(PeriodicPower(MainEEGChannels, StageEpochs, :), 1, 'omitnan'), 2, 'omitnan'))';


        % find all peaks in average power spectrum
        MetadataRow = table(string(Participant), StageLabels(StageIdx), 'VariableNames', {'Participants', 'Stages'}');
        Table = all_peak_parameters(Frequencies, MeanPower, FittingFrequencyRange, MetadataRow, StageIdx, MinRSquared, MaxError);
        PeriodicPeaksTable = cat(1, PeriodicPeaksTable, Table);
        figure;histogram(PeriodicPeaks(MainEEGChannels, StageEpochs, 1), 1:CustomPeakSettings.DistributionFrequencyResolution:45)

        %%% get topographies & custom peaks
        for BandIdx = 1:nBands

            % standard range
            Band = Bands.(BandLabels{BandIdx});
            Range = dsearchn(Frequencies', Band');
            LogTopographies(ParticipantIdx, StageIdx, BandIdx, :) = ...
                squeeze(mean(mean(log10(SmoothPower(TopoChannels, StageEpochs, Range(1):Range(2))), 3, 'omitnan'), 2, 'omitnan'));

            Range = dsearchn(FooofFrequencies', Band');
            PeriodicTopographies(ParticipantIdx, StageIdx, BandIdx, :) = ...
                squeeze(mean(mean(PeriodicPower(TopoChannels, StageEpochs, Range(1):Range(2)), 3, 'omitnan'), 2, 'omitnan'));

            % identify individual peak within each canonical band
            [isPeak, Peak] = oscip.check_peak_in_band(PeriodicPeaks(MainEEGChannels, StageEpochs, :), Band, 1, CustomPeakSettings);

            % custom topography (not used)
            if isPeak
                CustomRange = dsearchn(FooofFrequencies', [Peak(1)-Peak(3)/2; Peak(1)+Peak(3)/2]);
                CustomTopographies(ParticipantIdx, StageIdx, BandIdx, :) = ...
                    squeeze(mean(mean(PeriodicPower(TopoChannels, StageEpochs, CustomRange(1):CustomRange(2)), 3, 'omitnan'), 2, 'omitnan'));

                % save peak information to metadata
                CenterFrequencies(ParticipantIdx, StageIdx, BandIdx) = Peak(1);
            end
        end
    end

    disp([num2str(ParticipantIdx), '/', num2str(nParticipants)])
end

Chanlocs = Chanlocs(TopoChannels);
save(fullfile(CacheDir, CacheName), 'CenterFrequencies', 'PeriodicPeaksTable', 'StageLabels', 'StageIndexes', 'StageMinutes',  ...
    'Chanlocs', 'CustomTopographies', 'LogTopographies', 'PeriodicTopographies', ...
    'AllSpectra', 'AllPeriodicSpectra', 'Frequencies', 'FooofFrequencies', 'Bands')


