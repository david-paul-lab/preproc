#!/bin/bash
#
# preproc.sh v1.0
# This is a batch script for pre-processing DTI data
# This script assumes that:
# 1. Data are acquired using a Siemens scanner (RCBI Scanner)
# 2. DTI data are acquired in the P>>A Phase encoding, future versions will
#    include support for other directions
# 3. You need to know the Echo Spacing and EPI Factor for your scans.
#    Email Renee_Stowell@URMC.Rochester.edu if you need help with this
# 4. For older data that are not acquired with reversed phase encoded images,
#    "0" will need to be specified as the <topupflag>
# 5. dcm2niix is installed on the local machine, instructions for downloading
#    can be found at: https://github.com/rordenlab/dcm2niix. Note: This is
#    a different program than "dcm2nii"
# 6. Matlab is installed on the local machine. This is necessary for "slice to
#    volume" correction algorithms incorporated in fsl
# 7. Appropriate pathnames must be specified for fsl functions
#    in the .bash_profile
#
# Files must in an appropriate file structure, and listed in a text file
# <dir_fname>
# ...Sub1/Series1/DTI directory: DTI images of the scan, A>>P phase encoding
# ...Sub1/Series2/PA_B0 directory: Folder P>>A phase encoded acquisition
# ...Sub1/Series2/MPRAGE: T1 Structural image
# ...Sub2/Series1/DTI directory: ""
# ...Sub2/Series2/PA_B0 directory: ""
# ...Sub1/Series2/MPRAGE:""
#
# Author: David A. Paul, MD
# Resident, Department of Neurosurgery,
# University of Rochester Medical Center
# Email david_paul@urmc.rochester.edu with questions
#
#CHANGES MADE FROM ORIGINAL: paths are all local to emmas computer. ampersand removed

Usage() {
  echo ""
  echo "Usage: preproc <dir_filename> <topupflag> <echospacing> <epifactor> "
  echo "
  exit"
}

dir_filename=${1}; topupflag=${2}; echo_spacing=${3}; epi_factor=${4}

# Directory with matlab scripts
matlab_bin=/Users/estrawderman/Desktop/DP_preproc/matbin


# ***** Set up basic variables *****
LF=$dir_filename".log" # setup the log file
if [ -e $LF ]; then
 mv $LF $LF".bak"
fi
echo Logfile is $LF
date >> $LF
start_time=`date +%s`
echo $start_time >> $LF

# Determine the number of subjects to process
subNum=$(cat $dir_filename | wc -w)
  subNum=$(expr $subNum / 2)
echo The total number of subjects is $subNum | tee -a $LF


i=1;
while [ "$i" -le "$subNum" ]; do

  indx=$(($i - 1))
  indx=$(($indx * 2)) # This number will need to change based on how many folders are inputted per subject
  ((indx++))
  tmp=$(cat $dir_filename | head -n $indx | tail -1)
  basedir=$(awk -v "X=$tmp" 'BEGIN { split(X, names, "/"); print "/"names[2]"/"names[3]"/"names[4]"/"names[5]"/"names[6]"/"names[7]"/"names[8]}')
  dti_avg=$(awk -v "X=$tmp" 'BEGIN { split(X, names, "/"); print names[9]}')
  echo $dti_avg
  ((indx++))
  tmp=$(cat $dir_filename | head -n $indx | tail -1)
  pa_b0_dir=$(awk -v "X=$tmp" 'BEGIN { split(X, names, "/"); print names[9]}')
  echo $pa_b0_dir

  data_analysis_folder=${basedir}"/data"   # create data analysis folder
  mkdir $data_analysis_folder; cd $data_analysis_folder
  date >> $LF

  # Run dcm2niix on the subject, saves to data_analysis folder

  if [ ! -e *.bvec ]; then
  dcm2niix -b y -ba y -o $data_analysis_folder ${basedir}"/"${dti_avg}
  cd $data_analysis_folder
  mv *.nii data.nii; mv *.bvec data.bvec; mv *.bval data.bval
  mv *.json image_header.json
  fi

  if [ ! -e *PA*.nii ]; then
  dcm2niix -o $data_analysis_folder ${basedir}"/"${pa_b0_dir}
  mv *PA*.nii pa_b0.nii; rm *PA*.json
  fi

  ((i++))
done

# Run topup in parallel
if [ $topupflag -eq "1" ]; then
  i=1;
  while [ "$i" -le "$subNum" ]; do
  /Users/estrawderman/Desktop/DP_preproc/topup_batch.sh $i $dir_filename $echo_spacing $epi_factor $LF 
  ((i++))
  done
  wait  # wait for all topup instances to finish
fi


# Run eddy_cuda, this parallised across available GPU's
i=1;
while [ "$i" -le "$subNum" ]; do
/Users/estrawderman/Desktop/DP_preproc/eddy_batch.sh $i $dir_filename $matlab_bin $echo_spacing $epi_factor
((i++))
done

end_time=`date +%s`
echo Execution time was `expr $end_time - $start_time` s. >> $LF
echo "MISSION ACCOMPLISHED!"
