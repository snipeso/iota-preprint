
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
CustomPeakSettings.PeakBandwidthMin = 0.5;
CustomPeakSettings.PeakBandwidthMax = 12;

ScoringIndexes= flip(-3:1);
ScoringLabels = flip({'N3', 'N2', 'N1', 'W', 'R'});


AllDistributions = nan(numel(Participants), numel(ScoringIndexes), 421);

for ParticipantIdx = 1:numel(Participants)

    % load data
    Participant = Participants{ParticipantIdx};
    load(fullfile(SourceSpecparam, [Participant, '_Sleep_Baseline.mat']), 'PeriodicPeaks', 'Scoring');

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
Grid = [1, numel(ScoringIndexes)];

Baseline = zeros(numel(Participants), numel(Frequencies));

figure('Units','centimeters','Position',[0 0 30 7])
for StageIdx = 1:numel(ScoringIndexes)

    chART.sub_plot([], Grid, [1, StageIdx], [], true, '', PlotProps);
chART.plot.increases_from_baseline(Baseline, squeeze(AllDistributions(:, StageIdx, :)),  Frequencies, 'pos', false, PlotProps, PlotProps.Color.Participants);
title(ScoringLabels{StageIdx})
xlim([3 40])
ylim([0 .7])
end



