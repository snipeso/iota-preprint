function Axes = plot_periodicpeaks(PeriodicPeaks, XLims, YLims, CLims, plotColorbar, PlotProps)
% plots periodic peaks in a cute way. Includes a histogram on top of all
% the peaks


% main  scatterplot
scatter(PeriodicPeaks.Frequency, PeriodicPeaks.BandWidth,  PeriodicPeaks.Power*PlotProps.Scatter.Size, PeriodicPeaks.Age, ...
    'filled', 'MarkerFaceAlpha', PlotProps.Scatter.Alpha)

chART.set_axis_properties(PlotProps)
xlabel('Frequency (Hz)')
ylabel('Bandwidth (Hz)')
ylim(YLims)
xlim(XLims)
clim(CLims)


% colorbar
if plotColorbar
    PlotProps.Colorbar.Location = 'eastoutside';
    PlotProps.Color.Steps.Rainbow = numel(CLims(1):1:CLims(2));

    Axes = gca;
    Axes.Units = 'pixels';
    Axes.Position(3) = Axes.Position(3)+PlotProps.Axes.xPadding*2;
    chART.plot.pretty_colorbar('Rainbow', CLims, 'Age', PlotProps);
    Axes = gca;
else
    colormap(chART.utils.resize_colormap(PlotProps.Color.Maps.Rainbow, ...
        PlotProps.Color.Steps.Rainbow))
end

% histogram on top
yyaxis right

if XLims(2)>=100 % resolution of histogram
    Steps = 2;
else
    Steps = 1;
end
Histogram = histogram(PeriodicPeaks.Frequency, XLims(1):Steps:XLims(2), 'FaceColor', 'none', 'EdgeColor','k');

ylim([0 max(max(Histogram.Values))*8])
set(gca, 'YTick', [], 'YColor', 'none', 'YDir', 'reverse')


yyaxis left