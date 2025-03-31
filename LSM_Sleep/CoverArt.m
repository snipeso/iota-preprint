
clear
clc
close all

Parameters = LSMParameters();
Paths = Parameters.Paths;
CriteriaSet = Parameters.CriteriaSet;

Channels = Parameters.Channels.NotEdge;
Task = Parameters.Task;
Format = 'Minimal'; % chooses which filtering to do
FreqLims = [3 45];

% folders
SourceSpecparam = fullfile(Paths.Final, 'EEG', 'Power',  '20sEpochs', Task, Format);


Participants = Parameters.Participants;

CustomPeakSettings = oscip.default_settings();
CustomPeakSettings.PeakBandwidthMin = 1;
CustomPeakSettings.PeakBandwidthMax = 12;

ScoringIndexes= flip(-3:1);
ScoringLabels = flip({'N3', 'N2', 'N1', 'W', 'R'});


AllDistributions = nan(numel(Participants), numel(ScoringIndexes),421);

for ParticipantIdx = 1:numel(Participants)

    % load data
    Participant = Participants{ParticipantIdx};
    load(fullfile(SourceSpecparam, [Participant, '_Sleep_Baseline.mat']), 'PeriodicPeaks','FooofFrequencies', 'Scoring', 'Chanlocs');

    for StageIdx = 1:numel(ScoringIndexes)
        [Distribution, Frequencies] = oscip.utils.peaks_distribution(PeriodicPeaks(:, Scoring==ScoringIndexes(StageIdx), :), FreqLims, CustomPeakSettings);

        AllDistributions(ParticipantIdx, StageIdx, :) = Distribution;
    end
end


%%


PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.yPadding = 5;
PlotProps.Axes.xPadding = 5;
PlotProps.Figure.Padding = 5;
PlotProps.Text.AxisSize = 15;
PlotProps.Text.FontName = 'Noto Sans';
PlotProps.Patch.Alpha = .35;

Baseline = zeros(numel(Participants), numel(Frequencies));

Colors = flip(chART.external.colorcet('L17'));

Colors = Colors(round(linspace(1, 256, numel(Participants))), :);
ParticipantOrder = [1, 6, 10, 8, 11, 13, 14, 16, 12,  7, 19, 2, 3, 4, 15, 9, 17, 5, 18];

figure('Units','centimeters','Position',[0 0 21, 29.7])
chART.sub_plot([], [1 1], [1, 1], [], false, '', PlotProps);
chART.plot.increases_from_baseline(Baseline, squeeze(AllDistributions(ParticipantOrder, 1, :)),  Frequencies, 'pos', false, PlotProps, Colors);

xlim([21 37.5])
ylim([0 .27])
% xlim([15 40])
% ylim([0 .27])
% xlim([4 38])
% ylim([0 .3])


% Access current axis
ax = gca;

% Set axis and tick color to white
ax.XColor = 'none';
ax.YColor = 'none';
ax.Color = [0 21 80]/256;

chART.save_figure('Cover', Paths.Results, PlotProps)


