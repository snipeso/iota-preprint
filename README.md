# Iota Oscillations (short report)

The code in this repository was used to generate the data from the Snipes (2025) short report *Iota oscillations (25-35 Hz) during wake and REM sleep in children and young adults* in the Journal of Neurophysiology.

Note: especially the preprocessing is only lightly described in the paper compared to everything that is actually done to automatically detect artefacts. Another preprint describes the preprocessing in detail, but it's more direct to just see what is implemented in the code.

## Setup

### Requirements
This code was writen for MATLAB 2023b which in turn runs python 3.10. It may or may not work with other versions.

External toolboxes:
- the [FOOOF/specparam](https://github.com/fooof-tools/fooof_mat) MATLAB wrapper (warning: can be difficult to set up). N.B. This is only a requirement to exactly reproduce the results in this paper. Since then, the eeg-oscillations toolbox has been updated to no longer require running python code.
- the [EEGLAB](https://sccn.ucsd.edu/eeglab/download.php) toolbox, with the "bva-io" plugin to import raw brainvision data  
    - can be easily installed through the EEGLAB gui. File>import data > From Brain. Vis. rec...
- The semi-automatic sleep data cleaning was done with the [SleepCleaner toolbox](https://github.com/HuberSleepLab/Hd-SleepCleaner), seperately from this repository

My toolboxes:
- the [eeg-oscillations](https://github.com/snipeso/eeg-oscillations) toolbox for calculating power, running FOOOF, etc. There is a specific version associated with the paper.
- the [chART](https://github.com/snipeso/chart) toolbox for plotting
- the [Matcycle](https://github.com/hubersleeplab/matcycle) toolbox, for the burst detection. There is a specific version for the iota paper.


The Parallel Processing MATLAB toolbox is a really good idea, although in theory the code works without it.

### Data
EEG data is saved with EEGLAB's standarard structure:

```matlab
EEG = struct();
EEG.data = []; % matrix of channels x timepoints
EEG.srate = 1000; % in Hz
EEG.chanlocs; % structure with information on channel locations, labels, etc. important for plotting topographies
% there are more, but these are the important ones

```

#### Children wake
EEG wake data was downloaded from [The Child Mind Institute](https://fcon_1000.projects.nitrc.org/indi/cmi_healthy_brain_network/index.html). EEG data could be downloaded immediately, whereas phenotypic data needs to be requested with a data sharing agreement. 


#### Zurich adults
EEG sleep data is available upon request. I am in the process of figuring out where to put the whole dataset together online, and so eventually it will also be freely available. In general though, any young adult sleep EEG should yield the same results.

##### Sleep scoring & artefacts
Sleep scoring and artefact detection was done manually. The output of which was saved in a .mat file for each night, containing `visnum` which is an array of scores for 20 s epochs such that:
- REM = 1
- Wake = 0
- N1 = -1
- N2 = -2
- N3 = -3

Artefacts were marked in a channel x epoch matrix called `artndxn` (also saved in the same mat file) such that 1 indicates data to keep and 0 data to remove.

### Output data
#### Power & specparam
- Power is saved as a Channel x Epoch x Frequency matrix.
- Periodic peaks are saved as a Channel x Epoch x 3 matrix, with the three layers representing center frequency, peak amplitude, and bandwidth.
- Wake metadata is a large table with "EID" the participant ID, "Sex" (1=female), "EHQ" for handedness (<0 is left)

## How to run 

### Wake

Wake scripts are in [HBN_Wake/](./HBN_Wake/)

1. Adjust paths in HBNParameters.m. Add toolbox paths to MATLAB if you haven't already.
2. Run preprocessing scripts Prep1 to Prep4.
3. Run the Analysis scripts
4. Run the Results scripts

### Sleep
Sleep scripts are in [LSM_Sleep/](./LSM_Sleep/)

1. Adjust paths in LSMParameters.m
2. Run Prep1-Prep4.
3. Conduct sleep scoring (manually)
4. Using [Hd-SleepCleaner](https://github.com/snipeso/Hd-SleepCleaner/), identify artefact epochs. This saves a file with artndx (ch x epochs) and visnum (1 x epochs) with the artefacts and scoring respectively. 
5. Run Analysis1-2
6. Run Results_Sleep

## Key functions
Here are some short cuts to important functions used in the code:

- Preprocessing: 
    - [filter_and_downsample_eeg()](./functions/eeg_preprocessing/filter_and_downsample_eeg.m)
    - [find_bad_segments()](./functions/eeg_preprocessing/find_bad_segments.m), the script to identify major artefacts
    - [remove_channel_or_window()](./functions/eeg_preprocessing/remove_channel_or_window.m), the function that choses whether to remove a channel or an epoch, based on which was worse.
    - [eeglab_ica()](./functions/eeg_preprocessing/eeglab_ica.m), gets ICA components

- Analysis:
    - [oscip.fit_fooof()](https://github.com/snipeso/eeg-oscillations/blob/main/%2Boscip/fit_fooof.m), this is where the fooof/specparam function gets run and all the parameters extracted, and [oscip.fit_fooof_multidimentional()](https://github.com/snipeso/eeg-oscillations/blob/main/%2Boscip/fit_fooof_multidimentional.m) is what runs it on every channel/epoch
    - [cycy.detect_bursts_all_channels()](https://github.com/HuberSleepLab/Matcycle/blob/main/%2Bcycy/detect_bursts_all_channels.m) detection of bursts with cycle-by-cycle analysis
    - [oscip.check_peak_in_band()](https://github.com/snipeso/eeg-oscillations/blob/main/%2Boscip/check_peak_in_band.m) checks whether there is a peak among the periodic peaks in a given frequency band, and indicates what the peak frequency is.
