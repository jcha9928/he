#!/bin/bash

year=2011
s=10004953_20111116

SUBJECTS_DIR=/ifs/scratch/pimri/posnerlab/1anal/IDP/fs

IMPATH=/ifs/scratch/pimri/posnerlab/1anal/IDP/${year}/${s}
EXPERTOPT=$SUBJECTS_DIR/expert.opt
FLAIR=`ls $IMPATH/*FLAIR*nii`
T1=`ls $IMAPTH/*T1*nii`
SUBJECT=${s}.05mm.flair
CMD=$SUBJECTS_DIR/logs/cmd.${s}

cat<<-EOM >$CMD
#!/bin/bash
#$ -cwd -S /bin/bash -N mpiprog
#$ -l mem=1G,time=6::
#$ -pe orte 32
#$ -l infiniband=TRUE
. /nfs/apps/openmpi/current/setenv.sh
mpirun recon-all -all -s $SUBJECT -hires -i $T1 -expert $EXPERTOPT -FLAIR $FLAIR -FLAIRpial -openmp 32
EOM
