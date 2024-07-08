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

% fooof
FooofFrequencyRange = [3 50]; % frequencies over which to fit the model
SmoothSpan = 2;
MaxError = .1;
MinRSquared = .98;

% plot parameters
ScatterSizeScaling = 100;
Alpha = .05;


% locations
Source = fullfile(Paths.Preprocessed, 'Power', 'Clean', Task);

Destination = fullfile(Paths.Final, 'EEG', 'Specparam');
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

    % run FOOOF
    [Slopes, Intercepts, FooofFrequencies, PeriodicPeaks, PeriodicPower, Errors, RSquared] ...
        = oscip.fit_fooof_multidimentional(SmoothPower, Frequencies, FooofFrequencyRange, MaxError, MinRSquared);

    % plot summary
    if numel(size(Power)) ==3
        Scores = zeros(1, size(Power, 2));
    elseif numel(size(Power)) ==2
        Scores = 0;
    end
    close
    oscip.plot.frequency_overview(PeriodicPower, FooofFrequencies, PeriodicPeaks, ...
        Scores, 0, "W", ScatterSizeScaling, Alpha, false, false)

    set(gcf, 'InvertHardcopy', 'off', 'Color', 'W')
    print(fullfile(Destination, extractBefore(File, '.mat')), '-dtiff', '-r1000')


    save(fullfile(Destination, Files{FileIdx}), 'Power', 'Frequencies', ...
        'SmoothPower', 'Slopes', 'Intercepts', 'FooofFrequencies', ...
        'PeriodicPeaks', 'PeriodicPower', 'Errors', 'RSquared', 'Chanlocs')
    disp(['Finished ', Files{FileIdx}])

end