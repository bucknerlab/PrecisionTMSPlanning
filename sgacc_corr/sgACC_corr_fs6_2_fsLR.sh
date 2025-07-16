module load wb_contain/1.0.0-linux_x64-ncf

SUB=$1
CODEDIR=$2
DATADIR=$3
EFIELDFOLDER=$4

FS6PATH=${CODEDIR}/ncf_tools/fsaverage6

file=sgACC_correlations_r2z


# Get midthickness and sphere files for future conversions from high res native space to 32k fs_LR
fsLR=${CODEDIR}/ncf_tools/fsLR
newLsphere=fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii
newRsphere=fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii
METHOD=ADAP_BARY_AREA

INPATH=${DATADIR}/${SUB}/${EFIELDFOLDER}/anticorrelations
OUTPATH=${INPATH}/fsaverage_LR32k/r2z
mkdir -p $OUTPATH

wb_contain -v 1.3.2 wb_command -cifti-separate ${INPATH}/${SUB}_${file}.dscalar.nii COLUMN -metric CORTEX_LEFT ${INPATH}/${SUB}_${file}.lh.func.gii -metric CORTEX_RIGHT ${INPATH}/${SUB}_${file}.rh.func.gii

wb_contain -v 1.3.2 wb_command -metric-resample ${INPATH}/${SUB}_${file}.lh.func.gii ${FS6PATH}/CONVERTED/FS6_lh.sphere.reg.surf.gii ${fsLR}/${newLsphere} ${METHOD} ${OUTPATH}/${SUB}_${file}_32k.lh.func.gii -area-metrics ${fsLR}/fsaverage6.L.midthickness_va_avg.41k_fsavg_L.shape.gii ${fsLR}/fs_LR.L.midthickness_va_avg.32k_fs_LR.shape.gii
echo ${OUTPATH}/${SUB}_${file}_32k.lh

wb_contain -v 1.3.2 wb_command -metric-resample ${INPATH}/${SUB}_${file}.rh.func.gii ${FS6PATH}/CONVERTED/FS6_rh.sphere.reg.surf.gii ${fsLR}/${newRsphere} ${METHOD} ${OUTPATH}/${SUB}_${file}_32k.rh.func.gii -area-metrics ${fsLR}/fsaverage6.R.midthickness_va_avg.41k_fsavg_R.shape.gii ${fsLR}/fs_LR.R.midthickness_va_avg.32k_fs_LR.shape.gii
echo ${OUTPATH}/${SUB}_${file}_32k.rh

wb_contain -v 1.3.2 wb_command -cifti-create-dense-timeseries ${OUTPATH}/${SUB}_${file}_32k.dtseries.nii -left-metric ${OUTPATH}/${SUB}_${file}_32k.lh.func.gii -right-metric ${OUTPATH}/${SUB}_${file}_32k.rh.func.gii -timestep 1 -timestart 0

