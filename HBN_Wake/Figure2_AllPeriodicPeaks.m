% plots the distribution of periodic peaks in the whole HBN dataset.
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
Iota = [25 35];

%%% paths
ResultsFolder = fullfile(Paths.Results, 'AllPeaks');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% plot


%% Figure 2: iota in wake

% load in analyses on preprocessed data
CacheName = 'PeriodicParameters_Clean.mat';
load(fullfile(CacheDir, CacheName), 'PeriodicPeaks', 'Metadata', 'AllSpectra', 'AllPeriodicSpectra', 'FooofFrequencies', 'Frequencies')


% sort rows by age so that the rarer adults come out on top
PeriodicPeaks = sortrows(PeriodicPeaks, 'Age', 'ascend'); % sort by age so that the rarer adults are on top

%%%%%%%%%%%%%%%%%%%
%%% plot

%%
PlotProps = Parameters.PlotProps.Manuscript;
% PlotProps.Figure.Padding = 100;
Grid = [1, 3];
XLim = [3 50];


%%% scatterplot peaks
figure('Units','centimeters', 'Position', [0 0 20 20])

PlotProps.Scatter.Alpha = .1;
CLims = [5 21];
YLims = [.3 12];

chART.sub_plot([], [1 1], [1 1], [], true, '', PlotProps);
Axes = plot_periodicpeaks(PeriodicPeaks, XLim, YLims, CLims, true, PlotProps);
Axes.Units = 'normalized';
Axes.Position(1) = Axes.Position(1)-.05; % move it a little bit

chART.save_figure('AllPeriodicPeaks', ResultsFolder, PlotProps)
%%

%%% C: Proportion of iota in population by age

% set up age resolution
AgeBins = [0:2:18, 22];
Labels = AgeBins(1:end-1)+diff(AgeBins)/2;
Labels(end) = 19;
Red = [193, 36, 133]/255;

% gather participants with iota
IotaPeriodicPeaks = PeriodicPeaks(PeriodicPeaks.Frequency>Iota(1) & PeriodicPeaks.Frequency<=Iota(2) & PeriodicPeaks.BandWidth < 4, :);
IotaPeriodicPeaks = one_row_each(IotaPeriodicPeaks, 'EID'); % in case multiple peaks were detected in the same participant
IotaByAge = tabulate(discretize(IotaPeriodicPeaks.Age, AgeBins));
IotaByAge = IotaByAge(:, 2);

% all participants
ParticipantsByAge = tabulate(discretize(Metadata.Age, AgeBins));
ParticipantsByAge = ParticipantsByAge(:, 2);

% plot stacked bar plot of distribution of participants
figure('Units','centimeters', 'Position', [0 0 20 20])
chART.sub_plot([], [1 1], [1 1], [], true, '', PlotProps);
chART.plot.stacked_bars([IotaByAge, ParticipantsByAge-IotaByAge], Labels, [], {' Iota', ' No iota'}, PlotProps, [0.4 0.4 0.4; .8 .8 .8])
ylabel('# participants')
xlabel('Age')
legend('Location', 'northeast', 'Box','off')
set(legend, 'ItemTokenSize', [18 18])
ylim([0 700])

% plot simple line plot of percentage with iota
yyaxis right
Axes2 = gca;
Axes2.YAxis(2).Color = Red;
plot(Labels, 100*IotaByAge./ParticipantsByAge, '-o', 'MarkerFaceColor', Red, 'Color',Red, ...
    'HandleVisibility', 'off', 'LineWidth',5, 'MarkerSize',15)

ylabel('%')
ylim([0 100])
xlim([4 20])
StringLabels = string(Labels);
StringLabels(end) = "+18";
xticklabels(StringLabels)
box off
chART.set_axis_properties(PlotProps)

% shift a bit
Axes2.Units = 'normalized';
Axes2.Position = Axes.Position;

chART.save_figure('AllIotaProportion', ResultsFolder, PlotProps)

%% Total iota recording percentage by age


CacheName = 'PeriodicParameters_Clean.mat';
load(fullfile(CacheDir, CacheName), 'Metadata')


clc

nTot = size(Metadata, 1);
nIota = size(IotaPeriodicPeaks, 1);
disp(['recordings with iota: ', num2str(round(100*nIota/nTot)), '%, (', num2str(nIota), '/', num2str(nTot), ')'])

nTot = nnz(Metadata.Age<14);
nIota = nnz(IotaPeriodicPeaks.Age<14);
disp(['recordings <14 with iota: ', num2str(round(100*nIota/nTot)), '%, (', num2str(nIota), '/', num2str(nTot), ')'])

nTot = nnz(Metadata.Age>=14 & Metadata.Age<18);
nIota = nnz(IotaPeriodicPeaks.Age>=14 & IotaPeriodicPeaks.Age<18);
disp(['recordings 14-18 with iota: ', num2str(round(100*nIota/nTot)), '%, (', num2str(nIota), '/', num2str(nTot), ')'])

nTot = nnz(Metadata.Age>=18);
nIota = nnz(IotaPeriodicPeaks.Age>=18);
disp(['recordings >18 with iota: ', num2str(round(100*nIota/nTot)), '%, (', num2str(nIota), '/', num2str(nTot), ')'])

x1 = nnz(~isnan(Metadata.IotaFrequency(Metadata.Age<14)));
n1 = numel(~isnan(Metadata.IotaFrequency(Metadata.Age<14)));

x2 = nnz(~isnan(Metadata.IotaFrequency(Metadata.Age>=14)));
n2 = numel(~isnan(Metadata.IotaFrequency(Metadata.Age>=14)));
z_test(n1, x1, n2, x2)

[Rho, p] = corr(Metadata.IotaFrequency, Metadata.Age, 'rows', 'complete');
disp(['Iota frequency x age: r=', num2str(round(Rho, 2)), ', p=', num2str(round(p, 3))])

[Rho, p] = corr(Metadata.IotaPower, Metadata.Age, 'rows', 'complete');
disp(['Iota power x age: r=', num2str(round(Rho, 2)), ', p=', num2str(round(p, 3))])


%% Totals

Iota40PeriodicPeaks = PeriodicPeaks(PeriodicPeaks.Frequency>35 & PeriodicPeaks.Frequency<=40 & PeriodicPeaks.BandWidth < 4, :);
nTot = size(Metadata, 1);
nIota = size(Iota40PeriodicPeaks, 1);
disp(['recordings with 35-40 Hz: ', num2str(round(100*nIota/nTot)), '%, (', num2str(nIota), '/', num2str(nTot), ')'])
