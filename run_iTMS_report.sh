#!/bin/bash
#
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 1
#SBATCH --mem=10GB
#SBATCH -t 0-24:00
#SBATCH --job-name iTMS_Report

CODEDIR=$1
CONFIG=$2

# load modules

module load Mambaforge/23.11.0-fasrc01
module load R/4.2.2-fasrc01
module load matlab/R2019b-fasrc01-ncf
module load wb_contain/1.0.0-linux_x64-ncf
module load freesurfer/6.0.0-ncf

which python
#module load anaconda
mamba activate report

#module load python
# run code
curr_dir=$(pwd)
cd ${CODEDIR}
pwd

python iReport.py ${CONFIG}
cd ${curr_dir}
pwd
mamba deactivate
