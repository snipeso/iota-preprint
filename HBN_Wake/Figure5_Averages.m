clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = HBNParameters();
Paths = Parameters.Paths;
CacheDir = Paths.Cache;

%%% paths
ResultsFolder = fullfile(Paths.Results, 'AllPeaks');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end

CacheName = 'PeriodicParameters_Clean.mat';
load(fullfile(CacheDir, CacheName),  'AllSpectra',  'Frequencies', 'Metadata')
