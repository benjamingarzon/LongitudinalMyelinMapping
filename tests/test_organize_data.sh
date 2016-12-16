#!/bin/bash

export STUDY_DIR="/home/ALDRECENTRUM/benjamin.garzon/Data/Left-HandStudy/"
#export DICOM_DIR="/shared/Data/Left-HandStudy/6405_20150420_165333/"

# organize Name FieldMap T1 T2
#./OrganizeData.sh --subject=test1 --T1w=00000004 --T2w=00000003 --fieldmap=00000006 --MGRE=00000005 --overwrite
#./OrganizeData.sh --subject=test2 --T1w=00000004 --overwrite #--fieldmap=00000006 #--overwrite
#./OrganizeData.sh --subject=test2 --fieldmap=00000006 --overwrite 


export DICOM_DIR="/home/ALDRECENTRUM/benjamin.garzon/Data/Left-HandStudy/6421_20150423_183607/"
./OrganizeData.sh --subject=subject0 --T1w=00000004 --T2w=00000003 --MGRE=00000005
