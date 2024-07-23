% filters sleep data for analysis. Saves all together in one folder.
% from iota-preprint, Snipes, 2024.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% parameters
P = LSMParameters();

Paths  = P.Paths;
RawPaths = P.RawFolders;
LineNoise = P.LineNoise;
FilterParameters = P.FilterParameters;

Destination_Formats = {'Minimal'}; % chooses which filtering to do


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run

for Indx_DF = 1:numel(Destination_Formats) % this is to keep it flexible in case I want to filter in multiple ways.
    Destination_Format = Destination_Formats{Indx_DF};

    % set selected parameters
    new_fs = FilterParameters.(Destination_Format).fs;
    lowpass = FilterParameters.(Destination_Format).lp;
    highpass = FilterParameters.(Destination_Format).hp;
    hp_stopband = FilterParameters.(Destination_Format).hp_stopband;


    for Indx_D = 1:size(Folders.Datasets,1) % loop through participants
        for Indx_F = 1:size(Folders.Subfolders, 1) % loop through all subfolders

            %%%%%%%%%%%%%%%%%%%%%%%
            %%% Check if data exists

            Path = fullfile(Paths.Datasets, RawPaths.Datasets{Indx_D}, RawPaths.Subfolders{Indx_F});

            % skip rest if folder not found
            if ~exist(Path, 'dir')
                warning([deblank(Path), ' does not exist'])
                continue
            end

            % identify meaningful folders traversed
            Levels = split(Folders.Subfolders{Indx_F}, '\');
            Levels(cellfun('isempty',Levels)) = []; % remove blanks
            Levels(strcmpi(Levels, 'EEG')) = []; % remove uninformative level that its an EEG

            Task = Levels{1}; % task is assumed to be the first folder in the sequence

            % if does not contain EEG, then skip
            Content = ls(Path);
            SET = contains(string(Content), '.set');
            if ~any(SET)
                if any(strcmpi(Levels, 'EEG')) % if there should have been an EEG file, be warned
                    warning([Path, ' is missing SET file'])
                end
                continue
            elseif nnz(SET) > 1 % if there's more than one set file, you'll need to fix that
                warning([Path, ' has more than one SET file'])
                continue
            end

            Filename_MAT = Content(SET, :);

            % set up destination location
            Destination = fullfile(Paths.Preprocessed, Destination_Format, 'SET', Task);

            Filename_Core = join([Folders.Datasets{Indx_D}, Levels(:)', Destination_Format], '_');
            Filename_Destination = [Filename_Core{1}, '.mat'];

            % create destination folder
            if ~exist(Destination, 'dir')
                mkdir(Destination)
            end

            % skip filtering if file already exists
            if ~Refresh && exist(fullfile(Destination, Filename_Destination), 'file')
                disp(['***********', 'Already did ', Filename_Core, '***********'])
                continue
            end


            %%%%%%%%%%%%%%%%%%%
            %%% process the data

            load(fullfile(Path, Filename_MAT), 'EEG')

            % low-pass filter
            EEG = pop_eegfiltnew(EEG, [], lowpass);

            % notch filter for line noise and harmonics
            EEG = line_filter(EEG, LineNoise, false);

            % resample
            EEG = pop_resample(EEG, new_fs);

            % high-pass filter
            % NOTE: this is after resampling, otherwise crazy slow.
            EEG = highpass_eeg(EEG, highpass, hp_stopband);

            EEG = eeg_checkset(EEG); % makes sure all fields are present


            % save preprocessing info in eeg structure
            EEG.setname = Filename_Core;
            EEG.filename = Filename_Destination;
            EEG.original.filename = Filename_MAT;
            EEG.original.filepath = Path;
            EEG.filtering = FilterParameters.(Destination_Format);

            % save EEG
            save(fullfile(Destination, Filename_Destination), 'EEG', 'v7.3')
        end
    end
end

disp(['************** Finished ',  Folders.Datasets{Indx_D}, '***************'])
%     end
% end