#!/bin/bash
# This script is for batch proccessing of eddy_cuda as called by the
# preproc.sh script

# Define filenames and folders
i=${1}; dir_filename=${2}; matlab_bin=${3}; echo_spacing=${4}; epi_factor=${5}

indx=$(($i - 1))
indx=$(($indx * 3)) # This number will need to change based on how many folders are inputted per subject
((indx++))
tmp=$(cat $dir_filename | head -n $indx | tail -1)
basedir=$(awk -v "X=$tmp" 'BEGIN { split(X, names, "/"); print "/"names[2]"/"names[3]"/"names[4]"/"names[5]"/"names[6]"/"names[7]"/"names[8]"/"names[9]}')
data_analysis_folder=${basedir}"/data"

mkdir $data_analysis_folder/eddy
eddy_folder=$data_analysis_folder/eddy; cd $eddy_folder
topup_folder=$data_analysis_folder/topup

# Run matlab script to create scslep file
if [ ! -e ${eddy_folder}"/slspec.txt" ]; then
  jsonfile=$data_analysis_folder/image_header.json
  matlab -nodisplay \
  -r "cd ${matlab_bin}; slspec_create('${jsonfile}'); exit" | tail +10
  cp ${matlab_bin}/slspec.txt ${eddy_folder}
fi

#Create eddy_acqparams file and index file
if [ ! -e ${eddy_folder}"/eddy_acqparams.txt" ]; then
  col4=$(echo "scale=10; $echo_spacing*$epi_factor *.001" | bc)
  pa_params="0 1 0 "${col4}
  ap_params="0 -1 0 "${col4}
  printf "%d %d %d %1.4f\n%d %d %d %1.4f\n" $pa_params $ap_params >> \
  eddy_acqparams.txt
fi

# Create eddy_index.txt file
if [ ! -e ${eddy_folder}"/eddy_index.txt" ]; then
  cd ${data_analysis_folder}"/pa_b0_split"
  num_pa_files=$(ls -l | wc -l); ((num_pa_files--))
  cd ${data_analysis_folder}"/ap_b0_split"
  num_ap_files=$(ls -l | wc -l); ((num_ap_files--))
  total_volumes=$((num_ap_files + num_pa_files))
  for ((volume=1; volume <= $total_volumes; volume++)); do
    encode_value=2
    if [ $volume -le $num_pa_files ]; then
      encode_value=1
    fi
    printf "%d " $encode_value >> ${eddy_folder}"/eddy_index.txt"
  done
fi

# Create merged bvecs and bval files
if [ ! -e ${eddy_folder}"/fullmerged.bvec" ]; then
  cp $data_analysis_folder/data.bvec ${eddy_folder}"/tmp.bvec"
  cp $data_analysis_folder/data.bval ${eddy_folder}"/tmp.bval"
  if [ $num_pa_files -eq 1 ]; then
    awk 'BEGIN {OMFT="%.16f" print "0 "$0}' ${eddy_folder}"/tmp.bval" > ${eddy_folder}"/fullmerged.bval"
    awk '{print "0 "$0}' ${eddy_folder}"/tmp.bvec" > ${eddy_folder}"/fullmerged.bvec"
  elif [ $num_pa_files -eq 2 ]; then
    awk '{print "0 0 "$0}' ${eddy_folder}"/tmp.bval" > ${eddy_folder}"/fullmerged.bval"
    awk '{print "0 0 "$0}' ${eddy_folder}"/tmp.bvec" > ${eddy_folder}"/fullmerged.bvec"
  else
    awk '{print "0 0 0 "$0}' ${eddy_folder}"/tmp.bval" > ${eddy_folder}"/fullmerged.bval"
    awk '{print "0 0 0 "$0}' ${eddy_folder}"/tmp.bvec" > ${eddy_folder}"/fullmerged.bvec"
  fi
fi
#Need to move items from topup to eddy folder
if [ ! -e ${eddy_folder}"/hifib0.nii.gz" ]; then
  cp ${topup_folder}/hifib0.nii.gz ${eddy_folder}
fi
if [ ! -e ${eddy_folder}"/topupresults_fieldcoef.nii.gz" ]; then
  cp ${topup_folder}/topupresults_fieldcoef.nii.gz ${eddy_folder}
fi
if [ ! -e ${eddy_folder}"topupresults_movpar.txt" ]; then
  cp ${topup_folder}/topupresults_movpar.txt ${eddy_folder}
fi
# Create mask using BET
cd ${eddy_folder}
if [ ! -e ${eddy_folder}"hifib0_bet_mask.nii.gz" ]; then
  bet hifib0.nii.gz hifib0_bet.nii.gz -m -f .2
fi
echo "BET is complete..."
# Create fullmerged.nii file (Combined PA and AP volumes)
if [ ! -e ${eddy_folder}"/fullmerged.nii" ]; then
  fslmerge -t ${eddy_folder}"/fullmerged.nii" ${data_analysis_folder}"/pa_b0.nii" ${data_analysis_folder}"/data.nii"
fi

# NEED TO ADD LINE IF > 3, not currently an issue

# Run Eddy CUDA or EDDY
# NOTE: If running locally without a gpu, you will not be able to run eddy_cuda
# eddy_cuda8 \

eddy_cuda --imain=fullmerged.nii.gz --mask=hifib0_bet_mask.nii.gz --index=eddy_index.txt --acqp=eddy_acqparams.txt --bvecs=fullmerged.bvec --bvals=fullmerged.bval --topup=topupresults --out=data_ec --slspec={matlab_bin}/slspec.txt --verbose
echo "Eddy done..."
