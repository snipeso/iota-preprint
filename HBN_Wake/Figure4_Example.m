% plot example participant to show burstiness of iota.
%
% From iota-preprint, Snipes, 2024.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = HBNParameters();
Paths = Parameters.Paths;
PlotProps = Parameters.PlotProps.Manuscript;

% paths
CacheDir = Paths.Cache;
CacheName = 'PeriodicParameters.mat';

ResultsFolder = fullfile(Paths.Results, 'WakeExamples');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end

SourceEEG = fullfile(Paths.Preprocessed, 'Power', 'Clean', 'RestingState');
SourcePower = fullfile(Paths.Core, 'Final_Old', 'EEG','Specparam/');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run

load(fullfile(CacheDir, CacheName), 'Metadata')

Participant = 'NDARMH180XE5'; TimeRange = [39 49]; % the bestest
% Participant = 'NDARUL694GYN'; TimeRange = [150 160];
% Participant = 'NDARDR804MFE'; TimeRange = [10 20];
% Participant = 'NDARTZ926NMZ';TimeRange = [54 64];
% Participant = 'NDARKL327YDQ'; TimeRange = [39 49]; % Works with same time interval
% Participant = 'NDARKL327YDQ'; TimeRange = [39 49]; % 16 year old
% Participant = 'NDARYH110YV9'; TimeRange = [39 49]; % 16 year old
% Participant= 'NDARTF566PYH'; TimeRange = [39 49]; % good time
% Participant= 'NDARAJ674WJT'; TimeRange = [39 49];
% Participant = 'NDARDR804MFE';TimeRange = [39 49];

% load preprocessed EEG
File = [Participant, '_RestingState.mat'];
load(fullfile(Paths.Preprocessed, 'Power\Clean\RestingState\', File), 'EEG')

% load fooof data
load(fullfile( Paths.Final, 'EEG', 'Power', '20sEpochs', 'Clean', File), 'Power', 'Frequencies', 'Chanlocs', 'PeriodicPeaks')

Info = Metadata(find(strcmp(Metadata.EID, Participant), 1, 'first'), :);

switch Info.Sex
    case 0
        Sex = 'male';
    case 1
        Sex = 'female';
end

%%% plot
Title = [num2str(round(Info.Age, 1)), ' year old ' Sex, ' (', Participant, ')'];
plot_example(EEG, Power, Frequencies, Chanlocs, Parameters.Channels.Standard_10_20,...
    PeriodicPeaks, TimeRange, Title, Parameters.PlotProps.Manuscript)
chART.save_figure(['Example_', Participant], ResultsFolder, PlotProps)
