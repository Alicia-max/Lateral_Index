# Lateral Index

## Background 
The repository contains code for a project conducted at [Lund University](https://www.lunduniversity.lu.se/lucat/group/v1000549), supervised by Hamid Behjat. The aim is to develop a new tool to measure hemispheric asymmetry using [geometric eigenmodes](https://www.nature.com/articles/s41586-023-06098-1). The project is mainly divided into four main stages:

- Modal Appromixation of the spatial pattern
- Spectral Alignement
- Computation of the LI (Laterality Index)
- Data analysis

Geometric Eigenmode is a method used for neuroimaging analysis, as hilighted in [Pang]((https://www.nature.com/articles/s41586-023-06098-1)). This analysis draws inspiration from [NSBLab toolbox](https://github.com/NSBLab/BrainEigenmodes/tree/main) and used code from [(saSOSKS) repository](https://github.com/aitchbi/saSOSKS). 
## Files structure
```
├── Modal_Approximation
    ├── demo_eigenmode_calculation.sh
    ├── surface_eigenmodes.py
    ├── run_recon.m
    ├── run_reconstruction.sh
├── Spectral_Alignment
    ├── run_subbdand.m
    ├── subbands.sh
├── Compute_LI
    ├── demo_permu.m
    ├── run_permu.sh
    ├── extract_LI.py
    ├── configs
        ├── .json
├── Data_Analysis
    ├── accuracy.ipynb
    ├── main_results.ipynb
    ├── get_id.ipynb
    ├── utils.py
├── functions_matlab
├── requirement.txt

```
functions_matlab are deriveed from [NSBLab toolbox](https://github.com/NSBLab/BrainEigenmodes/tree/main) and [(saSOSKS) repository](https://github.com/aitchbi/saSOSKS).

## Implementation 

### Modal_Approximation

 `surface_eigenmodes.py` : Python script using [LaPy](https://github.com/Deep-MI/LaPy/tree/main) to extract geometric eigenmodes from FreeSurfer output. It extracts ad store volume corrected eigenvalues and geomtric modes. 

 `demo_eigenmode_calculation.sh` : Editable bash script to run `surface_eigenmodes.py` 
 
 `run_recon.m` : Matlab script to appproximate spatial pattern using derived geomtric egienmodes. It extractes weights and intermediate variables usefull for further analayis. 
 
 `run_reconstruction.sh` : Editable bash script to run  `run_recon.m`

###  Spectral_Alignment

`run_subbdand.m` : Matlab script to design spectral sub-band. 

`subbands.sh` : Editable bash script to run `run_subbdand.m`

###  Compute_LI

`demo_permu.m` : Matlab script for permuation testing of the designed index. 

`run_permu.sh` : Editable bash script to run `demo_permu.m`

`extract_LI.py` : Python code to collect LI spectra at the group level. It takes as an input a config file and output the designed dataset with a .pkl file format. 

`configs`: directory containing example of example files.

### Data_Analysis
`accuracy.ipynb` : Python code to plot intermediate analysis (accuracy and sub-band assignement). 

`main_results.ipynb`  : Python code to extract the main result from the project by using the designed dataset with `extract_LI.py`.

`main_results.ipynb` : Python code to extract [BioFinder-2](https://biofinder.se) subset dataset. 

`utils.py` : Python code containing useful function for the notebook. 

## Usage 
As part of an overall project, the codes depend on each other's output. The extraction of modes and approximation of the signal should be run first. Once applied to each subject of interest, spectral alignment can be performed. Finally, the permutation testing, followed by LI computation, can be executed.

All code runs using a bash script provided as an example, except for extract_LI.py, which can be run using the following command:

```bash
python extract_LI.pyS.py --config  config/file.json
```

with file.json as in `config/`
## Dependencies 
 - FreeSurfer
 - LaPy

## Compatibility  
The codes have been tested on versions of Python 3.8 and .. and versions of MATLAB R2021b and . 
