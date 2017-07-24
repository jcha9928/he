#!/bin/bash

list=$1
#year=2011

s=10004362
threads=8

SUBJECTS_DIR=/ifs/scratch/pimri/posnerlab/1anal/IDP/fs

IMPATH=/ifs/scratch/pimri/posnerlab/1anal/IDP/data/${s}
EXPERTOPT=$SUBJECTS_DIR/expert.opt
FLAIR=`ls $IMPATH/flair*nii*`
T1=`ls $IMPATH/t1*nii*`
SUBJECT=${s}_1mm_flair_test
CMD1=/ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job/cmd1.${s}
CMD2=/ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job/cmd2.${s}

recon1=/ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job/recon1.${s}
recon2=/ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job/recon2.${s}

### 1 INITIAL RECON-ALL
cat<<EOC >$recon1
#!/bin/bash
FREESURFER_HOME=/ifs/home/msph/epi/jep2111/app/freesurfer/
source $FREESURFER_HOME/SetUpFreeSurfer.sh
SUBJECTS_DIR=/ifs/scratch/pimri/posnerlab/1anal/IDP/fs
echo NOW PERFORMING RECON-ALL
#recon-all -all -s ${SUBJECT}.test_mpi128 -hires -i $T1 -expert $EXPERTOPT -FLAIR $FLAIR -FLAIRpial -hippocampal-subfields-T1 -openmp 64 
recon-all -all -s ${SUBJECT} -i $T1 -FLAIR $FLAIR -FLAIRpial -qcache
EOC

chmod +x $recon1


cat<<-EOM >$CMD1
#!/bin/bash
#$ -V
#$ -cwd -S /bin/bash -N recon1
#$ -l mem=9G,time=72::
#$ -o /ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job -e /ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job
source /ifs/home/msph/epi/jep2111/.bashrc
$recon1
EOM

prejobid=`qsub $CMD1 | awk '{print $3}'`
#echo $CMD1

### 2 HIPPOCAMPAL SEGMENTATION
cat<<EOC >$recon2
#!/bin/bash
FREESURFER_HOME=/ifs/home/msph/epi/jep2111/app/freesurfer/
source $FREESURFER_HOME/SetUpFreeSurfer.sh
SUBJECTS_DIR=/ifs/scratch/pimri/posnerlab/1anal/IDP/fs
echo NOW PERFORMING RECON-ALL
#recon-all -all -s ${SUBJECT}.test_mpi128 -hires -i $T1 -expert $EXPERTOPT -FLAIR $FLAIR -FLAIRpial -hippocampal-subfields-T1 -openmp 64 
recon-all -s ${SUBJECT} -hippocampal-subfields-T1T2 $FLAIR flair -itkthreads ${threads} 
EOC

chmod +x $recon2


cat<<-EOM >$CMD2
#!/bin/bash
#$ -V
#$ -cwd -S /bin/bash -N recon2
#$ -l mem=3G,time=24::
#$ -pe smp ${threads}
#$ -o /ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job -e /ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job
source /ifs/home/msph/epi/jep2111/.bashrc
$recon2
EOM

qsub -hold_jid $prejobid $CMD2
#echo $CMD2
