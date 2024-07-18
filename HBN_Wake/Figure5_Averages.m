clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = HBNParameters();
Paths = Parameters.Paths;
CacheDir = Paths.Cache;

%%% paths
ResultsFolder = fullfile(Paths.Results, 'Topographies');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end

CacheName = 'PeriodicParameters_Clean.mat';
load(fullfile(CacheDir, CacheName),  'AllSpectra', 'Frequencies', ...
    'AllPeriodicSpectra', 'FooofFrequencies', 'Metadata', 'LogTopographies', ...
    'PeriodicTopographies', 'CustomTopographies', 'Chanlocs', 'Bands')


%%
% close all

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.External.EEGLAB.TopoRes = 100;

Grid = [2 5];

Red = PlotProps.Color.Maps.Linear(128, :);
figure('Units','centimeters', 'Position', [0 0 32 13])


% plot log power average
chART.sub_plot([], Grid, [1, 1], [], 1, 'A', PlotProps);
plot(Frequencies, AllSpectra, 'Color', [.4 .4 .4 .01])
hold on
chART.set_axis_properties(PlotProps)
plot(Frequencies, mean(AllSpectra, 'omitnan'), 'Color', Red, 'LineWidth', 2)
xlim([3 50])
xticks([1 10 20 30 40])
xlabel('Frequency (Hz)')
ylabel('Power')
box off
title('Spectral power')
set(gca, 'YScale', 'log', 'XScale', 'log');


% log topo
Axes= chART.sub_plot([], Grid, [1, 2], [], 0, '', PlotProps);
Axes.Position(1) = Axes.Position(1)-.03;
chART.plot.eeglab_topoplot(squeeze(mean(LogTopographies(:, end, :), 1, 'omitnan')), Chanlocs, [], [-1.4, -.97], ...
    'log power', 'Linear', PlotProps)
topo_corner_text(['N=', num2str(nnz(~isnan(LogTopographies(:, end, 1))))], PlotProps)
title('25-35 Hz', 'FontWeight','normal', 'FontSize', PlotProps.Text.AxisSize)


% plot periodic power average
chART.sub_plot([], Grid, [1, 3], [], 1, 'B', PlotProps);
plot(FooofFrequencies, AllPeriodicSpectra, 'Color', [.4 .4 .4 .01])
hold on
chART.set_axis_properties(PlotProps)
plot(FooofFrequencies, mean(AllPeriodicSpectra, 'omitnan'), 'Color', Red, 'LineWidth', 2)
xlim([3 50])
xticks([1 10 20 30 40])
ylim([-.15 1.75])
xlabel('Frequency (Hz)')
ylabel('Log power')
box off
title('Periodic power')

% periodic topo
Axes= chART.sub_plot([], Grid, [1, 4], [], 0, '', PlotProps);
Axes.Position(1) = Axes.Position(1)-.03;
chART.plot.eeglab_topoplot(squeeze(mean(PeriodicTopographies(:, end, :), 1, 'omitnan')), Chanlocs, [], [.06 .1], ...
    'log power', 'Linear', PlotProps)
topo_corner_text(['N=', num2str(nnz(~isnan(PeriodicTopographies(:, end, 1))))], PlotProps)
title('25-35 Hz', 'FontWeight','normal', 'FontSize', PlotProps.Text.AxisSize)


% plot custom peak
chART.sub_plot([], Grid, [1, 5], [], -1, 'C', PlotProps); % little hack to put C in the right spot
chART.sub_plot([], Grid, [1, 5], [], false, '', PlotProps);

% Axes.Position(1) = Axes.Position(1)+.03;
chART.plot.eeglab_topoplot(squeeze(mean(CustomTopographies(:, end, :), 1, 'omitnan')), Chanlocs, [], [.15 .4], ...
    'log power', 'Linear', PlotProps)
topo_corner_text(['N=', num2str(nnz(~isnan(CustomTopographies(:, end, 1))))], PlotProps)
title('Custom iota', 'FontSize', PlotProps.Text.TitleSize)


% plot all bands periodic topographies
chART.sub_plot([], Grid, [2, 1], [], 1, 'D', PlotProps); % little hack to put C in the right spot


BandLabels = fieldnames(Bands);
for BandIdx = 1:numel(BandLabels)-1
    Band = Bands.(BandLabels{BandIdx});
    chART.sub_plot([], Grid, [2, BandIdx], [], false, '', PlotProps);

    if BandIdx == numel(BandLabels)-1
        Label = 'log power';
    else
        Label = ' ';
    end
    chART.plot.eeglab_topoplot(squeeze(mean(CustomTopographies(:, BandIdx, :), 1, 'omitnan')), Chanlocs, [], [], Label, 'Linear', PlotProps)
    topo_corner_text(['N=', num2str(nnz(~isnan(CustomTopographies(:, BandIdx, 1))))], PlotProps)
    title([BandLabels{BandIdx}, ' (', num2str(Band(1)), '-', num2str(Band(2)), ' Hz)'])
end

chART.save_figure('Averages', ResultsFolder, PlotProps)

