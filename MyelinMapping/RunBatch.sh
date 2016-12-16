#!/bin/bash
#filename="./Scan_list.txt"
filename="/home/share/LeftHand/VBM/scans_table.txt"
export STUDY_DIR=
while read -r line
do
    SUBJECT=`echo "$line" | cut -f1 -d' '`
 #   SESSIONS=`echo "$line" | cut -f2 -d' '`
    SESSION=`echo "$line" | cut -f2 -d' '`

    echo "$SUBJECT.$SESSION"
    #ProcessMyelinMapping.sh --subject=$SUBJECT --res=0.8 --sessions="$SUBJECT.$SESSION" --cross-only #--base-only --long-only

#    ProcessMyelinMapping.sh --subject=$SUBJECT --res=0.8 --sessions=$SESSION --cross-only #--base-only --long-only

done < "$filename"

#export STUDY_DIR=/home/share/LeftHand/test
#ProcessMyelinMapping.sh --subject=LH1004 --res=0.8 --sessions=LH1004.1 --cross-only &
#ProcessMyelinMapping.sh --subject=LH1004 --res=0.8 --sessions=LH1004.3 --cross-only

