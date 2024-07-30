function plot_peaks_sleep(PeriodicPeaks, Scoring, PlotProps, Slopes)
% PeriodicPeaks is either a P x T x 3 matrix, or a Ch x T x 3 matrix
% Scoring is a 1 x T matrix or a P x T matrix
% from iota-preprint, Snipes, 2024.



if size(Scoring, 1) ~= size(PeriodicPeaks, 1)
    ScoringMatrix = repmat(Scoring, size(PeriodicPeaks, 1), 1);
else
    ScoringMatrix = Scoring;
end

% ScoringLabels = flip({'R', 'W', 'N1', 'N2', 'N3'});
% Values = flip([1 0 -1 -2 -3]);
% Colors = flip(get_stage_colors());
ScoringLabels = {'R', 'W', 'N1', 'N2', 'N3'};
Values = [1 0 -1 -2 -3];
Colors = get_stage_colors();
hold on
for StageIdx = 1:numel(ScoringLabels)
    F = [];
    BW = [];
    P = [];

    for ParticipantIdx = 1:size(PeriodicPeaks, 1)
        if exist('Slopes', 'var') && ~isempty(Slopes)
            Sc = ScoringMatrix(ParticipantIdx, :)==Values(StageIdx) & PeriodicPeaks(ParticipantIdx, :, 3)<5;
            BW = cat(1, BW, Slopes(ParticipantIdx, Sc)');
        else
            Sc = ScoringMatrix(ParticipantIdx, :)==Values(StageIdx);
            BW = cat(1, BW, PeriodicPeaks(ParticipantIdx, Sc, 3)');
        end

        F = cat(1, F, PeriodicPeaks(ParticipantIdx, Sc, 1)');
        P = cat(1, P, PeriodicPeaks(ParticipantIdx, Sc, 2)');
    end


    scatter(F, BW, P*2, 'filled', 'MarkerFaceAlpha', .02, 'MarkerFaceColor', Colors(StageIdx, :), 'HandleVisibility','off');
    scatter(0, 0, nan, 'MarkerFaceColor', Colors(StageIdx, :), 'MarkerEdgeColor','none');
end

legend(ScoringLabels)
chART.set_axis_properties(PlotProps)


if exist('Slopes', 'var') && ~isempty(Slopes)
    ylabel('Slope (a.u.)')
    ylim([.5 4.5])
    set(legend, 'ItemTokenSize', [10 10], 'location', 'southeast')
else
    ylim([1 12])
    ylabel('Bandwidth (Hz)')
    set(legend, 'ItemTokenSize', [10 10], 'location', 'northeast')
end

ylim([0.5 12])
xticks([10:10:50])
yticks(0:3:12)
grid on

xlabel('Center frequency (Hz)')
