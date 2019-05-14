#!/bin/bash
# This script is for batch proccessing of BEDPOSTx as called by the
# preproc.sh script

# Define filenames and folders
i=${1}; dir_filename=${2};
indx=$(($i - 1))
indx=$(($indx * 3)) # This number will need to change based on how many folders are inputted per subject
((indx++))
tmp=$(cat $dir_filename | head -n $indx | tail -1)
basedir=$(awk -v "X=$tmp" 'BEGIN { split(X, names, "/"); print "/"names[2]"/"names[3]"/"names[4]"/"names[5]"/"names[6]"/"names[7]"/"names[8]"/"names[9]}')
data_analysis_folder=$basedir/data; cd $data_analysis_folder
bp_folder=${data_analysis_folder}"/bedpostx"; mkdir $bp_folder; cd $bp_folder
eddy_folder=${data_analysis_folder}"/eddy"

#Move items to bedpostx folder
mv ${eddy_folder}"/b1000_nodif_brain_mask.nii.gz" ./nodif_brain_mask.nii.gz
cp ${eddy_folder}"/b1000.nii.gz" ./data.nii.gz
cp ${eddy_folder}"/b1000.bvec" ./bvecs
cp ${eddy_folder}"/b1000.bval" ./bvals

#run Bedpostx
bedpostx_gpu $bp_folder -n 2
