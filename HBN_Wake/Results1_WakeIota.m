% All the results with the whole HBN dataset (demographics, spectra,
% topographies, etc).
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
Channels = Parameters.Channels;
Iota = [25 35];

%%% paths
ResultsFolder = fullfile(Paths.Results, 'AllPeaks');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% plot


%% Participant demographics
clc

CacheName = 'PeriodicParameters_Clean.mat';
load(fullfile(CacheDir, CacheName), 'Metadata')

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

Metadata.Diagnosis_Category(strcmp(Metadata.Diagnosis_Category, '.')) = {'No Diagnosis Given'};

% all diagnostic criteria
AllDiagnoses = tabulate(Metadata.Diagnosis_Category);
AllDiagnoses = cell2table(AllDiagnoses, 'VariableNames', {'Diagnosis', 'Tot', '%'});

AllDiagnoses = sortrows(AllDiagnoses, '%', 'descend');
disp(AllDiagnoses)

writetable(AllDiagnoses, fullfile(ResultsFolder, 'Demographics.csv'))

disp('________________________')

% only neurodevelopmental

Metadata.Diagnosis(contains(Metadata.Diagnosis, 'ADHD') | contains(Metadata.Diagnosis, 'Attention-Deficit')) = {'ADHD'};
AllDiagnoses = tabulate(Metadata.Diagnosis(strcmp(Metadata.Diagnosis_Category, 'Neurodevelopmental Disorders')));

AllDiagnoses = cell2table(AllDiagnoses, 'VariableNames', {'Diagnosis', 'Tot', '%'});

AllDiagnoses = sortrows(AllDiagnoses, '%', 'descend');
disp(AllDiagnoses)

writetable(AllDiagnoses, fullfile(ResultsFolder, 'DemographicsNeurodevelopmental.csv'))

%% Figure 1: iota in wake

% load in analyses on preprocessed data
CacheName = 'PeriodicParameters_Clean.mat';
load(fullfile(CacheDir, CacheName), 'PeriodicPeaks', 'Metadata', 'AllSpectra', 'Frequencies')


% sort rows by age so that the rarer adults come out on top
PeriodicPeaks = sortrows(PeriodicPeaks, 'Age', 'ascend'); % sort by age so that the rarer adults are on top

%%%%%%%%%%%%%%%%%%%
%%% plot

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.yPadding = 5;
PlotProps.Scatter.Size = 30;

Grid = [1, 4];
XLim = [3 50];
Red = chART.color_picker(1, '', 'red');

figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width*1.2 PlotProps.Figure.Width/3])

%%% A: Power spectra
chART.sub_plot([], Grid, [1, 1], [], 1, 'A', PlotProps);
plot(Frequencies, log10(AllSpectra), 'Color', [.3 .3 .3 .05])
hold on
chART.set_axis_properties(PlotProps)
plot(Frequencies, log10(mean(AllSpectra, 'omitnan')), 'Color', Red, 'LineWidth', 4)
xlim(XLim)
xticks([1 10 20 30 40 50])
ylim([-2.1 2])
xlabel('Frequency (Hz)')
ylabel('Log power')
box off


%%% B: Scatter plot of all periodic peaks
PlotProps.Scatter.Alpha = .1;
CLims = [5 21];
YLims = [.3 12.3];

chART.sub_plot([], Grid, [1, 2], [], .2, 'B', PlotProps);
Axes = plot_periodicpeaks(PeriodicPeaks, XLim, YLims, CLims, true, PlotProps);
Axes.Units = 'normalized';
Axes.Position(1) = Axes.Position(1)-.015; % move it a little bit
Axes.Position(3) = Axes.Position(3)+0.0629;


%%% C: Proportion of iota in population by age

% set up age resolution
AgeBins = [0:2:18, 22];
Labels = AgeBins(1:end-1)+diff(AgeBins)/2;
Labels(end) = 19;

% gather participants with iota
IotaPeriodicPeaks = PeriodicPeaks(PeriodicPeaks.Frequency>Iota(1) & PeriodicPeaks.Frequency<=Iota(2) & PeriodicPeaks.BandWidth < 4, :);
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

% shift a bit
Axes2.Units = 'normalized';
Axes2.Position(1) = Axes2.Position(1) + .05;
Axes2.Position(3) = Axes2.Position(3) - .045;


%%% D: average topography
PlotProps.Colorbar.Location = 'eastoutside';
load(fullfile(CacheDir, CacheName), 'CustomTopographies', 'Chanlocs')

Keep = labels2indexes(Channels.TopoPlot, Chanlocs);
Chanlocs = Chanlocs(Keep);
CustomTopographies = CustomTopographies(:, :, Keep);

BandLabels = fieldnames(Parameters.Bands);
IotaIdx = find(strcmp(BandLabels, 'Iota'));

IotaTopo = squeeze(CustomTopographies(:, IotaIdx, :));

chART.sub_plot([], Grid, [1, 4], [], 3.5, 'D', PlotProps);
chART.plot.eeglab_topoplot(mean(IotaTopo, 1, 'omitnan'), Chanlocs, [], [.15 .38], ...
    'Periodic power', 'Linear', PlotProps)
colormap(PlotProps.Color.Maps.Rainbow) % needed to reset colormaps; eeglab's topoplot changes the colormap for the whole figure
set(gca, 'colormap', PlotProps.Color.Maps.Linear)

chART.save_figure('AllPeriodicPeakBandwidths', ResultsFolder, PlotProps)



%% identify peak locations

MeanTopo = mean(IotaTopo, 1, 'omitnan');

Topography = table();
Topography.Labels = {Chanlocs.labels}';
Topography.Iota = MeanTopo';

disp(sortrows(Topography, 'Iota', 'descend'))


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
disp(['Iota frequency x age: r=', num2str(round(Rho, 3)), ', p=', num2str(round(p, 3))])

[Rho, p] = corr(Metadata.IotaPower, Metadata.Age, 'rows', 'complete');
disp(['Iota power x age: r=', num2str(round(Rho, 3)), ', p=', num2str(round(p, 3))])

