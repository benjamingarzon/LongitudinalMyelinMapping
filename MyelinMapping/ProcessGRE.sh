#!/bin/sh
# do after running ProcessMyelinMapping
# sample on caret surface

export PROJ_FRAC="0.3 0.7 0.1"

WORKDIR="/home/share/Left-HandStudy"
POSTFIX="/unprocessed/3T/MGRE/proc"
SUBJECTS_DIR="/home/share/Left-HandStudy/recon"
TIMEPOINTS="1 2 3 4"

# template : average of r2star
# base: average of T1

FWHM=10
FWHM_VOL=2

function ProcessGRE() {
SUBJECT=$1


for TP in $TIMEPOINTS;
do
	mkdir $WORKDIR/$SUBJECT.$TP/MGRE
	TP_LIST="$TP_LIST $WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/r2star.nii.gz"
	LTA_LIST="$LTA_LIST $WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/proc/r2startoTemplate.lta"
	MAP_LIST="$MAP_LIST $WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/proc/r2startoTemplate.nii.gz"

done

COMMAND="mri_robust_template --mov $TP_LIST --template $WORKDIR/$SUBJECT/r2starTemplate.nii.gz --satit --lta $LTA_LIST --mapmov $MAP_LIST --iscale"
echo $COMMAND

#$COMMAND

cd $WORKDIR/$SUBJECT

# find transform from GRE0 to T1_acpc and register
fslmaths r2starTemplate.nii.gz -abs -thr .001 -bin -s 1 -thr .8 -bin r2star_mask
fslmaths r2starTemplate.nii.gz -thr 1 -add r2star_mask -recip t2starTemplate.nii.gz

#bbregister --s $SUBJECT.base --mov $WORKDIR/$SUBJECT/t2starTemplate.nii.gz --init-fsl --lta $WORKDIR/$SUBJECT/Templatetobase.lta --o $WORKDIR/$SUBJECT/t2starTemplate_reg.nii.gz --t2

# register to T1_acpc and from there to MNI

CONFIG=$WORKDIR/$SUBJECT.$TP/MNINonLinear/xfms/NonlinearReg.txt
mri_convert $SUBJECTS_DIR/$SUBJECT.base/mri/T1.mgz $WORKDIR/$SUBJECT/T1base.nii.gz
mri_convert $SUBJECTS_DIR/$SUBJECT.base/mri/brainmask.mgz $WORKDIR/$SUBJECT/T1base_brain.nii.gz

#flirt -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain -in $WORKDIR/$SUBJECT/T1base_brain.nii.gz -omat $WORKDIR/$SUBJECT/BasetoMNI_aff.mat
#fnirt --in=$WORKDIR/$SUBJECT/T1base.nii.gz --ref=${FSLDIR}/data/standard/MNI152_T1_2mm_brain  --aff=$WORKDIR/$SUBJECT/BasetoMNI_aff.mat --refmask=${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil --cout=$WORKDIR/$SUBJECT/BasetoMNI_nonlinear #--config=$CONFIG

applywarp --ref=${FSLDIR}/data/standard/MNI152_T1_2mm --in=$WORKDIR/$SUBJECT/T1base.nii.gz --warp=$WORKDIR/$SUBJECT/BasetoMNI_nonlinear --out=$WORKDIR/$SUBJECT/T1toMNI


for TP in $TIMEPOINTS;
do
mri_concatenate_lta $WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/proc/r2startoTemplate.lta $WORKDIR/$SUBJECT/Templatetobase.lta $WORKDIR/$SUBJECT.$TP/MGRE/r2startobase.lta
mri_vol2vol --mov $WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/QSM.nii.gz --s $SUBJECT.base --o $WORKDIR/$SUBJECT.$TP/MGRE/QSMtobase.nii.gz --lta $WORKDIR/$SUBJECT.$TP/MGRE/r2startobase.lta --targ $SUBJECTS_DIR/$SUBJECT.base/mri/T1.mgz
mri_vol2vol --mov $WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/r2star.nii.gz --s $SUBJECT.base --o $WORKDIR/$SUBJECT.$TP/MGRE/r2startobase.nii.gz --lta  $WORKDIR/$SUBJECT.$TP/MGRE/r2startobase.lta --targ $SUBJECTS_DIR/$SUBJECT.base/mri/T1.mgz

tkregister2 --mov $WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/r2star.nii.gz --targ $WORKDIR/$SUBJECT/T1base.nii.gz --reg $WORKDIR/$SUBJECT.$TP/MGRE/r2startobase.lta --fslregout $WORKDIR/$SUBJECT.$TP/MGRE/r2startobase.mat --noedit 
applywarp --in=$WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/QSM.nii.gz --out=$WORKDIR/$SUBJECT.$TP/MGRE/QSMtoMNI.nii.gz --ref=/usr/local/fsl/data/standard/MNI152_T1_2mm.nii.gz --premat=$WORKDIR/$SUBJECT.$TP/MGRE/r2startobase.mat --warp=$WORKDIR/$SUBJECT/BasetoMNI_nonlinear
applywarp --in=$WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/r2star.nii.gz --out=$WORKDIR/$SUBJECT.$TP/MGRE/r2startoMNI.nii.gz --ref=/usr/local/fsl/data/standard/MNI152_T1_2mm.nii.gz --premat=$WORKDIR/$SUBJECT.$TP/MGRE/r2startobase.mat --warp=$WORKDIR/$SUBJECT/BasetoMNI_nonlinear

# extract ventricles
mri_extract_label $SUBJECTS_DIR/$SUBJECT.base/mri/aparc+aseg.mgz 4 43 ventricles.nii.gz
fslmaths ventricles.nii.gz -bin ventricles.nii.gz
mri_morphology ventricles.nii.gz erode 1 ventricles.nii.gz


#MEAN=`fslstats $WORKDIR/$SUBJECT.$TP/MGRE/QSMtobase.nii.gz -k $WORKDIR/$SUBJECT.$TP/MGRE/ventricles.nii.gz -m`
MEAN=`fslstats $WORKDIR/$SUBJECT.$TP/MGRE/QSMtobase.nii.gz -k $WORKDIR/$SUBJECT/ventricles.nii.gz -m`

echo $MEAN > $WORKDIR/$SUBJECT.$TP/MGRE/QSM_ventricle_mean.dat

fslmaths $WORKDIR/$SUBJECT.$TP/MGRE/QSMtobase.nii.gz -sub $MEAN $WORKDIR/$SUBJECT.$TP/MGRE/QSMtobase.nii.gz
fslmaths $WORKDIR/$SUBJECT.$TP/MGRE/QSMtoMNI.nii.gz -sub $MEAN $WORKDIR/$SUBJECT.$TP/MGRE/QSMtoMNI.nii.gz


# sample on the surface
mri_vol2surf --interp trilinear --cortex --mov $WORKDIR/$SUBJECT.$TP/MGRE/QSMtobase.nii.gz --regheader $SUBJECT.base --hemi lh --out $WORKDIR/$SUBJECT.$TP/MGRE/lh.QSM.mgz --projfrac-avg $PROJ_FRAC #--fwhm $FWHM
mri_vol2surf --interp trilinear --cortex --mov $WORKDIR/$SUBJECT.$TP/MGRE/QSMtobase.nii.gz --regheader $SUBJECT.base --hemi rh --out $WORKDIR/$SUBJECT.$TP/MGRE/rh.QSM.mgz --projfrac-avg $PROJ_FRAC #--fwhm $FWHM

mri_vol2surf --interp trilinear --cortex --mov $WORKDIR/$SUBJECT.$TP/MGRE/r2startobase.nii.gz --regheader $SUBJECT.base --hemi lh --out $WORKDIR/$SUBJECT.$TP/MGRE/lh.r2star.mgz --projfrac-avg $PROJ_FRAC # --fwhm $FWHM
mri_vol2surf --interp trilinear --cortex --mov $WORKDIR/$SUBJECT.$TP/MGRE/r2startobase.nii.gz --regheader $SUBJECT.base --hemi rh --out $WORKDIR/$SUBJECT.$TP/MGRE/rh.r2star.mgz --projfrac-avg $PROJ_FRAC #--fwhm $FWHM

# normalization
# surf
#mri_surf2surf --srcsubject $SUBJECT.base --trgsubject fsaverage --sval $WORKDIR/$SUBJECT.$TP/MGRE/lh.QSM.mgz --cortex --hemi lh --tval $WORKDIR/$SUBJECT.$TP/MGRE/lh.QSM.fsaverage.mgz #--fwhm-trg $FWHM 
#mri_surf2surf --srcsubject $SUBJECT.base --trgsubject fsaverage --sval $WORKDIR/$SUBJECT.$TP/MGRE/rh.QSM.mgz --cortex --hemi rh --tval $WORKDIR/$SUBJECT.$TP/MGRE/rh.QSM.fsaverage.mgz #--fwhm-trg $FWHM 

#mri_surf2surf --srcsubject $SUBJECT.base --trgsubject fsaverage --sval $WORKDIR/$SUBJECT.$TP/MGRE/lh.r2star.mgz --cortex --hemi lh --tval $WORKDIR/$SUBJECT.$TP/MGRE/lh.r2star.fsaverage.mgz #--fwhm-trg $FWHM 
#mri_surf2surf --srcsubject $SUBJECT.base --trgsubject fsaverage --sval $WORKDIR/$SUBJECT.$TP/MGRE/rh.r2star.mgz --cortex --hemi rh --tval $WORKDIR/$SUBJECT.$TP/MGRE/rh.r2star.fsaverage.mgz #--fwhm-trg $FWHM 

done

fslmerge -t $WORKDIR/$SUBJECT/r2star_base_all.nii.gz  $WORKDIR/$SUBJECT.*/MGRE/r2startobase.nii.gz

fslmerge -t $WORKDIR/$SUBJECT/QSM_all.nii.gz  $WORKDIR/$SUBJECT.*/MGRE/QSMtoMNI.nii.gz
fslmerge -t $WORKDIR/$SUBJECT/r2star_all.nii.gz  $WORKDIR/$SUBJECT.*/MGRE/r2startoMNI.nii.gz

# normalize QSM
fslmaths $WORKDIR/$SUBJECT/QSM_all.nii.gz -s $FWHM_VOL $WORKDIR/$SUBJECT/QSM_all_smooth.nii.gz
fslmaths $WORKDIR/$SUBJECT/r2star_all.nii.gz -s $FWHM_VOL $WORKDIR/$SUBJECT/r2star_all_smooth.nii.gz

}
for SUBJECT in LH1001 LH1002 LH1003 LH1005; 
do
ProcessGRE $SUBJECT &
done



# apply to QSM and r2star and merge all
#for TP in $TIMEPOINTS;
#do
#echo 
#mri_vol2vol --mov $WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/QSM.nii.gz --targ $WORKDIR/$SUBJECT/GRE0Template.nii.gz --o $WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/QSMtoTemplate.nii.gz --reg $WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/proc/GRE0toTemplate.lta
#mri_vol2vol --mov $WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/r2star.nii.gz --targ $WORKDIR/$SUBJECT/GRE0Template.nii.gz --o $WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/r2startoTemplate.nii.gz --reg $WORKDIR/$SUBJECT.$TP/unprocessed/3T/MGRE/proc/GRE0toTemplate.lta
#done
