function plot_periodicpeaks(PeriodicPeaks, CLims, PlotProps)
% plots periodic peaks in a cute way. Includes a histogram on top of all
% the peaks


scatter(PeriodicPeaks.Frequency, PeriodicPeaks.BandWidth, PeriodicPeaks.Power*100, PeriodicPeaks.Age, 'filled', 'MarkerFaceAlpha', .1)
chART.set_axis_properties(PlotProps)
xlabel('Frequency (Hz)')
ylabel('Bandwidth (Hz)')
% ylim([.5 12.5])
ylim([.5 12.1])
xlim([3 50])
axis square
Bar = colorbar;
Axes = gca;
colorbar off
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.Color.Steps.Rainbow = numel(5:1:22);
chART.plot.pretty_colorbar('Rainbow', CLims, 'Age', PlotProps)
% ylabel(Bar, 'Age', 'FontName', PlotProps.Text.FontName, ...
%     'FontSize', PlotProps.Text.AxisSize,'Color', 'k')
% colormap(PlotProps.Color.Maps.Rainbow)
clim(CLims)

yyaxis right
Histogram = histogram(PeriodicPeaks.Frequency, 3:1:50, 'FaceColor', [.8 .8 .8], 'EdgeColor','none');
ylim([0 8000])
set(gca, 'YTick', [], 'YColor', 'black', 'YDir', 'reverse')
