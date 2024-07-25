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

ScoringIndexes = -3:1:1; % TEMP
ScoringLabels = {'N3', 'N2', 'N1', 'W', 'R'};



% folders
SourceSpecparam = fullfile(Paths.Final, 'EEG', 'Power',  '20sEpochs', Task, Format);
SourceEEG = fullfile(Paths.Preprocessed, Format, 'Clean', Task);

ResultsFolder = fullfile(Paths.Results);
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plot

%%
PlotProps = Parameters.PlotProps.Manuscript;
Grid = [2 5];

% PlotProps.Debug = true;
figure('Units','centimeters', 'Position', [0 0 30 15])

%%%%%%%%%%%%%%%%
%%% Example data

% load(fullfile(SourceSpecparam, [ExampleParticipant, '_Sleep_Baseline.mat']), ...
%     'PeriodicPower', 'Slopes', 'FooofFrequencies', 'PeriodicPeaks', 'Scoring', 'Chanlocs', 'Time', 'ScoringIndexes', 'ScoringLabels')

load(fullfile(SourceSpecparam, [ExampleParticipant, '_Sleep_Baseline.mat']), ...
    'PeriodicPower', 'Slopes', 'FooofFrequencies', 'PeriodicPeaks', 'Scoring', 'Chanlocs', 'Time')

Time = Time/60/60; % convert time to hours

%%% A: periodic peaks
AAxes = chART.sub_plot([], Grid, [1, 1], [], true, 'A', PlotProps);
% Axes.Position(2) = 0.0794; % from B, lower plot, just to align axis. Bad code
plot_peaks_sleep(PeriodicPeaks(labels2indexes(Channels, Chanlocs), :, :), Scoring, PlotProps)

%%% B: time-frequency

YLims = [3 40];
MiniGrid = [3 1];
% PlotProps.Figure.Padding = 20;
% PlotProps.Text.AxisSize = 10;
MeanPower = squeeze(mean(PeriodicPower(labels2indexes(Channels, Chanlocs), :, :), 1, 'omitnan'));
MP = smooth_frequencies(MeanPower, FooofFrequencies, 4)';

chART.sub_plot([], Grid, [1, 2], [], true, 'B', PlotProps); axis off;
Space = chART.sub_figure(Grid, [1, 2], [1, 2], '', PlotProps);

% plot time-frequency
chART.sub_plot(Space, MiniGrid, [2, 1], [2 1], false, '', PlotProps);
% imagesc(Time, FooofFrequencies, MeanPower')

imagesc(Time, FooofFrequencies, MP)
chART.set_axis_properties(PlotProps)
clim(quantile(MeanPower(:), [.001, .999]))
set(gca, 'YDir', 'normal')
ylabel('Frequency (Hz)')
set(gca, 'TickLength', [0 0], 'YLim', YLims)
B1Axis = gca;

% plot hypnogram
chART.sub_plot(Space, MiniGrid, [3, 1], [], false, '', PlotProps);
hold on
plot(Time, -Slopes, 'Color', [.1 .1 .1 .01])
plot(Time, Scoring, 'LineWidth', PlotProps.Line.Width/3, 'Color', [chART.color_picker(1, '', 'red'), .5])
chART.set_axis_properties(PlotProps)
axis tight
box off
xlabel('Time (h)')
yticks(sort(ScoringIndexes))
yticklabels(ScoringLabels)
ylim([-3.5 1.5]) % by chance the ranges work the same; otherwise would need a second axis

% align A to the bottom of B
B2Axes = gca;
AAxes.Position(4) = AAxes.Position(4) + AAxes.Position(2) - B2Axes.Position(2);
AAxes.Position(2) = B2Axes.Position(2);

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
% Space(1) = Space(1)-20;
Space(2) = Space(2)- 20;
Space(3) = Space(3)-50;
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
        % title([StageTitles{StageIdx}, ' ', BandLabels{BandIdx}])
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
    if ParticipantIdx > 9 % split after the 9th recording
        R = 2;
        C = ParticipantIdx-9;
    else
        R = 1;
        C = ParticipantIdx;
    end

    Participant = Participants{ParticipantIdx};
    load(fullfile(SourceSpecparam, [Participant, '_Sleep_Baseline.mat']), 'PeriodicPeaks', 'Scoring');
    chART.sub_plot(Space, MiniGrid, [R, C], [], false, '', PlotProps);
    plot_peaks_sleep(PeriodicPeaks(labels2indexes(Channels, Chanlocs), :, :), Scoring, PlotProps)
    box off
    set(gca,  'TickLength', [0 0])
    xlabel('')
    ylabel('')
    legend off
    xlim([3 45])
    if R ==2 & C == 1
        continue
    end
end


B1Axis.Colormap = PlotProps.Color.Maps.Linear; % reduce noise in plot

chART.save_figure('PeriodicPeaks', ResultsFolder, PlotProps)



%% Example REM sleep
    
load(fullfile(SourceEEG, [ExampleParticipant, '_Sleep_Baseline.mat']), 'EEG')

TimeRange = [14680 14690]; % pretty good!
Channels10_20 = labels2indexes([125 32, Parameters.Channels.Standard_10_20], EEG.chanlocs);
TimeRange = round(TimeRange*EEG.srate);
Snippet = EEG.data(Channels10_20, TimeRange(1):TimeRange(2)); % TODO: select 10:20 system
Snippet = [Snippet(1, :)-Snippet(2, :); nan(2, size(Snippet, 2)); Snippet(3:end, :)];



PlotProps.Figure.Padding = 5;
YGap = 20;
figure('Units','centimeters', 'Position',[0 0 30 15])
chART.sub_plot([], [1 1], [1, 1], [], true, '', PlotProps);

EEGSnippet = EEG;
EEGSnippet.data = Snippet;
EEGSnippet.chanlocs = [EEG.chanlocs(8), EEG.chanlocs(Channels10_20)];

EEGSnippet = eeg_checkset(EEGSnippet);
EEGSnippet = pop_eegfiltnew(EEGSnippet, .5);
plot_eeg(EEGSnippet.data, EEG.srate, YGap, PlotProps)

FrequencyRange = Bands.Iota;
plot_burst_mask(EEGSnippet, FrequencyRange, YGap, PlotProps)

chART.save_figure([ExampleParticipant, '_REM_Example'], ResultsFolder, PlotProps)
