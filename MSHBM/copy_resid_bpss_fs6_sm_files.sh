###############################################################
# Script to copy REST-BOLD data for MSHBM network estimation
#
# Arguments:
#   SUB      - Subject ID
#   DATADIR  - Top-level data directory
#   SESS     - Session identifier
#   IPROCDIR - iProc directory name (usually iProc_BASELINE in our data)
#
# Summary:
#   - Creates a directory for the subject's REST-BOLD input data.
#   - Counts and copies the processed REST-BOLD files in both hemispheres to the new directory.
###############################################################

SUB=$1
DATADIR=$2
SESS=$3
IPROCDIR=$4

SCRATCHDIS=${DATADIR}/${SUB}/${SUB}_${SESS}/NETWORKS/baseline_rest_input/${SUB}

mkdir -p $SCRATCHDIS

RESTDIR=${DATADIR}/${SUB}/${IPROCDIR}/MRI/${SUB}/FS6

lh_rest=*/REST*/lh*nat_resid_bpss_fsaverage6_sm*.nii.gz
rh_rest=*/REST*/rh*nat_resid_bpss_fsaverage6_sm*.nii.gz
cd $RESTDIR
l=`ls $lh_rest | wc -l`
r=`ls $rh_rest | wc -l`

echo "${SUB}...left ${l} right ${r}"

cp $lh_rest $SCRATCHDIS
cp $rh_rest $SCRATCHDIS