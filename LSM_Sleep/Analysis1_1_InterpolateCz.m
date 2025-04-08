% Calculates power and specparam properties on epochs of the EEG data.
% Requires EEG and cutting information from manually selected artefact
% epochs/channels.
% from iota-neurophys, Snipes, 2024.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = LSMParameters();
Paths = P.Paths;
Task = P.Task;
Format = 'Minimal';

Refresh = false;

% locations
Source = fullfile(Paths.Final, 'EEG', 'Power',  '20sEpochs', Task, Format);
Files = list_filenames(Source);
Files(~contains(Files, '.mat')) = [];

Destination = fullfile(Paths.Final, 'EEG', 'Power',  '20sEpochs', Task, [Format, '_noCz']);
if ~exist(Destination, 'dir')
    mkdir(Destination)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run

for FileIdx = 1:numel(Files)

    File = Files{FileIdx};

    %%% load in data

    if exist(fullfile(Destination, File), 'file') && ~Refresh
        disp(['Already did ', File])
        continue
    end

    load(fullfile(Source, File), 'Power', 'Frequencies', 'Scoring',  'BadSegments',  'Artefacts', 'Time', 'Chanlocs', ...
        'SmoothPower', 'PeriodicPower', 'FooofFrequencies', 'PeriodicPeaks', ...
        'Intercepts', 'Slopes', 'Errors', 'RSquared', 'ScoringLabels', 'ScoringIndexes')


    % add Cz to whole matrix
    Power(end, :, :) = [];
    SmoothPower(end, :, :) = [];
    PeriodicPower(end, :, :) = [];
    PeriodicPeaks(end, :, :) = [];
    Intercepts(end, :, :) = [];
    Slopes(end, :, :) = [];
    Errors(end, :, :) = [];
    RSquared(end, :, :) = [];
    Chanlocs(end) = [];

    save(fullfile(Destination, File), 'Power', 'Frequencies', 'Scoring',  'BadSegments',  'Artefacts', 'Time', 'Chanlocs', ...
        'SmoothPower', 'PeriodicPower', 'FooofFrequencies', 'PeriodicPeaks', ...
        'Intercepts', 'Slopes', 'Errors', 'RSquared', 'ScoringLabels', 'ScoringIndexes')
    disp(['Finished ', File])
end


