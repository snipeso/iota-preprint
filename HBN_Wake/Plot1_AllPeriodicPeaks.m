% plots the distribution of periodic peaks in the whole HBN dataset.
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


%% Figure 2


% load in analyses on preprocessed data
CacheName = 'PeriodicParameters_Clean.mat';
load(fullfile(CacheDir, CacheName), 'PeriodicPeaks', 'Metadata')

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.yPadding = 5;
PlotProps.Scatter.Alpha = .1;
CLims = [5 21];
XLims = [3 50];
YLims = [.5 12.1];
Grid = [1, 2];


PeriodicPeaks = sortrows(PeriodicPeaks, 'Age', 'ascend'); % sort by age so that the rarer adults are on top

figure('Units','centimeters', 'Position', [0 0 22 10])
chART.sub_plot([], Grid, [1, 1], [], 1, 'A', PlotProps);
Axes = plot_periodicpeaks(PeriodicPeaks, XLims, YLims, CLims, true, PlotProps);
Axes.Position(1) = Axes.Position(1)- .015;
title('Wake periodic peaks',  'FontSize', PlotProps.Text.TitleSize)
set(gca, 'TickDir', 'in')
% axis square

% correlation iota amplitude and age
Frequencies = 1:22;
IotaPeakParams = PeriodicPeaks(PeriodicPeaks.Frequency>25 & PeriodicPeaks.Frequency<=35 & PeriodicPeaks.BandWidth < 4, :);
IotaPeakParams = one_row_each(IotaPeakParams, 'EID');
IotaByAge = tabulate(discretize(IotaPeakParams.Age, Frequencies));
IotaByAge = IotaByAge(:, 2);


AllParticipants = one_row_each(PeriodicPeaks, 'EID');
ParticipantsByAge = tabulate(discretize(AllParticipants.Age,Frequencies));
ParticipantsByAge = ParticipantsByAge(:, 2);


chART.sub_plot([], Grid, [1, 2], [], 1.5, 'B', PlotProps);
chART.plot.stacked_bars([IotaByAge, ParticipantsByAge-IotaByAge], [], [], {'Iota', 'No iota'}, PlotProps, [0.4 0.4 0.4; .8 .8 .8])
ylabel('# participants')
% axis square
xlabel('Age')
legend('Location', 'northeast')
ylim([0 450])


yyaxis right
Red = chART.color_picker(1, '', 'red');
Axes2 = gca;
Axes2.YAxis(2).Color = Red;
plot(Frequencies(1:end-1), 100*IotaByAge./ParticipantsByAge, '-o', 'MarkerFaceColor', Red, 'Color',Red, 'HandleVisibility', 'off')
ylabel('%')
xlim([4 22])
box off
chART.set_axis_properties(PlotProps)
title('Participants with iota', 'FontSize', PlotProps.Text.TitleSize)
Axes2 = gca; 
Axes2.Units = 'pixels';
Axes2.Position(3) = Axes2.Position(3)-PlotProps.Axes.xPadding*2;
Axes2.Position(1) = Axes2.Position(1)+ PlotProps.Axes.xPadding;
Axes2.Units = 'normalized';

set(gca, 'TickDir', 'in')
chART.save_figure('AllPeriodicPeakBandwidths', ResultsFolder, PlotProps)


%% Periodic peaks detected in un processed data

PlotProps = Parameters.PlotProps.Manuscript;

% PlotProps.Debug = true;
CLims = [5 21];
XLims = [3 50];
YLims = [.5 12.1];
Grid = [2, 3];
LabelSpace = .5;

% load in analyses on unfiltered data
CacheName = 'PeriodicParameters_Unfiltered.mat';
load(fullfile(CacheDir, CacheName), 'NoisePeriodicPeaks', 'PeriodicPeaks')
% UnfilteredPeriodicPeaks = NoisePeriodicPeaks;
UnfilteredPeriodicPeaks = PeriodicPeaks;

UnfilteredPeriodicPeaks = sortrows(UnfilteredPeriodicPeaks, 'Age', 'ascend'); % sort by age so that the rarer adults are on top
NoisePeriodicPeaks = sortrows(NoisePeriodicPeaks, 'Age', 'ascend'); % sort by age so that the rarer adults are on top


figure('Units','centimeters', 'Position', [0 0 30 17])
chART.sub_plot([], Grid, [1, 1], [], LabelSpace, 'A', PlotProps);
hold on
plot([8 13], [8 13]*3, 'Color', [.4 .4 .4], 'LineWidth', 2)
scatter(Metadata.AlphaFrequency, Metadata.IotaFrequency, 50, Metadata.Age, 'filled', 'MarkerFaceAlpha', .2)

chART.set_axis_properties(PlotProps)
xlabel('Alpha peak frequency (Hz)')
ylabel('Iota peak frequency (Hz)')
xlim([8 13])
ylim([25 35])
clim(CLims)
title('Alpha vs iota')

PlotProps.Scatter.Alpha = .07;
chART.sub_plot([], Grid, [1, 2], [], LabelSpace, 'B', PlotProps);
plot_periodicpeaks(UnfilteredPeriodicPeaks, XLims, YLims, CLims, false, PlotProps);
title('Periodic peaks, unprocessed data',  'FontSize', PlotProps.Text.TitleSize)



NoiseIdx = NoisePeriodicPeaks.Frequency >58 & NoisePeriodicPeaks.Frequency<62;
LineNoise = NoisePeriodicPeaks(NoiseIdx, :);
Gamma = NoisePeriodicPeaks(~NoiseIdx, :);

PlotProps.Scatter.Alpha = .3;
chART.sub_plot([], Grid, [1, 3], [], true, 'C', PlotProps);

hold on
scatter(LineNoise.Frequency, LineNoise.BandWidth, 10, [.5 .5 .5], ...
     'MarkerEdgeAlpha', .1, 'Marker', '.')
plot_periodicpeaks(Gamma, [20 100], YLims, CLims, false, PlotProps);

title('Gamma, unprocessed',  'FontSize', PlotProps.Text.TitleSize)

% PlotProps.Axes.yPadding = 60;

chART.sub_plot([], Grid, [2, 1], [], true, 'D', PlotProps);
axis off % just a black spot for the D letter

ExampleParticipants = {'NDARHF854JX7', 'NDARMH180XE5', 'NDARJR579FW7', 'NDARXN719LXU'};

MiniGrid = [1 4];
PlotPropsTemp = PlotProps;
PlotPropsTemp.Figure.Padding = 0;
PlotPropsTemp.yPadding = 0;
PlotPropsTemp.xPadding = 0;
Space = chART.sub_figure(Grid, [2 1], [1 3], '', PlotPropsTemp, [], 1);
PlotProps.Axes.xPadding = 2;
for ParticipantIdx = 1:numel(ExampleParticipants)
    Participant = ExampleParticipants{ParticipantIdx};
    Info = Metadata(find(strcmp(Metadata.EID, Participant), 1, 'first'), :);

    load(fullfile('E:\Raw\EEG\', Participant, 'EEG', 'raw', 'mat_format', 'RestingState.mat'), 'EEG')
    [RawPower, Frequencies] = oscip.compute_power(EEG.data, EEG.srate, 8, .9);

    chART.sub_plot(Space, MiniGrid, [1, ParticipantIdx], [], 0.05, '', PlotProps);

    plot(Frequencies, RawPower, 'Color',  [.5 .5 .5 .1])
    chART.set_axis_properties(PlotProps)
    box off
    set(gca, 'YScale', 'log', 'XScale', 'log');
    xticks([0 1 10 30 60 120])
    title([string(Participant); [' (\iota=', num2str(round(Info.IotaFrequency, 1)),  ' Hz; \alpha=',num2str(round(Info.AlphaFrequency, 1)) ' Hz)']], ...
        'FontWeight','normal', 'FontSize',PlotProps.Text.AxisSize)
    axis tight
        % yticks([0, 1, 10, 100, 1000])
    ylim(quantile(RawPower(:), [.02, .999]))
    xlabel('Frequency (Hz)')
    if ParticipantIdx ==1
    ylabel('Power')
    end
    xlim([1 250])
end

chART.save_figure(['Example_', Participant, '_Raw'], ResultsFolder, PlotProps)


%% iota and alpha correlation
clc

[Rho, p] = corr(Metadata.AlphaFrequency, Metadata.IotaFrequency, 'rows', 'complete');
disp(['Alpha x iota: r=', num2str(round(Rho, 2)), ', p=', num2str(round(p, 3))])

[Rho, p] = corr(Metadata.AlphaFrequency, Metadata.Age, 'rows', 'complete');
disp(['Alpha x age: r=', num2str(round(Rho, 2)), ', p=', num2str(round(p, 3))])

[Rho, p] = corr(Metadata.IotaFrequency, Metadata.Age, 'rows', 'complete');
disp(['Iota x age: r=', num2str(round(Rho, 2)), ', p=', num2str(round(p, 3))])

[Rho, p] = corr(Metadata.IotaPower, Metadata.Age, 'rows', 'complete');
disp(['Iota power x age: r=', num2str(round(Rho, 2)), ', p=', num2str(round(p, 3))])

%% demographics

% clean up mistakes with diagnoses
Bad = cellfun(@numel, Metadata.Diagnosis)==0;
Metadata.Diagnosis(Bad) = repmat({'.'}, nnz(Bad), 1);

Bad = cellfun(@numel, Metadata.Diagnosis_Category)==0;
Metadata.Diagnosis_Category(Bad) = repmat({'.'}, nnz(Bad), 1);

% very quick check of how many adhd are in the data
Total = size(Metadata, 1);
disp(['ADHD: ', num2str(round(100*nnz(contains(Metadata.Diagnosis, 'ADHD'))/Total)), '%'])

tabulate(Metadata.Diagnosis)
