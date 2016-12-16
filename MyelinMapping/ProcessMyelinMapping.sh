#!/bin/bash 

# Process data using HCP pipeline

Usage() {
    echo ""
    echo "Author: Benjamin Garzon <benjamin.garzon@gmail.com>"
    echo "v 1.0, May 2015"
    echo "  Call the HCP processing pipeline for MyelinMapping."
    echo "  Usage: `basename $0` --subject=<SUBJECT NAME> [ --res=<RESOLUTION> --sessions=<SESSION DIRS> --cross-only --base-only --long-only]"
    echo " "
    echo "  IMPORTANT: You need to set the variable STUDY_DIR before running it, e.g."
    echo "  export STUDY_DIR=/home/MyUser/Data/Study/"
    echo " "
    echo "  --res : set resolution in mm (e.g. --res=0.8, default 0.8mm)"
    echo "  --subject : name of the subject to be processed (e.g. --subject=subject0)" 
    echo "  --sessions : an optional list with the different timepoints/sessions separated by commas (e.g. --sessions=subject0_t1,subject0_t2,subject0_t3). Do not write spaces between session names. When specifying sessions, the longitudinal stream will be used and the name specified by --subject will be taken as the global name for all the sessions." 
    echo "  --cross-only, --cross-only, --long-only : use to run only one of the stages in the pipeline." 
    
    echo " "
    exit 1
}


get_opt1() {
    arg=`echo $1 | sed 's/=.*//'`
    echo $arg
}


get_arg1() {
    if [ X`echo $1 | grep '='` = X ] ; then 
	echo "Option $1 requires an argument" 1>&2
	exit 1
    else 
	arg=`echo $1 | sed 's/.*=//'`
	if [ X$arg = X ] ; then
	    echo "Option $1 requires an argument" 1>&2
	    exit 1
	fi
	echo $arg
    fi
}

process(){

SUBJECT=$1
RESOLUTION=$2
$EXEC_DIR/PreFreeSurferPipelineBatch.sh --Subjlist=$SUBJECT --StudyFolder=$STUDY_DIR --Resolution=$RESOLUTION
$EXEC_DIR/FreeSurferPipelineBatch.sh --Subjlist=$SUBJECT --StudyFolder=$STUDY_DIR
$EXEC_DIR/PostFreeSurferPipelineBatch.sh --Subjlist=$SUBJECT --StudyFolder=$STUDY_DIR

}

process_longitudinal(){

BASE=${1}.base
SESSIONS=$2
RESOLUTION=$3

DO_CROSS=$4
DO_BASE=$5
DO_LONG=$6

SESSION_LIST="`echo $SESSIONS | sed 's/,/ /g'`"

#if [ $DO_CROSS -eq 1 ]; then
if [ ]; then

for SUBJECT in $SESSION_LIST;
do
echo $SUBJECT
$EXEC_DIR/PreFreeSurferPipelineBatch.sh --Subjlist=$SUBJECT --StudyFolder=$STUDY_DIR --Resolution=$RESOLUTION
done
fi

echo $SESSIONS
$EXEC_DIR/FreeSurferPipelineLongitudinalBatch.sh --Base_template=$BASE --Subjlist=$SESSIONS --StudyFolder=$STUDY_DIR --DoCross=$DO_CROSS --DoBase=$DO_BASE --DoLong=$DO_LONG

if [ $DO_LONG -eq 1 ]; then
for SUBJECT in $SESSION_LIST;
do
echo $SUBJECT
$EXEC_DIR/PostFreeSurferPipelineBatch.sh --Subjlist=$SUBJECT --StudyFolder=$STUDY_DIR
done
fi
}

# Default values
SESSIONS=''
RESOLUTION=0.8
DO_CROSS=1
DO_BASE=1
DO_LONG=1

if [ $# -lt 1 ] ; then Usage; exit 0; fi
while [ $# -ge 1 ] ; do
    iarg=`get_opt1 $1`;
    case "$iarg"
	in
	--subject)
	    SUBJECT=`get_arg1 $1`;
	    shift;;
	--res)
	    RESOLUTION=`get_arg1 $1`;
	    shift;;
	--sessions)
	    SESSIONS=`get_arg1 $1`;
	    shift;;
	--cross-only)
            DO_CROSS=1;
            DO_BASE=0;
            DO_LONG=0;
	    shift;;
	--base-only)
            DO_CROSS=0;
            DO_BASE=1;
            DO_LONG=0;
	    shift;;
	--long-only)
            DO_CROSS=0;
            DO_BASE=0;
            DO_LONG=1;
	    shift;;
	*)
	    #if [ `echo $1 | sed 's/^\(.\).*/\1/'` = "-" ] ; then 
	    echo "Unrecognised option $1" 1>&2
	    exit 1
	    #fi
	    #shift;;
    esac
done

echo "Doing subject $SUBJECT."
echo "Working at $RESOLUTION mm resolution."
mkdir $STUDY_DIR/logs
if [ "$SESSIONS" == '' ]; then
   process $SUBJECT $RESOLUTION > $STUDY_DIR/logs/log-$SUBJECT.txt 
else
   echo "Using longitudinal pipeline"
   process_longitudinal $SUBJECT $SESSIONS $RESOLUTION $DO_CROSS $DO_BASE $DO_LONG > $STUDY_DIR/logs/log-$SUBJECT.txt 
fi



