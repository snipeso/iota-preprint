% script to calculate ICA components used to clean data.
%
% From iota-preprocessing by Sophia Snipes, 2024

% close all
clc
clear

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = HBNParameters();
Paths = P.Paths;
Tasks = P.Tasks(1);
Parameters = P.Parameters;
EEG_Channels = P.Channels;

MinNeighborCorrelation = .3;
ChopEdge = 2; % in seconds, cut off these many seconds at the beginning and end of recordings
WindowLength = 3; % in seconds
MinDataKeep = .15; % proportion of noise in data as either channel or segment, above which the channel/segment is tossed
MinChannels = P.MinChannels; % maximum number of channels that can be removed
MinTime = P.MinTime; % ninimum file duration in seconds
CorrelationFrequencyRange = [4 40];
MaxPorportionUniqueCorr = .02; % the minimum number of unique correlation values across channels when rounding correlations to 3 decimal points

Refresh = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Source_All = fullfile(Paths.Preprocessed, 'ICA', 'MAT');
Destination_All = fullfile(Paths.Preprocessed, 'ICA', 'Components');



for Indx_T = 1:numel(Tasks)
    Task = Tasks{Indx_T};

    Source = fullfile(Source_All, Task);
    Destination = fullfile(Destination_All, Task);

    if ~exist(Destination, 'dir')
        mkdir(Destination)
    end

    Files = list_filenames(Source);
    Files(~contains(Files, '.mat'))=  [];

    for Indx_F = 1:numel(Files)
    % parfor Indx_F = 1:numel(Files)
        File = Files{Indx_F};

        % skip if file already exists
        if ~Refresh && exist(fullfile(Destination, File), 'file')
            disp(['***********', 'Already did ', File, '***********'])
            continue
        end

        try

            % load data
            Data = load(fullfile(Source, File), 'EEG');
            EEG = Data.EEG;
            if ~isfield(EEG, 'data')
                continue
            end

            Channels = EEG_Channels;

            % convert to double
            EEG.data = double(EEG.data);

            % remove bad channels and really bad timepoints
            [~, BadChannels, BadWindows_t] = find_bad_segments(EEG, WindowLength, MinNeighborCorrelation, ...
                MaxPorportionUniqueCorr, Channels.notEEG, true, MinDataKeep, CorrelationFrequencyRange);

            BadWindows_t(1:ChopEdge*EEG.srate) = 1;
            BadWindows_t(end-ChopEdge*EEG.srate:end) = 1;
            EEG.data(:, BadWindows_t) = [];
            EEG.pnts = size(EEG.data, 2);
            EEG = eeg_checkset(EEG);

            if numel(BadChannels)> MinChannels
                warning(['Removed too many channels in ', File])
                continue
            end

            if size(EEG.data, 2) < EEG.srate*MinTime
                warning(['Removed too many timepoints removed in ', File])
                continue
            end

            % remove maybe other noise (flatlines, and little bad windows)
            FlatChannels = find_flat_channels(EEG);

            % save info of which are bad channels
            EEG.badchans = unique([BadChannels, FlatChannels]);
            if numel([EEG.badchans])> MinChannels
                warning(['Removed too many channels in ', File])
                continue
            end

            % remove also external electrodes
            EEG.badchans = unique([Channels.notEEG, EEG.badchans]);

            % remove really bad channels
            EEG = pop_select(EEG, 'nochannel', EEG.badchans);

            % remove bad timepoints
            EEG = clean_artifacts(EEG, ...
                'FlatlineCriterion', 'off', ...
                'Highpass', 'off', ...
                'ChannelCriterion', 'off', ...
                'LineNoiseCriterion', 'off', ...
                'BurstRejection', 'off',...
                'BurstCriterion', 'off', ...
                'BurstCriterionRefMaxBadChns', 'off', ...
                'WindowCriterion', .1); % quite strict

            if size(EEG.data, 2) < EEG.srate*MinTime
                warning(['Removed too many timepoints removed in ', File])
                continue
            end

            % add Cz
            EEG = add_cz(EEG);

            % rereference to average
            EEG = pop_reref(EEG, []);

            % run ICA (takes a while)
            Rank = sum(eig(cov(double(EEG.data'))) > 1E-7);
            if Rank ~= size(EEG.data, 1)
                warning(['Applying PCA reduction for ', File])
            end

            % calculate components
            EEG = pop_runica(EEG, 'runica', 'pca', Rank);

            % classify components
            EEG = iclabel(EEG);

            parsave(fullfile(Destination, File), EEG)
        catch
            warning(['Skipping ', File])
            continue
        end
        disp(['***********', 'Finished ', File, '***********'])
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function parsave(Path, EEG)
save(Path, 'EEG')
end



