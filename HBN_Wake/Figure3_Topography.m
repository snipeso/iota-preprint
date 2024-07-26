% Scripts to plot the topographies based on the individual iota peaks
clear
clc
close all

Parameters = HBNParameters();
Paths = Parameters.Paths;

CacheDir = Paths.Cache;
CacheName = 'PeriodicParameters_Clean.mat';

ResultsFolder = fullfile(Paths.Results, 'Topographies');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end

load(fullfile(CacheDir, CacheName),  'Metadata', 'CustomTopographies', 'Chanlocs')

CleanTopo = squeeze(CustomTopographies(:, end, :));

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.External.EEGLAB.TopoRes = 100;

%% Everyone's topographies (used to choose which ones are representative)
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


%% Figure 2: Average Topography & examples

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.External.EEGLAB.TopoRes = 300;
PlotProps.Axes.xPadding = 20;

PlotTopos = {'NDARZT199MF6', 'NDARFD453NPR', 'NDARXH140YZ0', 'NDARLL846UYQ', 'NDARPN886HH9';
    'NDARKM635UY0', 'NDARAE710YWG', 'NDARTG681ZDV', 'NDARLZ986JLL', 'NDARVK847ZRT'};


Grid = [2, size(PlotTopos, 2)+2];

figure('Units','normalized', 'OuterPosition',[0 0 .5 .33])
chART.sub_plot([], Grid, [2, 1], [2, 2], false, '', PlotProps);
chART.plot.eeglab_topoplot(mean(CleanTopo, 1, 'omitnan'), Chanlocs, [], ...
    '', 'log power', 'Linear', PlotProps)
title(['Average (N=', num2str(nnz(~isnan(CleanTopo(:, 1)))), ')'])

PlotProps.Axes.xPadding = 15;
for IndexR = 1:size(PlotTopos, 1)
    for IndexC = 1:size(PlotTopos, 2)
        Index = find(strcmp(Metadata.EID, PlotTopos(IndexR, IndexC)));
        Data = CleanTopo(Index, :);
        chART.sub_plot([], Grid, [IndexR, IndexC+2], [], false, '', PlotProps);
        chART.plot.eeglab_topoplot(Data, Chanlocs, [], quantile(Data, [.01, 1]), '', 'Linear', PlotProps)

        title(Metadata.Participant(Index), 'FontWeight','normal', 'FontSize', PlotProps.Text.AxisSize)
    end
end

chART.save_figure('AverageTopography', ResultsFolder, PlotProps)


%% identify peak locations

MeanTopo = mean(CleanTopo, 1, 'omitnan');

Topography = table();
Topography.Labels = {Chanlocs.labels}';
Topography.Iota = MeanTopo';

disp(sortrows(Topography, 'Iota', 'descend'))




