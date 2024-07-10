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

PeakDetectionSettings = oscip.default_settings();
PeakDetectionSettings.PeakBandwidthMax = 4; % broader peaks are not oscillations
PeakDetectionSettings.PeakBandwidthMin = .5; % Hz; narrow peaks are more often than not noise
IotaBand = [25 35];
AlphaBand = [8 13];
FittingFrequencyRange = [3 50];
SmoothSpan = 2;


SourcePower =  fullfile(Paths.Final, 'EEG', 'Specparam');
Folder = 'window4s_allt';

CacheDir = Paths.Cache;
CacheName = 'PeriodicParameters.mat';

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

% % average information per recording; for quick statistics
% Metadata.Iota = nan(nRecordings, 1); % -1: harmonic; 0 no peak; 1 iota peak
% Metadata.IotaFrequency = nan(nRecordings, 1);
% Metadata.IotaPower = nan(nRecordings, 1);
% Metadata.IotaBandwidth = nan(nRecordings, 1);

PeakParams = table();
Topographies = nan(nRecordings, 123);
StrawmanTopographies = Topographies;

ColumnNames = Metadata.Properties.VariableNames;
DSMIDs = [find(contains(ColumnNames, 'DSM_')), find(contains(ColumnNames, '_isCurrent')), find(strcmp(ColumnNames, 'Diagnosis'))];

for RecordingIdx = 1:nRecordings

    Participant = Metadata.EID{RecordingIdx};


    % load in data
    DataOut = load_datafile(SourcePower, Participant, '', '', ...
        {'Power', 'Frequencies', 'Chanlocs', 'PeriodicPeaks', 'WhitenedPower', 'FooofFrequencies'}, '.mat');
    if isempty(DataOut); continue; end
    Power = DataOut{1};
    Frequencies = DataOut{2};
    Chanlocs = DataOut{3};
    PeriodicPeaks = DataOut{4};
    WhitenedPower = DataOut{5};
    FooofFrequencies = DataOut{6};

    % smooth power

    % remove edge channels
    Power(labels2indexes(Channels.Edge, Chanlocs), :) = nan;


    % find iota
    [isIota, MaxPeak] = oscip.check_peak_in_band(PeriodicPeaks, IotaBand, 1, PeakDetectionSettings);

    % load in variables that apply to whole recording
    Metadata.Iota(RecordingIdx) = isIota;
    Metadata.IotaFrequency(RecordingIdx) = MaxPeak(1);
    Metadata.IotaPower(RecordingIdx) =  MaxPeak(2);
    Metadata.IotaBandwidth(RecordingIdx) = MaxPeak(3);

    % save topography
       Range = dsearchn(FooofFrequencies', IotaBand');
    StrawmanTopographies(RecordingIdx, :) = squeeze(mean(mean(WhitenedPower(:, :, Range(1):Range(2)), 3), 2));
 
    % Range = dsearchn(Freqs', IotaBand');
    % StrawmanTopographies(RecordingIdx, :) = squeeze(mean(mean(log(Power(:, :, Range(1):Range(2))), 3), 2));
    if isIota
        IotaRange = dsearchn(FooofFrequencies', [MaxPeak(1)-MaxPeak(3)/2; MaxPeak(1)+MaxPeak(3)/2]);
        Topographies(RecordingIdx, :) = squeeze(mean(mean(WhitenedPower(:, :, IotaRange(1):IotaRange(2)), 3, 'omitnan'), 2, 'omitnan'));
    end

    % same for alpha
    [isAlpha, MaxPeak] = oscip.check_peak_in_band(PeriodicPeaks, AlphaBand, 1, PeakDetectionSettings);

    Metadata.Alpha(RecordingIdx) = isAlpha;
    Metadata.AlphaFrequency(RecordingIdx) = MaxPeak(1);
    Metadata.AlphaPower(RecordingIdx) =  MaxPeak(2);
    Metadata.AlphaBandwidth(RecordingIdx) = MaxPeak(3);


    % find all peaks in average spectrum,
    MeanPower = squeeze(mean(mean(Power, 1, 'omitnan'), 2, 'omitnan'))';
    SmoothPower = oscip.smooth_spectrum(MeanPower, Frequencies, SmoothSpan); % better for fooof if the spectra are smooth


    Table = all_peak_parameters(Frequencies, SmoothPower, FittingFrequencyRange, Metadata(RecordingIdx, [1:4, DSMIDs]), RecordingIdx);
   
    if isempty(Table)
        continue
    end
    PeakParams = cat(1, PeakParams, Table);

    % Iota = Table(Table.Frequency>=IotaBand(1) & Table.Frequency<= IotaBand(2), :);
    % if size(Iota, 1) == 1
    %     Metadata.AverageIotaFrequency(RecordingIdx) = Iota.Frequency;
    % elseif size(Iota, 1) > 1
    %     Iota = sortrows(Iota, 'Power', 'descend');
    %     Metadata.AverageIotaFrequency(RecordingIdx) = Iota.Frequency(1);
    % else
    %     Metadata.AverageIotaFrequency(RecordingIdx) = nan;
    % end
    % 
    % Alpha = Table(Table.Frequency>=AlphaBand(1) & Table.Frequency<= AlphaBand(2), :);
    % if size(Alpha, 1) == 1
    %     Metadata.AverageAlphaFrequency(RecordingIdx) = Alpha.Frequency;
    % elseif size(Alpha, 1) > 1
    %     Alpha = sortrows(Alpha, 'Power', 'descend');
    %       Metadata.AverageAlphaFrequency(RecordingIdx) = Alpha.Frequency(1);
    % else
    %     Metadata.AverageAlphaFrequency(RecordingIdx) = nan;
    % end

    disp([num2str(RecordingIdx), '/', num2str(nRecordings)])
end

save(fullfile(CacheDir, CacheName), 'Metadata', 'PeakParams', 'Chanlocs', 'Topographies', 'StrawmanTopographies')


function Table = all_peak_parameters(Freqs, MeanPower, FittingFrequencyRange, MetadataRow, TaskIdx)

MetadataRow.Frequency = nan;
MetadataRow.BandWidth = nan;
MetadataRow.Power = nan;
MetadataRow.TaskIdx = TaskIdx;

[~, ~, ~, PeriodicPeaks, ~, ~, ~] = oscip.fit_fooof(MeanPower, Freqs, FittingFrequencyRange, .1, .98);

if isempty(PeriodicPeaks)
    Table = table();
    return
end

Table = repmat(MetadataRow, size(PeriodicPeaks, 1), 1);
Table.Frequency = PeriodicPeaks(:, 1);
Table.Power = PeriodicPeaks(:, 2);
Table.BandWidth = PeriodicPeaks(:, 3);
end