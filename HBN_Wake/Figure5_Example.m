% plot example participant to show burstiness of iota.
%
% From iota-preprint, Snipes, 2024.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = HBNParameters();
Paths = Parameters.Paths;
PlotProps = Parameters.PlotProps.Manuscript;

% paths
CacheDir = Paths.Cache;
CacheName = 'PeriodicParameters.mat';

ResultsFolder = fullfile(Paths.Results, 'WakeExamples');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end

SourceEEG = fullfile(Paths.Preprocessed, 'Power', 'Clean', 'RestingState');
SourcePower = fullfile(Paths.Core, 'Final_Old', 'EEG','Specparam/');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run

load(fullfile(CacheDir, CacheName), 'Metadata')

Participant = 'NDARMH180XE5'; TimeRange = [39 49]; % the bestest
% Participant = 'NDARUL694GYN'; TimeRange = [150 160]; % works for all of these others as well
% Participant = 'NDARDR804MFE'; TimeRange = [10 20];
% Participant = 'NDARTZ926NMZ';TimeRange = [54 64];
% Participant = 'NDARKL327YDQ'; TimeRange = [39 49]; % Works with same time interval
% Participant = 'NDARKL327YDQ'; TimeRange = [39 49]; % 16 year old
% Participant = 'NDARYH110YV9'; TimeRange = [39 49]; % 16 year old
% Participant= 'NDARTF566PYH'; TimeRange = [39 49]; % good time
% Participant= 'NDARAJ674WJT'; TimeRange = [39 49];
% Participant = 'NDARDR804MFE';TimeRange = [39 49];

% load preprocessed EEG
File = [Participant, '_RestingState.mat'];
load(fullfile(Paths.Preprocessed, 'Power\Clean\RestingState\', File), 'EEG')

% load fooof data
load(fullfile( Paths.Final, 'EEG', 'Power', '20sEpochs', 'Clean', File), 'Power', 'Frequencies', 'Chanlocs', 'PeriodicPeaks')

Info = Metadata(find(strcmp(Metadata.EID, Participant), 1, 'first'), :);

PlotProps = Parameters.PlotProps.Manuscript;

PlotProps.Figure.Padding = 30;
%%% detect iota peak and determine custom range
PeakDetectionSettings = oscip.default_settings();
PeakDetectionSettings.PeakBandwidthMax = 4; % broader peaks are not oscillations
PeakDetectionSettings.PeakBandwidthMin = .5; % Hz; narrow peaks are more often than not noise
PeakDetectionSettings.PeakAmplitudeMin = .5;

[~, MaxIotaPeak] = oscip.check_peak_in_band(PeriodicPeaks, [25 35], 1, PeakDetectionSettings);

IotaRange = [MaxIotaPeak(1)-MaxIotaPeak(3)/2, MaxIotaPeak(1)+MaxIotaPeak(3)/2];
PlotProps.Colorbar.Location = 'eastoutside';

WindowLength = 2;
MovingWindowSampleRate = .2;
Grid = [1, 1];

% find best iota channel
[~, MaxCh] = max(Power(:, dsearchn(Frequencies', MaxIotaPeak(1))));

Data = EEG.data(MaxCh, :);
SampleRate = EEG.srate;

% run multitaper
[Spectrum, Frequencies, Time] = cycy.utils.multitaper(Data, SampleRate, WindowLength, MovingWindowSampleRate);

Time = Time/60;

figure('Units','centimeters', 'Position', [0 0 50 20])

%%% A: time frequency
chART.sub_plot([], Grid, [1, 1], [], true, '', PlotProps);
LData = squeeze(log10(Spectrum));
CLim = quantile(LData(:)', [.6 .999]);

cycy.plot.time_frequency(LData, Frequencies, Time(end), 'contourf', [1 50], CLim, 100)
PlotA = gca;

chART.set_axis_properties(PlotProps)
colormap(PlotProps.Color.Maps.Linear)
set(gca, 'TickLength', [.005 0])
xlabel('Time (min)')
xlim([3 247]/60)

colorbar off
box off
Colorbar = chART.plot.pretty_colorbar('Linear', CLim, 'Log power', PlotProps);


chART.save_figure(['ExampleFrequency_', Participant], ResultsFolder, PlotProps)


%%
ChannelIndexes = Parameters.Channels.Standard_10_20;

%%% B: EEG
Channels = labels2indexes(ChannelIndexes, Chanlocs);
TimeRangeEEG = round(TimeRange*EEG.srate);
Snippet = EEG.data(Channels, TimeRangeEEG(1):TimeRangeEEG(2)); % TODO: select 10:20 system

Axes=chART.sub_plot([], Grid, [3, 1], [2, 1], true, 'B', PlotProps);
YGap = 40;

hold on
PlotProps.Line.Width = 1.5;
plot_eeg(Snippet, SampleRate, YGap, PlotProps)

% plot highlight sections where there's a lot more iota
EEGSnippet = EEG;
EEGSnippet.data = Snippet;
plot_burst_mask(EEGSnippet, IotaRange, YGap, PlotProps)
set(gca, 'TickLength', [.005 0])
Axes.Position(2) = Axes.Position(2)+.01;






% chART.save_figure(['ExampleTime_', Participant], ResultsFolder, PlotProps)

