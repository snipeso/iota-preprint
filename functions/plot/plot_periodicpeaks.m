function Axes = plot_periodicpeaks(PeriodicPeaks, XLims, YLims, CLims, PlotProps)
% plots periodic peaks in a cute way. Includes a histogram on top of all
% the peaks


% main  scatterplot
scatter(PeriodicPeaks.Frequency, PeriodicPeaks.BandWidth, PeriodicPeaks.Power*100, PeriodicPeaks.Age, ...
    'filled', 'MarkerFaceAlpha', PlotProps.Scatter.Alpha)
chART.set_axis_properties(PlotProps)
xlabel('Frequency (Hz)')
ylabel('Bandwidth (Hz)')
ylim(YLims)
xlim(XLims)
axis square


% colorbar
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.Color.Steps.Rainbow = numel(5:1:22);
chART.plot.pretty_colorbar('Rainbow', CLims, 'Age', PlotProps)
clim(CLims)
Axes = gca;

% histogram on top
yyaxis right
Histogram = histogram(PeriodicPeaks.Frequency, XLims(1):1:XLims(2), 'FaceColor', [.5 .5 .5], 'EdgeColor','none');
ylim([0 max(max(Histogram.Values))*8])
set(gca, 'YTick', [], 'YColor', 'none', 'YDir', 'reverse')
