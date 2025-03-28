function plot_example(EEG, Power, Freqs, Chanlocs, Channels, PeriodicPeaks, TimeRange, CriteriaSet, Title, PlotProps)
%  plot_example(EEG, Power, Freqs, Chanlocs, Channels, PeriodicPeaks, TimeRange, Title, PlotProps)
%
% Script to plot a lot of different things from the same recording
% 
% from iota-preprint, Snipes, 2024.

%%% detect iota peak and determine custom range
PeakDetectionSettings = oscip.default_settings();
PeakDetectionSettings.PeakBandwidthMax = 4; % broader peaks are not oscillations
PeakDetectionSettings.PeakBandwidthMin = .5; % Hz; narrow peaks are more often than not noise
PeakDetectionSettings.PeakAmplitudeMin = .5;

[~, MaxIotaPeak] = oscip.check_peak_in_band(PeriodicPeaks, [25 35], 1, PeakDetectionSettings);

IotaRange = [MaxIotaPeak(1)-MaxIotaPeak(3)/2, MaxIotaPeak(1)+MaxIotaPeak(3)/2];
% PlotProps.Figure.Padding= 30;
PlotProps.Colorbar.Location = 'eastoutside';

WindowLength = 2;
MovingWindowSampleRate = .2;
Grid = [4, 1];

% find best iota channel
[~, MaxCh] = max(Power(:, dsearchn(Freqs', MaxIotaPeak(1))));

Data = EEG.data(MaxCh, :);
SampleRate = EEG.srate;

% run multitaper
[Spectrum, Frequencies, Time] = cycy.utils.multitaper(Data, SampleRate, WindowLength, MovingWindowSampleRate);

Time = Time/60;

figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width PlotProps.Figure.Width*1.1])

%%% A: time frequency
chART.sub_plot([], Grid, [1, 1], [], true, 'A', PlotProps);
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
Colorbar = chART.plot.pretty_colorbar('Linear', CLim, 'Log power', PlotProps);


%%% B: EEG
Channels = labels2indexes(Channels, Chanlocs);
TimeRangeEEG = round(TimeRange*EEG.srate);
Snippet = EEG.data(Channels, TimeRangeEEG(1):TimeRangeEEG(2)); % TODO: select 10:20 system

Axes=chART.sub_plot([], Grid, [3, 1], [2, 1], true, 'B', PlotProps);
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


%%% C: power spectra
Blue = PlotProps.Color.Maps.Linear(1, :);
Grid = [4 4];
chART.sub_plot([], Grid, [4, 1], [1 2], true, 'C', PlotProps);
hold on

plot(Freqs, squeeze(mean(log10(Power), 2, 'omitnan')), 'Color', [.5 .5 .5 .1])
plot(Freqs, squeeze(mean(mean(log10(Power), 2, 'omitnan'), 1)), 'Color', Blue, 'LineWidth',3)

chART.set_axis_properties(PlotProps)
set(gca, 'TickLength', [.005 0])

xlim([3 50])
xticks([ 10 20 30 40 50])
xlabel('Frequency (Hz)')
ylabel('Log power')


%%% D: topographies

% detect alpha
[~, MaxAlphaPeak] = oscip.check_peak_in_band(PeriodicPeaks, [8 13], 1, PeakDetectionSettings);
AlphaRange = [MaxAlphaPeak(1)-MaxAlphaPeak(3)/2, MaxAlphaPeak(1)+MaxAlphaPeak(3)/2];
AlphaRangePoints = dsearchn(Freqs', AlphaRange');
AlphaPower = squeeze(mean(mean(log10(Power(:, :, AlphaRangePoints(1):AlphaRangePoints(2))), 2, 'omitnan'), 3, 'omitnan'));

CLim = quantile(AlphaPower, [0.01, 1]);


chART.sub_plot([], Grid, [4, 3], [1 1], true, 'D', PlotProps); axis off

% plot
chART.sub_plot([], Grid, [4, 3], [1 1], false, '', PlotProps);
chART.plot.eeglab_topoplot(AlphaPower, Chanlocs, [], CLim, 'Log power', 'Linear', PlotProps)
clim(CLim)
Range = round(AlphaRange);
title(['Alpha (', num2str(Range(1)), '-', num2str(Range(2)), ' Hz)'])

% detect iota
IotaRangePoints = dsearchn(Freqs', IotaRange');
IotaPower = squeeze(mean(mean(log10(Power(:, :, IotaRangePoints(1):IotaRangePoints(2))), 2, 'omitnan'), 3, 'omitnan'));

CLim = quantile(IotaPower, [0.01, 1]);

chART.sub_plot([], Grid, [4, 4], [1 1], false, '', PlotProps);
chART.plot.eeglab_topoplot(IotaPower, Chanlocs, [], CLim, '', 'Linear', PlotProps)
Topo = gca;
ColorbarTopo = chART.plot.pretty_colorbar('Linear', CLim, 'Log power', PlotProps);
clim(CLim)
Range = round(IotaRange);
title(['Iota (', num2str(Range(1)), '-' num2str(Range(2)), ' Hz)'])


% adjust A so that it aligns with D
Colorbar.Position([1 3]) = ColorbarTopo.Position([1 3]);
PlotA.Position(3) = Topo.Position(3)+Topo.Position(1)-PlotA.Position(1);