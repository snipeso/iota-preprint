function P = LSMParameters()
% This is where I save all the parameters and variables used throughout the
% the code for analyzing the sleep LSM dataset.
% for iota-preprint, Snipes, 2024.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Paths

Paths = struct();

% raw data (really big hard disk)
RawCore = 'D:\LSM\Data\';
Paths.Datasets = fullfile(RawCore, 'Raw');

% where to put preprocessed data (much smaller hard disk)
PrepCore = 'F:\Data';

Paths.Preprocessed = fullfile(PrepCore, 'Preprocessed');
Paths.Core = PrepCore;

% where current functions are
Paths.Analysis = mfilename('fullpath');
Paths.Analysis = fullfile(extractBefore(Paths.Analysis, '\Preprocessing\'));

% add to path all folders in functions
Content = deblank(string(ls(fullfile(Paths.Analysis, 'functions'))));
for Indx = 1:numel(Content)
    addpath(fullfile(Paths.Analysis, 'functions', Content{Indx}))
end

P.Paths = Paths;


%%% Folders for raw data: participants, and respective subfolders (legacy
%%% code)

RawFolders = struct();

RawFolders.Template = 'PXX';
RawFolders.Ignore = {'CSVs', 'other', 'Lazy', 'P00', 'Applicants'};

[RawFolders.Subfolders, RawFolders.Datasets] = AllFolderPaths(Paths.Datasets, ...
    RawFolders.Template, false, RawFolders.Ignore);

P.RawFolders = RawFolders;