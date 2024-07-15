% goes through each partcipipant finds their peaks in average channels

% runs fooof on all wake recordings, and gets basic numbers that allow
% comparisons. updates metadata table, and creates big table of all
% detected peaks.

clear
clc
close all


Parameters = HBNParameters();
Paths = Parameters.Paths;
Channels = Parameters.Channels;

IotaBand = [25 35];
BandwidthRange = [.5 4];
AlphaBand = [8 13];

ControlBand = [40 50];

FittingFrequencyRange = [3 50];
NoiseSmoothSpan = 5;
NoiseFittingFrequencyRange = [20 100];
MaxError = .1;
MinRSquared = .98;
MaxBadChannels = 50;

RangeSlopes = [0 3.5];
RangeIntercepts = [0 4];


SourceName = 'Clean'; nFrequencies = 513;
% SourceName = 'Unfiltered'; nFrequencies = 1025;
SourcePower = fullfile(Paths.Final, 'EEG', 'Power', '20sEpochs', SourceName);
Folder = 'window4s_allt';

CacheDir = Paths.Cache;
CacheName = ['PeriodicParameters_', SourceName, '.mat'];

if ~exist(CacheDir, 'dir')
    mkdir(CacheDir)
end

% Metadata = readtable(fullfile(Paths.Metadata, 'MetadataHBM.csv'));
load(fullfile(Paths.Metadata, 'MetadataHBN.mat'), 'Metadata')
Files = list_filenames(SourcePower);
Files(~contains(Files, '.mat')) = [];
Participants = extractBefore(Files, '_RestingState');
Metadata(~ismember(Metadata.EID, Participants), :) = [];
Metadata = one_row_each(Metadata, 'EID');

nRecordings = size(Metadata, 1); % this does not consider tasks

PeriodicPeaks = table();
NoisePeriodicPeaks = table();

AllSpectra = nan(nRecordings, nFrequencies);
AllPeriodicSpectra = nan(nRecordings, 192);

CustomTopographies = nan(nRecordings, 123);
BandTopographies = CustomTopographies;
PeriodicTopographies = CustomTopographies;
ControlTopographies = CustomTopographies;

Metadata.IotaFrequency = nan(nRecordings, 1); % this is to check that iota is not obviously a harmonic of alpha
Metadata.IotaPower = nan(nRecordings, 1);
Metadata.AlphaFrequency = nan(nRecordings, 1);

ColumnNames = Metadata.Properties.VariableNames;
DSM_IDs = [find(contains(ColumnNames, 'DSM_')), find(contains(ColumnNames, '_isCurrent')), find(strcmp(ColumnNames, 'Diagnosis'))];

for RecordingIdx = 1:nRecordings

    Participant = Metadata.EID{RecordingIdx};


    % load in data
    DataOut = load_datafile(SourcePower, Participant, '', '', ...
        {'SmoothPower', 'Frequencies', 'Chanlocs', 'PeriodicPower', 'FooofFrequencies', 'Slopes', 'Intercepts'}, '.mat');
    if isempty(DataOut); continue; end
    SmoothPower = DataOut{1};
    Frequencies = DataOut{2};
    Chanlocs = DataOut{3};
    PeriodicPower = DataOut{4};
    FooofFrequencies = DataOut{5};
    Slopes = DataOut{6};
    Intercepts = DataOut{7};

    %%% Get periodic peaks

    % remove edge channels
    SmoothPower(labels2indexes(Channels.Edge, Chanlocs), :, :) = nan;
    PeriodicPower(labels2indexes(Channels.Edge, Chanlocs), :, :) = nan;

    % remove data based on aperiodic activity
    SmoothPower = remove_bad_aperiodic(SmoothPower, Slopes, Intercepts, RangeSlopes, RangeIntercepts, MaxBadChannels);
    PeriodicPower = remove_bad_aperiodic(PeriodicPower, Slopes, Intercepts, RangeSlopes, RangeIntercepts, MaxBadChannels);

    % find all peaks in average power spectrum
    MeanPower = squeeze(mean(mean(SmoothPower, 1, 'omitnan'), 2, 'omitnan'))'; % its important that the channels are averaged first!
    Table = all_peak_parameters(Frequencies, MeanPower, FittingFrequencyRange, Metadata(RecordingIdx, [1:4, DSM_IDs]), RecordingIdx, MinRSquared, MaxError);
    PeriodicPeaks = cat(1, PeriodicPeaks, Table);

    % repeat for full spectrum
    MeanSmoothPower = oscip.smooth_spectrum(MeanPower, Frequencies, NoiseSmoothSpan);

    IotaPeak = select_max_peak(Table, IotaBand, BandwidthRange);

    NoiseTable = all_peak_parameters(Frequencies, MeanSmoothPower, NoiseFittingFrequencyRange, Metadata(RecordingIdx, [1:4, DSM_IDs]), RecordingIdx, .9, .2);
    NoisePeriodicPeaks = cat(1, NoisePeriodicPeaks, NoiseTable);

    %%% get mean spectra
    AllSpectra(RecordingIdx, :) = MeanPower;
    AllPeriodicSpectra(RecordingIdx, :) = squeeze(mean(mean(PeriodicPower, 1, 'omitnan'), 2, 'omitnan'))';



    %%% get topographies

    % custom iota topography
    if ~isempty(IotaPeak)
        IotaCustomRange = dsearchn(FooofFrequencies', [IotaPeak(1)-IotaPeak(3)/2; IotaPeak(1)+IotaPeak(3)/2]);
        CustomTopographies(RecordingIdx, 1:numel(Chanlocs)) = squeeze(mean(mean(PeriodicPower(:, :, IotaCustomRange(1):IotaCustomRange(2)), 3, 'omitnan'), 2, 'omitnan'));
    end

    % standard iota range
    Range = dsearchn(FooofFrequencies', IotaBand');
    BandTopographies(RecordingIdx, 1:numel(Chanlocs)) = squeeze(mean(mean(log10(SmoothPower(:, :, Range(1):Range(2))), 3), 2));
    PeriodicTopographies(RecordingIdx, 1:numel(Chanlocs)) = squeeze(mean(mean(PeriodicPower(:, :, Range(1):Range(2)), 3), 2));
    ControlRange = dsearchn(FooofFrequencies', ControlBand');

    ControlTopographies(RecordingIdx, 1:numel(Chanlocs)) = squeeze(mean(mean(PeriodicPower(:, :, ControlRange(1):ControlRange(2)), 3), 2));

    %%% save peak frequency to check harmonic
    if ~isempty(IotaPeak)
        Metadata.IotaFrequency(RecordingIdx) = IotaPeak(1);
        Metadata.IotaPower(RecordingIdx) = IotaPeak(2);
    end


    AlphaPeak = select_max_peak(Table, AlphaBand, BandwidthRange);
    if ~isempty(AlphaPeak)
        Metadata.AlphaFrequency(RecordingIdx) = AlphaPeak(1);
    end


    disp([num2str(RecordingIdx), '/', num2str(nRecordings)])
end

save(fullfile(CacheDir, CacheName), 'Metadata', 'PeriodicPeaks', 'NoisePeriodicPeaks', ...
    'Chanlocs', 'CustomTopographies', 'BandTopographies',  'ControlTopographies', ...
    'AllSpectra', 'AllPeriodicSpectra', 'Frequencies', 'FooofFrequencies')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function Table = all_peak_parameters(Freqs, MeanPower, FittingFrequencyRange, MetadataRow, TaskIdx, MinRSquared, MaxError)

% set up new row
MetadataRow.Frequency = nan;
MetadataRow.BandWidth = nan;
MetadataRow.Power = nan;
MetadataRow.TaskIdx = TaskIdx;

% fit fooof
[~, ~, ~, PeriodicPeaks, ~, ~, ~] = oscip.fit_fooof(MeanPower, Freqs, FittingFrequencyRange, MaxError, MinRSquared);

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