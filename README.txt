This script assumes that:
1. Data are acquired using a Siemens scanner (RCBI Scanner)
2. DTI data are acquired in the P>>A Phase encoding, future versions will
   include support for other directions
3. You need to know the Echo Spacing and EPI Factor for your scans.
   Email Renee_Stowell@URMC.Rochester.edu if you need help with this
4. For older data that are not acquired with reversed phase encoded images,
   "0" will need to be specified as the <topupflag>
5. dcm2niix is installed on the local machine, instructions for downloading
   can be found at: https://github.com/rordenlab/dcm2niix. Note: This is
   a different program than "dcm2nii"
6. Matlab is installed on the local machine. This is necessary for "slice to
   volume" correction algorithms incorporated in fsl
7. Appropriate pathnames must be specified for fsl functions
   in the .bash_profile

Files must in an appropriate file structure, and listed in a text file
<dir_fname>
...Sub1/Series1/DTI directory: DTI images of the scan, A>>P phase encoding
...Sub1/Series2/PA_B0 directory: Folder P>>A phase encoded acquisition
...Sub1/Series2/MPRAGE: T1 Structural image
...Sub2/Series1/DTI directory: ""
...Sub2/Series2/PA_B0 directory: ""
...Sub1/Series2/MPRAGE:""


Author: David A. Paul, MD
Resident, Department of Neurosurgery,
University of Rochester Medical Center
Email david_paul@urmc.rochester.edu with questions
