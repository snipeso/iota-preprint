% This script plots all the sleep related figures
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
% Format = 'Minimal'; % chooses which filtering to do
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


IotaBand = [25 40];
IotaTextColor = [73 63 11]/255;

Grid = [8 9];

%%% A: periodic peaks individuas

load(fullfile(CacheDir, CacheName), 'CenterFrequencies', 'StageLabels', 'StageIndexes', 'StageMinutes')


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

% add minutes to stage labels
% StageLabelsWithMinutes = StageLabels;
% for StageIdx  = 1:numel(StageLabels)
%     StageLabelsWithMinutes{StageIdx} = [StageLabels{StageIdx}, ' (', num2str(round(mean(StageMinutes(:, StageIdx), 1))), '±', num2str(round(std(StageMinutes(:, StageIdx), 0, 1))), ' min)'];
% end

Grid = [7 9];
chART.sub_plot([], Grid, [5, 1], [2, 9], false, 'B', PlotProps);

[AxesGrid, WhiteAxes] = colorscale_grid(MeanCenterFrequency, nParticipants,  Bands, StageLabels, StageMinutes, PlotProps);
 set(AxesGrid, 'Units', 'centimeters')
  set(WhiteAxes, 'Units', 'centimeters')
 CurrentPosition = AxesGrid.Position;
%  CurrentPosition = [3.5, CurrentPosition(2)-.3, LastLittleAxes.Position(3)+LastLittleAxes.Position(1)-3.5, CurrentPosition(4)];
% AxesGrid.Position = CurrentPosition;
% WhiteAxes.Position = CurrentPosition;

LastLittleAxes.Units = 'normalized';

disp('N per stage:')
[StageLabels', string(sum(StageMinutes>=1)')]

%%% C: topography

load(fullfile(CacheDir, CacheName), 'PeriodicTopographies', 'Chanlocs', 'Bands', 'StageLabels')
BandLabels = fieldnames(Bands);
nStages = numel(StageLabels);
nBands = numel(BandLabels);
PlotProps.Colorbar.Location = 'North';

PlotIndexes = {[4 2], [4 4], [1 2], [2 3], [5 1], [5 5]}; % [stage, band]
Titles = {'W — alpha', 'W — beta', 'N3 — alpha', 'N2 — sigma', 'R — theta', 'R — iota'};

GridRws = 8;
Grid = [GridRws, numel(PlotIndexes)];
for PlotIdx = 1:numel(PlotIndexes)
    Indexes = PlotIndexes{PlotIdx};
    Data = squeeze(mean(PeriodicTopographies(:, Indexes(1), Indexes(2), :), 1, 'omitnan'));
    disp([BandLabels{Indexes(2)}, ' ', StageLabels{Indexes(1)}, ' ' num2str(nnz(~isnan(PeriodicTopographies(:, Indexes(1), Indexes(2), 1))))])
    % Data = squeeze(mean(CustomTopographies(:, StageIdx, BandIdx, :), 1, 'omitnan'));
    if all(isnan(Data)|Data==0)
        continue
    end

    if PlotIdx ==1
        chART.sub_plot([], Grid, [GridRws, PlotIdx], [2, 1], false, 'C', PlotProps);
        axis off
        Legend = 'Log power';
    else
        Legend = '';
    end

    CLims = quantile(Data, [0 1]);

      Axes = chART.sub_plot([], Grid, [GridRws, PlotIdx], [2, 1], false, '', PlotProps);
    chART.plot.eeglab_topoplot(Data, Chanlocs, [], CLims, '', 'Linear', PlotProps);
        set(gca, 'Units', 'centimeters')
    Axes.Position(2) = 2;
    % title([BandLabels{Indexes(2)}, ' ', StageLabels{Indexes(1)}])
    title(Titles{PlotIdx})

    Axes = chART.sub_plot([], [GridRws, numel(PlotIndexes)], [GridRws, PlotIdx], [2, 1], false, ' ', PlotProps);
    set(gca, 'Units', 'centimeters')
    Axes.Position(2) = Axes.Position(2)-3;

    chART.plot.pretty_colorbar('Linear', CLims, Legend, PlotProps);
    axis off
end

AxesGrid.Colormap = chART.utils.custom_gradient([1 1 1], PlotProps.Color.Maps.Linear(1, :));

% chART.save_figure('PeriodicPeaks', ResultsFolder, PlotProps)



%%

Data = squeeze(mean(PeriodicTopographies(:, 5, 5, :), 1, 'omitnan'));
MeanTopo = Data;

Topography = table();
Topography.Labels = {Chanlocs.labels}';
Topography.Iota = MeanTopo;

disp(sortrows(Topography, 'Iota', 'descend'))



%% Figure 8 hypnogram

PlotProps = Parameters.PlotProps.Manuscript;
% PlotProps.Axes.yPadding = 5;

load(fullfile(SourceSpecparam, [ExampleParticipant, '_Sleep_Baseline.mat']), ...
    'PeriodicPower', 'Slopes', 'FooofFrequencies',  'Scoring', 'Chanlocs', 'Time', 'ScoringIndexes', 'ScoringLabels')
Time = Time/60/60; % convert time to hours

figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width*1.1 PlotProps.Figure.Height])

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
set(gca, 'YDir', 'normal')
ylabel('Frequency (Hz)')
xlabel('Time (h)')
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
chART.sub_plot([], Grid, [3, 1], [1 1], true, 'B', PlotProps);
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


%%% C: REM bout
CacheName = [ExampleParticipant, '_BurstsOneREM.mat'];
load(fullfile(CacheDir, CacheName), 'Bursts', 'EEGSnippet', 'BurstClusters')
EOG2 =  EEGSnippet.data(32, :)-EEGSnippet.data(125, :);

rms_per_channel = sqrt(EOG2.^2);
t = linspace(0, size(EEGSnippet.data, 2)/EEGSnippet.srate, size(EEGSnippet.data, 2));
chART.sub_plot([], Grid, [4, 1], [1 1], true, 'C', PlotProps);

scatter([Bursts.Start]/EEGSnippet.srate/60, [Bursts.ChannelIndex], [Bursts.MeanAmplitude]*5, 'filled', 'MarkerFaceAlpha', .1, 'MarkerFaceColor', PlotProps.Color.Maps.Linear(128, :))
hold on
plot(t/60, mat2gray(smooth(rms_per_channel, 1000))*129, 'LineWidth', 2, 'color', [0 0 0])
axis tight


%%% D: example REM time

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
B3Axes = gca;
B3Axes.Units = B1Axis.Units;
B3Axes.Position(3) = Width;


chART.save_figure('ExampleHypnogram', ResultsFolder, PlotProps)


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




