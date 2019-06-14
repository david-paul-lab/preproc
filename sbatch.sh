#!/bin/bash

#SBATCH -t 48:00:00
#SBATCH --mem=60GB
#SBATCH --gres=gpu:2 -p gpu
module load matlab fsl/6.0.0/b1 dcm2niix 

# Usage: preproc <dir_filename> <topupflag> <eddyflag> <dtiflag> <bpxflag> <echospacing> <epifactor>

# Run Topup, eddy, dtifit
#./preproc.sh /scratch/dmi/dpaul2_lab/pitu2/dbdf/scripts/preproc/filenames.txt 1 1 1 0 .66 172

# Run with Bedpostx
#./preproc.sh /scratch/dmi/dpaul2_lab/pitu2/dbdf/scripts/preproc/filenames.txt 0 0 0 1 .66 172
