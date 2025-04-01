function add_peak_text(Peak, Color, PlotProps)

if ~isnan(Peak)
    text(Peak(1), 5, num2str(round(Peak(1), 1)), 'FontSize', PlotProps.Text.LegendSize, ...
        'FontName', PlotProps.Text.FontName, 'Color', Color, ...
        'HorizontalAlignment', 'center');
end