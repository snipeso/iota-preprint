close all
for PIdx = 1:numel(Participants)
    figure
    Data = squeeze(PeriodicTopographies(PIdx, 5, 5, :));
    chART.plot.eeglab_topoplot(Data, Chanlocs, [], [], '', 'Linear', PlotProps)
    colorbar
        title(Participants{PIdx})
end