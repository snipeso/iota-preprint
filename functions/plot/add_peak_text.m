function add_peak_text(PeriodicPeaks, Band, Color, PlotProps)

[isPeak, MaxPeak] = oscip.check_peak_in_band(PeriodicPeaks, Band, 1);

if isPeak
    text(MaxPeak(1), 4, num2str(round(MaxPeak(1))), 'FontSize', PlotProps.Text.LegendSize, ...
        'FontName', PlotProps.Text.FontName, 'Color', Color, ...
        'HorizontalAlignment', 'center');
end