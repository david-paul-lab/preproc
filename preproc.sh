#!/bin/bash
# preproc.sh v1.0
# Wrapper Batch script for pre-processing DTI data aquired at UR CABIN

Usage() {
  echo ""
  echo "Usage: preproc <dir_filename> <topupflag> <eddyflag> <dtiflag> <bpxflag> <echospacing> <epifactor> "
  echo "
  exit"
}

dir_filename=${1}; topupflag=${2}; eddyflag=${3}; dtiflag=${4}
bpxflag=${5}; echo_spacing=${6}; epi_factor=${7}

# Directory with all of the pre-processing steps (BHWARD)
scripts=/scratch/dmi/dpaul2_lab/pitu2/dbdf/scripts/preproc

# Directory with matlab scripts (BHWARD)
matlab_bin=/scratch/dmi/dpaul2_lab/pitu2/dbdf/scripts/preproc/matlab_bin

date #for record keeping purposes
start_time=`date +%s` #track how long script runs

# Determine the number of subjects to process
subNum=$(cat $dir_filename | wc -w)
subNum=$(expr $subNum / 3)
echo The total number of subjects is $subNum


i=1;
while [ "$i" -le "$subNum" ]; do
  indx=$(($i - 1))
  indx=$(($indx * 3)) # This number will need to change based on how many folders are inputted per subject
  ((indx++))
  tmp=$(cat $dir_filename | head -n $indx | tail -1)
  basedir=$(awk -v "X=$tmp" 'BEGIN { split(X, names, "/"); print "/"names[2]"/"names[3]"/"names[4]"/"names[5]"/"names[6]"/"names[7]"/"names[8]"/"names[9]}')
  dti_avg=$(awk -v "X=$tmp" 'BEGIN { split(X, names, "/"); print names[10]}')
  echo $dti_avg
  ((indx++))
  tmp=$(cat $dir_filename | head -n $indx | tail -1)
  pa_b0_dir=$(awk -v "X=$tmp" 'BEGIN { split(X, names, "/"); print names[10]}')
  echo $pa_b0_dir
  ((indx++))
  tmp=$(cat $dir_filename | head -n $indx | tail -1)
  mprage_dir=$(awk -v "X=$tmp" 'BEGIN { split(X, names, "/"); print names[10]}')
  echo $mprage_dir
  data_analysis_folder=${basedir}"/data"   # create data analysis folder
  mkdir $data_analysis_folder; cd $data_analysis_folder

  # Run dcm2niix on each subject, saves to data_analysis folder
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

  if [ ! -e *T1*.nii ]; then
    dcm2niix -o $data_analysis_folder ${basedir}"/"${mprage_dir}
    mv *T1*.nii T1.nii; rm *T1*.json
  fi
  ((i++))
done

# Run topup in parallel
if [ $topupflag -eq "1" ]; then
  i=1;
  while [ "$i" -le "$subNum" ]; do
    ${scripts}"/topup_batch.sh" $i $dir_filename $echo_spacing $epi_factor &
    ((i++))
  done
  wait
fi

# Run eddy_cuda, this parallelized across available GPU's
if [ $eddyflag -eq "1" ]; then
  i=1;
  while [ "$i" -le "$subNum" ]; do
    #/Users/estrawderman/Desktop/DP_preproc/eddy_batch.sh $i $dir_filename $matlab_bin $echo_spacing $epi_factor
    ${scripts}"/eddy_batch.sh" $i $dir_filename $matlab_bin $echo_spacing $epi_factor
    ((i++))
  done
fi

# Run dtifit
if [ $dtiflag -eq "1" ]; then
  i=1;
  while [ "$i" -le "$subNum" ]; do
    ${scripts}"/dtifit_batch.sh" $i $dir_filename $matlab_bin &
    ((i++))
  done
  wait
fi

#Run bedpostx_gpu, parallelized across available GPU's
if [ $bpxflag -eq "1" ]; then
  i=1;
  while [ "$i" -le "$subNum" ]; do
    ${scripts}"/bedpostx_batch.sh" $i $dir_filename
    ((i++))
  done
fi

end_time=`date +%s`
echo Execution time was `expr $end_time - $start_time` s.

# Move SLURM log file to data analysis folder
function datevar()
{
  date +%d%m%Y
}
jobdate=$(datevar)
if [ ! -e ${data_analysis_folder}"/"${jobdate}"_slurmOutput.log" ]; then
  mv *.out ${data_analysis_folder}"/"${jobdate}"_slurmOutput.log"
else
  mv ${data_analysis_folder}"/"${jobdate}"_slurmOutput.log" ${data_analysis_folder}"/"${jobdate}"_slurmOutput.log.bak"
  mv *.out ${data_analysis_folder}"/"${jobdate}"_slurmOutput.log"
fi

echo "MISSION ACCOMPLISHED!"
