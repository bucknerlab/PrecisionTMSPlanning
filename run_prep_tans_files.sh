#!/bin/bash
#
#SBATCH -n 1                           
#SBATCH -N 1                           
#SBATCH -c 1                           
#SBATCH --mem=10GB                     
#SBATCH -t 0-24:00                     
#SBATCH --job-name PREP_TANS           

# NOTE: The purpose of this script is to prepare iProc + MSHBM outputs for TANS E-Field modeling / optimization. This is specific to the needs of our data.

# Read arguments
CODEDIR=$1
SUBID=$2
SESS=$3
DATADIR=$4
IPROC_folder=$5
EFIELD_folder=$6

module load freesurfer/6.0.0-ncf        # Load FreeSurfer module

# Add workbench to PATH
export PATH=${PATH}:${CODEDIR}/ncf_tools/connectome-workbench/1.3.2-fasrc01/bin_rh_linux64/
FS6PATH=${CODEDIR}/ncf_tools/fsaverage6        # Path to fsaverage6 templates

# Prepare files for TANS
WKDIR=${DATADIR}/${SUBID}/${EFIELD_folder}   
	
mkdir -p ${WKDIR}                          
cd $WKDIR                                  
mkdir -p ${WKDIR}/iprocfiles              
mkdir -p ${WKDIR}/anat/T1w/fsaverage_LR32k 
mkdir -p ${WKDIR}/anat/MNINonLinear/fsaverage_LR32k 
mkdir -p ${WKDIR}/pfm                      

OUTPATH=${WKDIR}                           

echo "Starting..."                         
echo "Do not worry about the [xxx] command not found messages. This is normal for reading in the .cfg file"

# Source the subject-specific iproc configuration file
iproc_config=${DATADIR}/${SUBID}/${IPROC_folder}/MRI/Subject_*/${SUBID}.cfg
source $iproc_config

# Set up anatomical destination/source directories
ANATDST=${WKDIR}/anat/T1w
ANATSRC=${DATADIR}/${SUBID}/${IPROC_folder}/MRI/${SUBID}/cross_session_maps/templates

# Copy the T1 weighted MRI file to the working directory
scp ${ANATSRC}/${T1_SESS}_mpr_reorient.nii.gz ${ANATDST}/mpr_reorient.nii.gz

# Set surface directory for subject
SURFDIR=${DATADIR}/${SUBID}/${IPROC_folder}/MRI/fs/${T1_SESS}_${T1_SCAN_NO}/surf

# Loop over surface files and hemispheres, copying each to iprocfiles
hemis=(lh rh)
files=(pial white sulc sphere.reg inflated)
for file in ${files[@]}; do
	for hemi in ${hemis[@]};do
		echo "copying ${SUBID} ${hemi}.${file}"
		scp ${SURFDIR}/${hemi}.${file} ${WKDIR}/iprocfiles/${SUBID}.${hemi}.${file}
	done
done

# Set up fs_LR atlas directory and names for registration spheres
fsLR=${CODEDIR}/ncf_tools/fsLR
newLsphere=fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii
newRsphere=fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii

SRC=${WKDIR}/iprocfiles                  # Source directory for processing files
DST=${WKDIR}/anat/T1w/fsaverage_LR32k    # Destination for processed files

mkdir -p ${SRC}/native_highres           # Directory for native high-res surfaces

# Generate subject-specific midthickness and registered spheres for resampling
wb_shortcuts -freesurfer-resample-prep ${SRC}/${SUBID}.lh.white ${SRC}/${SUBID}.lh.pial ${SRC}/${SUBID}.lh.sphere.reg ${fsLR}/${newLsphere} ${SRC}/native_highres/${SUBID}.lh.midthickness.surf.gii ${DST}/${SUBID}.lh.midthickness.32k_fs_LR.surf.gii ${SRC}/native_highres/${SUBID}.lh.sphere.reg.surf.gii
wb_shortcuts -freesurfer-resample-prep ${SRC}/${SUBID}.rh.white ${SRC}/${SUBID}.rh.pial ${SRC}/${SUBID}.rh.sphere.reg ${fsLR}/${newRsphere} ${SRC}/native_highres/${SUBID}.rh.midthickness.surf.gii ${DST}/${SUBID}.rh.midthickness.32k_fs_LR.surf.gii ${SRC}/native_highres/${SUBID}.rh.sphere.reg.surf.gii

# Convert FreeSurfer surface files to GIFTI format in native high-res space
files=(pial white inflated)
for file in ${files[@]}; do
	for hemi in ${hemis[@]};do
		mris_convert --to-scanner ${SRC}/${SUBID}.${hemi}.${file} ${SRC}/native_highres/${SUBID}.${hemi}.${file}.surf.gii
	done
done

# Resample native high-res surfaces to 32k fs_LR using barycentric method
METHOD=BARYCENTRIC
files=(pial white inflated)
for file in ${files[@]}; do
	wb_command -surface-resample ${SRC}/native_highres/${SUBID}.lh.${file}.surf.gii ${SRC}/native_highres/${SUBID}.lh.sphere.reg.surf.gii ${fsLR}/${newLsphere} ${METHOD} ${DST}/${SUBID}.lh.${file}.32k_fs_LR.surf.gii
	wb_command -surface-resample ${SRC}/native_highres/${SUBID}.rh.${file}.surf.gii ${SRC}/native_highres/${SUBID}.rh.sphere.reg.surf.gii ${fsLR}/${newRsphere} ${METHOD} ${DST}/${SUBID}.rh.${file}.32k_fs_LR.surf.gii
done


# Get functional network parcellation files
MSHBMDIR=${DATADIR}/${SUBID}/${SUBID}_${SESS}/NETWORKS/MSHBM_outputs

# Find left and right hemisphere network label files
leftLabel=`ls ${MSHBMDIR}/*_lh.label.gii`
rightLabel=`ls ${MSHBMDIR}/*_rh.label.gii`
scp $leftLabel ${SRC}/${SUBID}.NETWORKS_lh.label.gii
scp $rightLabel ${SRC}/${SUBID}.NETWORKS_rh.label.gii

METHOD=ADAP_BARY_AREA

# Resample functional networks from FS6 to native high-res (left and right)
echo "LEFT metric resample ${METHOD}"
wb_command -label-resample ${SRC}/${SUBID}.NETWORKS_lh.label.gii ${FS6PATH}/CONVERTED/FS6_lh.sphere.reg.surf.gii ${SRC}/native_highres/${SUBID}.lh.sphere.reg.surf.gii ${METHOD} ${SRC}/native_highres/${SUBID}.NETWORKS_lh_resampled_${METHOD}.label.gii -area-surfs ${FS6PATH}/FS6_lh.midthickness.surf.gii ${SRC}/native_highres/${SUBID}.lh.midthickness.surf.gii
echo "RIGHT metric resample ${METHOD}"
wb_command -label-resample ${SRC}/${SUBID}.NETWORKS_rh.label.gii ${FS6PATH}/CONVERTED/FS6_rh.sphere.reg.surf.gii ${SRC}/native_highres/${SUBID}.rh.sphere.reg.surf.gii ${METHOD} ${SRC}/native_highres/${SUBID}.NETWORKS_rh_resampled_${METHOD}.label.gii -area-surfs ${FS6PATH}/FS6_rh.midthickness.surf.gii ${SRC}/native_highres/${SUBID}.rh.midthickness.surf.gii

# Resample the network labels to fs_LR 32k space
NETDST=${WKDIR}/pfm
echo "Resample LEFT network labels to fs_LR 32k"
wb_command -label-resample ${SRC}/native_highres/${SUBID}.NETWORKS_lh_resampled_${METHOD}.label.gii ${SRC}/native_highres/${SUBID}.lh.sphere.reg.surf.gii ${fsLR}/${newLsphere} ${METHOD} ${NETDST}/${SUBID}_NETWORKS_lh.32k_fs_LR.label.gii -area-surfs ${SRC}/native_highres/${SUBID}.lh.midthickness.surf.gii ${DST}/${SUBID}.lh.midthickness.32k_fs_LR.surf.gii
echo "Resample RIGHT network labels to fs_LR 32k"
wb_command -label-resample ${SRC}/native_highres/${SUBID}.NETWORKS_rh_resampled_${METHOD}.label.gii ${SRC}/native_highres/${SUBID}.rh.sphere.reg.surf.gii ${fsLR}/${newRsphere} ${METHOD} ${NETDST}/${SUBID}_NETWORKS_rh.32k_fs_LR.label.gii -area-surfs ${SRC}/native_highres/${SUBID}.rh.midthickness.surf.gii ${DST}/${SUBID}.rh.midthickness.32k_fs_LR.surf.gii


# Combine left and right fs_LR 32k network label files into a single CIFTI dlabel file
echo "COMBINE left and right fs_LR 32k network labels"
wb_command -cifti-create-label ${NETDST}/${SUBID}_NETWORKS.32k_fs_LR.dlabel.nii -left-label ${NETDST}/${SUBID}_NETWORKS_lh.32k_fs_LR.label.gii -right-label ${NETDST}/${SUBID}_NETWORKS_rh.32k_fs_LR.label.gii

# Convert combined dlabel to dtseries (dense timeseries) CIFTI
echo "CONVERT network dlabel to dtseries"
wb_command -cifti-change-mapping ${NETDST}/${SUBID}_NETWORKS.32k_fs_LR.dlabel.nii ROW ${NETDST}/${SUBID}_FunctionalNetworks_32k.dtseries.nii -series 1 1


# Prepare sulcal depth (sulc) metric surface files (convert to GIFTI)
echo "CONVERT sulc iproc to metric native highres"
mris_convert --to-scanner -c ${SRC}/${SUBID}.lh.sulc ${SRC}/${SUBID}.lh.white ${SRC}/native_highres/${SUBID}.lh.sulc.shape.gii
mris_convert --to-scanner -c ${SRC}/${SUBID}.rh.sulc ${SRC}/${SUBID}.rh.white ${SRC}/native_highres/${SUBID}.rh.sulc.shape.gii


# Resample sulcal depth metrics to fs_LR 32k
echo "Resample sulc to fs_LR 32k"
METHOD=ADAP_BARY_AREA

wb_command -metric-resample ${SRC}/native_highres/${SUBID}.lh.sulc.shape.gii ${SRC}/native_highres/${SUBID}.lh.sphere.reg.surf.gii ${fsLR}/${newLsphere} ${METHOD} ${DST}/${SUBID}.lh.sulc.32k_fs_LR.shape.gii -area-surfs ${SRC}/native_highres/${SUBID}.lh.midthickness.surf.gii ${DST}/${SUBID}.lh.midthickness.32k_fs_LR.surf.gii
wb_command -metric-resample ${SRC}/native_highres/${SUBID}.rh.sulc.shape.gii ${SRC}/native_highres/${SUBID}.rh.sphere.reg.surf.gii ${fsLR}/${newRsphere} ${METHOD} ${DST}/${SUBID}.rh.sulc.32k_fs_LR.shape.gii -area-surfs ${SRC}/native_highres/${SUBID}.rh.midthickness.surf.gii ${DST}/${SUBID}.rh.midthickness.32k_fs_LR.surf.gii

MNIDST=${WKDIR}/anat/MNINonLinear/fsaverage_LR32k

# Create dense scalar CIFTI file for sulcal depth (L/R combined)
wb_command -cifti-create-dense-scalar ${MNIDST}/${SUBID}.sulc.32k_fs_LR.dscalar.nii -left-metric ${DST}/${SUBID}.lh.sulc.32k_fs_LR.shape.gii -right-metric ${DST}/${SUBID}.rh.sulc.32k_fs_LR.shape.gii


### Medial Wall mask preparation
echo "metric resample fs6 medial wall to high res native space"
wb_command -metric-resample ${FS6PATH}/FS6_MedialWall_lh.shape.gii ${FS6PATH}/CONVERTED/FS6_lh.sphere.reg.surf.gii ${SRC}/native_highres/${SUBID}.lh.sphere.reg.surf.gii ADAP_BARY_AREA ${SRC}/native_highres/${SUBID}.MedialWall_lh_resampled_ADAP_BARY_AREA.shape.gii -area-surfs ${FS6PATH}/FS6_lh.pial.surf.gii ${SRC}/native_highres/${SUBID}.lh.pial.surf.gii
wb_command -metric-resample ${FS6PATH}/FS6_MedialWall_rh.shape.gii ${FS6PATH}/CONVERTED/FS6_rh.sphere.reg.surf.gii ${SRC}/native_highres/${SUBID}.rh.sphere.reg.surf.gii ADAP_BARY_AREA ${SRC}/native_highres/${SUBID}.MedialWall_rh_resampled_ADAP_BARY_AREA.shape.gii -area-surfs ${FS6PATH}/FS6_rh.pial.surf.gii ${SRC}/native_highres/${SUBID}.rh.pial.surf.gii


# Resample medial wall metrics to fs_LR 32k space
echo "resample to fs_LR 32k"
wb_command -metric-resample ${SRC}/native_highres/${SUBID}.MedialWall_lh_resampled_ADAP_BARY_AREA.shape.gii ${SRC}/native_highres/${SUBID}.lh.sphere.reg.surf.gii ${fsLR}/${newLsphere} ADAP_BARY_AREA ${DST}/${SUBID}.MedialWall_lh.32k_fs_LR.shape.gii -area-surfs ${SRC}/native_highres/${SUBID}.lh.midthickness.surf.gii ${DST}/${SUBID}.lh.midthickness.32k_fs_LR.surf.gii
wb_command -metric-resample ${SRC}/native_highres/${SUBID}.MedialWall_rh_resampled_ADAP_BARY_AREA.shape.gii ${SRC}/native_highres/${SUBID}.rh.sphere.reg.surf.gii ${fsLR}/${newRsphere} ADAP_BARY_AREA ${DST}/${SUBID}.MedialWall_rh.32k_fs_LR.shape.gii -area-surfs ${SRC}/native_highres/${SUBID}.rh.midthickness.surf.gii ${DST}/${SUBID}.rh.midthickness.32k_fs_LR.surf.gii

# Process medial wall masks 
wb_command -metric-math "round(x)" ${DST}/${SUBID}.MedialWall_bin_lh.32k_fs_LR.shape.gii -var x ${DST}/${SUBID}.MedialWall_lh.32k_fs_LR.shape.gii
wb_command -metric-math "1-(x)" ${MNIDST}/${SUBID}.L.atlasroi.32k_fs_LR.shape.gii -var x ${DST}/${SUBID}.MedialWall_bin_lh.32k_fs_LR.shape.gii
wb_command -metric-math "round(x)" ${DST}/${SUBID}.MedialWall_bin_rh.32k_fs_LR.shape.gii -var x ${DST}/${SUBID}.MedialWall_rh.32k_fs_LR.shape.gii
wb_command -metric-math "1-(x)" ${MNIDST}/${SUBID}.R.atlasroi.32k_fs_LR.shape.gii -var x ${DST}/${SUBID}.MedialWall_bin_rh.32k_fs_LR.shape.gii


# Compute Vertex Surface Area from midthickness surface for both hemispheres
echo "calculate vertex surface area from midthickness"
for Hemisphere in lh rh; do
surface_to_measure=${DST}/${SUBID}.${Hemisphere}.midthickness.32k_fs_LR.surf.gii
output_metric=${DST}/${SUBID}.${Hemisphere}.midthickness_va.32k_fs_LR.shape.gii
wb_command -surface-vertex-areas ${surface_to_measure} ${output_metric}
done

# Combine left and right vertex surface area metrics into a single CIFTI dscalar file
echo "Combine L and R vertex surface area and mask with medial wall"
left_metric=${DST}/${SUBID}.lh.midthickness_va.32k_fs_LR.shape.gii
roi_left=${MNIDST}/${SUBID}.L.atlasroi.32k_fs_LR.shape.gii
right_metric=${DST}/${SUBID}.rh.midthickness_va.32k_fs_LR.shape.gii
roi_right=${MNIDST}/${SUBID}.R.atlasroi.32k_fs_LR.shape.gii
midthickness_va_file=${DST}/${SUBID}.midthickness_va.32k_fs_LR.dscalar.nii

wb_command -cifti-create-dense-scalar ${midthickness_va_file} -left-metric ${left_metric} -roi-left ${roi_left} -right-metric ${right_metric} -roi-right ${roi_right}
echo "...Finished!"
