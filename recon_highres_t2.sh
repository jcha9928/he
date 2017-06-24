#!/bin/bash

$EXPERTOPT=$SUBJECTS_DIR/expert.opt
$FLAIR=
$T1=
$SUBJECT=${s}.05mm.flair

recon-all -all -s $SUBJECT -hires -i $T1 -expert $EXPERTOPT -FLAIR $FLAIR -FLAIRpial 
