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
    'PeriodicPeaks', 'Scoring', 'Chanlocs', 'Artefacts')

load(fullfile(SourceEEG, [ExampleParticipant, '_Sleep_Baseline.mat']), 'EEG')


PeriodicPeaksREM = PeriodicPeaks(labels2indexes(Channels, Chanlocs), Scoring==1, :);

%%
[isPeak, MaxPeak] = oscip.check_peak_in_band(PeriodicPeaksREM, Bands.Iota, 1);
BandRange = MaxPeak(1) + [-2 2];

%%

% select only REM sleep
[Starts, Ends] = data2windows(Scoring==1 & ~all(Artefacts));
REMWindows = [Starts', Ends']*20;
REMWindows = REMWindows(4, :);
EEGSnippet = pop_select(EEG, 'time', REMWindows);

% filter to remove drifts
EEGSnippet = eeg_checkset(EEGSnippet);
EEGSnippet = pop_eegfiltnew(EEGSnippet, .5);
EEGSnippet = pop_eegfiltnew(EEGSnippet, [], 45);

%%
Bursts = burst_detection(EEGSnippet, BandRange, CriteriaSet);
Bursts = cycy.average_cycles(Bursts, {'Amplitude'});
BurstClusters = cycy.aggregate_bursts_into_clusters(Bursts, EEGSnippet, 1);
CacheDir = Paths.Cache;
CacheName = [ExampleParticipant, '_BurstsOneREM.mat'];

save(fullfile(CacheDir, CacheName), 'Bursts', 'EEGSnippet', 'BurstClusters')


%%

load(fullfile(CacheDir, CacheName), 'Bursts', 'EEGSnippet', 'BurstClusters')


%%  



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


cycy.plot.plot_all_bursts(EEGSnippet, 20, Bursts, 'Band');

%%
EOG2 =  EEGSnippet.data(32, :)-EEGSnippet.data(125, :);

rms_per_channel = sqrt(EOG2.^2);
t = linspace(0, size(EEGSnippet.data, 2)/EEGSnippet.srate, size(EEGSnippet.data, 2));

figure('Units','centimeters','Position',[0 0 25 8])

scatter([Bursts.Start]/EEG.srate/60, [Bursts.ChannelIndex], [Bursts.MeanAmplitude]*5, 'filled', 'MarkerFaceAlpha', .1, 'MarkerFaceColor', PlotProps.Color.Maps.Linear(128, :))
hold on
plot(t/60, mat2gray(smooth(rms_per_channel, 1000))*129, 'LineWidth', 2, 'color', [0 0 0])
axis tight
