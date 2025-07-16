sub=$1
root=$2
IFS=',' read -r -a conditions <<< "$3"
Ein=$4

echo "Copying coordinates and dose files to report folder."
# merge the non-cluster ROI files (one per network)
echo $sub

oroot=${root}/${sub}/${Ein}/report/dose
mkdir -p $oroot
for condition in ${conditions[@]}; do
	echo $condition
	WKDIR=${root}/${sub}/${Ein}/tans/${condition}/A0/Optimize
	dose=$WKDIR/BestDose.txt
	curve=$WKDIR/OnTarget_vs_HotspotSize_Curve_AbsThreshold_100Vm.png
	hotspot=$WKDIR/OnTarget_AbsThreshold_100Vm_MinHotSpotSize_1000mm2.png
	scp $curve ${oroot}/${condition}_didt_curve.png
	scp $hotspot ${oroot}/${condition}_hotspot.png
	scp $dose ${oroot}/${condition}_bestdose.txt

done
echo $sub
oroot=${root}/${sub}/${Ein}/report/coordinates
mkdir -p $oroot
for condition in ${conditions[@]}; do
	echo $condition
	WKDIR=${root}/${sub}/${Ein}/tans/${condition}/A0/Optimize
	dose=$WKDIR/BestDose.txt
	center=$WKDIR/CoilCenterCoordinates.txt
	orient=$WKDIR/CoilOrientationCoordinates.txt
	scp $center ${oroot}/${condition}_center.txt
	scp $orient ${oroot}/${condition}_orientation.txt
done
