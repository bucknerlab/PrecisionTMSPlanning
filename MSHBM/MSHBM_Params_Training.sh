#!/bin/bash
#
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 1
#SBATCH -p ncf_sba
#SBATCH --mem=100GB
#SBATCH -t 0-12:00
#SBATCH --job-name MSHBM_Training

module load ncf/1.0.0-fasrc01
module load freesurfer/6.0.0-ncf
module load matlab/R2019b-fasrc01-ncf
module load connectome_workbench/1.3.2-centos6_x64-ncf
module load fsl/5.0.4-ncf
export CBIG_CODE_DIR=$codedir/ncf_tools/CBIG_CODE

sub_list=$1
numofnet=$2
outputdir=$3
codedir=$4

matlab -nojvm -nodesktop -r "addpath(genpath('$codedir')); MSHBM_Params_Training('$sub_list','$numofnet','$outputdir','$codedir'); quit"