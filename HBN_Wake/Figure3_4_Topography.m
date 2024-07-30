% Scripts to plot the topographies based on the individual iota peaks.
%
% From iota-preprint, Snipes, 2024.

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

CleanTopo = squeeze(CustomTopographies(:, end, :));



%% Figure 3: Iota average topography & examples

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
chART.plot.eeglab_topoplot(mean(CleanTopo, 1, 'omitnan'), Chanlocs, [], ...
    '', 'Log power', 'Linear', PlotProps)
title(['Average (N=', num2str(nnz(~isnan(CleanTopo(:, 1)))), ')'])

% plot individuals
PlotProps.Axes.xPadding = 5;
PlotProps.Axes.yPadding =10;
for IndexR = 1:size(PlotTopos, 1)
    for IndexC = 1:size(PlotTopos, 2)
        Index = find(strcmp(Metadata.EID, PlotTopos(IndexR, IndexC)));
        Data = CleanTopo(Index, :);
        chART.sub_plot([], Grid, [IndexR, IndexC+2], [], false, '', PlotProps);
        chART.plot.eeglab_topoplot(Data, Chanlocs, [], quantile(Data, [.01, 1]), '', 'Linear', PlotProps)
        chART.plot.topo_corner_text([num2str(round(Metadata.IotaFrequency(Index))), 'Hz'], PlotProps)
        title(Metadata.Participant(Index), 'FontSize', PlotProps.Text.LegendSize)
    end
end

chART.save_figure('AverageTopography', ResultsFolder, PlotProps)


%% Figure 4: all band topographies

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.Figure.Padding = 25;
PlotProps.Axes.xPadding = 1;
PlotProps.Axes.yPadding = 5;

BandLabels = fieldnames(Bands);
BandTitles = BandLabels;
BandTitles{strcmp(BandLabels, 'LowBeta')} = 'Low Beta';
BandTitles{strcmp(BandLabels, 'HighBeta')} = 'High Beta';

Grid = [2, numel(BandLabels)];

LogTopographies(:, :, end) = nan; % there's something wrong with the aperiodic signal in the data. TODO: figure out

figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width+2 PlotProps.Figure.Width/3])

chART.sub_plot([], Grid, [1, 1], [], -1, 'A', PlotProps); axis off
chART.sub_plot([], Grid, [2, 1], [], -1, 'B', PlotProps); axis off

for BandIdx = 1:numel(BandLabels)
    Label = ' ';
    PlotIdx = BandIdx;
    if BandIdx==numel(BandLabels)

        PlotIdx = numel(BandLabels) -1;
    elseif BandIdx ==numel(BandLabels) -1 % iota was placed at end for some reason that must have previously made sense, now I have this stupd fix
        PlotIdx = numel(BandLabels);
        Label = 'Log power';
    end
    Axes = chART.sub_plot([], Grid, [1, PlotIdx], [], false, '', PlotProps);
    Axes.Units = 'pixels';
    Axes.Position(2) = Axes.Position(2)-10;
    Axes.Units = 'normalized';
    Data = squeeze(mean(LogTopographies(:, BandIdx, :), 1, 'omitnan'));
    CLims = quantile(Data, [.01, 1]);
    chART.plot.eeglab_topoplot(Data, Chanlocs, [],  CLims, Label, 'Linear', PlotProps)
    clim(CLims)
    title({BandTitles{BandIdx}, ['(', num2str(Bands.(BandLabels{BandIdx})(1)), '-', num2str(Bands.(BandLabels{BandIdx})(2)), ' Hz)']})

    chART.sub_plot([], Grid, [2, PlotIdx], [], false, '', PlotProps);
    Data = squeeze(mean(PeriodicTopographies(:, BandIdx, :), 1, 'omitnan'));
    chART.plot.eeglab_topoplot(Data, Chanlocs, [],  quantile(Data, [.01, 1]), Label, 'Linear', PlotProps)
end

chART.save_figure('AllBandTopographies', ResultsFolder, PlotProps)


%% identify peak locations

MeanTopo = mean(CleanTopo, 1, 'omitnan');

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
for Index =1:size(CleanTopo, 1)

    Data = CleanTopo(Index, :);
    if any(isnan(Data))
        continue
    end
    subplot(8, 12, IndexPlot)
    chART.plot.eeglab_topoplot(Data, Chanlocs, [], [], '', 'Linear', PlotProps)
    IndexPlot = IndexPlot+1;
    title([Metadata.EID{Index}, ' (', num2str(round(Metadata.Age(Index))) 'yo)'], 'FontWeight','normal', 'FontSize', 8)
    if IndexPlot>8*12
        IndexPlot = 1;
        chART.save_figure(['AllTopos_', num2str(Index), '.png'], ResultsFolder, PlotProps)

        figure('Units','normalized', 'OuterPosition',[0 0 1 1])
    end
end


