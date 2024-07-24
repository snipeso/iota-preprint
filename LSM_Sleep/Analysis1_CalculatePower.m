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
SourceEEG =  fullfile(Paths.Preprocessed, Format, 'MAT');
SourceScoring =  fullfile(Paths.Core, 'Outliers', Task);
Path = fullfile(SourceEEG, Task);
Files = list_filenames(Path);
Files(~contains(Files, Session)) = []; % to save time, only do basleine nights

Destination = fullfile(Paths.Final, 'EEG', 'Power',  '20sEpochs', Task, Format);

if ~exist(Destination, 'dir')
    mkdir(Destination)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run

for FileIdx = 1:numel(Files)

    % check if file already exists
    File = Files{FileIdx};
    if ~Refresh && exist(fullfile(Destination, File), 'file')
        disp(['Already did ', char(File)])
        continue
    end

    % load in file
    load(fullfile(Path, File), 'EEG')
    SampleRate = EEG.srate;
    Data = EEG.data;
    Chanlocs = EEG.chanlocs;

    % load in scoring
    Filename_Cuts = replace(File, '.mat', '_Cutting_artndxn.mat');

    load(fullfile(SourceScoring, Filename_Cuts), 'artndxn', 'visnum', 'scoringlen')
    Artefacts = artndxn;

    % calculate power
    [Power, Frequencies] = oscip.compute_power_on_epochs(Data, ...
        SampleRate, scoringlen, WelchWindowLength, WelchWindowOverlap);

    SmoothPower = oscip.smooth_spectrum(Power, Frequencies, SmoothSpan); % better for fooof if the spectra are smooth

    
    % adjust scoring size (can be off by one)
    Scoring = reorder_scoring(visnum, size(Power, 2));


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


function Scoring = reorder_scoring(ScoringOriginal, nEpochs)

% adjust size
Scoring = nan([1, nEpochs]);
if numel(Scoring)<numel(ScoringOriginal)
    Scoring = ScoringOriginal(1:nEpochs);
else
    Scoring(1:numel(ScoringOriginal)) = ScoringOriginal;
end

% reorder wake and REM, whichwas saved as 1 and 0, but should be
% switched
Scoring(Scoring==0) = 2;
Scoring(Scoring==1) = 0;
Scoring(Scoring==2) = 1;
end