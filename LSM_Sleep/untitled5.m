figure
hold on

Colors = chART.utils.resize_colormap(PlotProps.Color.Maps.Rainbow, nParticipants);

for BandIdx = 1:size(CenterFrequencies, 3)
    for ParticipantIdx = 1:size(CenterFrequencies, 1)
        plot(Stages, squeeze(CenterFrequencies(ParticipantIdx, :, BandIdx)), '-o', ...
            'Color', [Colors(ParticipantIdx, :), .5], 'LineWidth',2)
    end
end



%%

Grid = [nBands, nParticipants];

for StageIdx = 1:nStages
    figure('Units','normalized', 'OuterPosition',[0 0 1 .5])
    for BandIdx = 1:nBands
        for ParticipantIdx = 1:nParticipants
            Data = squeeze(PeriodicTopographies(ParticipantIdx, StageIdx, BandIdx, :));
            if all(isnan(Data)|Data==0)
                continue
            end
            chART.sub_plot([], Grid, [BandIdx, ParticipantIdx], [], false, '', PlotProps);
            chART.plot.eeglab_topoplot(Data, Chanlocs, [], [], '', 'Linear', PlotProps);
        end
    end
end


%%

Colors = chART.utils.resize_colormap(PlotProps.Color.Maps.Rainbow, nParticipants);

PlotStages = [4 5 2 1];
figure
for PlotIdx = 1:numel(PlotStages)
    subplot(2, 2, PlotIdx)
    hold on
    for ParticipantIdx = 1:nParticipants
    plot(Frequencies, squeeze(AllSpectra(ParticipantIdx, PlotStages(PlotIdx), :)), 'Color',[Colors(ParticipantIdx, :), .5])
    end
    set(gca,'YScale', 'log', 'XLim', [3 45])
end
%
% Grid = [2 2];
% PlotStages = [4 5; 2 1];
% 
% figure
% for R = 1:2
%     for C = 1:2
%     chART.sub_plot([], Grid, [R, C], [], true, 'A', PlotProps);
% 
% plot(Frequencies, squeeze(AllSpectra(:, PlotStages(R, C), :)))
% set(gca,'YScale', 'log')
%     end
% end


%%

Grid = [nBands, nStages];


figure('Units','centimeters', 'OuterPosition',[0 0 30 30])
for BandIdx = 1:nBands
    for StageIdx = 1:nStages
        % Data = squeeze(mean(PeriodicTopographies(:, StageIdx, BandIdx, :), 1, 'omitnan'));
         Data = squeeze(mean(CustomTopographies(:, StageIdx, BandIdx, :), 1, 'omitnan'));
        if all(isnan(Data)|Data==0)
            continue
        end
        chART.sub_plot([], Grid, [BandIdx, StageIdx], [], false, '', PlotProps);
        chART.plot.eeglab_topoplot(Data, Chanlocs, [], [], '', 'Linear', PlotProps);
        title([BandLabels{BandIdx}, ' ', StageLabels{StageIdx}])
    end
end



%% Table of center frequencies

AllCenterFrequencies = table();
    for BandIdx = 1:nBands
AllCenterFrequencies.Band(BandIdx) = BandLabels(BandIdx);
for StageIdx = 1:nStages
    AllCenterFrequencies.(StageLabels{StageIdx})(BandIdx) = nnz(~isnan(CenterFrequencies(:, StageIdx, BandIdx)));

    end
end

disp(AllCenterFrequencies)


