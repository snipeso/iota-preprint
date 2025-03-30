% this script removes manually detected artefacts, re-references to the
% average, and saves the data with the scoring

clear
clc
close all


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = LSMParameters();

Paths  = P.Paths;
Refresh = false;
Task = P.Task;
Format = 'Minimal'; % chooses which filtering to do
RemovalThreshold = .1;

ScoringIndexes = -3:1:1;
ScoringLabels = {'N3', 'N2', 'N1', 'W', 'R'};

% locations
SourceScoring =  fullfile(Paths.Core, 'Outliers', Task);
SourceEEG = fullfile(Paths.Preprocessed, Format, 'MAT', Task);
Files = list_filenames(SourceEEG);

Destination = fullfile(Paths.Preprocessed,  Format, 'Clean', Task);

if ~exist(Destination, 'dir')
    mkdir(Destination)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run

for FileIdx = 1:numel(Files)

    % check if destination file already exists
    File = Files{FileIdx};
    if ~Refresh && exist(fullfile(Destination, File), 'file')
        disp(['Already did ', char(File)])
        continue
    end

    % load in EEG
    load(fullfile(SourceEEG, File), 'EEG')
    EEG = eeg_checkset(EEG);

    % load in artefacts
    Filename_Cuts = replace(File, '.mat', '_Cutting_artndxn.mat');

    load(fullfile(SourceScoring, Filename_Cuts), 'artndxn', 'visnum', 'scoringlen')
    Artefacts = ~artndxn; % artndxn indicates 1 to keep and 0 to remove
    Scoring = visnum;


    % reorder wake and REM, which was saved as 1 and 0, but should be
    % switched
    Scoring(Scoring==0) = 2;
    Scoring(Scoring==1) = 0;
    Scoring(Scoring==2) = 1;

    % determine whether to remove channel or epoch
    BadSegments = remove_channel_or_window(Artefacts, RemovalThreshold);

    % for bad channels, remove and interpolate
    BadChannels = all(BadSegments==1, 2);
    EEG = pop_interp(EEG, find(BadChannels));

    % average-reference data
    EEG = add_cz(EEG);
    EEG = pop_reref(EEG, []);

    % save
    save(fullfile(Destination, File), 'EEG', 'Artefacts', 'BadSegments', 'Scoring', 'ScoringLabels', 'ScoringIndexes', '-v7.3')
    disp(['Finished ', File])
end



