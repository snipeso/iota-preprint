% plot example participant to show burstiness of iota.
%
% From iota-neurophys, Snipes, 2024.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = HBNParameters();
Paths = Parameters.Paths;
PlotProps = Parameters.PlotProps.Manuscript;
CriteriaSet = Parameters.CriteriaSet;

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
% Participant = 'NDARUL694GYN'; TimeRange = [150 160]; % works for all of these others as well
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

%%

%%% plot
Title = [num2str(round(Info.Age, 1)), ' year old ' Sex, ' (', Participant, ')'];
plot_example(EEG, Power, Frequencies, Chanlocs, Parameters.Channels.Standard_10_20,...
    PeriodicPeaks, TimeRange, CriteriaSet, Title, Parameters.PlotProps.Manuscript)
chART.save_figure(['Example_', Participant], ResultsFolder, PlotProps)



%% get cycle-by-cycle on whole recording

EEGBroadband = pop_eegfiltnew(EEG, .5);
EEGBroadband = pop_eegfiltnew(EEGBroadband, [], 45);

[~, MaxPeak] = oscip.check_peak_in_band(PeriodicPeaks, Parameters.Bands.Iota, 1);
BandRange = MaxPeak(1) + [-2 2];

Bursts = burst_detection(EEGBroadband, BandRange, CriteriaSet);
Bursts = cycy.average_cycles(Bursts, {'Amplitude'});
BurstClusters = cycy.aggregate_bursts_into_clusters(Bursts, EEGBroadband, 1);


%% sanity check
% to see if link between iota and eye movements persists in wake

figure('Units','centimeters','Position',[0 0 25 8])

scatter([Bursts.Start]/EEG.srate/60, [Bursts.ChannelIndex], [Bursts.MeanAmplitude]*5, 'filled', 'MarkerFaceAlpha', .1, 'MarkerFaceColor', PlotProps.Color.Maps.Linear(128, :))

EOG2 =  EEGBroadband.data(32, :)-EEGBroadband.data(121, :);

rms_per_channel = sqrt(EOG2.^2);
t = linspace(0, size(EEGBroadband.data, 2)/EEGBroadband.srate, size(EEGBroadband.data, 2));

hold on
plot(t/60, mat2gray(smooth(rms_per_channel, 1000))*129, 'LineWidth', 2, 'color', [0 0 0])
axis tight
 

%%

BurstDensity = nan(1, numel(Chanlocs));
Amplitude = BurstDensity;
Duration = size(EEGBroadband.data, 2)/EEG.srate/60;

for ChIdx = 1:numel(Chanlocs)
    B = Bursts([Bursts.ChannelIndex]==ChIdx);
    BurstDensity(ChIdx) = numel(B)/Duration;
    Amplitude(ChIdx) = mean([B.Amplitude]);
end

%% figures for reviewers

PlotProps.Colorbar.Location = 'eastoutside';
figure
chART.plot.eeglab_topoplot(BurstDensity, Chanlocs, [], [], 'bursts/min', 'Linear', PlotProps)

figure
chART.plot.eeglab_topoplot(Amplitude, Chanlocs, [], [], '\muV', 'Linear', PlotProps)

figure
scatter([Bursts.DurationPoints]/EEGBroadband.srate, [Bursts.MeanAmplitude], 'filled', 'MarkerFaceAlpha', .2)
xlabel('Duration (s)')
ylabel('Amplitude (\muV)')
figure;histogram([Bursts.BurstFrequency], 25:.5:34)
xlabel('Frequency (Hz)')
