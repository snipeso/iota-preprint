
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
PlotProps.Patch.Alpha = .5;

Baseline = zeros(numel(Participants), numel(Frequencies));

Colors = flip(chART.external.colorcet('L17'));


% targetRGB = [229 238 247] / 255;  % Normalize to [0,1]
% nColors = 256;
% Colors = flip([linspace(0, targetRGB(1), nColors)', ...
%         linspace(0, targetRGB(2), nColors)', ...
%         linspace(0, targetRGB(3), nColors)']);


% Define RGB keypoints and normalize
color1 = [88 146 204] / 255;    % start (medium blue)
color2 = [229 238 247] / 255;   % midpoint (light)
color3 = [0 0 0];               % end (black)

% Number of steps in each segment
n = 256;
n1 = round(n/2);  % from color1 to color2
n2 = n - n1;      % from color2 to color3

% Interpolate each segment
segment1 = [linspace(color1(1), color2(1), n1)', ...
            linspace(color1(2), color2(2), n1)', ...
            linspace(color1(3), color2(3), n1)'];

segment2 = [linspace(color2(1), color3(1), n2)', ...
            linspace(color2(2), color3(2), n2)', ...
            linspace(color2(3), color3(3), n2)'];

% Combine full colormap
% Colors = [segment1; segment2];
% Colors = Colors(round(linspace(1, 256, numel(Participants))), :);
% ParticipantOrder = [9 18 4 7 2 19 3 15 13 14 17 5 11 16 1 6,  12, 8, 10];
ParticipantOrder = 1:19;

% Colormap = chART.external.colorcet('L9');
Colormap = PlotProps.Color.Maps.Linear;
Colors = Colormap(round(linspace(1, 250, 19)), :);


% figure('Units','centimeters','Position',[0 0 21, 29.7])
figure('Units','normalized','OuterPosition',[0 0 1 1])
chART.sub_plot([], [1 1], [1, 1], [], false, '', PlotProps);

targetRGB = [24, 55, 85] / 255;  % Normalize to [0,1]
nColors = 256;
cmap = [linspace(0, targetRGB(1), nColors)', ...
        linspace(0, targetRGB(2), nColors)', ...
        linspace(0, targetRGB(3), nColors)'];

gradientImage = repmat(linspace(0, 1, nColors)', 1, nColors);

% XLim = [20 37.5];
XLim = [4 38];
YLim = [0 .5];
% YLim = [0 .27];

% imagesc(XLim, YLim, gradientImage);
% colormap(cmap);
axis off;
axis xy;  % So it goes top-down

% colormap(flip(cmap));

chART.plot.increases_from_baseline(Baseline, squeeze(AllDistributions(ParticipantOrder, 1, :)),  Frequencies, 'pos', false, PlotProps, Colors);

xlim(XLim)
ylim(YLim)
% xlim([15 40])
% ylim([0 .27])
% xlim([4 38])
% ylim([0 .3])


% Access current axis
ax = gca;

% Set axis and tick color to white
ax.XColor = 'none';
ax.YColor = 'none';
% ax.Color = [0 21 80]/256;
ax.Color = 'none';

set(gca, 'Color', 'k')
set(gcf, 'Color', 'k')

PlotProps.Color.Background = 'k';
chART.save_figure('Cover', Paths.Results, PlotProps)


