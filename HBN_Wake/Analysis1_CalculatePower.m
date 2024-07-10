% calculate power over 20 s epochs for every channel

clear
close all
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% setup

P = HBNParameters();
Paths = P.Paths;
Task = 'RestingState';
Refresh = false;

% power
EpochLength = 20;
WelchWindowLength = 4; % in seconds
WelchOverlap = .5; % 50% of the welch windows will overlap
SmoothSpan = 2;


% plot parameters
ScatterSizeScaling = 100;
Alpha = .05;


% locations
Source = fullfile(Paths.Preprocessed, 'Power', 'Clean', Task);

Destination = fullfile(Paths.Final, 'EEG', 'Power', '20sEpochs', Task);
if ~exist(Destination, 'dir')
    mkdir(Destination)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run

Files = oscip.list_filenames(Source);


for FileIdx = 1:numel(Files)

    File = Files{FileIdx};
    if ~Refresh && exist(fullfile(Destination, File), 'file')
        disp(['***********', 'Already did ', File, '***********'])
        continue
    end

    load(fullfile(Source, File), 'EEG')
    SampleRate = EEG.srate;
    Data = EEG.data;
    Chanlocs = EEG.chanlocs;

    % calculate power
    [Power, Frequencies] = oscip.compute_power_on_epochs(Data, ...
        SampleRate, EpochLength, WelchWindowLength, WelchOverlap);

    SmoothPower = oscip.smooth_spectrum(Power, Frequencies, SmoothSpan); % better for fooof if the spectra are smooth

    save(fullfile(Destination, Files{FileIdx}), 'Power', 'Frequencies', ...
        'SmoothPower', 'Chanlocs')
    disp(['Finished ', num2str(FileIdx), '/', num2str(numel(Files))])
end