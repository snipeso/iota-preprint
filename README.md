# Iota preprint

The code in this repository was used to generate the data from the Snipes 2024 preprint *Iota oscillations (25-35 Hz) during wake and REM sleep in children and young adults*.

## Key functions
If you're here because you think I may have messed up, I explained something poorly, or you want to try it for yourself, here are the key functions in the pipeline that produced the paper:

- [filter_and_downsample_eeg.m](./functions/eeg_preprocessing/filter_and_downsample_eeg.m) is what it sounds like.
- [find_bad_segments.m](./functions/eeg_preprocessing/find_bad_segments.m) is the cobbled-together script to identify movement artefacts based on the correlation of neighboring channels. I know it can be done a lot better, but it got the job done.
- [remove_channel_or_window.m](./functions/eeg_preprocessing/remove_channel_or_window.m) is the function that choses whether to remove a channel or an epoch, based on which was worse. I think this is nifty.
- [Prep4_RemoveICA.m](./HBN_Wake/Prep4_RemoveICA.m) is where physiological artefacts are removed with ICA. It's not perfect, but it works ok.
- [oscip.fit_fooof.m](https://github.com/snipeso/eeg-oscillations/blob/main/%2Boscip/fit_fooof.m) is where the fooof function gets run and all the parameters extracted, and [oscip.fit_fooof_multidimentional.m](https://github.com/snipeso/eeg-oscillations/blob/main/%2Boscip/fit_fooof_multidimentional.m) is what runs it on every channel/epoch. This is amazing, hands down the most useful sleep-analysis code I've written.


## Requirements

- the [FOOOF](https://github.com/fooof-tools/fooof_mat) MATLAB wrapper (can be a bitch to install, because matlab and python are like oil and vinegar)
- the [eeg-oscillations](https://github.com/snipeso/eeg-oscillations) toolbox for calculating power, running FOOOF, etc.
- the [chART](https://github.com/snipeso/chart) toolbox for plotting
- the [Matcycle](https://github.com/hubersleeplab/matcycle) toolbox, just for plotting for the burst detection
- the [EEGLAB](https://sccn.ucsd.edu/eeglab/download.php) toolbox, with the "bva-io" plugin to import raw brainvision data  
    - can be easily installed through the EEGLAB gui. File>import data > From Brain. Vis. rec...

The Parallel Processing MATLAB toolbox is a good idea, but in theory it should work without it. I didn't have centuries to try running the code without, though.

## Data
EEG data is saved with EEGLAB's standarard structure:

```matlab
EEG = struct();
EEG.data = []; % matrix of channels x timepoints
EEG.srate = 1000; % in Hz
EEG.chanlocs; % structure with information on channel locations, labels, etc. important for plotting topographies
% there are more, but these are the important ones

```

### Children wake
EEG wake data was downloaded from [The Child Mind Institute](https://fcon_1000.projects.nitrc.org/indi/cmi_healthy_brain_network/index.html). EEG data could be downloaded immediately, whereas phenotypic data needs to be requested with a data sharing agreement. 


### Zurich adults
EEG sleep data is available upon request. I am in the process of figuring out where to put it online, and so eventually it will also be freely available. In general though, any young adult sleep EEG should yield the same results.

#### Sleep scoring & artefacts
Sleep scoring and artefact detection was done manually. The output of which was saved in a .mat file for each night, containing `visnum` which is an array of scores for 20 s epochs such that:
- REM = 1
- Wake = 0
- N1 = -1
- N2 = -2
- N3 = -3

Artefacts were marked in a channel x epoch matrix called `artndxn` (also saved in the same mat file) such that 1 indicates data to keep and 0 data to remove.


## Run 

### wake

Wake scripts are in [HBN_Wake/](./HBN_Wake/)

1. Adjust paths in HBNParameters.m
2. Run preprocessing scripts Prep1 to Prep4
3. Run the analysis scripts Analysis1 to Analysis2
4. Run the plotting scripts Figure1-Figure5

### sleep
Sleep scripts are in [LSM_Sleep/](./LSM_Sleep/)

1. Adjust paths in LSMParameters.m
2. Run Prep0-Prep1.
3. Conduct sleep scoring (manually)
4. Using [Hd-SleepCleaner](https://github.com/snipeso/Hd-SleepCleaner/), identify artefact epochs. This saves a file with artndx (ch x epochs) and visnum (1 x epochs) with the artefacts and scoring respectively. 
5. Run Analysis1-2
6. Run Figure6-7
