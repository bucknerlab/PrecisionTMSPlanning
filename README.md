# Intro
The purpose of this pipeline is generate a report for within-individual TMS planning.

# Getting started
The overall steps, as described in Sun, Billot et al. 2025 (Human Brain Mapping) include: taking raw BOLD data as inputs, preprocessing with iProc, estimating networks with MS-HBM, running E-Field modeling/target optimization with TANS, and generating a TMS planning report. The code for external packages (iProc, MS-HBM, TANS) are NOT included here, but can be downloaded/accessed via the README_WS.md file in the respective directories.

Make sure to install the necessary packages. On FASSE at Harvard, we ran the following 2 lines of code to set up the python environment. These python packages are used for the TMS report generation.

```
module load Mambaforge/23.11.0-fasrc01
mamba env create -f report_environment.yaml
```

Run these lines to set up your R environment. These R modules are used for making the spatial selectivity and E-field intensity plots in Sun, Billot et al 2025.

```
module load R/4.2.2-fasrc01
PATH_TO_LOCAL_R=/example/wendysun/R/ifxrstudio/RELEASE_3_16 # replace with your path, you can figure out what it is by calling print(.libPaths()) in R.
Rscript Renv_setup.R ${PATH_TO_LOCAL_R}
```

# Running
### Config file
Included in this directory, EXMPL_tms_config.cfg should serve as a template. 

### Main executable script
iTMS.py is the main executable. There is a bash wrapper for each step that runs the step, usually by submitting it as a SLURM job.

### Example usage:
```
module load Mambaforge/23.11.0-fasrc01
python iTMS.py /path/to/subject/data/EXMPL_tms_config.cfg REPORT
```
