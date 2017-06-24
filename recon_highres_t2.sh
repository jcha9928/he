#!/bin/bash

year=2011
s=10004953_20111116

SUBJECTS_DIR=/ifs/scratch/pimri/posnerlab/1anal/IDP/fs

IMPATH=/ifs/scratch/pimri/posnerlab/1anal/IDP/${year}/${s}
EXPERTOPT=$SUBJECTS_DIR/expert.opt
FLAIR=`ls $IMPATH/3DFLAIR*nii`
T1=`ls $IMPATH/3DT1*nii`
SUBJECT=${s}.05mm.flair
CMD=$SUBJECTS_DIR/logs/cmd.${s}
recon=$SUBJECTS_DIR/logs/recon.${s}
echo "recon-all -all -s $SUBJECT -hires -i $T1 -expert $EXPERTOPT -FLAIR $FLAIR -FLAIRpial -hippocampal-subfields-T1 -openmp 32 -hemi lh" > $recon
chmod +x $recon


cat<<-EOM >$CMD
#!/bin/bash
#$ -cwd -S /bin/bash -N mpiprog
#$ -l mem=3G,time=24::
#$ -pe orte 32
#$ -l infiniband=TRUE
source ~/.bashrc
. /nfs/apps/openmpi/current/setenv.sh
mpirun $recon
EOM
