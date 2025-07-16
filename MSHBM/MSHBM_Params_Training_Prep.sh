#!/bin/bash
#
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -p cnl
#SBATCH --job-name MSHBM_Prep
#SBATCH --mem=100GB
#SBATCH -t 0-12:00

module load ncf/1.0.0-fasrc01
module load freesurfer/6.0.0-ncf
module load matlab/R2019b-fasrc01-ncf
module load connectome_workbench/1.3.2-centos6_x64-ncf
module load fsl/5.0.4-ncf
export CBIG_CODE_DIR=$codedir/ncf_tools/CBIG_CODE

sub_list=$1
outputdir=$2
codedir=$3

matlab -nojvm -nodesktop -r "addpath(genpath('$codedir')); MSHBM_wrapper('$sub_list','$outputdir','$codedir'); quit" &&
sleep 0.1

sbatch -o ${outputdir}/log/MSHBM_Training_%j.out -e ${outputdir}/log/MSHBM_Training_%j.err $codedir/MSHBM/MSHBM_Params_Training.sh $sub_list 15 $outputdir $codedir


