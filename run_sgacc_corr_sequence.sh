#!/bin/bash
#
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 1
#SBATCH --mem=10GB
#SBATCH -t 0-24:00
#SBATCH --job-name SGACC_CORR

codedir=$1
sub=$2
sess=$3
datadir=$4
iprocdir=$5
efieldfolder=$6
threshold=$7

module load matlab/R2019b-fasrc01-ncf
module load wb_contain/1.0.0-linux_x64-ncf

cd $codedir
pwd

#srun 
matlab -nodisplay -nodesktop -r "sgacc_corr_sequence('${codedir}','${sub}','${sess}','${datadir}','${iprocdir}','${efieldfolder}', '${threshold}')"
