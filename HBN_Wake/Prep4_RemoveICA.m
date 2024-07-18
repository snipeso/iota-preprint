% Removes bad components in EEG automatically, based on ICLabel's
% classification.
%
% From iota-preprocessing by Sophia Snipes, 2024

close all
clc
clear

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = HBNParameters();
Paths = P.Paths;
Parameters = P.Parameters;
EEG_Channels = P.Channels;
Tasks = P.Tasks(1);

Refresh = true;

Spread = 0; % how many times more the main component has to be larger than the next largest component ("Spread" is a reference to the italian term "spread" referring to the difference between the yields of italian and german bonds)
SlopeRange = [8 30];
MuscleSlopeMin = .5;
ChopEdge = 2; % in seconds, cut off these many seconds at the beginning and end of recordings
WindowLength = 3; % s, bad time windows
RemoveComps = [2, 3, 4, 6]; % 1:Brain, 2:Muscle, 3:Eye, 4:Heart, 5:Line Noise, 6:Channel Noise, 7:Other
MinTime = P.MinTime; % minimum time to keep data in seconds
MinNeighborCorrelation = .3;
MinChannels = P.MinChannels; % maximum number of channels that can be removed
CorrelationFrequencyRange = [1 40];
MaxPorportionUniqueCorr = .02; % the minimum number of unique correlation values across channels when rounding correlations to 3 decimal points

% EEGLAB preprocessing
MinCorrelation =    0.500; % their defaults. Somehow, the function for finding bad channels without using channel locations worked a lot better
NoLocsChannelCritExcluded =    0.1000; % their defaults
MinDataKeep =  0.3000; %  this should be between .1 or .3, with smaller being stricter cleaning
WindowCriteriaTolerances = [-Inf, 12]; % their defaults
ChannelCriteriaMaxBadTime = 0.5000;
MaxAmplitude = 150;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Filetype to clean
% CleanType = 'Power';
CleanType = 'Unfiltered';


% get paths
Source_Power = fullfile(Paths.Preprocessed, CleanType, 'MAT');
Source_Components = fullfile(Paths.Preprocessed, 'ICA', 'Components');

Destination_All = fullfile(Paths.Preprocessed, CleanType, 'Clean');
Destination_All_Rejects = fullfile(Paths.Preprocessed, 'ICA', 'Cleanable');

% prepare final chanlocs, without the external channels
load('StandardChanlocs128.mat', 'StandardChanlocs')
load('Cz.mat', 'CZ')
FinalChanlocs = StandardChanlocs;
FinalChanlocs(ismember({StandardChanlocs.labels}, string(EEG_Channels.notEEG))) = [];
FinalChanlocs(end+1) = CZ;

for Indx_T = 1:numel(Tasks)

    Task = Tasks{Indx_T};
    Source = fullfile(Source_Components, Task);
    Destination = fullfile(Destination_All,  Task);
    Destination_Rejects = fullfile(Destination_All_Rejects, Task);

    if ~exist(Destination, 'dir')
        mkdir(Destination)
    end


    if ~exist(Destination_Rejects, 'dir')
        mkdir(Destination_Rejects)
    end

    Files = list_filenames(Source);
    Files(~contains(Files, '.mat'))=  [];


    for Indx_F = 1:numel(Files)

        %%% load data

        File = Files{Indx_F};

        % skip if file already exists
        if ~Refresh && exist(fullfile(Destination, File), 'file')
            disp(['***********', 'Already did ', File, '***********'])
            continue
        end

        % load data from which you want to remove components
        Filepath_Power = fullfile(Source_Power,Task, File);
        if ~exist(Filepath_Power, 'file')
            warning(['Cant find ' Filepath_Power])
            continue
        end
        load(Filepath_Power, 'EEG')
        Data = EEG;

        % load ICA components
        Filepath_ICA = fullfile(Source, File);
        if ~exist(Filepath_ICA, 'file')
            warning(['Cant find ' Filepath_ICA])
            continue
        end
        load(Filepath_ICA, 'EEG')

        % try
            %%% preprocess data

            % remove bad channels
            Data = pop_select(Data, 'nochannel', labels2indexes(EEG.badchans, Data.chanlocs));

            % add CZ
            Data = add_cz(Data);

            % rereference to average
            Data = pop_reref(Data, []);

            %%% remove major artifact components
            Components = EEG.etc.ic_classification.ICLabel.classifications;

            % assign one category to each component
            Top = top_components_by_category(Components, Spread);

            % identify slope in beta-gamma range
            Slopes = ica_slopes(EEG, SlopeRange);

            % if anything classified as noise or other that has a flat
            % slope, or tilts positive, then its muscle activity.
            Top(ismember(Top, [5 6 7]) & Slopes<=MuscleSlopeMin) = 2;

            % remove Muscle, Eye, and Heart components
            Rejects = ismember(Top, RemoveComps);
            EEG.reject.gcompreject = Rejects';

            % save separate location of removed comps
            save(fullfile(Destination_Rejects, File), 'EEG')


            % create new data structure with ICA metadata, and EEG data
            NewEEG = EEG; % gets everything from IC structure
            NewEEG.data = Data.data; % replace data
            NewEEG.pnts = Data.pnts; % replaces data related fields
            NewEEG.srate = Data.srate;
            NewEEG.xmax = Data.xmax;
            NewEEG.times = Data.times;
            NewEEG.event = Data.event;
            NewEEG.icaact = [];

            % remove components
            badcomps = find(EEG.reject.gcompreject); % get indexes of selected components
            NewEEG = pop_subcomp(NewEEG, badcomps);


            [~, BadCh, BadWindows_t] = ...
                find_bad_segments(NewEEG, WindowLength, -inf, MaxPorportionUniqueCorr, EEG_Channels.notEEG, false, MinDataKeep, CorrelationFrequencyRange, MaxAmplitude); % mine; just a quick check

            BadWindows_t(1:ChopEdge*EEG.srate) = 1;
            BadWindows_t(end-ChopEdge*EEG.srate:end) = 1;
            NewEEG.data(:, BadWindows_t) = [];
            disp(['Removing ', num2str(nnz(BadWindows_t)/numel(BadWindows_t)*100), '% data in time'])

            NewEEG = pop_select(NewEEG, 'nochannel', BadCh);
            disp(['Removing ', num2str(numel(BadCh)), ' channels'])
            NewEEG = eeg_checkset(NewEEG);


            % % last cleaning of data
            % NewEEG = clean_windows(NewEEG,MinDataKeep,WindowCriteriaTolerances); % EEGLABs (veeery lax)
            % 
            % [NewEEG,removed_channels] = clean_channels_nolocs(NewEEG,...
            %     MinCorrelation,NoLocsChannelCritExcluded,[],ChannelCriteriaMaxBadTime);


            if size(NewEEG.data, 2) < NewEEG.srate*MinTime
                warning(['Removed too many timepoints removed in ', File])
                continue
            end

            if size(NewEEG.data, 1) < 128-numel(EEG_Channels.notEEG)-MinChannels
                warning(['Removed too many channels removed in ', File])
                continue
            end

            % interpolate bad channels
            NewEEG = pop_interp(NewEEG, FinalChanlocs);


            % save
            EEG = NewEEG;
            save(fullfile(Destination, File), 'EEG')

            disp(['Finished ', File])
        % catch
        %     warning('something didnt work')
        % end
    end
end


