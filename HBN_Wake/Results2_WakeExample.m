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
CriteriaSet = Parameters.CriteriaSet;
Channels = Parameters.Channels;

ResultsFolder = fullfile(Paths.Results, 'WakeExamples');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end

SourceEEG = fullfile(Paths.Preprocessed, 'Power', 'Clean', 'RestingState');
SourcePower = fullfile(Paths.Core, 'Final_Old', 'EEG','Specparam/');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run


%% Figure 2

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.External.EEGLAB.TopoRes = 300;
PlotProps.Axes.xPadding = 20;

PlotTopos = {
    'NDARTH506TRG', 'NDARKM635UY0', 'NDARXH140YZ0',  'NDARVK847ZRT', 'NDARAE710YWG', 'NDARPD977VX2'}; % IDs of participants

CacheDir = Paths.Cache;
CacheName = 'PeriodicParameters_Clean.mat';

load(fullfile(CacheDir, CacheName),  'Metadata', 'CustomTopographies', 'Chanlocs')

Keep = labels2indexes(Channels.TopoPlot, Chanlocs);
Chanlocs = Chanlocs(Keep);
CustomTopographies = CustomTopographies(:, :, Keep);

[idx, loc] = ismember(PlotTopos, Metadata.EID);
indexes = loc(idx); % Get only the valid indexes

BandLabels = fieldnames(Parameters.Bands);
IotaIdx = find(strcmp(BandLabels, 'Iota'));
IotaTopo = squeeze(CustomTopographies(:, IotaIdx, :));


Topographies = IotaTopo(indexes, :);
IotaFrequencies = Metadata.IotaFrequency(indexes);
Participants = Metadata.Participant(indexes);
Participant = 'NDARMH180XE5'; TimeRange = [39 49]; % the bestest

File = [Participant, '_RestingState.mat'];
load(fullfile(Paths.Preprocessed, 'Power\Clean\RestingState\', File), 'EEG')

% load fooof data
load(fullfile( Paths.Final, 'EEG', 'Power', '20sEpochs', 'Clean', File), 'Power', 'Frequencies', 'PeriodicPeaks')

Info = Metadata(find(strcmp(Metadata.EID, Participant), 1, 'first'), :);

switch Info.Sex
    case 0
        Sex = 'male';
    case 1
        Sex = 'female';
end



Title = [num2str(round(Info.Age, 1)), ' year old ' Sex, ' (', Participant, ')'];


plot_examples(EEG, Power, Topographies, IotaFrequencies, Participants, Frequencies, Chanlocs, Parameters.Channels.Standard_10_20,...
    PeriodicPeaks, TimeRange, CriteriaSet, Title, Parameters.PlotProps.Manuscript)
chART.save_figure(['Example_', Participant], ResultsFolder, PlotProps)


%%%%%%%%%%%%%%%%%%%%%%
%%% sanity check to see if link between iota and eye movements persists in wake

%% get cycle-by-cycle on whole recording

EEGBroadband = pop_eegfiltnew(EEG, .5);
EEGBroadband = pop_eegfiltnew(EEGBroadband, [], 45);

[~, MaxPeak] = oscip.check_peak_in_band(PeriodicPeaks, Parameters.Bands.Iota, 1);
BandRange = MaxPeak(1) + [-2 2];

Bursts = burst_detection(EEGBroadband, BandRange, CriteriaSet);
Bursts = cycy.average_cycles(Bursts, {'Amplitude'});



%% plot bursts and eyes

figure('Units','centimeters','Position',[0 0 25 8])

scatter([Bursts.Start]/EEG.srate/60, [Bursts.ChannelIndex], [Bursts.MeanAmplitude]*5, 'filled', 'MarkerFaceAlpha', .1, 'MarkerFaceColor', PlotProps.Color.Maps.Linear(128, :))

EOG2 =  EEGBroadband.data(32, :)-EEGBroadband.data(121, :);

rms_per_channel = sqrt(EOG2.^2);
t = linspace(0, size(EEGBroadband.data, 2)/EEGBroadband.srate, size(EEGBroadband.data, 2));

hold on
plot(t/60, mat2gray(smooth(rms_per_channel, 1000))*129, 'LineWidth', 2, 'color', [0 0 0])
axis tight
 

%%% Figures for reviewers

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
title('Bursts per minute')

figure
chART.plot.eeglab_topoplot(Amplitude, Chanlocs, [], [], '\muV', 'Linear', PlotProps)
title('Burst amplitudes')

figure
scatter([Bursts.DurationPoints]/EEGBroadband.srate, [Bursts.MeanAmplitude], 'filled', 'MarkerFaceAlpha', .2)
xlabel('Duration (s)')
ylabel('Amplitude (\muV)')
title('Burst duration vs amplitudes')
set(gcf, 'color', 'w')

figure;histogram([Bursts.BurstFrequency], 25:.5:34)
xlabel('Frequency (Hz)')
title('Burst frequencies (narrow band frequency of 27-31 Hz)')
set(gcf, 'color', 'w')

figure
histogram([Bursts.CyclesCount], 1:30)
title('Number of cycles in bursts')