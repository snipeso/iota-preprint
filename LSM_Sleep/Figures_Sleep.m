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

figure('Units','centimeters', 'Position',[0 0 50 28])
chART.sub_plot([], [1 1], [1, 1], [], true, '', PlotProps);

% basic EEG

plot_eeg(EEGSnippet.data, EEG.srate, YGap, PlotProps)

% bursts
FrequencyRange = [30 35];
plot_burst_mask(EEGSnippet, FrequencyRange, YGap, PlotProps)

chART.save_figure('REM_Example', ResultsFolder, PlotProps)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% not included: topography of all stages/bands

load(fullfile(CacheDir, CacheName), 'PeriodicTopographies', 'Chanlocs', 'Bands', 'StageLabels')
BandLabels = fieldnames(Bands);
nStages = numel(StageLabels);
nBands = numel(BandLabels);

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.xPadding = 5;
PlotProps.Axes.yPadding = 5;
Grid = [nBands, nStages];

PeriodicTopographies(:, :, :, end) = nan; %

CLims = [
    .1 .25; % theta
    .15 .7; % alpha
    .1 .55; % sigma
    .1 .37; % beta
    .05 .2; % iota
    ];

figure('Units','centimeters', 'OuterPosition',[0 0 PlotProps.Figure.Width PlotProps.Figure.Width])
for BandIdx = 1:nBands
    for StageIdx = 1:nStages
        Data = squeeze(mean(PeriodicTopographies(:, StageIdx, BandIdx, :), 1, 'omitnan'));
        % Data = squeeze(mean(CustomTopographies(:, StageIdx, BandIdx, :), 1, 'omitnan'));
        if all(isnan(Data)|Data==0)
            continue
        end
        chART.sub_plot([], Grid, [BandIdx, StageIdx], [], false, '', PlotProps);
        chART.plot.eeglab_topoplot(Data, Chanlocs, [], CLims(BandIdx, :), '', 'Linear', PlotProps);
        colorbar
        title([BandLabels{BandIdx}, ' ', StageLabels{StageIdx}])
    end
end

chART.save_figure('AllTopographies', ResultsFolder, PlotProps)


% TODO: average all bands!! 
% REM, Wake, NREM x bands in table

%% plot all iota topographies

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.External.EEGLAB.TopoRes = 50;
PlotProps.Debug = true;
Participants = Parameters.Participants;

load(fullfile(CacheDir, CacheName), 'CustomTopographies', 'Chanlocs', 'Bands', 'StageLabels', 'CenterFrequencies')
nStages = numel(StageLabels);
BandLabels = fieldnames(Bands);
nBands = numel(BandLabels);
figure('Units','centimeters', 'OuterPosition',[0 0 PlotProps.Figure.Width*2 PlotProps.Figure.Width])
Grid = [nStages, numel(Participants)];


for ParticipantIdx = 1:numel(Participants)
    for StageIdx = 1:nStages
        Data = squeeze(CustomTopographies(ParticipantIdx, StageIdx, end, :));
        if all(isnan(Data)|Data==0)
            continue
        end
        chART.sub_plot([], Grid, [StageIdx, ParticipantIdx], [], false, '', PlotProps);
        chART.plot.eeglab_topoplot(Data, Chanlocs, [], [], '', 'Linear', PlotProps);
        title([Participants{ParticipantIdx}, ' ', StageLabels{StageIdx}])
    end
end




