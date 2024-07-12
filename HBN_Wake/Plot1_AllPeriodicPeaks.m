
clear
clc
close all

Parameters = HBNParameters();
Paths = Parameters.Paths;

CacheDir = Paths.Cache;
SourceName = 'Unfiltered';
CacheName = ['PeriodicParameters_', SourceName, '.mat'];

load(fullfile(CacheDir, CacheName), 'PeakParams', 'Metadata')


%%% paths
ResultsFolder = fullfile(Paths.Results, 'AllPeaks');
if ~exist(ResultsFolder,'dir')
    mkdir(ResultsFolder)
end

Bad = cellfun(@numel, Metadata.Diagnosis)==0;
Metadata.Diagnosis(Bad) = repmat({'.'}, nnz(Bad), 1);

Bad = cellfun(@numel, Metadata.Diagnosis_Category)==0;
Metadata.Diagnosis_Category(Bad) = repmat({'.'}, nnz(Bad), 1);

%% demographics
Total = size(Metadata, 1);
disp(['ADHD: ', num2str(round(100*nnz(contains(Metadata.Diagnosis, 'ADHD'))/Total)), '%'])


tabulate(Metadata.Diagnosis)

%% all recordings
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.xPadding = 30;
PlotProps.Axes.yPadding = 5;
CLims = [5 21];
Grid = [1, 2];

PeakParams = sortrows(PeakParams, 'Age', 'ascend');

% figure('Units','centimeters', 'Position', [0 0 11 10])
figure('Units','centimeters', 'Position', [0 0 22 10])
chART.sub_plot([], Grid, [1, 1], [], true, 'A', PlotProps);
% scatter(PeakParams.Frequency, PeakParams.BandWidth, PeakParams.Power*200, 'filled', 'MarkerFaceAlpha', .15, 'MarkerFaceColor', chART.color_picker(1))
scatter(PeakParams.Frequency, PeakParams.BandWidth, PeakParams.Power*100, PeakParams.Age, 'filled', 'MarkerFaceAlpha', .1)
chART.set_axis_properties(PlotProps)
xlabel('Frequency (Hz)')
ylabel('Bandwidth (Hz)')
% ylim([.5 12.5])
ylim([.5 12.1])
xlim([3 50])
axis square
Bar = colorbar;
Axes = gca;
colorbar off
PlotProps.Colorbar.Location = 'eastoutside';
PlotProps.Color.Steps.Rainbow = numel(5:1:22);
chART.plot.pretty_colorbar('Rainbow', CLims, 'Age', PlotProps)
% ylabel(Bar, 'Age', 'FontName', PlotProps.Text.FontName, ...
%     'FontSize', PlotProps.Text.AxisSize,'Color', 'k')
% colormap(PlotProps.Color.Maps.Rainbow)
clim(CLims)
title('Periodic peaks',  'FontSize', PlotProps.Text.TitleSize)

yyaxis right
histogram(PeakParams.Frequency, 3:1:50, 'FaceColor', [.8 .8 .8], 'EdgeColor','none')
ylim([0 8000])
set(gca, 'YTick', [], 'YColor', 'none', 'YDir', 'reverse')

%%
% correlation iota amplitude and age
Frequencies = 1:22;
IotaPeakParams = PeakParams(PeakParams.Frequency>25 & PeakParams.Frequency<=35 & PeakParams.BandWidth < 4, :);
IotaPeakParams = one_row_each(IotaPeakParams, 'EID');
IotaByAge = tabulate(discretize(IotaPeakParams.Age, Frequencies));
IotaByAge = IotaByAge(:, 2);


AllParticipants = one_row_each(PeakParams, 'EID');
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
plot(Frequencies(1:end-2), 100*IotaByAge./ParticipantsByAge, '-o', 'MarkerFaceColor', Red, 'Color',Red, 'HandleVisibility', 'off')
ylabel('%')
xlim([4 22])
box off
chART.set_axis_properties(PlotProps)
title('Participants with iota', 'FontSize', PlotProps.Text.TitleSize)
chART.save_figure('AllPeriodicPeakBandwidths', ResultsFolder, PlotProps)
