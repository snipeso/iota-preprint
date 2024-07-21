% TODO: example participant

clear
clc
close all


Parameters = HBNParameters();
Paths = Parameters.Paths;
PlotProps = Parameters.PlotProps.Manuscript;

CacheDir = Paths.Cache;
CacheName = 'PeriodicParameters.mat';

%%% paths
ResultsFolder = fullfile(Paths.Results, 'WakeExamples');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end


SourceEEG = fullfile(Paths.Preprocessed, 'Power', 'Clean', 'RestingState');
SourcePower = fullfile(Paths.Core, 'Final_Old', 'EEG','Specparam/');

load(fullfile(CacheDir, CacheName), 'Metadata')



% left handed 8.9 year old
% Participant = 'NDARMH180XE5'; TimeRange = [39 49]; % the bestest
% Participant = 'NDARUL694GYN'; TimeRange = [150 160];
Participant = 'NDARDR804MFE'; TimeRange = [10 20];
% Participant = 'NDARTZ926NMZ';TimeRange = [54 64];
% Participant = 'NDARKL327YDQ'; TimeRange = [39 49]; % Works with same time interval
% Participant = 'NDARKL327YDQ'; TimeRange = [39 49]; % 16 year old
% Participant = 'NDARYH110YV9'; TimeRange = [39 49]; % 16 year old
% Participant= 'NDARTF566PYH'; TimeRange = [39 49]; % good time
% Participant= 'NDARAJ674WJT'; TimeRange = [39 49];
% Participant = 'NDARDR804MFE';TimeRange = [39 49];


load(fullfile(['E:\Preprocessed\Power\Clean\RestingState\', Participant, '_RestingState.mat']), 'EEG')

Info = Metadata(find(strcmp(Metadata.EID, Participant), 1, 'first'), :);


DataOut = load_datafile(SourcePower, Participant, '', '', ...
    {'Power', 'Frequencies', 'Chanlocs', 'PeriodicPeaks', 'WhitenedPower', 'FooofFrequencies'   }, '.mat');
Power = DataOut{1};
Freqs = DataOut{2};
Chanlocs = DataOut{3};
PeriodicPeaks = DataOut{4};
% Power = DataOut{5};
% Freqs = DataOut{6};

switch Info.Sex
    case 0
        Sex = 'male';
    case 1
        Sex = 'female';
end


Title = [num2str(round(Info.Age, 1)), ' year old ' Sex, ' (', Participant, ')'];        
plot_example(EEG, Power, Freqs, Chanlocs, Parameters.Channels.Standard_10_20,...
    PeriodicPeaks, TimeRange, Title, Parameters.PlotProps.Manuscript)
chART.save_figure(['Example_', Participant], ResultsFolder, PlotProps)


%% plot raw power spectrum

Participant = 'NDARMH180XE5'; TimeRange = [39 49];
% Participant = 'NDARJR579FW7'; TimeRange = [39 49];
% Participant = 'NDARTZ926NMZ';TimeRange = [54 64];
 % Participant = 'NDARKL327YDQ';
Info = Metadata(find(strcmp(Metadata.EID, Participant), 1, 'first'), :);

load(fullfile('E:\Raw\EEG\', Participant, 'EEG', 'raw', 'mat_format', 'RestingState.mat'), 'EEG')

figure('Units','centimeters', 'Position', [0 0 11 10])
[RawPower, Frequencies] = oscip.compute_power(EEG.data, EEG.srate, 8, .9);
plot(Frequencies, RawPower, 'Color',  [.5 .5 .5 .1])
chART.set_axis_properties(PlotProps)
box off
set(gca, 'YScale', 'log', 'XScale', 'log');
xticks([0 1 10 30 60 120])
title([Participant,' (iota=', num2str(round(Info.IotaFrequency, 1)),  ' Hz; alpha=',num2str(round(Info.AlphaFrequency, 1)) ' Hz)'], 'FontWeight','normal')
axis tight
ylim(quantile(RawPower(:), [.02 .999]))
xlabel('Frequency (Hz)')
ylabel('Power')
xlim([1 250])
chART.save_figure(['Example_', Participant, '_Raw'], ResultsFolder, PlotProps)

