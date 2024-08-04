% This script plots the topographies from sleep
%
% iota-preprint, Snipes 2024

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = LSMParameters();
Paths = Parameters.Paths;

Channels = Parameters.Channels.NotEdge;
Task = Parameters.Task;
Format = 'Minimal'; % chooses which filtering to do
FreqLims = [3 45];

ExampleParticipant = 'P09';


% folders
SourceSpecparam = fullfile(Paths.Final, 'EEG', 'Power',  '20sEpochs', Task, Format);
SourceEEG = fullfile(Paths.Preprocessed, Format, 'Clean', Task);

ResultsFolder = fullfile(Paths.Results);
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end

CacheDir = Paths.Cache;
CacheName = ['PeriodicParameters_', Task, '_', Format, '.mat'];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plot


load(fullfile(CacheDir, CacheName), 'PeriodicTopographies', 'Chanlocs', 'Bands', 'StageLabels')
BandLabels = fieldnames(Bands);
nStages = numel(StageLabels);
nBands = numel(BandLabels);

PeriodicTopographies(:, :, :, end) = nan;


%%

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Figure.Padding = 25;
PlotProps.Axes.xPadding = 1;
PlotProps.Axes.yPadding = 5;
Grid = [nBands, nStages+1];
StageIndexes = [5 4 3 1 2];
% PlotProps.Colorbar.Location = 'eastoutside';
CLims = [
.1 .25;
.2 .7;
.1 .5;
0 .35;
.05 .2
];

figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width*.85 PlotProps.Figure.Width/1.5])

for BandIdx = 1:nBands
    for StageIdx = 1:nStages

        Data = squeeze(mean(PeriodicTopographies(:, StageIdx, BandIdx, :), 1, 'omitnan'));

        % plot
        Axes = chART.sub_plot([], Grid, [BandIdx, StageIndexes(StageIdx)], [], false, '', PlotProps);
        % Axes.Position(2) = Axes.Position(2)-.03;
        chART.plot.eeglab_topoplot(Data, Chanlocs, [], CLims(BandIdx, :), '', 'Linear', PlotProps)
        if StageIndexes(StageIdx)==1
             chART.plot.vertical_text([num2str(Bands.(BandLabels{BandIdx})(1)), '-', num2str(Bands.(BandLabels{BandIdx})(2)), ' Hz'], .15, .5, PlotProps)
        end
        if BandIdx==1
              title(StageLabels{StageIdx}) 
        end
    end
chART.sub_plot([], Grid, [BandIdx, nStages+1], [], false, '', PlotProps); axis off
chART.plot.pretty_colorbar('Linear', CLims(BandIdx, :), 'Log power', PlotProps);
end

% chART.save_figure('AllBandSleepTopographies', ResultsFolder, PlotProps)
