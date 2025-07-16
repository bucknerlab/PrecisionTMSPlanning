#!/bin/bash

SUBID=$1
SESS=$2
BASE=$3
CODEDIR=$4

# load modules

module load Mambaforge/23.11.0-fasrc01

which python
mamba activate report

curr_dir=$(pwd)
cd ${CODEDIR}/MSHBM
pwd


python make-network-only-pptx.py ${SUBID} ${SESS} ${BASE} ${CODEDIR}

cd ${curr_dir}
pwd

mamba deactivate
