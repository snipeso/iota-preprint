% this script removes manually detected artefacts, re-references to the
% average, and saves the data with the scoring.
% From iota-neurophys, Snipes, 2024.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = LSMParameters();

Paths  = P.Paths;
Refresh = false;
Task = P.Task;
EEG_Channels = P.Channels;
Format = 'Minimal'; % chooses which filtering to do
RemovalThreshold = .1; % percent of data before completely removing channel/epoch

ScoringIndexes = -3:1:1;
ScoringLabels = {'N3', 'N2', 'N1', 'W', 'R'};

% locations
SourceScoring =  fullfile(Paths.Core, 'Outliers', Task);
SourceEEG = fullfile(Paths.Preprocessed, Format, 'MAT', Task);
Files = list_filenames(SourceEEG);

Destination = fullfile(Paths.Preprocessed,  Format, 'Clean2', Task);

if ~exist(Destination, 'dir')
    mkdir(Destination)
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run

load('StandardChanlocs128.mat', 'StandardChanlocs')
load('Cz.mat', 'CZ')
FinalChanlocs = StandardChanlocs;
FinalChanlocs(ismember({StandardChanlocs.labels}, string(EEG_Channels.notEEG))) = [];
FinalChanlocs(end+1) = CZ;

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

    % remove bad channels
    BadChannels = all(BadSegments==1, 2);
    EEG = pop_select(EEG, 'nochannel', find(BadChannels));

    % average-reference data
    EEG = add_cz(EEG);
    EEG = pop_reref(EEG, []);

    % interpolate all but the non-eeg channels, and remove also from
    % artefact matrices.
    EEG = pop_interp(EEG, FinalChanlocs);
    Artefacts(ismember({StandardChanlocs.labels}, string(EEG_Channels.notEEG)), :) = [];
    BadSegments(ismember({StandardChanlocs.labels}, string(EEG_Channels.notEEG)), :) = [];
    Artefacts(end+1, :) = 0; %#ok<SAGROW>
    BadSegments(end+1, :) = 0; %#ok<SAGROW>

    % save
    save(fullfile(Destination, File), 'EEG', 'Artefacts', 'BadSegments', 'Scoring', 'ScoringLabels', 'ScoringIndexes', '-v7.3')
    disp(['Finished ', File])
end



