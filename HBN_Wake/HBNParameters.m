function Parameters = HBNParameters()
% Here is located all the common variables, paths, and parameters that get
% repeatedly called by more than one script.
%
% From iota-neurophys by Sophia Snipes, 2024

Parameters.Tasks = {'RestingState'}; % the dataset has other tasks, so I left the option open to do more than one
Parameters.LineNoise = 60; % Hz

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Locations

Paths = struct(); % I make structs of variables so they don't flood the workspace

% get path where these scripts were saved
Paths.Analysis = mfilename('fullpath');
Paths.Analysis = extractBefore(Paths.Analysis, 'HBN_Wake');

Core ='G:\'; % insert here the folder where your data is saved
Paths.Core = Core;

if ~exist(Core, "dir")
    error('Missing external hard disk')
end

Paths.Datasets = fullfile(Core, 'Raw'); % make sure you save all the EEG data in a folder that is {Core}/Raw/EEG
Paths.Preprocessed = fullfile(Core, 'Preprocessed');
Paths.Final = fullfile(Core, 'Final'); % where data from each file gets saved once its been turned into something else
Paths.Metadata = fullfile(Core, 'Metadata');
Paths.Cache = fullfile(Core, 'Cache', 'iota-neurophys'); % for data from all participants merged into a single matrix or so
Paths.Results = fullfile(Core, 'Results', 'iota-neurophys');

if ~exist(Paths.Cache, 'dir')
    mkdir(Paths.Cache)
end

Parameters.Paths = Paths;

% add location of subfunctions
addpath(fullfile(Paths.Analysis, 'functions', 'general')) % needed for "list_filenames"
Subfunctions = list_filenames(fullfile(Paths.Analysis, 'functions'));

for Indx_F = 1:numel(Subfunctions)
    addpath(fullfile(Paths.Analysis, 'functions', Subfunctions{Indx_F}))
end

% if eeglab has not run, run it so all the subdirectories get added
if ~exist('topoplot', 'file')
    eeglab
    close all
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Analysis variables

%%% EEG channels
EEG_Channels = struct();
EEG_Channels.notEEG = [49, 56, 107, 113, 126, 127];
EEG_Channels.Edge = [1 8 14 17 21 25 32 128 38 44 43 48 63 68 73 81 88 94 99 120 119 114 121 125];
EEG_Channels.NotEdge = 1:128;
EEG_Channels.NotEdge(EEG_Channels.Edge) = [];
EEG_Channels.TopoPlot = 1:128; % intentionally doesn't include 129, Cz
EEG_Channels.TopoPlot([EEG_Channels.notEEG, 48 119]) = []; % remove the two little tippy channels because they make topographies look more central than they are

EEG_Channels.Standard_10_20 = [11 22 9 24 124 33 122 129 36 104 45 108 62 52 92 58 96 75 70 83];

Parameters.Channels = EEG_Channels;

%%% spectral bands (only used in biorxiv preprint, not final paper)

Bands = struct();
Bands.Theta = [4 7];
Bands.Alpha = [8 13];
Bands.LowBeta = [14 17];
Bands.HighBeta = [18 25];
Bands.Iota = [25 35];
Bands.Gamma = [35 48];
Parameters.Bands = Bands;

%%% Filtering & downsampling

% Power: starting data for properly cleaned wake data
PreprocessingParameters.Power.fs = 250; % new sampling rate for running code faster
PreprocessingParameters.Power.lp = 50; % low pass filter as antialiasing for the downsampling
PreprocessingParameters.Power.hp = 0.5; % high pass filter for later visualization
PreprocessingParameters.Power.hp_stopband = 0.25; % high pass filter gradual roll-off

% Unfiltered (control analyses, not in paper but in preprint)
PreprocessingParameters.Unfiltered.fs = 500; % new sampling rate
PreprocessingParameters.Unfiltered.lp = []; % low pass filter
PreprocessingParameters.Unfiltered.hp = []; % high pass filter
PreprocessingParameters.Unfiltered.hp_stopband = []; % high pass filter gradual roll-off
Parameters.LineNoise = [];

% ICA: heavily filtered data for getting ICA components
PreprocessingParameters.ICA.fs = 500; % new sampling rate
PreprocessingParameters.ICA.lp = 100; % low pass filter
PreprocessingParameters.ICA.hp = 2.5; % high pass filter
PreprocessingParameters.ICA.hp_stopband = 1.5; % high pass filter gradual roll-off

Parameters.Parameters = PreprocessingParameters;


%%% Thresholds
Parameters.MinTime = 60; % minimum file duration in seconds required after preprocessing
Parameters.MinChannels = 25; % minimum number of channels that can be removed after preprocessing (eventually comes out to 97 clean channel minimum; this code is awful)


%%% Plotting parameters
Parameters.PlotProps.Manuscript = chART.load_plot_properties({ 'Manuscript', 'Iota'});


%%% cycle-by-cycle parameters
CriteriaSet = struct();

CriteriaSet.MonotonicityInAmplitude = 0.9;
CriteriaSet.AmplitudeConsistency = .3; % left and right cycles should be of similar amplitude
CriteriaSet.isTruePeak = 1;
CriteriaSet.isProminent = 1;
CriteriaSet.MinCyclesPerBurst = 4;
CriteriaSet.ShapeConsistency = .4;
CriteriaSet.FlankConsistency = .4;

Parameters.CriteriaSet = CriteriaSet;