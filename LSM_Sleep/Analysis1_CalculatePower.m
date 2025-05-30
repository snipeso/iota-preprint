% Calculates power and specparam properties on epochs of the EEG data.
% Requires EEG and cutting information from manually selected artefact
% epochs/channels.
% from iota-neurophys, Snipes, 2024.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = LSMParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Format = Parameters.Format;
Session = Parameters.Session;
Channels = Parameters.Channels;

% power of epochs
WelchWindowLength = Parameters.Power.WelchWindowLength;
WelchWindowOverlap = Parameters.Power.WelchWindowOverlap;
EpochLength = Parameters.EpochLength;

% fooof
SmoothSpan = Parameters.FOOOF.SmoothSpan; % Hz
FittingFrequencyRange = Parameters.FOOOF.FittingFrequencyRange;
MaxError = Parameters.FOOOF.MaxError;
MinRSquared = Parameters.FOOOF.MinRSquared;

% plotting
ScatterSizeScaling = 10;
Alpha = .05;

Refresh = false;

% locations
SourcePath = fullfile(Paths.Preprocessed, Format, 'Clean', Task);
Files = list_filenames(SourcePath);
Files(~contains(Files, Session)) = []; % to save time, only do basleine nights

Destination = fullfile(Paths.Final, 'EEG', 'Power',  '20sEpochs', Task, Format);

if ~exist(Destination, 'dir')
    mkdir(Destination)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run

for FileIdx = 1:numel(Files)

    File = Files{FileIdx};
    if ~Refresh && exist(fullfile(Destination, File), 'file')
        disp(['Already did ', char(File)])
        continue
    end

    %%% load in data

    load(fullfile(SourcePath, File), 'EEG', 'BadSegments', 'Scoring', 'ScoringLabels', 'ScoringIndexes', 'Artefacts')

    Data =EEG.data;
    Chanlocs = EEG.chanlocs;
    SampleRate = EEG.srate;

    %%% calculate specparams

    % calculate power
    [Power, Frequencies] = oscip.compute_power_on_epochs(Data, ...
        SampleRate, EpochLength, WelchWindowLength, WelchWindowOverlap);

    % adjust scoring size (can be off by one)
    nEpochs = size(Power, 2);
    Scoring = resize_epochs(Scoring, nEpochs);
    Time = linspace(0, (nEpochs-1)*EpochLength, nEpochs);
    Artefacts = resize_epochs(Artefacts, nEpochs);


    % set to nan bad power
    for ChannelIdx = 1:size(Artefacts, 1)
        Power(ChannelIdx, Artefacts(ChannelIdx, :)==1, :) = nan;
    end

    % smoothing spectrum identifies fewer spurious peaks, and makes fooof
    % run faster
    SmoothPower = oscip.smooth_spectrum(Power, Frequencies, SmoothSpan); % better for fooof if the spectra are smooth


    % run FOOOF
    [Slopes, Intercepts, FooofFrequencies, PeriodicPeaks, PeriodicPower, Errors, RSquared] ...
        = oscip.fit_fooof_multidimentional(SmoothPower, Frequencies, FittingFrequencyRange, MaxError, MinRSquared);


    save(fullfile(Destination, File), 'Power', 'Frequencies', 'Scoring',  'BadSegments',  'Artefacts', 'Time', 'Chanlocs', ...
        'SmoothPower', 'PeriodicPower', 'FooofFrequencies', 'PeriodicPeaks', ...
        'Intercepts', 'Slopes', 'Errors', 'RSquared', 'ScoringLabels', 'ScoringIndexes')


    % plot to check all is ok
    oscip.plot.frequency_overview(PeriodicPower, FooofFrequencies, PeriodicPeaks, ...
        Scoring, ScoringIndexes, ScoringLabels, ScatterSizeScaling, Alpha, false, false)
    set(gcf, 'InvertHardcopy', 'off', 'Color', 'W')
    chART.save_figure(replace(File, '.mat', '.png'), Destination)

    close all
    clear EEG Power SmoothPower PeriodicPeaks PeriodicPower
    disp(['Finished ', File])
end


function Resized = resize_epochs(Original, nEpochs)

% adjust size
Resized = nan([size(Original, 1), nEpochs]);
if size(Resized, 2)<size(Original, 2)
    Resized = Original(:, 1:nEpochs);
else
    Resized(:, 1:size(Original, 2)) = Original;
end
end

