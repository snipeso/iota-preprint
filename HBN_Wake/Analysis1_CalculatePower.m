% calculate power over 20 s epochs for every channel

clear
close all
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% setup

P = HBNParameters();
Paths = P.Paths;
Task = P.Tasks{1};
Refresh = false;

% power
EpochLength = 20;
WelchWindowLength = 4; % in seconds
WelchOverlap = .5; % 50% of the welch windows will overlap
SmoothSpan = 2;

FooofFrequencyRange = [3 50];
MaxError = .1;
MinRSquared = .98;


% locations
DestinationName = 'Clean';
Source = fullfile(Paths.Preprocessed, 'Power', 'Clean', Task);

DestinationName = 'NotchFiltered';
Source = fullfile(Paths.Preprocessed, 'Power', 'NotchFiltered', Task);

% DestinationName = 'Unfiltered';
% Source = fullfile(Paths.Preprocessed, 'Unfiltered', 'MAT', Task);


Destination = fullfile(Paths.Final, 'EEG', 'Power', '20sEpochs', DestinationName);
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


    [Slopes, Intercepts, FooofFrequencies, PeriodicPeaks, PeriodicPower, Errors, RSquared] = ...
        oscip.fit_fooof_multidimentional(SmoothPower, Frequencies, FooofFrequencyRange, MaxError, MinRSquared);

    save(fullfile(Destination, Files{FileIdx}), 'Power', 'Frequencies', ...
        'SmoothPower', 'Slopes', 'Intercepts', 'FooofFrequencies', ...
        'PeriodicPeaks', 'PeriodicPower', 'Errors', 'RSquared', 'Chanlocs')

    disp(['Finished ', num2str(FileIdx), '/', num2str(numel(Files))])
end