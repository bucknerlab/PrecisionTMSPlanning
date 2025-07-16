CODEDIR=$1
SUB=$2
ROOT=$3
CONDITIONS=$4

# cd $CODEDIR


echo "HELLO"

#srun 
matlab -nodisplay -nodesktop -r "quantify_efield_hotspot('${CODEDIR}','${SUB}','${ROOT}','${CONDITIONS}');exit;"