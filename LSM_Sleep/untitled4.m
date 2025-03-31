
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

    % Frequencies = FooofFrequencies;
    % Distribution = squeeze(mean(mean(PeriodicPower(labels2indexes(Channels, Chanlocs), Scoring==ScoringIndexes(StageIdx), :), 1, 'omitnan'), 2, 'omitnan'));
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
PlotProps.Patch.Alpha = .75; 

Baseline = zeros(numel(Participants), numel(Frequencies));


figure('Units','centimeters','Position',[0 0 21, 29.7])
  chART.sub_plot([], [1 1], [1, 1], [], false, '', PlotProps);
  chART.plot.increases_from_baseline(Baseline, squeeze(AllDistributions(:, 1, :)),  Frequencies, 'pos', false, PlotProps, PlotProps.Color.Participants);

xlim([16 38])
ylim([0 .27])



% Access current axis
ax = gca;

% Set axis and tick color to white
ax.XColor = 'none';
ax.YColor = 'none';
ax.Color = 'k'
% % Ticks pointing inward
% ax.XAxis.TickDirection = 'in';
% 
% % Bring axis line and ticks to front
% ax.Layer = 'top';
% 
% % Move tick labels above the ticks using negative gap multiplier
% ax.XRuler.TickLabelGapMultiplier = -2;  % Adjust for fine control
%%

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.yPadding = 5;
PlotProps.Axes.xPadding = 5;
PlotProps.Figure.Padding = 5;
PlotProps.Patch.Alpha = .5; 
Grid = [1, numel(ScoringIndexes)];


figure('Units','centimeters','Position',[0 0 30 7])
for StageIdx = 1:numel(ScoringIndexes)

    chART.sub_plot([], Grid, [1, StageIdx], [], true, '', PlotProps);
chART.plot.increases_from_baseline(Baseline, squeeze(AllDistributions(:, StageIdx, :)),  Frequencies, 'pos', false, PlotProps, PlotProps.Color.Participants);
title(ScoringLabels{StageIdx})
xlim([16 40])
ylim([0 .5])
end



