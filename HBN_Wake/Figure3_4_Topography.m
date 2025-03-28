% Scripts to plot the topographies based on the individual iota peaks.
%
% From iota-neurophys, Snipes, 2024.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = HBNParameters();
Paths = Parameters.Paths;

CacheDir = Paths.Cache;
CacheName = 'PeriodicParameters_Clean.mat';

ResultsFolder = fullfile(Paths.Results, 'Topographies');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run

% load in data
load(fullfile(CacheDir, CacheName),  'Metadata', 'CustomTopographies', 'Chanlocs', 'LogTopographies', 'PeriodicTopographies', 'Bands')


BandLabels = fieldnames(Bands);
BandTitles = BandLabels;
BandTitles{strcmp(BandLabels, 'LowBeta')} = 'Low Beta';
BandTitles{strcmp(BandLabels, 'HighBeta')} = 'High Beta';

IotaIdx = find(strcmp(BandLabels, 'Iota'));

IotaTopo = squeeze(CustomTopographies(:, IotaIdx, :));



%% abridged (pending acceptance, I'll make this code nice)


PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.External.EEGLAB.TopoRes = 300;
PlotProps.Axes.xPadding = 20;

PlotTopos = {
    'NDARLZ986JLL', 'NDARKM635UY0', 'NDARXH140YZ0',  'NDARVK847ZRT', 'NDARAE710YWG', 'NDARPD977VX2'}; % IDs of participants


[idx, loc] = ismember(PlotTopos, Metadata.EID);
indexes = loc(idx); % Get only the valid indexes

Topographies = IotaTopo(indexes, :);
IotaFrequencies = Metadata.IotaFrequency(indexes);
Participants = Metadata.Participant(indexes);
Participant = 'NDARMH180XE5'; TimeRange = [39 49]; % the bestest

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



Title = [num2str(round(Info.Age, 1)), ' year old ' Sex, ' (', Participant, ')'];


plot_examples(EEG, Power, Topographies, IotaFrequencies, Participants, Frequencies, Chanlocs, Parameters.Channels.Standard_10_20,...
    PeriodicPeaks, TimeRange, Title, Parameters.PlotProps.Manuscript)
chART.save_figure(['Example_', Participant], ResultsFolder, PlotProps)


%% Figure 3: Iota average topography & examples (original)

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.External.EEGLAB.TopoRes = 300;
PlotProps.Axes.xPadding = 20;

PlotTopos = {'NDARZT199MF6', 'NDARFD453NPR', 'NDARXH140YZ0', 'NDARLL846UYQ', 'NDARPN886HH9';
    'NDARKM635UY0', 'NDARAE710YWG', 'NDARTG681ZDV', 'NDARLZ986JLL', 'NDARVK847ZRT'}; % IDs of participants

Grid = [2, size(PlotTopos, 2)+2];

figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width PlotProps.Figure.Width/3.5])

% plot average
chART.sub_plot([], Grid, [2, 1], [2, 2], false, '', PlotProps);
chART.plot.eeglab_topoplot(mean(IotaTopo, 1, 'omitnan'), Chanlocs, [], [.15 .38], ...
    'Log power', 'Linear', PlotProps)
title(['Average (N=', num2str(nnz(~isnan(IotaTopo(:, 1)))), ')'])

% plot individuals
PlotProps.Axes.xPadding = 5;
PlotProps.Axes.yPadding =10;
for IndexR = 1:size(PlotTopos, 1)
    for IndexC = 1:size(PlotTopos, 2)
        IndexC = find(strcmp(Metadata.EID, PlotTopos(IndexR, IndexC)));
        Data = IotaTopo(IndexC, :);
        chART.sub_plot([], Grid, [IndexR, IndexC+2], [], false, '', PlotProps);
        chART.plot.eeglab_topoplot(Data, Chanlocs, [], quantile(Data, [.01, 1]), '', 'Linear', PlotProps)
        chART.plot.topo_corner_text([num2str(round(Metadata.IotaFrequency(IndexC))), 'Hz'], PlotProps)
        title(Metadata.Participant(IndexC), 'FontSize', PlotProps.Text.LegendSize)
    end
end

chART.save_figure('AverageTopography', ResultsFolder, PlotProps)


%% Figure 4: all band topographies

CLimsLog = [
    .16 .4;
    -.01 .3;
    -.65 -.35;
    -.85 -.6;
    -1.3 -.9;
    -1.6 -1.1;
    ];

CLimsPeriodic = [];

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.Figure.Padding = 25;
PlotProps.Axes.xPadding = 3;
PlotProps.Axes.yPadding = 5;

Grid = [2, numel(BandLabels)];

LogTopographies(:, :, end) = nan; % there's something wrong with the aperiodic signal in the data. TODO: figure out

figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width+2 PlotProps.Figure.Width/2.7])

chART.sub_plot([], Grid, [1, 1], [], -1, 'A', PlotProps); axis off
chART.sub_plot([], Grid, [2, 1], [], -1, 'B', PlotProps); axis off

for BandIdx = 1:numel(BandLabels)
    Label = ' ';
    if BandIdx==numel(BandLabels)
        Label = 'Log power';
    end

    Axes = chART.sub_plot([], Grid, [1, BandIdx], [], false, '', PlotProps);

    % shift slightly
    Axes.Units = 'pixels';
    Axes.Position(2) = Axes.Position(2)-10;
    Axes.Units = 'normalized';

    % plot log power
    Data = squeeze(mean(LogTopographies(:, BandIdx, :), 1, 'omitnan'));
    chART.plot.eeglab_topoplot(Data, Chanlocs, [],  quantile(Data, [.01, 1]), Label, 'Linear', PlotProps)
    title({BandTitles{BandIdx}, ['(', num2str(Bands.(BandLabels{BandIdx})(1)), '-', num2str(Bands.(BandLabels{BandIdx})(2)), ' Hz)']})

    % plot periodic power
    chART.sub_plot([], Grid, [2, BandIdx], [], false, '', PlotProps);
    Data = squeeze(mean(PeriodicTopographies(:, BandIdx, :), 1, 'omitnan'));
    chART.plot.eeglab_topoplot(Data, Chanlocs, [],  quantile(Data, [.01, 1]), Label, 'Linear', PlotProps)
end

chART.save_figure('AllBandTopographies', ResultsFolder, PlotProps)


%% identify peak locations

MeanTopo = mean(IotaTopo, 1, 'omitnan');

Topography = table();
Topography.Labels = {Chanlocs.labels}';
Topography.Iota = MeanTopo';

disp(sortrows(Topography, 'Iota', 'descend'))




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Unpublished

%% Everyone's topographies (used to choose which ones are representative)

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.External.EEGLAB.TopoRes = 100;

figure('Units','normalized', 'OuterPosition',[0 0 1 1])
IndexPlot = 1;
for IndexC =1:size(IotaTopo, 1)

    Data = IotaTopo(IndexC, :);
    if any(isnan(Data))
        continue
    end
    subplot(8, 12, IndexPlot)
    chART.plot.eeglab_topoplot(Data, Chanlocs, [], [], '', 'Linear', PlotProps)
    IndexPlot = IndexPlot+1;
    title([Metadata.EID{IndexC}, ' (', num2str(round(Metadata.Age(IndexC))) 'yo)'], 'FontWeight','normal', 'FontSize', 8)
    if IndexPlot>8*12
        IndexPlot = 1;
        chART.save_figure(['AllTopos_', num2str(IndexC), '.png'], ResultsFolder, PlotProps)

        figure('Units','normalized', 'OuterPosition',[0 0 1 1])
    end
end


