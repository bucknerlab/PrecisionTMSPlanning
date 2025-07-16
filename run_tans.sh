#!/bin/bash
#
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 32
#SBATCH --mem=150GB
#SBATCH -t 0-24:00
#SBATCH --job-name TANS_PROF

SUB=$1
INDIR=$2
HEAD=$3
ROI=$4
GRID=$5
EFIELD=$6
OPTIMIZE=$7
DOSE=$8

PARCEL=$9
THRESH=${10}
TARGET=${11}
AVOID=${12}
SEARCH=${13}
OUTDIR=${14}
CODEDIR=${15}
MASKDIR=${16}

module load freesurfer/7.4.1-centos8_x64-ncf
module load fsl/6.0.6.4-centos7_x64-ncf
module load wb_contain/1.0.0-linux_x64-ncf
module load matlab/R2019b-fasrc01-ncf

echo -e "Running tans_PROFETT with the following parameters: \n OUTDIR = '${OUTDIR}' \n SUB = ${SUB}'  \n INDIR = ${INDIR} \n HEAD = '${HEAD}' \n ROI = '${ROI}' \n GRID = '${GRID}' \n EFIELD = '${EFIELD}' \n OPTIMIZE = '${OPTIMIZE}' \n DOSE = '${DOSE}' \n PARCEL = '${PARCEL}' \n THRESH = '${THRESH}' \n TARGET = '${TARGET}' \n AVOID = '${AVOID}' \n SEARCH = '${SEARCH}' \n CODEDIR = '${CODEDIR}' \n MASKDIR = '${MASKDIR}'"

cd $CODEDIR
pwd

#srun 
matlab -nodisplay -nodesktop -r "tans_PROFETT('${SUB}','${INDIR}','${HEAD}','${ROI}','${GRID}','${EFIELD}','${OPTIMIZE}','${DOSE}','${PARCEL}','${THRESH}','${TARGET}','${AVOID}','${SEARCH}','${OUTDIR}', '${CODEDIR}', '${MASKDIR}')"

