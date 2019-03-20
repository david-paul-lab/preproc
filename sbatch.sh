#!/bin/bash

#SBATCH -t 8:00:00
#SBATCH -mem 60GB
#SBATCH --gres=gpu:2 -p gpu
module load matlab fsl dcm2niix cuda

./preproc.sh filenames.txt 1 .66 .172
