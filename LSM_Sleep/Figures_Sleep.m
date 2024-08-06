% This script plots all the sleep related figures
% iota-preprint, Snipes 2024

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = LSMParameters();
Paths = Parameters.Paths;

Channels = Parameters.Channels.NotEdge;
Task = Parameters.Task;
Format = 'Minimal'; % chooses which filtering to do
FreqLims = [3 45];

ExampleParticipant = 'P09';


% folders
SourceSpecparam = fullfile(Paths.Final, 'EEG', 'Power',  '20sEpochs', Task, Format);
SourceEEG = fullfile(Paths.Preprocessed, Format, 'Clean', Task);

ResultsFolder = fullfile(Paths.Results);
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end

CacheDir = Paths.Cache;
CacheName = ['PeriodicParameters_', Task, '_', Format, '.mat'];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plot




%% Figure 8 hypnogram

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.yPadding = 5;

load(fullfile(SourceSpecparam, [ExampleParticipant, '_Sleep_Baseline.mat']), ...
    'Power', 'Slopes', 'Frequencies',  'Scoring', 'Chanlocs', 'Time', 'ScoringIndexes', 'ScoringLabels')
Time = Time/60/60; % convert time to hours

figure('Units','centimeters', 'Position', [0 0 50 20])

Grid = [3 6];
MeanPower = squeeze(mean(log(Power(labels2indexes(Channels, Chanlocs), :, :)), 1, 'omitnan'));
SmoothMeanPower = smooth_frequencies(MeanPower, Frequencies, 4)';


%%% A: plot time-frequency
TickLength = .005;
chART.sub_plot([], [1 1], [1, 1], [], true, '', PlotProps);

imagesc(Time, Frequencies, SmoothMeanPower)
chART.set_axis_properties(PlotProps)
CLims = [-4.5 1.5];
clim(CLims)
set(gca, 'YDir', 'normal')
ylabel('Frequency (Hz)')
set(gca, 'TickLength', [TickLength 0], 'YLim', FreqLims)
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.Text.LegendSize = PlotProps.Text.AxisSize;
box off
Bar = chART.plot.pretty_colorbar('Linear', CLims, 'Log power', PlotProps);
B1Axis = gca;
Width = B1Axis.Position(3);
Bar.Position(3) = 0.014647239581274;
B1Axis.Position(1) = 0.06;
B1Axis.Position(3) = .85;

chART.save_figure('ExampleSleepFrequency', ResultsFolder, PlotProps)

%%%  B: plot hypnogram


figure('Units','centimeters', 'Position', [0 0 50 2])

ScoringNew = Scoring;
ScoringNew(ScoringNew==-2) = -3;
ScoringNew(ScoringNew==-1) = -3;
ScoringNew(ScoringNew==1) = -1;
ScoringNew(ScoringNew==0) = 1;
imagesc(ScoringNew)
colormap(PlotProps.Color.Maps.Linear)
clim([-3 2])
axis off
A = gca;
A.Position([1, 3]) = B1Axis.Position([1, 3]);
chART.save_figure('ExampleSleepFrequency_Scoring', ResultsFolder, PlotProps)


%% Figure 9: Example REM sleep

load(fullfile(SourceEEG, [ExampleParticipant, '_Sleep_Baseline.mat']), 'EEG')
load(fullfile(CacheDir, CacheName), 'Bands')

% select data
TimeRange = [14680 14690]; % pretty good!
Channels10_20 = labels2indexes(Parameters.Channels.Standard_10_20, EEG.chanlocs);
TimeRange = round(TimeRange*EEG.srate);
Snippet = EEG.data(Channels10_20, TimeRange(1):TimeRange(2));

%%
EEGSnippet = EEG;
EEGSnippet.data = Snippet;

% filter to remove drifts
EEGSnippet.chanlocs = EEG.chanlocs(Channels10_20);
EEGSnippet = eeg_checkset(EEGSnippet);
EEGSnippet = pop_eegfiltnew(EEGSnippet, .5);

%%% plot
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Figure.Padding = 5;
PlotProps.Line.Width = 3;
YGap = 30;

figure('Units','centimeters', 'Position',[0 0 51 28])
chART.sub_plot([], [1 1], [1, 1], [], true, '', PlotProps);

% basic EEG

plot_eeg(EEGSnippet.data, EEG.srate, YGap, PlotProps)

% bursts
FrequencyRange = [30 35];
plot_burst_mask(EEGSnippet, FrequencyRange, YGap, PlotProps)

chART.save_figure('REM_Example', ResultsFolder, PlotProps)


