function colorscale_grid(CenterFrequency, nParticipants, Bands, yLabels, PlotProps)


[nRows, nCols] = size(nParticipants);


imagesc(nParticipants)
chART.set_axis_properties(PlotProps)

colormap(flip(PlotProps.Color.Maps.Divergent))

clim([-max(abs(nParticipants(:))), max(abs(nParticipants(:)))]*2)

xticks(1:nCols)
xticklabels(xLabels)

yticks(1:nRows)
yticklabels(yLabels)

ax = gca;            % Get current axes
ax.TickLength = [0 0]; 
ax.XAxisLocation = 'top'; 
ax.FontWeight = 'bold';  

for row = 1:nRows
    for col = 1:nCols
        value = nParticipants(row, col);

        if value==0
            Text = '(0)';
        else
        Text = [num2str(CenterFrequency(row, col)), ' Hz (',num2str(value), ')'];
        end
        text(col, row, Text, ...   % Format to 2 decimals
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'Color', 'k', ...       % Change to 'w' if colormap is dark
            'FontSize', PlotProps.Text.AxisSize);
    end
end
