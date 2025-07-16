# Variable initialization
sub=$1
sess=$2
base=$3

module load wb_contain/1.0.0-linux_x64-ncf

root="${base}/scenes"
scene_file="${root}/Example_networks.scene"
orig_file1="EXAMPLE" # DO NOT CHANGE
orig_file2="YYMMDD_MGBX" # DO NOT CHANGE

oroot="${base}/${sub}/${sub}_${sess}/NETWORKS/MSHBM_outputs"

# Create the output directory if it doesn't exist
mkdir -p "$oroot"

# Set the new scene file name
new_scene="${root}/${sub}_networks.scene"

# Replace template files with the correct values
echo "Replacing ${orig_file1} with ${sub} in ${new_scene}"
sed -e "s@${orig_file1}@${sub}@g" "${scene_file}" > "${new_scene}"
sed -i -e "s@${orig_file2}@${sess}@g" "${new_scene}"

# Move the scene file to the output directory
echo "Moving to $oroot"
wb_contain -v 1.3.2 wb_command -scene-file-relocate "${new_scene}" "$oroot/${sub}_networks.scene"
