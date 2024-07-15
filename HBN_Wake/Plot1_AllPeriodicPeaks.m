% plots the distribution of periodic peaks in the whole HBN dataset.
clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = HBNParameters();
Paths = Parameters.Paths;

CacheDir = Paths.Cache;
SourceName = 'Clean';
% SourceName = 'Unfiltered';
CacheName = ['PeriodicParameters_', SourceName, '.mat'];

load(fullfile(CacheDir, CacheName), 'PeriodicPeaks', 'Metadata')


%%% paths
ResultsFolder = fullfile(Paths.Results, 'AllPeaks');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% plot


%% Figure 2

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.xPadding = 30;
PlotProps.Axes.yPadding = 5;
CLims = [5 21];
Grid = [1, 2];

PeriodicPeaks = sortrows(PeriodicPeaks, 'Age', 'ascend');

figure('Units','centimeters', 'Position', [0 0 22 10])
chART.sub_plot([], Grid, [1, 1], [], true, 'A', PlotProps);
 plot_periodicpeaks(PeriodicPeaks, CLims, PlotProps)
title('Periodic peaks',  'FontSize', PlotProps.Text.TitleSize)



% correlation iota amplitude and age
Frequencies = 1:22;
IotaPeakParams = PeriodicPeaks(PeriodicPeaks.Frequency>25 & PeriodicPeaks.Frequency<=35 & PeriodicPeaks.BandWidth < 4, :);
IotaPeakParams = one_row_each(IotaPeakParams, 'EID');
IotaByAge = tabulate(discretize(IotaPeakParams.Age, Frequencies));
IotaByAge = IotaByAge(:, 2);


AllParticipants = one_row_each(PeriodicPeaks, 'EID');
ParticipantsByAge = tabulate(discretize(AllParticipants.Age,Frequencies));
ParticipantsByAge = ParticipantsByAge(:, 2);


chART.sub_plot([], Grid, [1, 2], [], true, 'B', PlotProps);
chART.plot.stacked_bars([IotaByAge, ParticipantsByAge-IotaByAge], [], [], {'Iota', 'No iota'}, PlotProps, [0.4 0.4 0.4; .8 .8 .8])
ylabel('# participants')
axis square
xlabel('Age')
Axes2 = gca;
Axes2.Position(3:4) = Axes.Position(3:4);
Axes2.Position(1) = Axes2.Position(1)+ .04;
legend('Location', 'northwest')
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
chART.save_figure('AllPeriodicPeakBandwidths', ResultsFolder, PlotProps)



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
