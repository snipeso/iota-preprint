% Calculates power and specparam properties on epochs of the EEG data.
% Requires EEG and cutting information from manually selected artefact
% epochs/channels.
% from iota-preprint, Snipes, 2024.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = LSMParameters();
Paths = P.Paths;
Task = P.Task;
Format = 'Minimal';
Session = P.Session;
Channels = P.Channels;

% power of epochs
WelchWindowLength = 4;
WelchWindowOverlap = .5;

% fooof
SmoothSpan = 2; % Hz
FittingFrequencyRange = [3 45];
MaxError = .1;
MinRSquared = .98;

% plotting
ScatterSizeScaling = 10;
Alpha = .05;

Refresh = false;
NotEdge = Channels.NotEdge;

% locations
SourceScoring =  fullfile(Paths.Core, 'Outliers', Task);
SourcePath = fullfile(Paths.Preprocessed, Format, 'MAT', Task);
Files = list_filenames(SourcePath);
Files(~contains(Files, Session)) = []; % to save time, only do basleine nights

Destination = fullfile(Paths.Final, 'EEG', 'Power',  '20sEpochs', Task, Format);

if ~exist(Destination, 'dir')
    mkdir(Destination)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run

for FileIdx = 1:numel(Files)

    %%% load in data
   

    %%% calculate specparams

    % calculate power
    [Power, Frequencies] = oscip.compute_power_on_epochs(Data, ...
        SampleRate, scoringlen, WelchWindowLength, WelchWindowOverlap);

    SmoothPower = oscip.smooth_spectrum(Power, Frequencies, SmoothSpan); % better for fooof if the spectra are smooth


    % adjust scoring size (can be off by one)
    Scoring = resize_scoring(visnum, size(Power, 2));


    % run FOOOF
    [Slopes, Intercepts, FooofFrequencies, PeriodicPeaks, PeriodicPower, Errors, RSquared] ...
        = oscip.fit_fooof_multidimentional(SmoothPower, Frequencies, FittingFrequencyRange, MaxError, MinRSquared);


    save(fullfile(Destination, File), 'Power', 'Frequencies', 'Scoring',  'Artefacts', 'Time', 'Chanlocs', ...
        'SmoothPower', 'PeriodicPower', 'FooofFrequencies', 'PeriodicPeaks', ...
        'Intercepts', 'Slopes', 'Errors', 'RSquared')


    oscip.plot.frequency_overview(PeriodicPower, FooofFrequencies, PeriodicPeaks, ...
        Scoring, -3:1:1, {'N3', 'N2', 'N1', 'W', 'R'}, ScatterSizeScaling, Alpha, false, false)
    set(gcf, 'InvertHardcopy', 'off', 'Color', 'W')
    chART.save_figure(replace(File, '.mat', 'png'), Destination)

    close all
    disp(['Finished ', File])
end


function Scoring = resize_scoring(ScoringOriginal, nEpochs)

% adjust size
Scoring = nan([1, nEpochs]);
if numel(Scoring)<numel(ScoringOriginal)
    Scoring = ScoringOriginal(1:nEpochs);
else
    Scoring(1:numel(ScoringOriginal)) = ScoringOriginal;
end
end

