# Variable initialization
sub=$1
sess=$2
base=$3

module load wb_contain/1.0.0-linux_x64-ncf
module load imagemagick

subscenes=("L_Lateral" "L_Medial" "L_Anterior" "L_Posterior" "R_Lateral" "R_Medial" "R_Anterior" "R_Posterior")

root="${base}/${sub}/${sub}_${sess}/NETWORKS/MSHBM_outputs"
scene_file=${root}/${sub}_networks.scene


oroot=$root
mkdir -p $oroot

for ss in ${subscenes[@]}; do
	echo $ss
	#Capture image
	wb_contain -v 1.3.2 wb_command -show-scene  ${scene_file} ${ss} $oroot/$ss.png 1053 390
	convert "$oroot/$ss.png" -transparent white "$oroot/$ss.png"

done

echo "Done taking screenshots of networks!"
