
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

CustomTopographies = squeeze(CustomTopographies(:, end, :));
Remove = ~any(isnan(CustomTopographies), 2);
CleanTopo = CustomTopographies(Remove, :);
ClusterMetadata = Metadata(~Remove, :);

[~, Order] = sort(max(CleanTopo, [], 2), 'descend');
CleanTopo = CleanTopo(Order, :);
ClusterMetadata = ClusterMetadata(Order, :);

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.External.EEGLAB.TopoRes = 100;

%% Everyone's topographies (used to choose which ones are representative)
figure('Units','normalized', 'OuterPosition',[0 0 1 1])
IndexPlot = 1;
for Index =1:size(CleanTopo, 1)
    subplot(8, 12, IndexPlot)
    chART.plot.eeglab_topoplot(CleanTopo(Index, :), Chanlocs, [], [], '', 'Linear', PlotProps)
    IndexPlot = IndexPlot+1;
    title([ClusterMetadata.EID{Index}, ' (', num2str(round(ClusterMetadata.Age(Index))) 'yo)'], 'FontWeight','normal', 'FontSize', 8)
    if IndexPlot>8*12
        IndexPlot = 1;
        chART.save_figure(['AllTopos_', num2str(Index), '.png'], ResultsFolder, PlotProps)

        figure('Units','normalized', 'OuterPosition',[0 0 1 1])
    end
end


%% Average Topography

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.External.EEGLAB.TopoRes = 300;
PlotProps.Axes.xPadding = 20;

PlotTopos = {'NDAREF150LNT', 'NDARLE849LCR', 'NDARKE358TFU',  'NDARGT022BEW', 'NDARCW497XW2';
   'NDAREV848HWX', 'NDARFJ803JF7', 'NDARJH441HJD', 'NDARFN452VPC', 'NDARFA737TG6'};


Grid = [2, size(PlotTopos, 2)+2];

figure('Units','normalized', 'OuterPosition',[0 0 .5 .33])
chART.sub_plot([], Grid, [2, 1], [2, 2], false, '', PlotProps);
chART.plot.eeglab_topoplot(mean(CleanTopo, 1), Chanlocs, [], ...
    '', 'log power', 'Linear', PlotProps)
title(['Average (N=', num2str(size(CleanTopo, 1)), ')'])

PlotProps.Axes.xPadding = 15;
for IndexR = 1:size(PlotTopos, 1)
    for IndexC = 1:size(PlotTopos, 2)
        Index = find(strcmp(ClusterMetadata.EID, PlotTopos(IndexR, IndexC)));
        Data = CleanTopo(Index, :);
        chART.sub_plot([], Grid, [IndexR, IndexC+2], [], false, '', PlotProps);
        chART.plot.eeglab_topoplot(Data, Chanlocs, [], quantile(Data, [.01, 1]), '', 'Linear', PlotProps)

        title(ClusterMetadata.Participant(Index), 'FontWeight','normal', 'FontSize', PlotProps.Text.AxisSize)
    end
end

chART.save_figure('AverageTopography', ResultsFolder, PlotProps)


%% identify peak locations

MeanTopo = mean(CleanTopo, 1);

Topography = table();
Topography.Labels = {Chanlocs.labels}';
Topography.Iota = MeanTopo';

disp(sortrows(Topography, 'Iota', 'descend'))




