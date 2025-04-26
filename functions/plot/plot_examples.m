function plot_examples(EEG, Power, Topographies, IotaFrequencies, Participants, Freqs, Chanlocs, Channels, PeriodicPeaks, TimeRange, CriteriaSet, Title, PlotProps)
%  plot_example(EEG, Power, Freqs, Chanlocs, Channels, PeriodicPeaks, TimeRange, Title, PlotProps)
%
% Script to plot a lot of different things from the same recording
%
% from iota-neurophys, Snipes, 2024.

%%% detect iota peak and determine custom range
PeakDetectionSettings = oscip.default_settings();
PeakDetectionSettings.PeakBandwidthMax = 4; % broader peaks are not oscillations
PeakDetectionSettings.PeakBandwidthMin = .5; % Hz; narrow peaks are more often than not noise
PeakDetectionSettings.PeakAmplitudeMin = .5;

[~, MaxIotaPeak] = oscip.check_peak_in_band(PeriodicPeaks, [25 35], 1, PeakDetectionSettings);

IotaRange = [MaxIotaPeak(1)-MaxIotaPeak(3)/2, MaxIotaPeak(1)+MaxIotaPeak(3)/2];
% PlotProps.Figure.Padding= 30;
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.External.EEGLAB.TopoRes = 300;

WindowLength = 2;
MovingWindowSampleRate = .2;
nTopos = size(Topographies, 1);
Grid = [4, nTopos];

% find best iota channel
[~, MaxCh] = max(Power(:, dsearchn(Freqs', MaxIotaPeak(1))));

Data = EEG.data(MaxCh, :);
SampleRate = EEG.srate;

% run multitaper
[Spectrum, Frequencies, Time] = cycy.utils.multitaper(Data, SampleRate, WindowLength, MovingWindowSampleRate);

Time = Time/60;

figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width PlotProps.Figure.Width*1.1])


%%% A: example topographies
% plot individuals
PlotProps.Axes.xPadding = 5;
PlotProps.Axes.yPadding = 10;
for IndexC = 1:nTopos
    Data = Topographies(IndexC, :);
    if IndexC==1
        chART.sub_plot([], Grid, [1, IndexC], [], 2, 'A', PlotProps);
        axis off
    end
    chART.sub_plot([], Grid, [1, IndexC], [], false, '', PlotProps);
    chART.plot.eeglab_topoplot(Data, Chanlocs, [], quantile(Data, [.01, 1]), '', 'Linear', PlotProps)
    chART.plot.topo_corner_text([num2str(round(IotaFrequencies(IndexC))), 'Hz'], PlotProps)
    title(Participants(IndexC), 'FontSize', PlotProps.Text.AxisSize)
end



%%% A: time frequency
chART.sub_plot([], Grid, [2, 1], [1, nTopos], true, 'B', PlotProps);
LData = squeeze(log10(Spectrum));
CLim = quantile(LData(:)', [.6 .999]);

cycy.plot.time_frequency(LData, Frequencies, Time(end), 'contourf', [1 50], CLim, 100)
PlotA = gca;

chART.set_axis_properties(PlotProps)
colormap(PlotProps.Color.Maps.Linear)
set(gca, 'TickLength', [.005 0])
xlabel('Time (min)')
xlim([3 247]/60)
title(Title)

colorbar off
box off

%%% B: EEG
Channels = labels2indexes(Channels, EEG.chanlocs);
TimeRangeEEG = round(TimeRange*EEG.srate);
Snippet = EEG.data(Channels, TimeRangeEEG(1):TimeRangeEEG(2)); % TODO: select 10:20 system

Axes=chART.sub_plot([], Grid, [4, 1], [2, nTopos], true, 'C', PlotProps);
YGap = 40;

hold on
PlotProps.Line.Width = 1.5;
plot_eeg(Snippet, SampleRate, YGap, PlotProps)

% plot highlight sections where there's a lot more iota
EEGSnippet = EEG;
EEGSnippet.data = Snippet;
plot_burst_mask(EEGSnippet, IotaRange, CriteriaSet, YGap, PlotProps)
set(gca, 'TickLength', [.005 0])
Axes.Position(2) = Axes.Position(2)+.01;

