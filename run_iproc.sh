#!/bin/bash
# load modules and set environmental variables for development purposes,
# when you are not loading iProc via a module
CODEDIR=$1
SUBID=$2
SESS=$3
DATADIR=$4
IPROC_folder=$5
STEP=$6

cd ${CODEDIR}/iProc
pwd


module load \
  ncf/1.0.0-fasrc01 \
  parallel/20180522-rocky8_x64-ncf \
  miniconda3/4.5.12-ncf \
  mricron/2012_12-ncf \
  niftidiff/1.0-ncf \
  afni/2016_09_04-ncf \
  matlab/7.4-ncf \
  fsl/5.0.10-centos7_x64-ncf \
  mricrogl/2019_09_04-ncf \
  yaxil/0.2.2-nodcm2niix \
  freesurfer/6.0.0-ncf \
  imagemagick/6.7.8-10-rocky8_x64-ncf \
  ants/2.4.4-rocky8_x64-ncf \
  connectome_workbench/1.3.2-centos6_x64-ncf \
  dcm2niix/1.0.20230411-rocky8_x64-ncf



export _IPROC_CODEDIR=$(pwd)

echo ${_IPROC_CODEDIR}


python iProc.py -q ncf -c ${DATADIR}/${SUBID}/${IPROC_folder}/MRI/Subject_lists/${SUBID}.cfg --debug -s ${STEP} --overwrite
