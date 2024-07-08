% saves and filters EEG data
%
% From iota-preprocessing by Sophia Snipes, 2024

close all
clear
clc


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = HBNParameters();
PrepParameters = P.Parameters;
LineNoise = P.LineNoise;
Task = P.Tasks{1};
MinTime = P.MinTime;
Paths = P.Paths;

Source = fullfile(Paths.Datasets, 'EEG');
Destination = fullfile(Paths.Preprocessed);
Refresh = false;

Destination_Formats = {'Unfiltered'}; % chooses which filtering to do

Participants = string(deblank(ls(Source)));
Participants(contains(Participants, '.')) = [];

load('StandardChanlocs128.mat', 'StandardChanlocs')

parfor ParticipantIdx = 1:numel(Participants) % loop through participants
    % for ParticipantIdx = 1:numel(Participants)

    AllParams = PrepParameters;
    AllParticipants = Participants;
    Participant = AllParticipants{ParticipantIdx};

    FilePath = fullfile(Source, Participant, 'EEG', 'raw', 'mat_format', 'RestingState.mat');
    if ~exist(FilePath, 'file')
        continue
    end

    try % its bad practice, but since it can crash for whatever reason, this lets code keep runing regardless
        Output = load(FilePath);

        % set up correct EEGLAB structure
        EEG = Output.EEG;

        if size(EEG.data, 1)<128
            warning([Participant 'doesnt have enough channels'])
            continue
        end

        EEG.data(129, :) = []; % its nice that they put CZ in there, but I add it in later
        EEG.chanlocs = StandardChanlocs;
        EEG.nbchan = 128;
        EEG.ref = 'Cz';
        if size(EEG.data, 2) < 100
            warning([Participant 'doesnt have enough data'])
        elseif  size(EEG.data, 2) < MinTime*EEG.srate
            warning([Participant 'doesnt have enough data'])
            continue
        end

        EEG = eeg_checkset(EEG);
        RawEEG = EEG;

        for Indx_DF = 1:numel(Destination_Formats)
            Destination_Format = Destination_Formats{Indx_DF};

            Parameters = AllParams.(Destination_Format);
            Parameters.line = LineNoise;

            % set up destination location
            DestinationFolder = fullfile(Destination, Destination_Format, 'MAT', Task);
            DestinationFilename = [Participant, '_RestingState.mat'];
            Filepath_Destination = fullfile(DestinationFolder, DestinationFilename);
            if ~exist(DestinationFolder, 'dir')
                mkdir(DestinationFolder)
            end

            if ~Refresh && exist(Filepath_Destination, 'file')
                disp(['Already did ', Participant, ' ', Destination_Format])
                continue
            end

            %%% preprocessing
            EEG = filter_and_downsample_eeg(RawEEG,  Parameters);

            %%% save
            EEG.setname = DestinationFilename;
            EEG.filtering = Parameters;

            EEG = eeg_checkset(EEG);
            parsave(Filepath_Destination, EEG)
            disp(['************** Finished ',  Participant, '***************'])
        end
    catch
        warning(['Skipping ', FilePath])
        continue
    end
end


function parsave(Filepath, EEG)
clc
save(Filepath, 'EEG')
disp(['saving ', Filepath])
end

