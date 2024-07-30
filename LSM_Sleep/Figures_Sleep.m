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

%% Figure X

% load(fullfile(CacheDir, CacheName), 'CenterFrequencies', 'PeriodicPeaks', 'StageLabels',  ...
%     'Chanlocs', 'CustomTopographies', 'LogTopographies', 'PeriodicTopographies', ...
%     'AllSpectra', 'AllPeriodicSpectra', 'Frequencies', 'FooofFrequencies', 'Bands')

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

disp(AllCenterFrequencies)
writetable(AllCenterFrequencies, fullfile(ResultsFolder, 'DetectedPeaksByStage.csv'))



%% Figure x

PlotProps = Parameters.PlotProps.Manuscript;
FreqLims = [3 45];
PlotProps.Figure.Padding = 25;

load(fullfile(SourceSpecparam, [ExampleParticipant, '_Sleep_Baseline.mat']), ...
    'PeriodicPower', 'Slopes', 'FooofFrequencies',  'Scoring', 'Chanlocs', 'Time', 'ScoringIndexes', 'ScoringLabels')
Time = Time/60/60; % convert time to hours

figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width PlotProps.Figure.Width/2])

Grid = [3 5];
MeanPower = squeeze(mean(PeriodicPower(labels2indexes(Channels, Chanlocs), :, :), 1, 'omitnan'));
SmoothMeanPower = smooth_frequencies(MeanPower, FooofFrequencies, 4)';


% plot time-frequency
chART.sub_plot([], Grid, [2, 1], [2 4], true, 'A', PlotProps);

imagesc(Time, FooofFrequencies, SmoothMeanPower)
chART.set_axis_properties(PlotProps)
% CLims = quantile(MeanPower(:), [.001, .999]);
CLims = [-.1 1.1];
clim(CLims)
set(gca, 'YDir', 'normal')
ylabel('Frequency (Hz)')
set(gca, 'TickLength', [0 0], 'YLim', FreqLims)
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.Text.LegendSize = PlotProps.Text.AxisSize;
chART.plot.pretty_colorbar('Linear', CLims, 'Log power', PlotProps)
B1Axis = gca;

%%%  plot hypnogram
chART.sub_plot([], Grid, [3, 1], [1 4], true, 'B', PlotProps);
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
set(gca, 'YColor', 'k', 'TickLength', [0 0])
ylim([-3.5 -.9]) % by chance the ranges work the same; otherwise would need a second axis
ylabel('Slope')
box off
B2Axes = gca;
B2Axes.Units = B1Axis.Units;
B2Axes.Position(3) = B1Axis.Position(3);

%%% C: topography

% data parameters

CLims = [0.05, .75];

StageTitles = {'Wake', 'REM'};
Stages = {0, 1};

Grid = [5 5];

Positions = [2, 4];

chART.sub_plot([], Grid, [2, 5], [2 1], true, 'C', PlotProps); axis off;

Band = [30 34];
for StageIdx = 1:numel(StageTitles) % rows
    % select data

    StageEpochs = ismember(Scoring, Stages{StageIdx}); % epochs of the requested stage
    FreqRange = dsearchn(FooofFrequencies', Band');

    Data = squeeze(mean(mean(PeriodicPower(:, StageEpochs, ...
        FreqRange(1):FreqRange(2)), 2, 'omitnan'), 3, 'omitnan'));

    % plot
    Axes = chART.sub_plot([], Grid, [Positions(StageIdx), 5], [2, 1], false, '', PlotProps);
    Axes.Position(2) = Axes.Position(2)-.03; 
    chART.plot.eeglab_topoplot(Data, Chanlocs, [], CLims, '', 'Linear', PlotProps)

    title(StageTitles{StageIdx})
end
Axes = chART.sub_plot([], Grid, [5, 5], [1, 1], false, '', PlotProps);
axis off
PlotProps.Colorbar.Location = 'north';
chART.plot.pretty_colorbar('Linear', CLims, 'Log power', PlotProps)
Axes.Position(4) = .3;
Axes.Position(2) = -.1;
chART.save_figure('ExampleHypnogram', ResultsFolder, PlotProps)


%% figure x


figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width PlotProps.Figure.Width/3])

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Figure.Padding = 30;

Grid = [2 11];
%%%%% Main participant

 chART.sub_plot([], Grid, [2 1], [2 2], false, '', PlotProps);
load(fullfile(SourceSpecparam, [ExampleParticipant, '_Sleep_Baseline.mat']), ...
   'PeriodicPeaks', 'Scoring', 'Chanlocs')

plot_peaks_sleep(PeriodicPeaks(labels2indexes(Channels, Chanlocs), :, :), Scoring, PlotProps)
xlim(FreqLims)

%%%%%%%%%%%%%%%%
%%% All data

Participants = Parameters.Participants;
Participants(strcmp(Participants, 'P09')) = [];

%%% D

for ParticipantIdx = 1:numel(Participants)

    % load data
    Participant = Participants{ParticipantIdx};
    load(fullfile(SourceSpecparam, [Participant, '_Sleep_Baseline.mat']), 'PeriodicPeaks', 'Scoring');

    % plot
    if ParticipantIdx > 9 % split after the 9th recording
        R = 2;
        C = 2+ParticipantIdx-9;
    else
        R = 1;
        C = 2+ParticipantIdx;
    end
    chART.sub_plot([], Grid, [R, C], [], false, '', PlotProps);
    plot_peaks_sleep(PeriodicPeaks(labels2indexes(Channels, Chanlocs), :, :), Scoring, PlotProps)

    box off
    set(gca,  'TickLength', [0 0])
    xlim(FreqLims)
    xlabel('')
    ylabel('')
    legend off
    if R ==2 & C == 1
        continue
    end
end

chART.save_figure('PeriodicPeaks', ResultsFolder, PlotProps)






%% Figure 6

% load in data
load(fullfile(SourceSpecparam, [ExampleParticipant, '_Sleep_Baseline.mat']), ...
    'PeriodicPower', 'Slopes', 'FooofFrequencies', 'PeriodicPeaks', 'Scoring', 'Chanlocs', 'Time', 'ScoringIndexes', 'ScoringLabels')

Time = Time/60/60; % convert time to hours

PlotProps = Parameters.PlotProps.Manuscript;
Grid = [2 5];

figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width PlotProps.Figure.Width/2])

%%% A: periodic peaks
AAxes = chART.sub_plot([], Grid, [1, 1], [], true, 'A', PlotProps);
plot_peaks_sleep(PeriodicPeaks(labels2indexes(Channels, Chanlocs), :, :), Scoring, PlotProps)
xlim(FreqLims)

%%% B: time-frequency
MiniGrid = [3 1];
MeanPower = squeeze(mean(PeriodicPower(labels2indexes(Channels, Chanlocs), :, :), 1, 'omitnan'));
SmoothMeanPower = smooth_frequencies(MeanPower, FooofFrequencies, 4)';

chART.sub_plot([], Grid, [1, 2], [], -.1, 'B', PlotProps); axis off;
Space = chART.sub_figure(Grid, [1, 2], [1, 2], '', PlotProps);
Space(3) = Space(3)-10;

% plot time-frequency
chART.sub_plot(Space, MiniGrid, [2, 1], [2 1], false, '', PlotProps);

imagesc(Time, FooofFrequencies, SmoothMeanPower)
chART.set_axis_properties(PlotProps)
clim(quantile(MeanPower(:), [.001, .999]))
set(gca, 'YDir', 'normal')
ylabel('Frequency (Hz)')
set(gca, 'TickLength', [0 0], 'YLim', FreqLims)
B1Axis = gca;

% plot hypnogram
chART.sub_plot(Space, MiniGrid, [3, 1], [], false, '', PlotProps);
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
set(gca, 'YColor', 'k', 'TickLength', [0 0])
ylim([-3.5 -.9]) % by chance the ranges work the same; otherwise would need a second axis
ylabel('Slope')

% align A to the bottom of B
B2Axes = gca;
AAxes.Position(4) = AAxes.Position(4) + AAxes.Position(2) - B2Axes.Position(2);
AAxes.Position(2) = B2Axes.Position(2);
box off


%%% C: topography

% data parameters
Bands = struct();
Bands.Iota = [30 34];
Bands.Alpha = [7 11];

BandLabels = fieldnames(Bands);


% plot parameters
PlotTopoProps = Parameters.PlotProps.TopoPlots;
PlotTopoProps.Figure.Padding = 10;
PlotTopoProps.Axes.yPadding = 10;
PlotTopoProps.Axes.xPadding = 5;
PlotTopoProps.Text.TitleSize = 9;

CLims = [0.05, .65;
    0.1 1];

Titles = {'Wake \iota', 'Wake \alpha', 'REM \iota', 'REM \alpha', 'NREM \iota', 'NREM \alpha'};
StageTitles = {'Wake', 'REM', 'NREM'};
Stages = {0, 1, [-2 -3]};

chART.sub_plot([], Grid, [1, 4], [], true, 'C', PlotProps); axis off;
Space = chART.sub_figure(Grid, [1 4], [1 2], '', PlotProps);
Space(1) = Space(1)+10;
Space(2) = Space(2)-20;
Space(3) = Space(3)-80;
Space(4) = Space(4)+20;
for StageIdx = 1:numel(StageTitles) % columns
    for BandIdx = 1:numel(BandLabels) % rows

        % select data
        Band = Bands.(BandLabels{BandIdx});
        if isempty(Band) || any(isnan(Band)) % don't actually need it for P09, but it helps if trying other participants
            continue
        end

        StageEpochs = ismember(Scoring, Stages{StageIdx}); % epochs of the requested stage
        FreqRange = dsearchn(FooofFrequencies', Band');

        Data = squeeze(mean(mean(PeriodicPower(:, StageEpochs, ...
            FreqRange(1):FreqRange(2)), 2, 'omitnan'), 3, 'omitnan'));

        % plot
        chART.sub_plot(Space, [numel(BandLabels), numel(StageTitles)], [BandIdx, StageIdx], [], false, '', PlotTopoProps);
        chART.plot.eeglab_topoplot(Data, Chanlocs, [], CLims(BandIdx, :), '', 'Linear', PlotTopoProps)

        if BandIdx == 1
            title(StageTitles{StageIdx})
        end

        if StageIdx == 1
            chART.plot.vertical_text(BandLabels{BandIdx}, .15, .5, PlotTopoProps)
        end
    end
end

for BandIdx = 1:2
    BandLabel = BandLabels{BandIdx};
    Band = Bands.(BandLabel);
    chART.sub_plot(Space, [numel(BandLabels), numel(StageTitles)], [BandIdx, numel(StageTitles)+1], [], false, '', PlotTopoProps);
    chART.plot.pretty_colorbar('Linear', CLims(BandIdx, :), ...
        [num2str(round(Band(1))), '-', num2str(round(Band(2))), ' Hz'], PlotTopoProps)
    axis off
end



%%%%%%%%%%%%%%%%
%%% All data

Participants = Parameters.Participants;
Participants(strcmp(Participants, 'P09')) = [];

%%% D
MiniGrid = [2 9]; % removing the example P09, this works out so nicely <3

PlotProps.Axes.yPadding = 30;
chART.sub_plot([], Grid, [2, 1], [], true, 'D', PlotProps); axis off; % these are hacks
Space = chART.sub_figure(Grid, [2 1], [1 5], '', PlotProps);
Space(2) = 20;
Space(4) = Space(4)+20;
PlotProps.Axes.yPadding = 15;

for ParticipantIdx = 1:numel(Participants)

    % load data
    Participant = Participants{ParticipantIdx};
    load(fullfile(SourceSpecparam, [Participant, '_Sleep_Baseline.mat']), 'PeriodicPeaks', 'Scoring');

    % plot
    if ParticipantIdx > 9 % split after the 9th recording
        R = 2;
        C = ParticipantIdx-9;
    else
        R = 1;
        C = ParticipantIdx;
    end
    chART.sub_plot(Space, MiniGrid, [R, C], [], false, '', PlotProps);
    plot_peaks_sleep(PeriodicPeaks(labels2indexes(Channels, Chanlocs), :, :), Scoring, PlotProps)

    box off
    set(gca,  'TickLength', [0 0])
    xlim(FreqLims)
    xlabel('')
    ylabel('')
    legend off
    if R ==2 & C == 1
        continue
    end
end

B1Axis.Colormap = PlotProps.Color.Maps.Linear; % reduce noise in plot

chART.save_figure('PeriodicPeaks', ResultsFolder, PlotProps)



%% Example REM sleep

load(fullfile(SourceEEG, [ExampleParticipant, '_Sleep_Baseline.mat']), 'EEG')

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
PlotProps.Figure.Padding = 5;
YGap = 20;
figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width PlotProps.Figure.Width/2])
chART.sub_plot([], [1 1], [1, 1], [], true, '', PlotProps);

% basic EEG
plot_eeg(EEGSnippet.data, EEG.srate, YGap, PlotProps)

% bursts
FrequencyRange = Bands.Iota;
plot_burst_mask(EEGSnippet, FrequencyRange, YGap, PlotProps)

chART.save_figure([ExampleParticipant, '_REM_Example'], ResultsFolder, PlotProps)



%% not included: topography of all stages/bands

load(fullfile(CacheDir, CacheName), 'PeriodicTopographies', 'Chanlocs', 'Bands', 'StageLabels')
BandLabels = fieldnames(Bands);
nStages = numel(StageLabels);
nBands = numel(BandLabels);

PlotProps = Parameters.PlotProps.Manuscript;
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

