
figure('Units','normalized','OuterPosition',[0 0 1 1])
PlotIdx = 1;
for FileIdx = 1000:size(Metadata,1)
        Data = squeeze(CustomTopographies(FileIdx, IotaIdx, :));
    if isnan(Metadata.IotaFrequency(FileIdx)) || all(isnan(Data))
        continue
    end

    subplot(7, 10, PlotIdx)

    chART.plot.eeglab_topoplot(Data, Chanlocs, [], [], '', 'Linear', PlotProps)
    title(Metadata.EID{FileIdx})
% title([Metadata.EID{FileIdx}, ' (age=', num2str(round(Metadata.Age(FileIdx))), '; hz=', num2str(round(Metadata.IotaFrequency(FileIdx))) , ')'])
    if PlotIdx == 7*10
figure('Units','normalized','OuterPosition',[0 0 1 1])
PlotIdx = 1;
    else
        PlotIdx = PlotIdx+1;
    end
end