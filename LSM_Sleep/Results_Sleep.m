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

disp('N per stage:')
[StageLabels', string(sum(StageMinutes>=1)')]

%%% C: topography
load(fullfile(CacheDir, CacheName), 'PeriodicTopographies', 'Chanlocs', 'Bands', 'StageLabels')
BandLabels = fieldnames(Bands);
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.Axes.xPadding = 5;
% PlotIndexes = {[5 5], [5 1], [4 2], [4 4],  [2 3], [1 2]}; % [stage, band]
% Titles = {'R — iota', 'R — theta', 'W — alpha', 'W — beta', 'N2 — sigma', 'N3 — alpha',};

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
    % Data = squeeze(mean(CustomTopographies(:, StageIdx, BandIdx, :), 1, 'omitnan'));
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

    CLims = quantile(Data, [0 1]);
    CLims = [.05 .2];

    AxesTopo = chART.sub_plot([], Grid, [GridRws, PlotIdx], [2, 1], false, '', PlotProps);
    chART.plot.eeglab_topoplot(Data, Chanlocs, [], CLims, '', 'Linear', PlotProps);
    set(gca, 'Units', 'centimeters')
    % Axes.Position(2) = 2;
    % title([BandLabels{Indexes(2)}, ' ', StageLabels{Indexes(1)}])
    title(Titles{PlotIdx})

    % Axes = chART.sub_plot([], [GridRws, numel(PlotIndexes)], [GridRws, PlotIdx], [2, 1], false, ' ', PlotProps);
    % set(gca, 'Units', 'centimeters')
    % Axes.Position(2) = Axes.Position(2)-3;

    axis off
end

Axes = chART.sub_plot([], Grid, [GridRws, PlotIdx+1], [2, 1], false, '', PlotProps);
chART.plot.pretty_colorbar('Linear', CLims, 'Periodic power', PlotProps);
Axes.Units = 'centimeters';
Axes.Position = [Axes.Position(1)-3, AxesTopo.Position(2)+1, 3, Axes.Position(4)-2];
% Axes.Position = [Axes.Position(1), AxesTopo.Position(2), Axes.Position(3), Axes.Position(4)];
set(Axes, 'visible', 'off')
AxesGrid.Colormap = chART.utils.custom_gradient([1 1 1], PlotProps.Color.Maps.Linear(1, :));

chART.save_figure('PeriodicPeaks', ResultsFolder, PlotProps)



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
% set(gca, 'YDir', 'normal', 'TickLength', [0.0100    0.0250])
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
% B1Axis.Position(2) = B1Axis.Position(2) + .01;

% plot hypnogram
chART.sub_plot([], Grid, [3, 1], [1 1], true, '', PlotProps);
yyaxis left
% Red = chART.color_picker(1, '', 'red');
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

rms_per_channel = sqrt(EOG2.^2);
t = linspace(0, size(EEGSnippet.data, 2)/EEGSnippet.srate, size(EEGSnippet.data, 2));
chART.sub_plot([], Grid, [4, 1], [1 1], true, 'B', PlotProps);

scatter([Bursts.Start]/EEGSnippet.srate/60, [Bursts.ChannelIndex], [Bursts.MeanAmplitude], 'filled', 'MarkerFaceAlpha', .1, 'MarkerFaceColor', PlotProps.Color.Maps.Linear(128, :))
hold on
plot(t/60, mat2gray(smooth(rms_per_channel, 1000))*123, 'LineWidth', 1.5, 'color', [0 0 0])
chART.set_axis_properties(PlotProps)
set(gca, 'YColor', 'none', 'TickLength', [TickLength 0])
axis tight
xlabel('Time (min)')
B3Axes = gca;
B3Axes.Units = B1Axis.Units;
B3Axes.Position(3) = Width;
B3Axes.Position = [B3Axes.Position(1), B3Axes.Position(2)-.01, Width, B3Axes.Position(4)+.01];


%%% C: example REM time

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
% B4Axes.Position(2) = B4Axes.Position(2) + .01; 
set(gca,  'TickLength', [TickLength 0])

chART.save_figure('ExampleHypnogram', ResultsFolder, PlotProps)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% not included: topography of all stages/bands

load(fullfile(CacheDir, CacheName), 'PeriodicTopographies', 'Chanlocs', 'Bands', 'StageLabels', 'CustomTopographies')
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
        % Data = squeeze(mean(PeriodicTopographies(:, StageIdx, BandIdx, :), 1, 'omitnan'));
        Data = squeeze(mean(CustomTopographies(:, StageIdx, BandIdx, :), 1, 'omitnan'));
        if all(isnan(Data)|Data==0)
            continue
        end
        chART.sub_plot([], Grid, [BandIdx, StageIdx], [], false, '', PlotProps);
        % chART.plot.eeglab_topoplot(Data, Chanlocs, [], CLims(BandIdx, :), '', 'Linear', PlotProps);
        chART.plot.eeglab_topoplot(Data, Chanlocs, [], [], '', 'Linear', PlotProps);

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




