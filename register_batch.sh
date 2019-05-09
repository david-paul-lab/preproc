#!/bin/bash
# This script is for batch proccessing of BEDPOSTx as called by the
# preproc.sh script

#Register Diffusion Image to MPRAGE image (FLIRT)
fslroi $eddy_folder/b1000.nii.gz $bp_folder/nodif_brain.nii.gz 0 1 #may have to change names

#Brain extract T1 image (not sure if path to T1 is right)
bet $basedir/t1.nii.gz $bp_folder/T1_brain.nii.gz -m -f 0.35
mkdir $bp_folder/matrix

#FLIRT
echo "Running FLIRT..."
flirt -in $bp_folder/nodif_brain.nii.gz -ref $bp_folder/T1_brain.nii.gz -omat $bp_folder/matrix/diff2str.mat -out $bp_folder/matrix/Diff2T1_flirt.nii.gz -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6 -cost mutualinfo -v
slices $bp_folder/matrix/T12Diff_brain_flirt.nii.gz $bp_folder/nodif_brain.nii.gz
slicer $bp_folder/matrix/T12Diff_brain_flirt.nii.gz $bp_folder/nodif_brain.nii.gz -a $bp_folder/matrix/reg_quality_check.png
convert_xfm -omat $bp_folder/matrix/str2diff.mat -inverse $bp_folder/matrix/diff2str.mat
echo "FLIRT completed"

#FNIRT
echo "Running FNIRT..."
fnirt --in=$bp_folder/nodif_brain.nii.gz --ref=$bp_folder/T1_brain.nii.gz --refmask=$bp_folder/T1_brain_mask.nii.gz --iout=$bp_folder/matrix/Diff2T1_fnirt.nii.gz --aff=$bp_folder/matrix/diff2str.mat --cout=$bp_folder/matrix/cout -v
rm $bp_folder/matrix/warp_diff_to_mprage

invwarp -w $bp_folder/matrix/cout -o $bp_folder/matrix/warp_mprage_to_diff -r $bp_folder/nodif_brain.nii.gz -v
echo "FNIRT completed"
