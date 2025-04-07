function [Axes, Axes2] = colorscale_grid(CenterFrequency, nParticipants, Bands, yLabels, StageMinutes, PlotProps)

nParticipants = cat(2, zeros(size(nParticipants, 1), 1), nParticipants); % add empty row for minutes
[nRows, nCols] = size(nParticipants);

% === Plot Heatmap ===
imagesc(nParticipants)
chART.set_axis_properties(PlotProps)

Colors = chART.utils.custom_gradient([1 1 1], PlotProps.Color.Maps.Linear(1, :));

colormap(Colors)
clim([0, max(abs(nParticipants(:)))] * 2)

% === Axis Setup ===
xticks(1:nCols)
xticklabels([])  % Hide default x-tick labels
yticks(1:nRows)
yticklabels(yLabels)

ax = gca;
ax.TickLength = [0 0];
ax.XAxisLocation = 'top';
ax.FontWeight = 'bold';
ax.TickLabelInterpreter = 'tex';
ax.FontSize = PlotProps.Text.TitleSize;

% === Position X-Axis Labels Above the Plot ===

% Get y-axis limits to position labels just above top
ylims = [.1 nRows+.5];
ylim(ylims)
% Label placement control

labelY = .1;  % anchor baseline
lineSpacing = 0.4;  % vertical spacing between label lines

BandNames = fieldnames(Bands);
BandNames = ['Duration'; BandNames];

for i = 1:nCols
    BandName = BandNames{i};

    if i==1
        rangeStr = '(min)';
    else
        BandRange = Bands.(BandName);
        rangeStr = sprintf('(%d–%d Hz)', round(BandRange(1)), round(BandRange(2)));
    end

    % Top line: band name
    text(i, labelY, BandName, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontWeight', 'bold', ...
        'FontSize', PlotProps.Text.TitleSize, ...
        'Interpreter', 'none', ...
        'Clipping', 'on');

    % Second line: range, just below
    text(i, labelY + lineSpacing, rangeStr, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontWeight', 'bold', ...
        'FontSize', PlotProps.Text.TitleSize, ...
        'Interpreter', 'none', ...
        'Clipping', 'on');
end

% === Overlay Center Text in Each Cell ===
for row = 1:nRows
    for col = 1:nCols
        if col==1
            Text = [num2str(round(mean(StageMinutes(:, row), 1, 'omitnan'))), ' ± ', num2str(round(std(StageMinutes(:, row), 0, 1, 'omitnan'))), ...
                ' (' , num2str(nnz(~isnan(StageMinutes(:, row)))), ')'];
        else
            value = nParticipants(row, col);

            if value == 0
                Text = '(0)';
            else
                Text = sprintf('%g Hz (%d)', CenterFrequency(row, col-1), value);
            end
        end

        text(col, row, Text, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'Color', 'k', ...
            'FontSize', PlotProps.Text.AxisSize);

    end
end
box off                    % Removes top and right borders

Axes=gca;

set(gcf, 'color', 'w')

Axes2 = axes('Position', Axes.Position, ...
    'Color', 'none', ...
    'XColor', [1 1 1], ...
    'YColor', [1 1 1], ...
    'XTick', [], ...
    'YTick', [], ...
    'XAxisLocation', 'top', ...
    'YAxisLocation', 'left');  % Optional if needed
end

