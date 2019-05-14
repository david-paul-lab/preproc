#!/bin/bash
# This script is for running DTIFIT with the preproc.sh script
i=${1}; dir_filename=${2}; matlab_bin=${3}
indx=$(($i - 1))
indx=$(($indx * 3)) # This number is based on number of folders per subject
((indx++))
tmp=$(cat $dir_filename | head -n $indx | tail -1)
basedir=$(awk -v "X=$tmp" 'BEGIN { split(X, names, "/"); print "/"names[2]"/"names[3]"/"names[4]"/"names[5]"/"names[6]"/"names[7]"/"names[8]"/"names[9]}')
data_analysis_folder=${basedir}"/data"
eddy_folder=${data_analysis_folder}"/eddy"

#Split eddy corrected file into separate volumes
split_folder=${eddy_folder}"/split"
mkdir $split_folder
cd $split_folder
full_eddy_volume=${eddy_folder}"/data_ec.nii.gz"
if [ ! -e vol0000.nii.gz ]; then
  echo "Running fslsplit on Eddy Corrected Data..."
  fslsplit $full_eddy_volume
fi
ls >> ${eddy_folder}"/eddy_corrected_volumes.txt" #list of all total_volumes

# Run Matlab script to create updated bvals and bvecs files, and text file with b=1000 volumes
bvecfile=${eddy_folder}"/fullmerged.bvec"
bvalfile=${eddy_folder}"/fullmerged.bval"
ecovolumes=${eddy_folder}"/eddy_corrected_volumes.txt"
#if [ ! -e $bvecfile ]; then
matlab -nodisplay \
-r "cd ${matlab_bin}; split_bvalue_data('${bvecfile}','${bvalfile}','${ecovolumes}'); exit"
mv ${matlab_bin}"/b1000.bval" $eddy_folder; bvalfile=${eddy_folder}"/b1000.bval"
mv ${matlab_bin}"/b1000.bvec" $eddy_folder; bvecfile=${eddy_folder}"/b1000.bvec"
mv ${matlab_bin}"/b1000volumes.txt" $eddy_folder
#else
#echo "It looks like you have already created updated bvec and bvals files!"
#fi

# Merge the b=1000 (and b=0) volumes into a single NIFTI file
cd $split_folder
b1000=${eddy_folder}/b1000.nii.gz
if [ ! -e $b1000 ]; then
  num_b1000_files=$(wc -l < ${eddy_folder}"/b1000volumes.txt"); ((num_b1000_files++))
  vol=() # Place the the b=1000 and b=0 volumes into an array
  for ((volume = 1; volume <= num_b1000_files; volume++)); do
    vol[$volume]=$(sed -n "$volume p" ${eddy_folder}"/b1000volumes.txt")
  done
  files="${vol[*]}"
  echo "Creating file with Eddy Corrected B=1000 volumes"
  echo $files
  fslmerge -t $b1000 $files
else
  echo "It looks like you already have a B=1000 file!"
fi

# Create brain mask and fit tensors
b1000_nodif=${eddy_folder}"/b1000_nodif.nii.gz"
b1000_nodif_brain=${eddy_folder}"/b1000_nodif_brain.nii.gz"
fslroi $b1000 $b1000_nodif 3 1 #extract the first AP b=0 volume
bet $b1000_nodif $b1000_nodif_brain -m -f 0.28 -R
tensor_dir=${data_analysis_folder}"/tensors"; mkdir $tensor_dir; cd $tensor_dir
dtifit -k $b1000 -o "b1000" -m ${b1000_nodif_brain}"_mask" -r $bvecfile -b $bvalfile
