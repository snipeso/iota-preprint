% plots and analyses to exclude that iota is just noise.
%
% From iota-preprint, Snipes, 2024.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = HBNParameters();
Paths = Parameters.Paths;
CacheDir = Paths.Cache;

%%% paths
ResultsFolder = fullfile(Paths.Results, 'AllPeaks');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% plot


PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Figure.Padding = 10;

CLims = [5 21];
XLim = [3 50];
YLims = [.3 12.3];
Grid = [2, 3];
LabelSpace = .5;

% load in analyses on unfiltered data
CacheName = 'PeriodicParameters_Unfiltered.mat';
load(fullfile(CacheDir, CacheName), 'NoisePeriodicPeaks', 'PeriodicPeaks')

CacheName = 'PeriodicParameters_Clean.mat';
load(fullfile(CacheDir, CacheName), 'Metadata',  'AllSpectra')
Blanks = any(isnan(AllSpectra), 2);
Metadata(Blanks, :) = [];


UnfilteredPeriodicPeaks = PeriodicPeaks;

UnfilteredPeriodicPeaks = sortrows(UnfilteredPeriodicPeaks, 'Age', 'ascend'); % sort by age so that the rarer adults are on top
NoisePeriodicPeaks = sortrows(NoisePeriodicPeaks, 'Age', 'ascend'); % sort by age so that the rarer adults are on top


figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width PlotProps.Figure.Width/1.75])

%%% A: iota vs alpha
chART.sub_plot([], Grid, [1, 1], [], true, 'A', PlotProps);
hold on
plot([8 13], [8 13]*3, ':', 'Color', [.6 .6 .6], 'LineWidth', 2, 'DisplayName',  ['Expected', newline, 'harmonic fit'])
Scatter = scatter(Metadata.AlphaFrequency, Metadata.IotaFrequency, 20, Metadata.Age, 'filled', 'MarkerFaceAlpha', .2);

% correlation lines
Lines = lsline;
Lines(1).Visible = 'off';
Lines(1).HandleVisibility = 'off';
Lines(2).Color = [0 0 0];
Lines(2).DisplayName = 'Linear fit';
Lines(2).LineWidth = 2;
Scatter.HandleVisibility = 'off';
legend
set(legend, 'location', 'southeast', 'ItemTokenSize', [10 10])

chART.set_axis_properties(PlotProps)
xlabel('Alpha center frequency (Hz)')
ylabel('Iota center frequency (Hz)')
xlim([8 13])
ylim([25 35])
clim(CLims)
title('Alpha vs. iota')


%%% B: Peaks in unprocessed data
PlotProps.Scatter.Alpha = .07;
chART.sub_plot([], Grid, [1, 2], [], true, 'B', PlotProps);
plot_periodicpeaks(UnfilteredPeriodicPeaks, XLim, YLims, CLims, false, PlotProps);
title('Periodic peaks, unprocessed',  'FontSize', PlotProps.Text.TitleSize)


%%% C: Peaks in high frequencies
NoiseIdx = NoisePeriodicPeaks.Frequency >58 & NoisePeriodicPeaks.Frequency<62;

PlotProps.Scatter.Alpha = .3;
chART.sub_plot([], Grid, [1, 3], [], true, 'C', PlotProps);
ylim([0.3 12.5])
% plot line noise
LineNoise = NoisePeriodicPeaks(NoiseIdx, :);


% plot all else
Gamma = NoisePeriodicPeaks(~NoiseIdx, :);
plot_periodicpeaks(Gamma, [18 100], YLims, CLims, false, PlotProps);

hold on
scatter(LineNoise.Frequency, LineNoise.BandWidth, 10, [.1 .1 .1], 'filled', ...
    'MarkerFaceAlpha', .1, 'Marker', 'o')
title('Gamma, unprocessed',  'FontSize', PlotProps.Text.TitleSize)


%%% D: plot individual examples

MiniGrid = [2 4];
PlotPropsTemp = PlotProps;
PlotPropsTemp.Figure.Padding = 0;
PlotPropsTemp.yPadding = 0;
PlotPropsTemp.xPadding = 0;

ExampleParticipants = {'NDARHF854JX7', 'NDARMH180XE5', 'NDARJR579FW7', 'NDARXN719LXU'};


chART.sub_plot([], Grid, [2, 1], [], true, 'D', PlotProps);
axis off % just a black spot for the D letter

% Space = chART.sub_figure(Grid, [2 1], [1 3], '', PlotPropsTemp, [], 1);
PlotProps.Axes.xPadding = 2;
PlotProps.Axes.yPadding = 20;
for ParticipantIdx = 1:numel(ExampleParticipants)

    % load in data
    Participant = ExampleParticipants{ParticipantIdx};
    Info = Metadata(find(strcmp(Metadata.EID, Participant), 1, 'first'), :);

    load(fullfile(Paths.Datasets,'EEG\', Participant, 'EEG', 'raw', 'mat_format', 'RestingState.mat'), 'EEG')

    % computer power
    [RawPower, Frequencies] = oscip.compute_power(EEG.data, EEG.srate, 8, .9);

    % plot
    Axes = chART.sub_plot([], MiniGrid, [2, ParticipantIdx], [], true, '', PlotProps);
    Axes.Position(2) = Axes.Position(2)-.03;

    plot(Frequencies, log10(RawPower), 'Color',  [.5 .5 .5 .1])

    chART.set_axis_properties(PlotProps)
    box off
    set(gca, 'XScale', 'log');
    xticks([0 1 10 30 60 120])
    title([string(Participant); [' (\iota=', num2str(round(Info.IotaFrequency, 1)),  ' Hz; \alpha=',num2str(round(Info.AlphaFrequency, 1)) ' Hz)']], ...
        'FontWeight','normal', 'FontSize',PlotProps.Text.AxisSize)
    axis tight
    ylim(quantile(log10(RawPower(:)), [.02, .999]))
    xlabel('Frequency (Hz)')
    if ParticipantIdx ==1
        ylabel('Log power')
    end
    xlim([1 250])
end

chART.save_figure('Unprocessed', ResultsFolder, PlotProps)


%% iota and alpha correlation
clc

nTot = size(Metadata, 1);
nAlpha = nnz(~isnan(Metadata.AlphaFrequency));
disp(['#alpha: ', num2str(nAlpha), ' (', num2str(round(100*nAlpha/nTot)), '%)'])

nTot = size(Metadata, 1);
nIota = nnz(~isnan(Metadata.IotaFrequency));
disp(['#iota: ', num2str(nIota), ' (', num2str(round(100*nIota/nTot)), '%)'])

nTot = size(Metadata, 1);
nBoth = nnz(~isnan(Metadata.IotaFrequency) & ~isnan(Metadata.AlphaFrequency));
disp(['#iota & alpha: ', num2str(nBoth), ' (', num2str(round(100*nBoth/nTot)), '%)'])


disp('_____________')


[Rho, p] = corr(Metadata.AlphaFrequency, Metadata.IotaFrequency, 'rows', 'complete');
disp(['Alpha x iota: r=', num2str(round(Rho, 2)), ', p=', num2str(round(p, 3))])

[Rho, p] = corr(Metadata.AlphaFrequency, Metadata.Age, 'rows', 'complete');
disp(['Alpha x age: r=', num2str(round(Rho, 2)), ', p=', num2str(round(p, 3))])


disp('_____________')


