
PlotProps = Parameters.PlotProps.Manuscript;
% PlotProps.Debug = true;
LabelSpace = 1;
Grid = [2 4];
figure('Units','centimeters', 'Position', [0 0 30 15])
IndxL = 1;

for Indx = 1:Grid(1)
    for Indx2 = 1:Grid(2)
        chART.sub_plot([], Grid, [Indx, Indx2], [], LabelSpace, PlotProps.Indexes.Letters{IndxL}, PlotProps);
        scatter(Metadata.AlphaFrequency, Metadata.IotaFrequency, 50, Metadata.Age, 'filled', 'MarkerFaceAlpha', .2)
        chART.set_axis_properties(PlotProps)
        hold on
        plot([8 13], [8 13]*3, 'Color', [.4 .4 .4], 'LineWidth', 2)
        xlabel('Alpha peak frequency (Hz)')
        ylabel('Iota')
        xlim([8 13])
        ylim([25 35])
        clim(CLims)
        IndxL= IndxL+1;
    end
end