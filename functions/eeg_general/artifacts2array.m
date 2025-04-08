function KeepPoints = artifacts2array(Artefacts, EEG, EpochLength)

KeepPoints = ones(1, size(EEG.data, 2));

[Starts, Ends] = data2windows(all(Artefacts==1, 1));

Starts = Starts*EpochLength*EEG.srate;
Ends = Ends*EpochLength*EEG.srate;

for StartIdx = 1:numel(Starts)
    KeepPoints(Starts(StartIdx):Ends(StartIdx)) = 0;
end