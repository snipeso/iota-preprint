% This script plots all the sleep related figures that were kicked out of
% the main paper.
% iota-neurophys, Snipes 2024

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = LSMParameters();
Paths = Parameters.Paths;
CriteriaSet = Parameters.CriteriaSet;

Channels = Parameters.Channels.NotEdge;
Task = Parameters.Task;
Format = 'Minimal'; % chooses which filtering to do
FreqLims = [3 45];

ExampleParticipant = 'P09';

% folders
SourceSpecparam = fullfile(Paths.Final, 'EEG', 'Power',  '20sEpochs', Task, Format);
SourceEEG = fullfile(Paths.Preprocessed, Format, 'Clean', Task);

ResultsFolder = fullfile(Paths.Results);
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end

CacheDir = Paths.Cache;
CacheName = ['PeriodicParameters_', Task, '_', Format, '.mat'];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plot

%% Table 1: peaks detected in sleep

load(fullfile(CacheDir, CacheName), 'CenterFrequencies', 'Bands', 'StageLabels')
BandLabels = fieldnames(Bands);
nStages = numel(StageLabels);
nBands = numel(BandLabels);


AllCenterFrequencies = table();
for BandIdx = 1:nBands
    AllCenterFrequencies.Band{BandIdx} = [num2str(Bands.(BandLabels{BandIdx})(1)), '-', num2str(Bands.(BandLabels{BandIdx})(2)), ' Hz'];
    for StageIdx = 1:nStages
        AllCenterFrequencies.(StageLabels{StageIdx})(BandIdx) = nnz(~isnan(CenterFrequencies(:, StageIdx, BandIdx)));
    end
end

AllCenterFrequencies = AllCenterFrequencies(:, [1 5 6 4 3 2]);
disp(AllCenterFrequencies)
writetable(AllCenterFrequencies, fullfile(ResultsFolder, 'DetectedPeaksByStage.csv'))