function Neighbors = find_neighbors(Chanlocs)
% Neighbors = find_neighbors(Chanlocs)
% finds all the channels that are 2 times the median minimum distance of
% each channel to the other.
%
% From iota-neurophys, by Snipes, 2024

M = channel_distances([Chanlocs.X], [Chanlocs.Y], [Chanlocs.Z]);
M(1:numel(Chanlocs)+1:numel(M)) = nan; % set diagonal to nan;
Neighbors = M <= median(min(M))*2;
end


function M = channel_distances(X, Y, Z)
% distances between electrodes

M = nan(numel(X));

for Indx_Ch1 = 1:numel(X)
    for Indx_Ch2 = 1:numel(X)
        M(Indx_Ch1, Indx_Ch2) = sqrt((X(Indx_Ch2)-X(Indx_Ch1))^2 +...
            (Y(Indx_Ch2)-Y(Indx_Ch1))^2 + (Z(Indx_Ch2)-Z(Indx_Ch1))^2);
    end
end
end
