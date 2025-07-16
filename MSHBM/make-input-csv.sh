###############################################################
# Prep the sub_list csv for MSHBM.
#
# Arguments:
#   sub   - Subject ID
#   root  - Root directory containing Templates and subject data folders
#   sesh  - Session identifier
#
# Steps:
#   - Copies a template CSV file into the subject’s NETWORKS directory
#   - Renames the file, replacing placeholders with subject/session values
#   - Cleans up temporary files
###############################################################

sub=$1
root=$2
sesh=$3 

template=${root}/Templates/
dest=${root}/${sub}/${sub}_${sesh}/NETWORKS/

mkdir -p $dest

scp ${template}/sub_list_SUBID.csv ${dest}/

cd ${dest}

mv sub_list_SUBID.csv sub_list_${sub}.csv

newfile=sub_list_${sub}.csv

sed -ie "s@SUBID_PLACEHOLDER@${sub}@g" ${newfile}
sed -ie "s@SESS_PLACEHOLDER@${sesh}@g" ${newfile}

rm *.csve

echo "created ${dest}/${newfile}!"
