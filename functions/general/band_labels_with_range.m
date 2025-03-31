% function BandLabels = band_labels_with_range(Bands)
% 
% BandLabelsSimple = fieldnames(Bands);
% BandLabels = cell(numel(BandLabelsSimple), 1);  % Preallocate
% 
% for BandIdx = 1:numel(BandLabelsSimple)
%     BandName = BandLabelsSimple{BandIdx};
%     BandRange = Bands.(BandName);
%     BandLabelText = sprintf('%s\\newline(%.0f–%.0f Hz)', BandName, BandRange(1), BandRange(2));
%     BandLabels{BandIdx} = BandLabelText;
% end
% 
% end
function BandLabels = band_labels_with_range(Bands)

BandNames = fieldnames(Bands);
BandLabels = cell(numel(BandNames), 1);  % Preallocate

for BandIdx = 1:numel(BandNames)
    BandName = BandNames{BandIdx};
    BandRange = Bands.(BandName);

    if strcmp(BandName, 'Iota')
        a=1
    end

    % Format the frequency range line
    freqStr = sprintf('(%d–%d Hz)', round(BandRange(1)), round(BandRange(2)));

    % Calculate padding needed to center the name relative to the freq line
    nFreq = length(freqStr);
    nName = length(BandName);
    totalPad = max(nFreq - nName, 0);
    leftPad = floor(totalPad / 2);
    rightPad = ceil(totalPad / 2);

    % Add spaces for centering
    paddedName = [repmat(' ', 1, leftPad), BandName, repmat(' ', 1, rightPad)];

    % Combine with newline
    BandLabels{BandIdx} = sprintf('%s\\newline%s', paddedName, freqStr);
end

end
