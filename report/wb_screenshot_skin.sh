module load wb_contain/1.0.0-linux_x64-ncf
module load imagemagick/7.1.1-8-rocky8_x64-ncf

sub=$1
base=$2
IFS=',' read -r -a networks <<< "$3"
Ein=$4

subscenes=() 
for network in "${networks[@]}"; do
    subscenes+=("${network}+Skin+CoilCenter")
    subscenes+=("${network}+Skin+CoilOrientation")
done

root=${base}/${sub}/${Ein}/report
scene_file=${root}/${sub}_skin.scene

oroot=$root/skin_figures
mkdir -p $oroot
for ss in ${subscenes[@]}; do
	echo $ss
	#Capture image
	wb_contain -v 1.3.2 wb_command -show-scene  ${scene_file} ${ss} $oroot/$ss.png 1053 754
	# Use ImageMagick to trim the image and save it to the destination directory
  	convert "$oroot/$ss.png" -trim +repage -transparent white "$oroot/$ss.png"
done
