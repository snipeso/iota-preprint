% filters sleep data for analysis. Saves all together in one folder.
% from iota-preprint, Snipes, 2024.
clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% parameters
P = LSMParameters();

Paths  = P.Paths;
RawPaths = P.RawFolders;
FilterParameters = P.FilterParameters;
Refresh = false;

Destination_Formats = {'Minimal'}; % chooses which filtering to do


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run

for Indx_DF = 1:numel(Destination_Formats) % this is to keep it flexible in case I want to filter in multiple ways.
    Destination_Format = Destination_Formats{Indx_DF};

    for Indx_D = 1:size(RawPaths.Datasets,1) % loop through participants
        for Indx_F = 1:size(RawPaths.Subfolders, 1) % loop through all subfolders

            %%%%%%%%%%%%%%%%%%%%%%%
            %%% Check if data exists

            Path = fullfile(Paths.Datasets, RawPaths.Datasets{Indx_D}, RawPaths.Subfolders{Indx_F});

            % skip rest if folder not found
            if ~exist(Path, 'dir')
                warning([deblank(Path), ' does not exist'])
                continue
            end

            % identify meaningful folders traversed
            Levels = split(RawPaths.Subfolders{Indx_F}, '\');
            Levels(cellfun('isempty',Levels)) = []; % remove blanks
            Levels(strcmpi(Levels, 'EEG')) = []; % remove uninformative level that its an EEG

            Task = Levels{1}; % task is assumed to be the first folder in the sequence

            % if does not contain EEG, then skip
            Content = ls(Path);
            MAT = contains(string(Content), '.mat');
            if ~any(MAT)
                if any(strcmpi(Levels, 'EEG')) % if there should have been an EEG file, be warned
                    warning([Path, ' is missing MAT file'])
                end
                continue
            elseif nnz(MAT) > 1 % if there's more than one set file, you'll need to fix that
                warning([Path, ' has more than one MAT file'])
                continue
            end

            Filename_MAT = Content(MAT, :);

            % set up destination location
            Destination = fullfile(Paths.Preprocessed, Destination_Format, 'MAT', Task);

            Filename_Core = join([RawPaths.Datasets{Indx_D}, Levels(:)'], '_');
            Filename_Destination = [Filename_Core{1}, '.mat'];

            % create destination folder
            if ~exist(Destination, 'dir')
                mkdir(Destination)
            end

            % skip filtering if file already exists
            if ~Refresh && exist(fullfile(Destination, Filename_Destination), 'file')
                disp(['***********', 'Already did ', Filename_Core{1}, '***********'])
                continue
            end


            %%%%%%%%%%%%%%%%%%%
            %%% process the data
            disp(['Loading ', Filename_MAT])
            load(fullfile(Path, Filename_MAT), 'EEG')

            EEG = filter_and_downsample_eeg(EEG, FilterParameters.(Destination_Format));
            EEG = eeg_checkset(EEG); % makes sure all fields are present


            % save preprocessing info in eeg structure
            EEG.setname = Filename_Core;
            EEG.filename = Filename_Destination;
            EEG.original.filename = Filename_MAT;
            EEG.original.filepath = Path;
            EEG.filtering = FilterParameters.(Destination_Format);

            % save EEG
            save(fullfile(Destination, Filename_Destination), 'EEG', '-v7.3')
        end
    end
end

disp(['************** Finished ',  Folders.Datasets{Indx_D}, '***************'])
%     end
% end