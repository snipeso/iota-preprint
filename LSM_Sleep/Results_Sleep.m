% This script plots all the sleep related figures. It's all a bit ugly...
% iota-neurophys, Snipes 2024

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = LSMParameters();
Paths = Parameters.Paths;
CriteriaSet = Parameters.CriteriaSet;
Participants = Parameters.Participants;
Bands = Parameters.Bands;

Channels = Parameters.Channels.NotEdge;
Task = Parameters.Task;
Format = 'Minimal'; % chooses which filtering to do
FreqLims = [3 45];

ExampleParticipant = 'P09';
ExampleParticipantIdx = find(strcmp(Participants, ExampleParticipant));

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


%% Figure 3: periodic peaks


Settings = oscip.default_settings();
Settings.PeakBandwidthMax = 4;
Settings.DistributionBandwidthMax = 4; % how much jitter there can be across periodic peaks

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Figure.Padding = 30;

IotaTextColor = [73 63 11]/255;

Grid = [8 9];

%%% A: periodic peaks individuals

load(fullfile(CacheDir, CacheName), 'CenterFrequencies', 'StageLabels',  'StageMinutes')


% Main participant
load(fullfile(SourceSpecparam, [ExampleParticipant, '_Sleep_Baseline.mat']), ...
    'PeriodicPeaks', 'Scoring', 'Chanlocs')

figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width PlotProps.Figure.Height*.8])

chART.sub_plot([], Grid, [3 1], [3 3], false, 'A', PlotProps);
plot_peaks_sleep(PeriodicPeaks(labels2indexes(Channels, Chanlocs), :, :), Scoring, PlotProps)
xlim(FreqLims)
add_peak_text(squeeze(CenterFrequencies(ExampleParticipantIdx, end, end-1)), IotaTextColor, PlotProps)

% All other participants

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
    xlim(FreqLims)
    xticks(10:20:50)
    legend off

    % find REM iota, and display
    ParticipantDataIdx = find(strcmp(Parameters.Participants, Participant));
    add_peak_text(squeeze(CenterFrequencies(ParticipantDataIdx, end, end-1)), IotaTextColor, PlotProps)
    add_peak_text(squeeze(CenterFrequencies(ParticipantDataIdx, end, end)), IotaTextColor, PlotProps)
end
LastLittleAxes = gca;
LastLittleAxes.Units = 'centimeters';

%%% B: table of all peaks
MeanCenterFrequency = round(squeeze(mean(CenterFrequencies, 1, 'omitnan')),1);
nParticipants = squeeze(sum(~isnan(CenterFrequencies), 1));

Grid = [7 9];
chART.sub_plot([], Grid, [5, 1], [2, 9], false, 'B', PlotProps);

[AxesGrid, WhiteAxes] = colorscale_grid(flip(MeanCenterFrequency), flip(nParticipants),  Bands, flip(StageLabels), flip(StageMinutes, 2), PlotProps);
set(AxesGrid, 'Units', 'centimeters')
set(WhiteAxes, 'Units', 'centimeters')
CurrentPosition = AxesGrid.Position;

AxesGrid.Position = [CurrentPosition(1), CurrentPosition(2)-.2, CurrentPosition(3), CurrentPosition(4)-.2];
WhiteAxes.Position= [CurrentPosition(1), CurrentPosition(2)-.2, CurrentPosition(3), CurrentPosition(4)-.2];
LastLittleAxes.Units = 'normalized';


%%% C: topography
load(fullfile(CacheDir, CacheName), 'PeriodicTopographies', 'Chanlocs', 'Bands', 'StageLabels')
BandLabels = fieldnames(Bands);
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.Axes.xPadding = 5;

PlotIndexes = {[5 5], [4 5], [3 5], [2 5], [1 5]}; % [stage, band]
Titles = {'R', 'W', 'N1', 'N2', 'N3'};

GridRws = 8;
Grid = [GridRws, numel(PlotIndexes)+1];

% remove outermost channels
RM = labels2indexes([48 119], Chanlocs);
Chanlocs(RM) = [];
PeriodicTopographies(:, :, :, RM) = [];

for PlotIdx = 1:numel(PlotIndexes)
    Indexes = PlotIndexes{PlotIdx};
    Data = squeeze(mean(PeriodicTopographies(:, Indexes(1), Indexes(2), :), 1, 'omitnan'));
    disp([BandLabels{Indexes(2)}, ' ', StageLabels{Indexes(1)}, ' ' num2str(nnz(~isnan(PeriodicTopographies(:, Indexes(1), Indexes(2), 1))))])
    if all(isnan(Data)|Data==0)
        continue
    end

    if PlotIdx ==1
        chART.sub_plot([], Grid, [GridRws, PlotIdx], [2, 1], false, 'C', PlotProps);
        axis off
        Legend = 'Periodic power';
    else
        Legend = '';
    end

    CLims = [.05 .2];

    AxesTopo = chART.sub_plot([], Grid, [GridRws, PlotIdx], [2, 1], false, '', PlotProps);
    chART.plot.eeglab_topoplot(Data, Chanlocs, [], CLims, '', 'Linear', PlotProps);
    set(gca, 'Units', 'centimeters')
    title(Titles{PlotIdx})
    axis off
end

Axes = chART.sub_plot([], Grid, [GridRws, PlotIdx+1], [2, 1], false, '', PlotProps);
chART.plot.pretty_colorbar('Linear', CLims, 'Periodic power', PlotProps);
Axes.Units = 'centimeters';
Axes.Position = [Axes.Position(1)-3, AxesTopo.Position(2)+1, 3, Axes.Position(4)-2];
set(Axes, 'visible', 'off')
AxesGrid.Colormap = chART.utils.custom_gradient([1 1 1], PlotProps.Color.Maps.Linear(1, :));

chART.save_figure('PeriodicPeaks', ResultsFolder, PlotProps)



%% top channels

Data = squeeze(mean(PeriodicTopographies(:, 5, 5, :), 1, 'omitnan'));
MeanTopo = Data;

Topography = table();
Topography.Labels = {Chanlocs.labels}';
Topography.Iota = MeanTopo;

disp(sortrows(Topography, 'Iota', 'descend'))



%% Figure 4 example sleep

PlotProps = Parameters.PlotProps.Manuscript;

load(fullfile(SourceSpecparam, [ExampleParticipant, '_Sleep_Baseline.mat']), ...
    'PeriodicPower', 'Slopes', 'FooofFrequencies',  'Scoring', 'Chanlocs', 'Time', 'ScoringIndexes', 'ScoringLabels')
Time = Time/60/60; % convert time to hours

figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width PlotProps.Figure.Height*1.1])

Grid = [7 1];
MeanPower = squeeze(mean(PeriodicPower(labels2indexes(Channels, Chanlocs), :, :), 1, 'omitnan'));
SmoothMeanPower = smooth_frequencies(MeanPower, FooofFrequencies, 4)';


%%% A: plot time-frequency
TickLength = .005;
chART.sub_plot([], Grid, [2, 1], [2 1], true, 'A', PlotProps);

imagesc(Time, FooofFrequencies, SmoothMeanPower)
chART.set_axis_properties(PlotProps)
CLims = [-.1 1.1];
clim(CLims)
set(gca, 'YDir', 'normal',   'TickLength', [TickLength 0])
ylabel('Frequency (Hz)')
set(gca, 'YLim', FreqLims)
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.Text.LegendSize = PlotProps.Text.AxisSize;
box off
Bar = chART.plot.pretty_colorbar('Linear', CLims, 'Periodic power', PlotProps);
B1Axis = gca;
Width = B1Axis.Position(3);
Bar.Position(3) = 0.014647239581274;
B1Axis.Position(3) = Width;

% plot hypnogram
chART.sub_plot([], Grid, [3, 1], [1 1], true, '', PlotProps);
yyaxis left
Red = PlotProps.Color.Maps.Linear(30, :);
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
B2Axes.Position(2) = B2Axes.Position(2)+.025;
B2Axes.Position(4) =B2Axes.Position(4)-.01;


%%% B: REM bout
CacheName = [ExampleParticipant, '_BurstsOneREM.mat'];
load(fullfile(CacheDir, CacheName), 'Bursts', 'EEGSnippet', 'BurstClusters')
EOG2 =  EEGSnippet.data(labels2indexes(32, EEGSnippet.chanlocs), :)-EEGSnippet.data(labels2indexes(125, EEGSnippet.chanlocs), :);

amp_eog = abs(EOG2);
t = linspace(0, size(EEGSnippet.data, 2)/EEGSnippet.srate, size(EEGSnippet.data, 2));
chART.sub_plot([], Grid, [4, 1], [1 1], true, 'B', PlotProps);

scatter([Bursts.Start]/EEGSnippet.srate/60, [Bursts.ChannelIndex], [Bursts.MeanAmplitude], 'filled', 'MarkerFaceAlpha', .1, 'MarkerFaceColor', PlotProps.Color.Maps.Linear(128, :))
hold on
plot(t/60, mat2gray(smooth(amp_eog, 1000))*123, 'LineWidth', 1.5, 'color', [0 0 0])
chART.set_axis_properties(PlotProps)
set(gca, 'YColor', 'none', 'TickLength', [TickLength 0])
axis tight
xlabel('Time (min)')
B3Axes = gca;
B3Axes.Units = B1Axis.Units;
B3Axes.Position(3) = Width;
B3Axes.Position = [B3Axes.Position(1), B3Axes.Position(2)-.01, Width, B3Axes.Position(4)+.01];


%%% C: example REM in time

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
PlotProps.Line.Width = 1.5;
YGap = 20;

% basic EEG
chART.sub_plot([], Grid, [7, 1], [3 1], true, 'C', PlotProps);
plot_eeg(EEGSnippet.data, EEG.srate, YGap, PlotProps)


% bursts
FrequencyRange = Bands.Iota; % TODO: make custom
plot_burst_mask(EEGSnippet, FrequencyRange, CriteriaSet, YGap, PlotProps)
B4Axes = gca;
B4Axes.Units = B1Axis.Units;
B4Axes.Position(3) = Width;
set(gca,  'TickLength', [TickLength 0])

chART.save_figure('ExampleHypnogram', ResultsFolder, PlotProps)



