function Axes = plot_periodicpeaks(PeriodicPeaks, XLims, YLims, CLims, plotColorbar, PlotProps)
% plots periodic peaks in a cute way. Includes a histogram on top of all
% the peaks


% main  scatterplot
scatter(PeriodicPeaks.Frequency, PeriodicPeaks.BandWidth,  5*PeriodicPeaks.Power*PlotProps.Scatter.Size, PeriodicPeaks.Age, ...
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
