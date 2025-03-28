function plot_eeg(Data, SampleRate, YGap, PlotProps)
% plot_eeg(Data, SampleRate, YGap, PlotProps)
%
% Plots eeg traces.
%
% From iota-neurophys, Snipes, 2024.

Dims = size(Data);
t = linspace(0, Dims(2)/SampleRate, Dims(2));

% get vertical spacing
Y = YGap*Dims(1):-YGap:0;
Y(end) = [];

hold on

%%% plot EEG
Color = PlotProps.Color.Generic;

Data = Data+Y';

plot(t, Data,  'Color', Color, 'LineWidth', PlotProps.Line.Width/3, 'HandleVisibility','off')
chART.set_axis_properties(PlotProps)

set(gca, 'YTick', [], 'YColor', 'none', 'FontName', PlotProps.Text.FontName, 'FontSize', PlotProps.Text.AxisSize)
axis tight
xlabel('Time (s)')
