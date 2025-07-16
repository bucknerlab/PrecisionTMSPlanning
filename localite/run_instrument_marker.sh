#!/bin/bash

CODEDIR=$1
SUB=$2
EFOLDER=$3
OUTDIR=$4
TARGET=$5
DISTANCE=$6
AVOID=$7
BASE=$8


module load simnibs
cd ${CODEDIR}

simnibs_python get_localite_gumm_file.py -b ${BASE} -e ${EFOLDER} -s ${SUB} -d ${DISTANCE} -a ${AVOID} -o ${OUTDIR} -t ${TARGET}
