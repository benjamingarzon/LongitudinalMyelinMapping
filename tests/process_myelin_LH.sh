#!/bin/bash

export STUDY_DIR="/home/share/Left-HandStudy/"

function do_process(){
   ProcessMyelinMapping.sh --subject=$1 --sessions=${1}.1,${1}.2,${1}.3,${1}.4
   sleep 5
}

do_process LH1001 &
do_process LH1002 &
do_process LH1003 &
do_process LH1005 &
