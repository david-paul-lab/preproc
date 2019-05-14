#!/bin/bash
# Script for running topup batch from fsl

# Define filenames and folders
i=${1}; dir_filename=${2}; echo_spacing=${3}; epi_factor=${4}
indx=$(($i - 1))
indx=$(($indx * 3)) # This number will need to change based on how many folders are inputted per subject
((indx++))
tmp=$(cat $dir_filename | head -n $indx | tail -1)
basedir=$(awk -v "X=$tmp" 'BEGIN { split(X, names, "/"); print "/"names[2]"/"names[3]"/"names[4]"/"names[5]"/"names[6]"/"names[7]"/"names[8]"/"names[9]}')
data_analysis_folder=${basedir}"/data"

# Define paramters for acqparams file
col4=$(echo "scale=10; $echo_spacing*$epi_factor *.001" | bc)
pa_params="0 1 0 "${col4}
ap_params="0 -1 0 "${col4}

topup_dir=$data_analysis_folder"/topup"
mkdir $topup_dir

# Process P>>A data
# Note: For topup, there is no "optimal" number of PA/AP B=0 volumes reported
# in the literature During preliminary testing, 3 PA and 5 AP volumes yielded
# great results. As such PA values will be capped at 3, and AP volumes at
# (2+PA volumes).
mkdir ${data_analysis_folder}"/pa_b0_split"
cd ${data_analysis_folder}"/pa_b0_split"
pa_b0_volume=${data_analysis_folder}"/pa_b0.nii"
if [ ! -e vol0000.nii.gz ]; then
  echo "Running fslsplit on P>>A acquisition..."
  fslsplit $pa_b0_volume
fi
num_pa_files=$(ls -l | wc -l)
((num_pa_files--))
echo The number of PA files is $num_pa_files
if [ $num_pa_files -gt 3 ]; then
  echo "NOTE: There are too many PA volumes! We will truncate down to 3"
  pa_vols=()
  for ((volume = 1; volume <= 3; volume++));  do
    pa_vols=(${pa_vols[@]} "$volume")
  done
  files="${palvols[*]}"
  echo "Merging first 3 PA volumes..."
  if [ ! -e ${data_analysis_folder}/pa_b0_truncated.nii.gz ]; then
    fslmerge -t ${data_analysis_folder}"/pa_b0_truncated.nii.gz" $files
  fi
  pa_b0_volume=${data_analysis_folder}"/pa_b0_truncated.nii.gz"
fi
# write to acqparams file
acqparams=${topup_dir}"/acqparams.txt"
touch ${acqparams}
if [ -e $acqparams ]; then
  mv $acqparams ${acqparams}".bak"
fi
for ((volume = 1; volume <= num_pa_files; volume++)); do
  printf '%s\n' "$pa_params" >> $acqparams
done

# Process A>>P data (this assumes that this data is the DTI data)
mkdir ${data_analysis_folder}"/ap_b0_split"
cd ${data_analysis_folder}"/ap_b0_split"
if [ ! -e vol0000.nii.gz ]; then
  echo "Running fslsplit on A>>P acquisition..."
  fslsplit ${data_analysis_folder}"/data.nii"
fi
# Index the B=0 volumes
cd ${data_analysis_folder}
num_volumes=$(cat data.bval | wc -w)
tr ' ' '\n' < ${data_analysis_folder}"/data.bval" >> tmp_list.txt #transpose b values into 1 column
awk '{print " "$0}' tmp_list.txt >> tmp_list2.txt # add blank space before each value
grep -n ' 0' tmp_list2.txt | cut -f1 -d: >> b0_volumes_tmp.txt # identify only the b0 volumes
rm tmp_list.txt; rm tmp_list2.txt # remove the tmp files

# Place the the B=0 volumes into an array
cd ${data_analysis_folder}"/ap_b0_split"
num_ap_files=$((num_pa_files + 2))
ls >> ../all_volumes.txt
vol=()
for ((volume = 1; volume <= num_ap_files; volume++)); do
  bindex=$(sed -n "$volume p" ../b0_volumes_tmp.txt)
  vol[$volume]=$(sed -n "$bindex p" ../all_volumes.txt)
  #echo $ap_params >> $acqparams # write to acqparams file
  printf '%s\n' "$ap_params" >> $acqparams
done
files="${vol[*]}"
echo $files

# Create B0_merge file
if [ ! -e ${data_analysis_folder}/b0_merged.nii.gz ]; then
  echo "Creating merged B0 image for Topup..."
  fslmerge -t ${data_analysis_folder}/b0_merged.nii.gz $pa_b0_volume $files
fi
# Run Topup!!
cd $topup_dir
if [ ! -e ${topup_dir}/hifib0.nii.gz ]; then
  echo "Running Topup..."
  topup --imain=${data_analysis_folder}/b0_merged.nii.gz --datain=$acqparams --iout=hifib0.nii.gz --config=b02b0.cnf --fout=topupfield --out=topupresults --verbose
fi
echo "Top up complete!"
