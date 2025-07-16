module load wb_contain/1.0.0-linux_x64-ncf

sub=$1
root=$2
IFS=',' read -r -a conditions <<< "$3"
Ein=$4
# merge the non-cluster ROI files (one per network)
echo $sub
for condition in ${conditions[@]}; do
	echo $condition
	WKDIR=${root}/${sub}/${Ein}/tans/${condition}/ROI
	cd $WKDIR
	wb_contain -v 1.3.2 wb_command -cifti-merge TANS_ROI.dtseries.nii -cifti TargetNetwork.dtseries.nii -cifti TargetNetwork+SearchSpace.dtseries.nii -cifti TargetNetwork+SearchSpace+SulcalMask.dtseries.nii -cifti TargetNetworkPatch.dtseries.nii

done
