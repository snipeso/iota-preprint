function EEG = eeglab_ica(EEG)
% EEG = eeglab_ica(EEG)
%
% Runs EEGLAB's runica for detecting independent components, after first
% calculating the rank of the data, so that it can first do "pca rank
% reduction"
%
% from iota-neurophys, Snipes, 2024

% run ICA (takes a while)
Rank = sum(eig(cov(double(EEG.data'))) > 1E-7);
if Rank ~= size(EEG.data, 1)
    warning(['Applying PCA reduction for ', File])
end

% calculate components
EEG = pop_runica(EEG, 'runica', 'pca', Rank);

% classify components
EEG = iclabel(EEG);