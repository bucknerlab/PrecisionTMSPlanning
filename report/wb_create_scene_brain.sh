sub=$1
base=$2
Ein=$3

root=${base}/scenes
scene_file=${root}/iTMS_32k_report_brain.scene
orig_file1="EXAMPLE" # DO NOT CHANGE THIS VARIABLE
suffix="_brain" 

module load wb_contain/1.0.0-linux_x64-ncf

oroot=${base}/${sub}/${Ein}/report
mkdir -p $oroot
new_scene=${root}/${sub}${suffix}.scene
#Replace template files with input files
echo "replacing ${orig_file1} with ${sub}"
echo $new_scene
sed -e "s@${orig_file1}@${sub}@g" ${scene_file} > ${new_scene}
echo "moving to $oroot"
wb_contain -v 1.3.2 wb_command -scene-file-relocate ${new_scene} $oroot/${sub}${suffix}.scene

