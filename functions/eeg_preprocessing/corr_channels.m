function R = corr_channels(Data, Chanlocs, ChannelTypes)
% R = corr_channels(Data, Chanlocs, ChannelTypes)
%
% correlates neighboring channels; lets you determine when one channel is
% an outlier.
% Data is a Ch x t matrix
% ChannelTypes is a string:
%   - 'Neighbor': only neighboring channels.
%   - 'NotNeighbor': Only non-neighboring channels
%   otherwise all
%
% From iota-neurophys by Sophia Snipes, 2024


if numel(Chanlocs)==129
    warning('removing CZ')
    Chanlocs(end) = [];
end

R = corr(Data');
Neighbors = find_neighbors(Chanlocs);

switch ChannelTypes
    case 'Neighbor'
        R(~Neighbors) = nan;
    case 'NotNeighbor'
        R(Neighbors) = nan;
        R(1:size(R, 1)+1:numel(R)) = nan;
end