function P = LSMParameters()
% This is where I save all the parameters and variables used throughout the
% the code for analyzing the sleep LSM dataset.
% for iota-preprint, Snipes, 2024.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Paths

Paths = struct();

% raw data (really big hard disk)
RawCore = 'E:\LSM\Data';
Paths.Datasets = fullfile(RawCore, 'Raw');

% where to put preprocessed data (much smaller hard disk)
PrepCore = 'F:\Data';

Paths.Preprocessed = fullfile(PrepCore, 'Preprocessed');
Paths.Core = PrepCore;

% where current functions are
Paths.Analysis = mfilename('fullpath');
Paths.Analysis = fullfile(extractBefore(Paths.Analysis, '\LSM_Sleep\'));

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

% eeglab functions
if ~exist('topoplot', 'file')
    eeglab
    close all
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Preprocessing filter parameters

FilterParameters = struct();

% this is what I use to calculate power with minimal filtering for removing
% drift and antialiasing to allow downsampling.
FilterParameters.Wake.Format = 'Minimal'; % reference name
FilterParameters.Wake.fs = 250; % new sampling rate
FilterParameters.Wake.lp = 100; % low pass filter
FilterParameters.Wake.hp = 0.2; % high pass filter
FilterParameters.Wake.hp_stopband = 0.1; % high pass filter

% this is what I used to use to calculate power
FilterParameters.Wake.Format = 'Power'; % reference name
FilterParameters.Wake.fs = 250; % new sampling rate
FilterParameters.Wake.lp = 40; % low pass filter
FilterParameters.Wake.hp = 0.5; % high pass filter
FilterParameters.Wake.hp_stopband = 0.25; % high pass filter

% ICA: heavily filtered data for getting ICA components (I don't use it,
% but in case I ever want to...)
FilterParameters.ICA.Format = 'ICA'; % reference name
FilterParameters.ICA.fs = 250; % new sampling rate
FilterParameters.ICA.lp = 80; % low pass filter
FilterParameters.ICA.hp = 2.5; % high pass filter
FilterParameters.ICA.hp_stopband = .5; % high pass filter


P.FilterParameters = FilterParameters;

P.LineNoise = 50; % Hz
