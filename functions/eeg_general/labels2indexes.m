function Indexes = labels2indexes(Labels, Chanlocs)
% Indexes = labels2indexes(Labels, Chanlocs)
%
% function for converting from labels to indexes.
%
% From iota-preprocessing by Sophia Snipes, 2024


Labels = string(Labels);

% handles exception of Cz, which for some stupid reason I saved as Cz.
Labels(strcmp(Labels, '129')) = 'CZ';

ChanLabels = string({Chanlocs.labels});

[Members, Indexes] = ismember(Labels, ChanLabels);

Members = Members(:)';
Labels = Labels';

Indexes(Indexes == 0) = [];

if any(not(Members))
    warning(strjoin([ 'Chan ', Labels(not(Members))', ' not present in the chanlocs']))
end


