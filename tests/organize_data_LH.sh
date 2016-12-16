#!/bin/bash

export STUDY_DIR="/home/share/Left-HandStudy/"

function do_organize(){
   export DICOM_DIR=$1
   echo $DICOM_DIR $2
#   OrganizeData.sh --subject=$2 --T1w=00000300 --T2w=00000400 --MGRE=00000005 &
#   OrganizeData.sh --subject=$2 --T1w=00000300 --T2w=00000400 &
   OrganizeData.sh --subject=$2 --T1w=00000400 --T2w=00000500 &
#   OrganizeData.sh --subject=$2 --MGRE=00000005 &
   OrganizeData.sh --subject=$2 --MGRE=00000005 --mag &
   sleep 5
}

#do_organize "/home/share/Data_LH/Baseline/LH1001" LH1001.1
#do_organize "/home/share/Data_LH/Baseline/LH1002" LH1002.1
#do_organize "/home/share/Data_LH/Baseline/LH1003" LH1003.1
#do_organize "/home/share/Data_LH/Baseline/LH1005" LH1005.1

#do_organize "/home/share/Data_LH/Week_3/LH1001*" LH1001.2
do_organize "/home/share/Data_LH/Week_3/LH1002*" LH1002.2
#do_organize "/home/share/Data_LH/Week_3/LH1003*" LH1003.2
#do_organize "/home/share/Data_LH/Week_3/LH1005*" LH1005.2

#do_organize "/home/share/Data_LH/Week_4/LH1001*" LH1001.3
#do_organize "/home/share/Data_LH/Week_4/LH1002*" LH1002.3
#do_organize "/home/share/Data_LH/Week_4/LH1003*" LH1003.3
#do_organize "/home/share/Data_LH/Week_4/LH1005*" LH1005.3

#do_organize "/home/share/Data_LH/Week_5/LH1001*" LH1001.4
#do_organize "/home/share/Data_LH/Week_5/LH1002*" LH1002.4
#do_organize "/home/share/Data_LH/Week_5/LH1003*" LH1003.4
#do_organize "/home/share/Data_LH/Week_5/LH1005*" LH1005.4
