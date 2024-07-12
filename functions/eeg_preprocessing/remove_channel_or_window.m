function BadSegments = remove_channel_or_window(BadSegments, Threshold)
% BadSegments = remove_channel_or_window(BadSegments, Threshold)
%
% makes sure that the channel is either completely removed, or the window
% is. BadSegments is a Channel x Epoch matrix of 1s and 0s. Threshold is
% the proportion of bad segments that are acceptable before the channel or
% epoch is removed (from 0 to 1).
%
% From iota-preprint, Snipes, 2024.

BadSegments = double(BadSegments);
[nCh, nWin] = size(BadSegments);

while any(sum(BadSegments, 2, 'omitnan')/nWin>Threshold) || ...
        any(sum(BadSegments, 1, 'omitnan')/nCh>Threshold) % while there is still missing data to remove in either channels or segments

    % identify amount of missing data for each channel/segment
    PrcntCh = sum(BadSegments, 2, 'omitnan')/nWin;
    PrcntWin = sum(BadSegments, 1, 'omitnan')/nCh;

    % find out which is missing most data
    [MaxCh, IndxCh] = max(PrcntCh);
    [MaxWin, IndxWin] = max(PrcntWin);

    % remove either a channel or a window
    if MaxCh > MaxWin % if the worst channel has more bad data than the worst segment, remove that one
        BadSegments(IndxCh, :) = nan; % nan so that it doesn't interfere with the tally
    else
        BadSegments(:, IndxWin) = nan;
    end
end

BadSegments(isnan(BadSegments)) = 1;
BadSegments = logical(BadSegments);
end
