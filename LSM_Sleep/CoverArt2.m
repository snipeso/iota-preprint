PlotProps.Figure.Padding = 5;
 PlotProps.Text.AxisSize = 15;
 PlotProps.Text.FontName = 'Noto Sans';
 PlotProps.Patch.Alpha = .35;
 PlotProps.Patch.Alpha = .4;
 
 Baseline = zeros(numel(Participants), numel(Frequencies));
 
 Colors = flip(chART.external.colorcet('L17'));
 
 Colors = Colors(round(linspace(1, 256, numel(Participants))), :);
 ParticipantOrder = [1, 6, 10, 8, 11, 13, 14, 16, 12,  7, 19, 2, 3, 4, 15, 9, 17, 5, 18];
 
 figure('Units','centimeters','Position',[0 0 21, 29.7])
 chART.sub_plot([], [1 1], [1, 1], [], false, '', PlotProps);
 chART.plot.increases_from_baseline(Baseline, squeeze(AllDistributions(ParticipantOrder, 1, :)),  Frequencies, 'pos', false, PlotProps, Colors);
 
 xlim([9 37.5])
 ylim([0 .37])
 % xlim([15 40])
 % ylim([0 .27])
 % xlim([4 38])
 % ylim([0 .3])
 
 
 % Access current axis
 ax = gca;
 
 % Set axis and tick color to white
 ax.XColor = 'none';
 ax.YColor = 'none';
 ax.Color = [0 21 80]/256;
 
 chART.save_figure('Cover', Paths.Results, PlotProps)