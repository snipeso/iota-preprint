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
Format = 'Minimal'; % chooses which filtering to do
SourceSpecparam = fullfile(Paths.Final, 'EEG', 'Power',  '20sEpochs', Task, Format);
SourceEEG = fullfile(Paths.Preprocessed, Format, 'Clean', Task);
Channels = Parameters.Channels.NotEdge;

ExampleParticipant = 'P09';

load(fullfile(SourceSpecparam, [ExampleParticipant, '_Sleep_Baseline.mat']), ...
    'PeriodicPeaks', 'Scoring', 'Chanlocs')

load(fullfile(SourceEEG, [ExampleParticipant, '_Sleep_Baseline.mat']), 'EEG')


PeriodicPeaksREM = PeriodicPeaks(labels2indexes(Channels, Chanlocs), Scoring==1, :);

%%
[isPeak, MaxPeak] = oscip.check_peak_in_band(PeriodicPeaksREM, Bands.Iota, 1);
BandRange = MaxPeak(1) + [-2 2];

%%

% select only REM sleep
[Starts, Ends] = data2windows(Scoring==1);
REMWindows = [Starts', Ends']*20;
EEGSnippet = pop_select(EEG, 'time', REMWindows);

% filter to remove drifts
EEGSnippet = eeg_checkset(EEGSnippet);
EEGSnippet = pop_eegfiltnew(EEGSnippet, .5);
EEGSnippet = pop_eegfiltnew(EEGSnippet, [], 45);

%%
Bursts = burst_detection(EEGSnippet, BandRange, CriteriaSet);

CacheDir = Paths.Cache;
CacheName = [ExampleParticipant, '_Bursts.mat'];

save(fullfile(CacheDir, CacheName), 'Bursts', 'EEGSnippet', 'BurstClusters')


%%

load(fullfile(CacheDir, CacheName), 'Bursts', 'EEGSnippet', 'BurstClusters')


%%  


BurstClusters = cycy.aggregate_bursts_into_clusters(Bursts, EEGSnippet, 1);

%%
Density = nan(1, numel(Chanlocs));
REMDuration = size(EEGSnippet.data, 2)/EEG.srate/60;

for ChIdx = 1:numel(Chanlocs)
    Density(ChIdx) = nnz([Bursts.ChannelIndex]==ChIdx)/REMDuration;
end

%%
PlotProps.Colorbar.Location = 'eastoutside';
figure
chART.plot.eeglab_topoplot(Density, Chanlocs, [], [0 50], 'bursts/min', 'Linear', PlotProps)

