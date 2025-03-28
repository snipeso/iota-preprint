function EEG = LoadEEGLAB(Path, Channels)
% Loads eeglab ".set" file (or mat file), and selects the requested channels. Assumes only
% one file is in provided folder.
% from iota-neurophys, Snipes, 2024.

EEG = []; % blank in case things go wrong

Files = ls(Path);

%%% determine whether there's any file that can be read in the folder
Extensions = extractAfter(Files, '.');

if any(strcmp(Extensions, 'mat')) % check first if there's a mat, since this doesn't require EEGLAB to open
    Extension = '.mat';
elseif ~any(strcmp(Extensions, 'set'))
    Extension = '.set';
else
    warning([Path, 'has no set or mat files'])
    return
end

EEGIndexes = contains(string(Files), Extension);

% check if there is only 1 set file
if ~any(EEGIndexes)
    if any(strcmpi(Levels, 'EEG')) % if there should have been an EEG file, be warned
        warning([Path, ' is missing SET file'])
    end
    return
elseif nnz(EEGIndexes) > 1 % if there's more than one set file, you'll need to fix that
    warning([Path, ' has more than one SET file'])
    return
end

% load data
if strcmp(Extension, 'set')
    EEG = pop_loadset('filename', Files(EEGIndexes, :), 'filepath', Path);
else
    load(fullfile(Path, Files(EEGIndexes, :)), 'EEG')
end

% select required channels (this is done sooner rather than later to speed
% things up)
if isfield(EEG, 'Sleep_Channels')
    EEG = pop_select(EEG, 'channel',EEG.Sleep_Channels);
else
    EEG = pop_select(EEG, 'channel', Channels); % gets only requested channels, but in numerical order
end

% resort channels
ChanLabels = {EEG.chanlocs.labels};
[~, b] = ismember(string(Channels), ChanLabels); % gets order of channels requested

EEG.data = EEG.data(b, :); % sorts the data
EEG.chanlocs = EEG.chanlocs(b); % sorts the chanlocs file, in case you want that
