
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

load(fullfile(CacheDir, CacheName),  'Metadata', 'BandTopographies', 'Chanlocs')

Remove = ~any(isnan(BandTopographies), 2);
CleanTopo = BandTopographies(Remove, :);
ClusterMetadata = Metadata(~Remove, :);

[~, Order] = sort(max(CleanTopo, [], 2), 'descend');
CleanTopo = CleanTopo(Order, :);
ClusterMetadata = ClusterMetadata(Order, :);

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.External.EEGLAB.TopoRes = 100;

%%
figure('Units','normalized', 'OuterPosition',[0 0 1 1])
IndexPlot = 1;
for Index =1:size(CleanTopo, 1)
    subplot(8, 12, IndexPlot)
    chART.plot.eeglab_topoplot(CleanTopo(Index, :), Chanlocs, [], [], '', 'Linear', PlotProps)
    IndexPlot = IndexPlot+1;
    title(num2str(Index))
    if IndexPlot>8*12
        IndexPlot = 1;
        chART.save_figure(['AllTopos_', num2str(Index)], ResultsFolder, PlotProps)

        figure('Units','normalized', 'OuterPosition',[0 0 1 1])
    end
end


%%
% subplot:
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.External.EEGLAB.TopoRes = 300;
PlotProps.Axes.xPadding = 20;
PlotIndex = [ 330  34  472  453 214;
    21  148 164  61 40];

Grid = [2, size(PlotIndex, 2)+2];

figure('Units','normalized', 'OuterPosition',[0 0 .5 .35])
chART.sub_plot([], Grid, [2, 1], [2, 2], false, '', PlotProps);
chART.plot.eeglab_topoplot(mean(CleanTopo, 1), Chanlocs, [], ...
    '', 'log power', 'Linear', PlotProps)
title(['Average (N=', num2str(size(CleanTopo, 1)), ')'])

PlotProps.Axes.xPadding = 15;
for IndexR = 1:size(PlotIndex, 1)
    for IndexC = 1:size(PlotIndex, 2)
        Index = PlotIndex(IndexR, IndexC);
        Data = CleanTopo(Index, :);
        chART.sub_plot([], Grid, [IndexR, IndexC+2], [], false, '', PlotProps);
        chART.plot.eeglab_topoplot(Data, Chanlocs, [], quantile(Data, [.01, 1]), '', 'Linear', PlotProps)

        %  Band = [ClusterMetadata.IotaFrequency(Index)-ClusterMetadata.IotaBandwidth(Index)/2, ...
        %      ClusterMetadata.IotaFrequency(Index)+ClusterMetadata.IotaBandwidth(Index)/2];
        % Title = [ClusterMetadata.Participant(Index); ['(', num2str(ClusterMetadata.IotaFrequency), '']];
        title(ClusterMetadata.Participant(Index), 'FontWeight','normal', 'FontSize', PlotProps.Text.AxisSize)
    end
end
% colormap(PlotProps.Color.Maps.Linear)

        chART.save_figure(['AllTopos_', num2str(Index)], ResultsFolder, PlotProps)

