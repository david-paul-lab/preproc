#!/bin/bash

#SBATCH -t 48:00:00
#SBATCH --mem=60GB
#SBATCH --gres=gpu:2 -p gpu
module load matlab fsl dcm2niix cuda

./preproc.sh /scratch/dmi/dpaul2_lab/pitu2/dbdf/scripts/preproc/filenames.txt 1 .66 .172
