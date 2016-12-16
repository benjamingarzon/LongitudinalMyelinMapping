#!/bin/bash 

DO_CROSS=0
DO_BASE=0
DO_LONG=0

get_batch_options() {
    local arguments=($@)

    unset command_line_specified_study_folder
    unset command_line_specified_subj_list
    unset command_line_specified_run_local

    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --StudyFolder=*)
                command_line_specified_study_folder=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --Subjlist=*)
                command_line_specified_subj_list=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --Base_template=*)
                Base_template=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --runlocal)
                command_line_specified_run_local="TRUE"
                index=$(( index + 1 ))
                ;;
            --DoCross=*)
                DO_CROSS=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --DoBase=*)
                DO_BASE=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --DoLong=*)
                DO_LONG=${argument/*=/""}
                index=$(( index + 1 ))
                ;;

        esac
    done
}

get_batch_options $@
echo $DO_CROSS $DO_BASE $DO_LONG

#StudyFolder="${HOME}/projects/Pipelines_ExampleData" #Location of Subject folders (named by subjectID)
StudyFolder="$STUDY_DIR"
#Subjlist="100307" #Space delimited list of subject IDs
#EnvironmentScript="${HOME}/projects/Pipelines/Examples/Scripts/SetUpHCPPipeline.sh" #Pipeline environment script
EnvironmentScript="${EXEC_DIR}/SetUpHCPPipeline.sh" #Pipeline environment script

if [ -n "${command_line_specified_study_folder}" ]; then
    StudyFolder="${command_line_specified_study_folder}"
fi

if [ -n "${command_line_specified_subj_list}" ]; then
    Subjlist=`echo "${command_line_specified_subj_list}" | sed 's/,/ /g'`
fi
echo "SUBJECTS $Subjlist"

# Requirements for this script
#  installed versions of: FSL (version 5.0.6), FreeSurfer (version 5.3.0-HCP), gradunwarp (HCP version 1.0.2)
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR , PATH (for gradient_unwarp.py)

#Set up pipeline environment variables and software
. ${EnvironmentScript}

echo $FREESURFER_HOME


# Log the originating call
echo "$@"

#if [ X$SGE_ROOT != X ] ; then
    QUEUE="-q long.q"
#fi

PRINTCOM=""
#PRINTCOM="echo"
#QUEUE="-q veryshort.q"


########################################## INPUTS ########################################## 

#Scripts called by this script do assume they run on the outputs of the PreFreeSurfer Pipeline

######################################### DO WORK ##########################################
TPS=""

ReconFolder=$StudyFolder/recon

if [ $DO_CROSS -eq 1 ]; then

mkdir $ReconFolder

for Subject in $Subjlist ; do
  echo $Subject

  #Input Variables
  SubjectID="$Subject" #FreeSurfer Subject ID Name
  SubjectDIR="${StudyFolder}/${Subject}/T1w" #Location to Put FreeSurfer Subject's Folder
  T1wImage="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore.nii.gz" #T1w FreeSurfer Input (Full Resolution)
  T1wImageBrain="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore_brain.nii.gz" #T1w FreeSurfer Input (Full Resolution)
  T2wImage="${StudyFolder}/${Subject}/T1w/T2w_acpc_dc_restore.nii.gz" #T2w FreeSurfer Input (Full Resolution)

  if [ -n "${command_line_specified_run_local}" ] ; then
      echo "About to run ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipelineLongitudinal_1.sh"
      queuing_command=""
  else
      echo "About to use fsl_sub to queue or run ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipelineLongitudinal_1.sh"
      queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
  fi

  ${queuing_command} ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipelineLongitudinal_1.sh \
      --subject="$Subject" \
      --subjectDIR="$ReconFolder" \
      --t1="$T1wImage" \
      --t1brain="$T1wImageBrain" \
      --printcom=$PRINTCOM
      #--t2="$T2wImage" \
            
  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

  echo "set -- --subject="$Subject" \
      --subjectDIR="$SubjectDIR" \
      --t1="$T1wImage" \
      --t1brain="$T1wImageBrain" \
      --t2="$T2wImage" \
      --printcom=$PRINTCOM"

  echo ". ${EnvironmentScript}"

  # Create link 
  #ln -s $SubjectDIR $ReconFolder/$Subject
  
done
fi

for Subject in $Subjlist ; do
  TPS="$TPS -tp $Subject"
done

# create unbiased template from all the time points

if [ $DO_BASE -eq 1 ]; then
recon-all -sd $ReconFolder -base $Base_template $TPS -all 
fi

# process time points using base templates

if [ $DO_LONG -eq 1 ]; then
for Subject in $Subjlist ; do

  echo $Subject
  
  #Input Variables
  SubjectID="$Subject" #FreeSurfer Subject ID Name
  SubjectDIR="${StudyFolder}/${Subject}/T1w" #Location to Put FreeSurfer Subject's Folder
  T1wImage="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore.nii.gz" #T1w FreeSurfer Input (Full Resolution)
  T1wImageBrain="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore_brain.nii.gz" #T1w FreeSurfer Input (Full Resolution)
  T2wImage="${StudyFolder}/${Subject}/T1w/T2w_acpc_dc_restore.nii.gz" #T2w FreeSurfer Input (Full Resolution)

  if [ -n "${command_line_specified_run_local}" ] ; then
      echo "About to run ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipelineLongitudinal_2.sh"
      queuing_command=""
  else
      echo "About to use fsl_sub to queue or run ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipelineLongitudinal_2.sh"
      queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
  fi

  ${queuing_command} ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipelineLongitudinal_2.sh \
      --subject="$Subject" \
      --subjectDIR="$SubjectDIR"  \
      --reconDIR="$ReconFolder" \
      --t1="$T1wImage" \
      --t1brain="$T1wImageBrain" \
      --t2="$T2wImage" \
      --Base_template="$Base_template" \
      --printcom=$PRINTCOM
      
  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

  echo "set -- --subject="$Subject" \
      --subjectDIR="$SubjectDIR" \
      --reconDIR="$ReconFolder" \
      --t1="$T1wImage" \
      --t1brain="$T1wImageBrain" \
      --t2="$T2wImage" \
      --Base_template="$Base_template" \
      --printcom=$PRINTCOM"

  echo ". ${EnvironmentScript}"

done

fi

      
      

