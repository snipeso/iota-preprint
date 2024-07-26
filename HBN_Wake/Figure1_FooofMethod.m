% this is just the basic code to plot the example data in Figure1 of the paper

clear
clc
close all

Parameters = prepParameters();
Paths = Parameters.Paths;
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Figure.Padding = 25;
Channels = Parameters.Channels;

ResultsFolder = fullfile(Paths.Results, 'FooofExample');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end


PlotProps.Text.AxisSize = 10;
PlotSize = [0 0 8 8];
LW_Plot = 1.5;
AperiodicGray = [.66 .66 .66];

load('E:\Final_Old\EEG\Specparam\NDARAE710YWG_RestingState.mat')

Freqs = Frequencies;
 PowerAverageSmooth = squeeze(mean(mean(SmoothPower(labels2indexes(Channels.NotEdge, Chanlocs), :, :), 1, 'omitnan'), 2, 'omitnan'))';

figure('Units','centimeters', 'Position', PlotSize)
chART.sub_plot([], [1 1], [1 1], [], true, '', PlotProps);
plot(Freqs, PowerAverageSmooth, 'Color', 'k', 'LineWidth',PlotProps.Line.Width)
chART.set_axis_properties(PlotProps)
xlabel('Frequency (Hz)')
ylabel('Power (\muV^2/Hz)')
xlim([1 40])
ylim([0 30])
axis square
box off
chART.save_figure('Power', ResultsFolder, PlotProps)

%% log log power
figure('Units','centimeters', 'Position', PlotSize)
chART.sub_plot([], [1 1], [1 1], [], true, '', PlotProps);
hold on
plot(log10(Freqs), log10(PowerAverageSmooth), 'Color', 'k', 'LineWidth',PlotProps.Line.Width)
    plot([0 1.59], [1.7 -1.25], 'Color', AperiodicGray, 'LineWidth',PlotProps.Line.Width*3, ...
    'LineStyle',':')
chART.set_axis_properties(PlotProps)
xlabel('Log frequency')
ylabel('Log power')
xlim(log10([1 40]))
ylim([-1.2 2])
axis square
box off
chART.save_figure('LogLogPower', ResultsFolder, PlotProps)

%% periodic power

WhitePowerAverageSmooth = squeeze(mean(mean(WhitenedPower(labels2indexes(Channels.NotEdge, Chanlocs), :, :), 1, 'omitnan'), 2, 'omitnan'))';

figure('Units','centimeters', 'Position', PlotSize)
chART.sub_plot([], [1 1], [1 1], [], true, '', PlotProps);
plot(FooofFrequencies, WhitePowerAverageSmooth, 'Color', 'k', 'LineWidth',PlotProps.Line.Width)
chART.set_axis_properties(PlotProps)
xlabel('Frequency (Hz)')
ylabel('Log power')
xlim([1 40])
ylim([-.1 1.2])
axis square
box off
chART.save_figure('WhitenedPower', ResultsFolder, PlotProps)