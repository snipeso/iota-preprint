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

%%% paths
ResultsFolder = fullfile(Paths.Results, 'AllPeaks');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% plot


%% Participant demographics
clc

Tot = size(Metadata, 1);
disp(['Total n = ', num2str(Tot)])
disp(['female = ', num2str(round(100*nnz(Metadata.Sex==1)/Tot)), '%']) % inexplicably, HBN coded female as "1"
disp(['left-handed = ', num2str(round(100*nnz(Metadata.EHQ_Total<0)/Tot)), '%']) % inexplicably, HBN coded female as "1"
disp(['mean age = ', num2str(round(mean(Metadata.Age), 1)), ' (', num2str(round(min(Metadata.Age), 1)),'-', num2str(round(max(Metadata.Age), 1)) ')'])


disp('_________________________')

% clean up mistakes with diagnoses (when left empty, matlab freaks out)
Bad = cellfun(@numel, Metadata.Diagnosis)==0;
Metadata.Diagnosis(Bad) = repmat({'.'}, nnz(Bad), 1);

Bad = cellfun(@numel, Metadata.Diagnosis_Category)==0;
Metadata.Diagnosis_Category(Bad) = repmat({'.'}, nnz(Bad), 1);

% very quick check of how many adhd are in the data
Total = size(Metadata, 1);
disp(['ADHD: ', num2str(round(100*nnz(contains(Metadata.Diagnosis, 'ADHD'))/Total)), '%'])

tabulate(Metadata.Diagnosis)


%% Figure 2

% load in analyses on preprocessed data
CacheName = 'PeriodicParameters_Clean.mat';
load(fullfile(CacheDir, CacheName), 'PeriodicPeaks', 'Metadata', 'AllSpectra', 'AllPeriodicSpectra', 'FooofFrequencies', 'Frequencies')

% remove blank recordings (files didn't survive preprocessing)
Blanks = any(isnan(AllSpectra), 2);
Metadata(Blanks, :) = [];

% sort rows by age so that the rarer adults come out on top
PeriodicPeaks = sortrows(PeriodicPeaks, 'Age', 'ascend'); % sort by age so that the rarer adults are on top

%%%%%%%%%%%%%%%%%%%
%%% plot

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.yPadding = 5;
Grid = [1, 3];
XLim = [3 50];
Red = chART.color_picker(1, '', 'red');

figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width PlotProps.Figure.Width/3])

%%% A: Power spectra
chART.sub_plot([], Grid, [1, 1], [], 1, 'A', PlotProps);
plot(Frequencies, log10(AllSpectra), 'Color', [.3 .3 .3 .05])
hold on
chART.set_axis_properties(PlotProps)
plot(Frequencies, mean(log10(AllSpectra), 'omitnan'), 'Color', Red, 'LineWidth', 4)
% set(gca, 'XScale', 'log', 'YScale', 'log')
xlim(XLim)
xticks([1 10 20 30 40 50])
ylim([-2 2])
xlabel('Frequency (Hz)')
ylabel('Log power')
box off
title('Wake spectral power')
set(gca, 'TickDir', 'in')


%%% B: Scatter plot of all periodic peaks

PlotProps.Scatter.Alpha = .1;
CLims = [5 21];
YLims = [.5 12.1];

chART.sub_plot([], Grid, [1, 2], [], .2, 'B', PlotProps);
Axes = plot_periodicpeaks(PeriodicPeaks, XLim, YLims, CLims, true, PlotProps);
Axes.Units = 'normalized';
Axes.Position(1) = Axes.Position(1)-.015; % move it a little bit
Axes.Position(3) = Axes.Position(3)+0.0629;
title('Periodic peaks', 'FontSize', PlotProps.Text.TitleSize)
set(gca, 'TickDir', 'in') % switch inward because otherwise t


%%% C: Proportion of iota in population by age

% set up age resolution
AgeBins = [0:2:18, 22];
Labels = AgeBins(1:end-1)+diff(AgeBins)/2;
Labels(end) = 19;

% gather participants with iota
IotaPeriodicPeaks = PeriodicPeaks(PeriodicPeaks.Frequency>25 & PeriodicPeaks.Frequency<=35 & PeriodicPeaks.BandWidth < 4, :);
IotaPeriodicPeaks = one_row_each(IotaPeriodicPeaks, 'EID'); % in case multiple peaks were detected in the same participant
IotaByAge = tabulate(discretize(IotaPeriodicPeaks.Age, AgeBins));
IotaByAge = IotaByAge(:, 2);

% all participants
ParticipantsByAge = tabulate(discretize(Metadata.Age, AgeBins));
ParticipantsByAge = ParticipantsByAge(:, 2);

% plot stacked bar plot of distribution of participants
chART.sub_plot([], Grid, [1, 3], [], 4.5, 'C', PlotProps);
chART.plot.stacked_bars([IotaByAge, ParticipantsByAge-IotaByAge], Labels, [], {'Iota', 'No iota'}, PlotProps, [0.4 0.4 0.4; .8 .8 .8])
ylabel('# participants')
xlabel('Age')
legend('Location', 'northeast')
ylim([0 700])

% plot simple line plot of percentage with iota
yyaxis right
Axes2 = gca;
Axes2.YAxis(2).Color = Red;
plot(Labels, 100*IotaByAge./ParticipantsByAge, '-o', 'MarkerFaceColor', Red, 'Color',Red, ...
    'HandleVisibility', 'off', 'LineWidth',2, 'MarkerSize',6)

ylabel('%')
ylim([0 100])
xlim([4 20])
StringLabels = string(Labels);
StringLabels(end) = "+18";
xticklabels(StringLabels)
box off
chART.set_axis_properties(PlotProps)
title('Iota', 'FontSize', PlotProps.Text.TitleSize)

% shift a bit
Axes2.Units = 'normalized';
Axes2.Position(1) = Axes2.Position(1) + .06;
Axes2.Position(3) = Axes2.Position(3) - .095;

set(gca, 'TickDir', 'in')
chART.save_figure('AllPeriodicPeakBandwidths', ResultsFolder, PlotProps)

%% Total iota recording percentage by age

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



%% Figure 5: Periodic peaks detected in unprocessed data

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Figure.Padding = 10;

% PlotProps.Debug = true;
CLims = [5 21];
XLim = [3 50];
YLims = [.5 12.1];
Grid = [2, 3];
LabelSpace = .5;

% load in analyses on unfiltered data
CacheName = 'PeriodicParameters_Unfiltered.mat';
load(fullfile(CacheDir, CacheName), 'NoisePeriodicPeaks', 'PeriodicPeaks')
UnfilteredPeriodicPeaks = PeriodicPeaks;

UnfilteredPeriodicPeaks = sortrows(UnfilteredPeriodicPeaks, 'Age', 'ascend'); % sort by age so that the rarer adults are on top
NoisePeriodicPeaks = sortrows(NoisePeriodicPeaks, 'Age', 'ascend'); % sort by age so that the rarer adults are on top


figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width PlotProps.Figure.Width/2])

%%% A: iota vs alpha
chART.sub_plot([], Grid, [1, 1], [], LabelSpace, 'A', PlotProps);
hold on
plot([8 13], [8 13]*3, ':', 'Color', [.6 .6 .6], 'LineWidth', 2, 'DisplayName',  ['Expected', newline, 'harmonic fit'])
Scatter = scatter(Metadata.AlphaFrequency, Metadata.IotaFrequency, 50, Metadata.Age, 'filled', 'MarkerFaceAlpha', .2);

% correlation lines
Lines = lsline;
Lines(1).Visible = 'off';
Lines(1).HandleVisibility = 'off';
Lines(2).Color = [0 0 0];
Lines(2).DisplayName = 'Linear fit';
Lines(2).LineWidth = 2;
Scatter.HandleVisibility = 'off';
legend
set(legend, 'location', 'southeast', 'ItemTokenSize', [10 10])

chART.set_axis_properties(PlotProps)
xlabel('Alpha center frequency (Hz)')
ylabel('Iota center frequency (Hz)')
xlim([8 13])
ylim([25 35])
clim(CLims)
title('Alpha vs iota')


%%% B: Peaks in unprocessed data
PlotProps.Scatter.Alpha = .07;
chART.sub_plot([], Grid, [1, 2], [], LabelSpace, 'B', PlotProps);
plot_periodicpeaks(UnfilteredPeriodicPeaks, XLim, YLims, CLims, false, PlotProps);
title('Periodic peaks, unprocessed data',  'FontSize', PlotProps.Text.TitleSize)


%%% C: Peaks in high frequencies
NoiseIdx = NoisePeriodicPeaks.Frequency >58 & NoisePeriodicPeaks.Frequency<62;

PlotProps.Scatter.Alpha = .3;
chART.sub_plot([], Grid, [1, 3], [], true, 'C', PlotProps);

% plot line noise
LineNoise = NoisePeriodicPeaks(NoiseIdx, :);

hold on
scatter(LineNoise.Frequency, LineNoise.BandWidth, 10, [.5 .5 .5], ...
    'MarkerEdgeAlpha', .1, 'Marker', '.')

% plot all else
Gamma = NoisePeriodicPeaks(~NoiseIdx, :);
plot_periodicpeaks(Gamma, [20 100], YLims, CLims, false, PlotProps);

title('Gamma, unprocessed',  'FontSize', PlotProps.Text.TitleSize)


%%% D: plot individual examples

MiniGrid = [1 4];
PlotPropsTemp = PlotProps;
PlotPropsTemp.Figure.Padding = 0;
PlotPropsTemp.yPadding = 0;
PlotPropsTemp.xPadding = 0;

ExampleParticipants = {'NDARHF854JX7', 'NDARMH180XE5', 'NDARJR579FW7', 'NDARXN719LXU'};

chART.sub_plot([], Grid, [2, 1], [], true, 'D', PlotProps);
axis off % just a black spot for the D letter

Space = chART.sub_figure(Grid, [2 1], [1 3], '', PlotPropsTemp, [], 1);
PlotProps.Axes.xPadding = 2;
for ParticipantIdx = 1:numel(ExampleParticipants)

    % load in data
    Participant = ExampleParticipants{ParticipantIdx};
    Info = Metadata(find(strcmp(Metadata.EID, Participant), 1, 'first'), :);

    load(fullfile(Paths.Datasets,'EEG\', Participant, 'EEG', 'raw', 'mat_format', 'RestingState.mat'), 'EEG')

    % computer power
    [RawPower, Frequencies] = oscip.compute_power(EEG.data, EEG.srate, 8, .9);

    % plot
    chART.sub_plot(Space, MiniGrid, [1, ParticipantIdx], [], 0.05, '', PlotProps);

    plot(Frequencies, RawPower, 'Color',  [.5 .5 .5 .1])

    chART.set_axis_properties(PlotProps)
    box off
    set(gca, 'YScale', 'log', 'XScale', 'log');
    xticks([0 1 10 30 60 120])
    title([string(Participant); [' (\iota=', num2str(round(Info.IotaFrequency, 1)),  ' Hz; \alpha=',num2str(round(Info.AlphaFrequency, 1)) ' Hz)']], ...
        'FontWeight','normal', 'FontSize',PlotProps.Text.AxisSize)
    axis tight
    ylim(quantile(RawPower(:), [.02, .999]))
    xlabel('Frequency (Hz)')
    if ParticipantIdx ==1
        ylabel('Power')
    end
    xlim([1 250])
end

chART.save_figure('Unprocessed', ResultsFolder, PlotProps)


%% iota and alpha correlation
clc

nTot = size(Metadata, 1);
nAlpha = nnz(~isnan(Metadata.AlphaFrequency));
disp(['#alpha: ', num2str(nAlpha), ' (', num2str(round(100*nAlpha/nTot)), '%)'])

nTot = size(Metadata, 1);
nIota = nnz(~isnan(Metadata.IotaFrequency));
disp(['#iota: ', num2str(nIota), ' (', num2str(round(100*nIota/nTot)), '%)'])

nTot = size(Metadata, 1);
nBoth = nnz(~isnan(Metadata.IotaFrequency) & ~isnan(Metadata.AlphaFrequency));
disp(['#iota & alpha: ', num2str(nBoth), ' (', num2str(round(100*nBoth/nTot)), '%)'])


disp('_____________')


[Rho, p] = corr(Metadata.AlphaFrequency, Metadata.IotaFrequency, 'rows', 'complete');
disp(['Alpha x iota: r=', num2str(round(Rho, 2)), ', p=', num2str(round(p, 3))])

[Rho, p] = corr(Metadata.AlphaFrequency, Metadata.Age, 'rows', 'complete');
disp(['Alpha x age: r=', num2str(round(Rho, 2)), ', p=', num2str(round(p, 3))])


disp('_____________')


