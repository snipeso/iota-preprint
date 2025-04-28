% this script is just to run the burst detection on one participant as a
% proof of concept.

% from iota-neurophys, Snipes. 2024.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = LSMParameters();
Paths = Parameters.Paths;
CriteriaSet = Parameters.CriteriaSet;
PlotProps = Parameters.PlotProps.Manuscript;

Task = Parameters.Task;
Bands = Parameters.Bands;
Format = Parameters.Format; % chooses which filtering to do
SourceSpecparam = fullfile(Paths.Final, 'EEG', 'Power',  '20sEpochs', Task, Format);
SourceEEG = fullfile(Paths.Preprocessed, Format, 'Clean', Task);
Channels = Parameters.Channels.NotEdge;

ExampleParticipant = 'P09';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run


%%% load in data
load(fullfile(SourceSpecparam, [ExampleParticipant, '_Sleep_Baseline.mat']), ...
    'PeriodicPeaks', 'Scoring', 'Chanlocs', 'Artefacts')

load(fullfile(SourceEEG, [ExampleParticipant, '_Sleep_Baseline.mat']), 'EEG')

PeriodicPeaksREM = PeriodicPeaks(labels2indexes(Channels, Chanlocs), Scoring==1, :);

%%

% find iota peak frequency
[isPeak, MaxPeak] = oscip.check_peak_in_band(PeriodicPeaksREM, Bands.Iota, 1);
BandRange = MaxPeak(1) + [-2 2];

% select only 3rd bours of REM sleep
REMBout = 3;
[Starts, Ends] = data2windows(Scoring==1);
REMWindows = [Starts', Ends']*20;
REMWindows = REMWindows(REMBout, :);
EEGSnippet = pop_select(EEG, 'time', REMWindows);

KeepPoints = artifacts2array(Artefacts(1:end-1, Starts(REMBout):Ends(REMBout)), EEGSnippet, 20);

% filter to remove drifts
EEGSnippet = eeg_checkset(EEGSnippet);
EEGSnippet = pop_eegfiltnew(EEGSnippet, .5);
EEGSnippet = pop_eegfiltnew(EEGSnippet, [], 45);

% detect bursts
Bursts = burst_detection(EEGSnippet, BandRange, CriteriaSet, KeepPoints);
Bursts = cycy.average_cycles(Bursts, {'Amplitude'});
BurstClusters = cycy.aggregate_bursts_into_clusters(Bursts, EEGSnippet, 1);
CacheDir = Paths.Cache;
CacheName = [ExampleParticipant, '_BurstsOneREM.mat'];

save(fullfile(CacheDir, CacheName), 'Bursts', 'EEGSnippet', 'BurstClusters', 'BandRange')
