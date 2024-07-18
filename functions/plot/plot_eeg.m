function plot_eeg(Data, SampleRate, YGap, PlotProps)


Dims = size(Data);
t = linspace(0, Dims(2)/SampleRate, Dims(2));


Y = YGap*Dims(1):-YGap:0;
Y(end) = [];

hold on

%%% plot EEG
% Color = [.3 .3 .3];
Color = PlotProps.Color.Generic;

Data = Data+Y';

plot(t, Data,  'Color', Color, 'LineWidth', PlotProps.Line.Width/3, 'HandleVisibility','off')
set(gca, 'YTick', [], 'YColor', 'none', 'FontName', PlotProps.Text.FontName, 'FontSize', PlotProps.Text.AxisSize)
axis tight
xlabel('Time (s)')