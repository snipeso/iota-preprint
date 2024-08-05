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

%% Table 1: peaks detected in sleep

load(fullfile(CacheDir, CacheName), 'CenterFrequencies', 'Bands', 'StageLabels')
BandLabels = fieldnames(Bands);
nStages = numel(StageLabels);
nBands = numel(BandLabels);


AllCenterFrequencies = table();
for BandIdx = 1:nBands
    AllCenterFrequencies.Band{BandIdx} = [num2str(Bands.(BandLabels{BandIdx})(1)), '-', num2str(Bands.(BandLabels{BandIdx})(2)), ' Hz'];
    for StageIdx = 1:nStages
        AllCenterFrequencies.(StageLabels{StageIdx})(BandIdx) = nnz(~isnan(CenterFrequencies(:, StageIdx, BandIdx)));
    end
end

AllCenterFrequencies = AllCenterFrequencies(:, [1 5 6 4 3 2]);
disp(AllCenterFrequencies)
writetable(AllCenterFrequencies, fullfile(ResultsFolder, 'DetectedPeaksByStage.csv'))


%% Figure 7: periodic peaks

Settings = oscip.default_settings();
Settings.PeakBandwidthMax = 4;
Settings.DistributionBandwidthMax = 4; % how much jitter there can be across periodic peaks

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Figure.Padding = 30;

IotaBand = [25 40];
IotaTextColor = [73 63 11]/255;

Grid = [3 9];

%%%%% Main participant

figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width PlotProps.Figure.Width/2.5])

chART.sub_plot([], Grid, [3 1], [3 3], false, '', PlotProps);
load(fullfile(SourceSpecparam, [ExampleParticipant, '_Sleep_Baseline.mat']), ...
    'PeriodicPeaks', 'Scoring', 'Chanlocs')

plot_peaks_sleep(PeriodicPeaks(labels2indexes(Channels, Chanlocs), :, :), Scoring, PlotProps)
xlim(FreqLims)
add_peak_text(PeriodicPeaks(labels2indexes(Channels, Chanlocs), Scoring==1, :), ...
    IotaBand, IotaTextColor, PlotProps)

%%% All data

Participants = Parameters.Participants;
Participants(strcmp(Participants, 'P09')) = [];

for ParticipantIdx = 1:numel(Participants)

    % load data
    Participant = Participants{ParticipantIdx};
    load(fullfile(SourceSpecparam, [Participant, '_Sleep_Baseline.mat']), 'PeriodicPeaks', 'Scoring');

    % plot
    if ParticipantIdx > 12 % split by row
        R = 3;
        C = 3+ParticipantIdx-12;
    elseif ParticipantIdx > 6 % second row
        R = 2;
        C = 3+ParticipantIdx-6;
    else % first row
        R = 1;
        C = 3+ParticipantIdx;
    end
    chART.sub_plot([], Grid, [R, C], [], false, '', PlotProps);
    plot_peaks_sleep(PeriodicPeaks(labels2indexes(Channels, Chanlocs), :, :), Scoring, PlotProps)

    box off
    set(gca,  'TickLength', [0 0])
    xlim(FreqLims)
    xlabel('')
    ylabel('')
    xticks(10:20:50)
    legend off

    % find REM iota, and display
    add_peak_text(PeriodicPeaks(labels2indexes(Channels, Chanlocs), Scoring==1, :), ...
        IotaBand, IotaTextColor, PlotProps)
end

chART.save_figure('PeriodicPeaks', ResultsFolder, PlotProps)


%% Figure 8 hypnogram

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.yPadding = 5;

load(fullfile(SourceSpecparam, [ExampleParticipant, '_Sleep_Baseline.mat']), ...
    'PeriodicPower', 'Slopes', 'FooofFrequencies',  'Scoring', 'Chanlocs', 'Time', 'ScoringIndexes', 'ScoringLabels')
Time = Time/60/60; % convert time to hours

figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width PlotProps.Figure.Width/2])

Grid = [3 6];
MeanPower = squeeze(mean(PeriodicPower(labels2indexes(Channels, Chanlocs), :, :), 1, 'omitnan'));
SmoothMeanPower = smooth_frequencies(MeanPower, FooofFrequencies, 4)';


%%% A: plot time-frequency
TickLength = .005;
chART.sub_plot([], Grid, [2, 1], [2 5], true, 'A', PlotProps);

imagesc(Time, FooofFrequencies, SmoothMeanPower)
chART.set_axis_properties(PlotProps)
CLims = [-.1 1.1];
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
B1Axis.Position(3) = Width;

%%%  B: plot hypnogram
chART.sub_plot([], Grid, [3, 1], [1 5], true, 'B', PlotProps);
yyaxis left
Red = chART.color_picker(1, '', 'red');
plot(Time, Scoring, 'LineWidth', PlotProps.Line.Width*2/3, 'Color', [Red, .8])
chART.set_axis_properties(PlotProps)
axis tight
box off
xlabel('Time (h)')
yticks(sort(ScoringIndexes))
yticklabels(ScoringLabels)
ylim([-3.1 1]) % by chance the ranges work the same; otherwise would need a second axis
set(gca, 'YColor', Red)

yyaxis right
plot(Time, -Slopes, '-', 'Color', [.5 .5 .5 .01])
set(gca, 'YColor', 'k', 'TickLength', [TickLength 0])
ylim([-3.5 -.9]) % by chance the ranges work the same; otherwise would need a second axis
ylabel('Exponent')
box off
B2Axes = gca;
B2Axes.Units = B1Axis.Units;
B2Axes.Position(3) = Width;

%%% C: topography

% data parameters
Band = [30 34];
CLims = [0.05, .75];

StageTitles = {'Wake', 'REM', 'NREM'};
Stages = {0, 1, [-2 -3]};
Positions = [2, 4, 6];
Shift = [.01, .02, .03];

Grid = [7 6];


chART.sub_plot([], Grid, [2, 6], [2 1], true, 'C', PlotProps); axis off;
PlotProps.Axes.yPadding = 10;
for StageIdx = 1:numel(StageTitles) % rows
    
    % select data
    StageEpochs = ismember(Scoring, Stages{StageIdx}); % epochs of the requested stage
    FreqRange = dsearchn(FooofFrequencies', Band');

    Data = squeeze(mean(mean(PeriodicPower(:, StageEpochs, ...
        FreqRange(1):FreqRange(2)), 2, 'omitnan'), 3, 'omitnan'));

    % plot
    Axes = chART.sub_plot([], Grid, [Positions(StageIdx), 6], [2, 1], false, '', PlotProps);
    Axes.Position(2) = Axes.Position(2)-Shift(StageIdx);
    % Axes.Position(4) = Axes.Position(4)+.08;
    chART.plot.eeglab_topoplot(Data, Chanlocs, [], CLims, '', 'Linear', PlotProps)

    title(StageTitles{StageIdx})
end

Grid = [7 6];
Axes = chART.sub_plot([], Grid, [Grid(1), 6], [1, 1], false, '', PlotProps);
axis off
PlotProps.Colorbar.Location = 'north';
chART.plot.pretty_colorbar('Linear', CLims, 'Log power', PlotProps);
Axes.Position(4) = .25;
Axes.Position(2) = -.1;
chART.save_figure('ExampleHypnogram', ResultsFolder, PlotProps)


%% Figure 9: Example REM sleep

load(fullfile(SourceEEG, [ExampleParticipant, '_Sleep_Baseline.mat']), 'EEG')
load(fullfile(CacheDir, CacheName), 'Bands')

% select data
TimeRange = [14680 14690]; % pretty good!
Channels10_20 = labels2indexes([125 32, Parameters.Channels.Standard_10_20], EEG.chanlocs);
TimeRange = round(TimeRange*EEG.srate);
Snippet = EEG.data(Channels10_20, TimeRange(1):TimeRange(2));
Snippet = [Snippet(1, :)-Snippet(2, :); nan(2, size(Snippet, 2)); Snippet(3:end, :)];

EEGSnippet = EEG;
EEGSnippet.data = Snippet;
EEGSnippet.chanlocs = [EEG.chanlocs(8), EEG.chanlocs(Channels10_20)];

% filter to remove drifts
EEGSnippet = eeg_checkset(EEGSnippet);
EEGSnippet = pop_eegfiltnew(EEGSnippet, .5);

%%% plot
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Figure.Padding = 5;
PlotProps.Line.Width = 1.5;
YGap = 20;
figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width+1 PlotProps.Figure.Width/2+1])
chART.sub_plot([], [1 1], [1, 1], [], true, '', PlotProps);

% basic EEG

plot_eeg(EEGSnippet.data, EEG.srate, YGap, PlotProps)

% bursts
FrequencyRange = Bands.Iota;
plot_burst_mask(EEGSnippet, FrequencyRange, YGap, PlotProps)

chART.save_figure([ExampleParticipant, '_REM_Example'], ResultsFolder, PlotProps)



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




