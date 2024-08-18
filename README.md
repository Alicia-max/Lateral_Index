# Laterality Index

## Background 
The repository contains code for a project conducted at [Lund University](https://www.lunduniversity.lu.se/lucat/group/v1000549), supervised by Hamid Behjat. The aim is to develop a new tool to measure hemispheric asymmetry using [geometric eigenmodes](https://www.nature.com/articles/s41586-023-06098-1). The project is mainly divided into four main parts:

- Modal Appromixation of the spatial pattern
- Spectral Alignement
- Computation of the LI (Laterality Index)
- Data analysis

Geometric Eigenmode is a method used for neuroimaging analysis, as hilighted in [Pang]((https://www.nature.com/articles/s41586-023-06098-1)). This analysis draws inspiration from [NSBLab toolbox](https://github.com/NSBLab/BrainEigenmodes/tree/main) and used code from [(saSOSKS) repository](https://github.com/aitchbi/saSOSKS). 
## File structure
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
├── functions_matlaba

```

## Implementation 


### Extraction_Eigenmodes 

`demo_eigenmode_calculation.sh` : Bash script to run `surface_eigenmodes.py` that could be modify if needed.

 `surface_eigenmodes.py` : Python script using [LaPy](https://github.com/Deep-MI/LaPy/tree/main) to extract geometric eigenmodes from FreeSurfer output. 

 --> output  : eigenvalue, eigenmodes and normalized eigenval. 

###  Reconstruction

`run_reconstruction.sh` : Bash script to run  `run_recon.m` that could be modify if needed.

`run_recon.m` : Matlab Script that compute the weights associated with each modes to reconstruced the given spatial pattern. 

 --> output  : normalized spatial map, betas, grouped betas, stepwise accuracy


###  Compute_LI

`run_permu.sh` : Bash script to run `demo_run.m`

`demo_run.m` : todo

`get_LI.py` :todo



## Usage 

## Dependencies 
 -  FreeSurfer
 -  Check Python Lib (LaPy; brainSpace;)

## Compatibility  
The codes have been tested on versions of Python ... and versions of MATLAB ....
