# iota preprint

The code in this repository was used to generate the data from the Snipes 2024 preprint *Iota oscillations (25-35 Hz) during wake and REM sleep in children and young adults*.

## Requirements

- the [FOOOF](https://github.com/fooof-tools/fooof_mat) MATLAB code
- the [eeg-oscillations](https://github.com/snipeso/eeg-oscillations) toolbox
- the [chART](https://github.com/snipeso/chart) toolbox (just for plotting)
- the [Matcycle](https://github.com/hubersleeplab/matcycle) toolbox (just for plotting for the burst detection)
- the [EEGLAB](https://sccn.ucsd.edu/eeglab/download.php) toolbox, with the "bva-io" plugin to import raw brainvision data (can be easily installed through the EEGLAB gui. File>import data > From Brain. Vis. rec...)

The Parallel Processing MATLAB toolbox is probably a good idea.

## Data
### Children wake
EEG wake data was downloaded from [The Child Mind Institute](https://fcon_1000.projects.nitrc.org/indi/cmi_healthy_brain_network/index.html). EEG data could be downloaded immediately, whereas phenotypic data needed to be requested with a data sharing agreement. 


### Zurich adults
EEG sleep data is available upon request. I am in the process of figuring out where to put it online, and so eventually it will also be freely available. In general though, any young adult sleep EEG should yield the same results.


## Run wake

1. Adjust paths in HBNParameters.m
2. Run preprocessing scripts Prep1 to Prep4
3. Run the analysis scripts Analysis1 to Analysis2
4. Run the plotting scripts Plot1 to Plot3

## Run sleep

1. Adjust paths in LSMParameters.m
2. Run Prep0-Prep1.
3. Conduct sleep scoring
4. Using [Hd-SleepCleaner](https://github.com/snipeso/Hd-SleepCleaner/) identify artefact epochs. This saves a file with artndx and visnum with the artefacts and scoring respectively. 
5. Run Analysis1-2
6. Run Figure6-7


