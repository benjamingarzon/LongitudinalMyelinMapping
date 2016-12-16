#!/bin/bash 
set -e

# Requirements for this script
#  installed versions of: FSL (version 5.0.6), FreeSurfer (version 5.3.0-HCP)
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR 

########################################## PIPELINE OVERVIEW ########################################## 

#TODO

########################################## OUTPUT DIRECTORIES ########################################## 

#TODO

# --------------------------------------------------------------------------------
#  Load Function Libraries
# --------------------------------------------------------------------------------

source $HCPPIPEDIR/global/scripts/log.shlib  # Logging related functions
source $HCPPIPEDIR/global/scripts/opts.shlib # Command line option functions

########################################## SUPPORT FUNCTIONS ########################################## 

# --------------------------------------------------------------------------------
#  Usage Description Function
# --------------------------------------------------------------------------------

show_usage() {
    echo "Usage information To Be Written"
    exit 1
}

# --------------------------------------------------------------------------------
#   Establish tool name for logging
# --------------------------------------------------------------------------------
log_SetToolName "FreeSurferPipeline.sh"

################################################## OPTION PARSING #####################################################

opts_ShowVersionIfRequested $@

if opts_CheckForHelpRequest $@; then
    show_usage
fi

log_Msg "Parsing Command Line Options"

# Input Variables
SubjectID=`opts_GetOpt1 "--subject" $@` #FreeSurfer Subject ID Name
SubjectDIR=`opts_GetOpt1 "--subjectDIR" $@` #Location to Put FreeSurfer Subject's Folder
ReconDIR=`opts_GetOpt1 "--reconDIR" $@` #Location for recon folders
T1wImage=`opts_GetOpt1 "--t1" $@` #T1w FreeSurfer Input (Full Resolution)
T1wImageBrain=`opts_GetOpt1 "--t1brain" $@` 
T2wImage=`opts_GetOpt1 "--t2" $@` #T2w FreeSurfer Input (Full Resolution)
Base_template=`opts_GetOpt1 "--Base_template" $@` #Base_template

T1wImageFile=`remove_ext $T1wImage`;
T1wImageBrainFile=`remove_ext $T1wImageBrain`;

PipelineScripts=${HCPPIPEDIR_FS}

if [ -e "$SubjectDIR"/"${SubjectID}"/scripts/IsRunning.lh+rh ] ; then
  rm "$SubjectDIR"/"${SubjectID}"/scripts/IsRunning.lh+rh
fi

#Make Spline Interpolated Downsample to 1mm
log_Msg "Make Spline Interpolated Downsample to 1mm"

#Mean=`fslstats $T1wImageBrain -M`
#flirt -interp spline -in "$T1wImage" -ref "$T1wImage" -applyisoxfm 1 -out "$T1wImageFile"_1mm.nii.gz
#applywarp --rel --interp=spline -i "$T1wImage" -r "$T1wImageFile"_1mm.nii.gz --premat=$FSLDIR/etc/flirtsch/ident.mat -o "$T1wImageFile"_1mm.nii.gz
#applywarp --rel --interp=nn -i "$T1wImageBrain" -r "$T1wImageFile"_1mm.nii.gz --premat=$FSLDIR/etc/flirtsch/ident.mat -o "$T1wImageBrainFile"_1mm.nii.gz
#fslmaths "$T1wImageFile"_1mm.nii.gz -div $Mean -mul 150 -abs "$T1wImageFile"_1mm.nii.gz

#Initial Recon-all Steps
log_Msg "Initial Recon-all Steps"
#-skullstrip of FreeSurfer not reliable for Phase II data because of poor FreeSurfer mri_em_register registrations with Skull on, run registration with PreFreeSurfer masked data and then generate brain mask as usual

recon-all -long ${SubjectID} ${Base_template} -sd $ReconDIR -motioncor -talairach -nuintensitycor -normalization 

mri_convert ${T1wImageBrainFile}_1mm.nii.gz $ReconDIR/${SubjectID}.long.${Base_template}/mri/brainmask.mgz --conform
mri_em_register -mask ${ReconDIR}/${SubjectID}.long.${Base_template}/mri/brainmask.mgz ${ReconDIR}/${SubjectID}.long.${Base_template}/mri/nu.mgz $FREESURFER_HOME/average/RB_all_2008-03-26.gca ${ReconDIR}/${SubjectID}.long.${Base_template}/mri/transforms/talairach_with_skull.lta
mri_watershed -T1 -brain_atlas $FREESURFER_HOME/average/RB_all_withskull_2008-03-26.gca ${ReconDIR}/${SubjectID}.long.${Base_template}/mri/transforms/talairach_with_skull.lta ${ReconDIR}/${SubjectID}.long.${Base_template}/mri/T1.mgz ${ReconDIR}/${SubjectID}.long.${Base_template}/mri/brainmask.auto.mgz 
cp ${ReconDIR}/${SubjectID}.long.${Base_template}/mri/brainmask.auto.mgz ${ReconDIR}/${SubjectID}.long.${Base_template}/mri/brainmask.mgz 

#recon-all -subjid ${SubjectID} -sd $SubjectDIR -autorecon2 -nosmooth2 -noinflate2 -nocurvstats -nosegstats -openmp 8
recon-all -long ${SubjectID} ${Base_template} -sd ${ReconDIR} -autorecon2 -nosmooth2 -noinflate2 -nocurvstats -nosegstats -openmp 8

#Highres white stuff and Fine Tune T2w to T1w Reg
log_Msg "High resolution white matter and fine tune T2w to T1w registration"
#"$PipelineScripts"/FreeSurferHiresWhite.sh "${SubjectID}" "$SubjectDIR" "$T1wImage" "$T2wImage"
"$PipelineScripts"/FreeSurferHiresWhite.sh "${SubjectID}.long.${Base_template}" "$ReconDIR" "$T1wImage" "$T2wImage"

#Intermediate Recon-all Steps
log_Msg "Intermediate Recon-all Steps"
#recon-all -subjid ${SubjectID} -sd $SubjectDIR -smooth2 -inflate2 -curvstats -sphere -surfreg -jacobian_white -avgcurv -cortparc 
recon-all -long ${SubjectID} ${Base_template} -sd ${ReconDIR} -smooth2 -inflate2 -curvstats -sphere -surfreg -jacobian_white -avgcurv -cortparc 

#Highres pial stuff (this module adjusts the pial surface based on the the T2w image)
log_Msg "High Resolution pial surface"
#"$PipelineScripts"/FreeSurferHiresPial.sh "${SubjectID}" "$SubjectDIR" "$T1wImage" "$T2wImage"
"$PipelineScripts"/FreeSurferHiresPial.sh "${SubjectID}.long.${Base_template}" "$ReconDIR" "$T1wImage" "$T2wImage"

#Final Recon-all Steps
log_Msg "Final Recon-all Steps"
#recon-all -subjid ${SubjectID} -sd $SubjectDIR -surfvolume -parcstats -cortparc2 -parcstats2 -cortparc3 -parcstats3 -cortribbon -segstats -aparc2aseg -wmparc -balabels -label-exvivo-ec 
recon-all -long ${SubjectID} ${Base_template} -sd ${ReconDIR} -surfvolume -parcstats -cortparc2 -parcstats2 -cortparc3 -parcstats3 -cortribbon -segstats -aparc2aseg -wmparc -balabels -label-exvivo-ec 

# create link to recon file into subject folder
ln -s "${ReconDIR}/${SubjectID}.long.${Base_template}" "${SubjectDIR}/${SubjectID}"

log_Msg "Completed"

