module load wb_contain/1.0.0-linux_x64-ncf
module load imagemagick/7.1.1-8-rocky8_x64-ncf

sub=$1
base=$2
IFS=',' read -r -a networks <<< "$3"
Ein=$4

subscenes=("Sulc+LH+Inflated+Dorsal" "Sulc+RH+Inflated+Dorsal" "SearchSpace+LH+Inflated+Dorsal" "SearchSpace+RH+Inflated+Dorsal" "AllNet+LH+MidT+Dorsal" "sgACCNet+LH+MidT+Dorsal" "sgACCNeg+LH+MidT+Dorsal" "AllNet+RH+MidT+Dorsal") 
for network in "${networks[@]}"; do
    subscenes+=("${network}+MidT+Dorsal")
done

subscenes_cluster=()
for network in "${networks[@]}"; do
    subscenes_cluster+=("${network}+Clusters+Inflated+Dorsal")
done

# Dynamically define subscenes_tansroi using the networks array
subscenes_tansroi=("sgACCNeg+LH+TANS+ROI")
for network in "${networks[@]}"; do
    subscenes_tansroi+=("${network}+TANS+ROI")
done

subscenes_magnE=("sgACCNeg+LH+magnE+LH+MidT+Dorsal")
for network in "${networks[@]}"; do
    subscenes_magnE+=("${network}+magnE+LH+MidT+Dorsal")
    subscenes_magnE+=("${network}+magnE+LM+MidT+Dorsal")
    subscenes_magnE+=("${network}+magnE+RH+MidT+Dorsal")
    subscenes_magnE+=("${network}+magnE+RM+MidT+Dorsal")
done


# Dynamically define subscenes_dose using the networks array
subscenes_dose=()
for network in "${networks[@]}"; do
    subscenes_dose+=("${network}+Dose+MidT+Dorsal")
done


root=${base}/${sub}/${Ein}/report

scene_file=${root}/${sub}_brain.scene 

oroot=$root/efield_figures
mkdir -p $oroot
for ss in ${subscenes[@]}; do
	echo $ss
	#Capture image
	wb_contain -v 1.3.2 wb_command -show-scene  ${scene_file} ${ss} $oroot/$ss.png 1053 754
	
done

for ssc in ${subscenes_cluster[@]}; do
	echo $ssc
	#Capture image
	wb_contain -v 1.3.2 wb_command -show-scene  ${scene_file} ${ssc} $oroot/$ssc.png 1053 754
done

for ssm in ${subscenes_magnE[@]}; do
	echo $ssm
	#Capture image
	wb_contain -v 1.3.2 wb_command -show-scene  ${scene_file} ${ssm} $oroot/$ssm.png 1053 754
done	

for sst in ${subscenes_tansroi[@]}; do
	echo $sst
	wb_contain -v 1.3.2 wb_command -show-scene ${scene_file} ${sst} -set-map-yoke I 1 $oroot/${sst}_targnet.png 1053 754
	wb_contain -v 1.3.2 wb_command -show-scene ${scene_file} ${sst} -set-map-yoke I 2 $oroot/${sst}_targnetsearch.png 1053 754
	wb_contain -v 1.3.2 wb_command -show-scene ${scene_file} ${sst} -set-map-yoke I 3 $oroot/${sst}_targnetsearchsulc.png 1053 754
	wb_contain -v 1.3.2 wb_command -show-scene ${scene_file} ${sst} -set-map-yoke I 4 $oroot/${sst}_targpatch.png 1053 754
done
for ssd in ${subscenes_dose[@]}; do
    echo "$ssd"
    for m in $(seq 10 19); do  # seq START END generates a sequence of numbers from START to END
        wb_contain -v 1.3.2 wb_command -show-scene "${scene_file}" "${ssd}" -set-map-yoke I "${m}" "${oroot}/${ssd}_${m}.png" 1053 754
    done
done
