function plot_distributions(x, y, windowSize)
% plotMovingIQR Plots a moving average with IQR shading for scatter data.
%
%   plotMovingIQR(x, y, windowSize)
%   Inputs:
%     x          - Vector of x-values
%     y          - Vector of y-values
%     windowSize - Size of the moving window (e.g., 50)
%
%   Example:
%     plotMovingIQR(x, y, 50)

    % Sort by x
    [xSorted, sortIdx] = sort(x);
    ySorted = y(sortIdx);

    % Initialize output vectors
    xSmooth = [];
    meanY = [];
    iqrLow = [];
    iqrHigh = [];

    % Moving window calculation
    for i = 1:length(xSorted) - windowSize + 1
        windowX = xSorted(i:i + windowSize - 1);
        windowY = ySorted(i:i + windowSize - 1);
        
        xSmooth(end + 1) = mean(windowX);
        meanY(end + 1) = mean(windowY);
        iqrLow(end + 1) = prctile(windowY, 25);
        iqrHigh(end + 1) = prctile(windowY, 75);
    end

    % Plotting
    figure; hold on;

    % IQR shaded region
    fill([xSmooth, fliplr(xSmooth)], ...
         [iqrLow, fliplr(iqrHigh)], ...
         [0.8 0.8 1], ... % light blue
         'EdgeColor', 'none', ...
         'FaceAlpha', 0.4);

    % Mean line
    plot(xSmooth, meanY, 'b', 'LineWidth', 2);

    % Original scatter data
    scatter(x, y, 15, 'filled', 'MarkerFaceColor', [0.8 0.3 0]);

    % Labels and formatting
    xlabel('X');
    ylabel('Y');
    title('Moving Mean with IQR Shading');
    box on;

end
