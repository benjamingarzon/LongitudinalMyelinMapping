#!/bin/bash 

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
            --Resolution=*)
                resolution=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --runlocal)
                command_line_specified_run_local="TRUE"
                index=$(( index + 1 ))
                ;;
        esac
    done
}

get_batch_options $@

#StudyFolder="${HOME}/projects/Pipelines_ExampleData" #Location of Subject folders (named by subjectID)
StudyFolder="/shared/Data/HCP" #Location of Subject folders (named by subjectID)
Subjlist="100307" #Space delimited list of subject IDs
#EnvironmentScript="${HOME}/projects/Pipelines/Examples/Scripts/SetUpHCPPipeline.sh" #Pipeline environment script
EnvironmentScript="${HOME}/Software/HCP/Examples/Scripts/SetUpHCPPipeline.sh" #Pipeline environment script

if [ -n "${command_line_specified_study_folder}" ]; then
    StudyFolder="${command_line_specified_study_folder}"
fi

if [ -n "${command_line_specified_subj_list}" ]; then
    Subjlist="${command_line_specified_subj_list}"
fi

# Requirements for this script
#  installed versions of: FSL (version 5.0.6), FreeSurfer (version 5.3.0-HCP), gradunwarp (HCP version 1.0.2) if doing gradient distortion correction
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR , PATH (for gradient_unwarp.py)

#Set up pipeline environment variables and software
. ${EnvironmentScript}

# Log the originating call
echo "$@"

#if [ X$SGE_ROOT != X ] ; then
    QUEUE="-q long.q"
#fi

PRINTCOM=""
#PRINTCOM="echo"
#QUEUE="-q veryshort.q"


########################################## INPUTS ########################################## 

#Scripts called by this script do NOT assume anything about the form of the input names or paths.
#This batch script assumes the HCP raw data naming convention, e.g.

#	${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_T1w_MPR1.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR2/${Subject}_3T_T1w_MPR2.nii.gz

#	${StudyFolder}/${Subject}/unprocessed/3T/T2w_SPC1/${Subject}_3T_T2w_SPC1.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/T2w_SPC2/${Subject}_3T_T2w_SPC2.nii.gz

#	${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_FieldMap_Magnitude.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_FieldMap_Phase.nii.gz

#Change Scan Settings: Sample Spacings, and $UnwarpDir to match your images
#These are set to match the HCP Protocol by default

#You have the option of using either gradient echo field maps or spin echo field maps to 
#correct your structural images for readout distortion, or not to do this correction at all
#Change either the gradient echo field map or spin echo field map scan settings to match your data
#The default is to use gradient echo field maps using the HCP Protocol

#If using gradient distortion correction, use the coefficents from your scanner
#The HCP gradient distortion coefficents are only available through Siemens
#Gradient distortion in standard scanners like the Trio is much less than for the HCP Skyra.


######################################### DO WORK ##########################################


for Subject in $Subjlist ; do
  echo $Subject
  
  #Input Images
  #Detect Number of T1w Images
  numT1ws=`ls ${StudyFolder}/${Subject}/unprocessed/3T | grep T1w_MPR | wc -l`
  echo "Found ${numT1ws} T1w Images for subject ${Subject}"
  T1wInputImages=""
  i=1
  while [ $i -le $numT1ws ] ; do
    T1wInputImages=`echo "${T1wInputImages}${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR${i}/${Subject}_3T_T1w_MPR${i}.nii.gz@"`
    i=$(($i+1))
  done
  
  #Detect Number of T2w Images
  numT2ws=`ls ${StudyFolder}/${Subject}/unprocessed/3T | grep T2w_SPC | wc -l`
  echo "Found ${numT2ws} T2w Images for subject ${Subject}"
  T2wInputImages=""
  i=1
  while [ $i -le $numT2ws ] ; do
    T2wInputImages=`echo "${T2wInputImages}${StudyFolder}/${Subject}/unprocessed/3T/T2w_SPC${i}/${Subject}_3T_T2w_SPC${i}.nii.gz@"`
    i=$(($i+1))
  done

  #Readout Distortion Correction:
  AvgrdcSTRING="FIELDMAP" #Averaging and readout distortion correction methods: "NONE" = average any repeats with no readout correction "FIELDMAP" = average any repeats and use field map for readout correction "TOPUP" = use spin echo field map
  
  #Using Regular Gradient Echo Field Maps (same as for fMRIVolume pipeline)
  MagnitudeInputName="${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_FieldMap_Magnitude.nii.gz" #Expects 4D magitude volume with two 3D timepoints or "NONE" if not used
  PhaseInputName="${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_FieldMap_Phase.nii.gz" #Expects 3D phase difference volume or "NONE" if not used
  TE="2.46" #for SIEMENS 2.46ms for 3T, 1.02ms for 7T, set to NONE if not using
  TE="`cat ${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/deltaTE.txt`"

  AvgrdcSTRING="NONE"
  TE="NONE"
  
  #Using Spin Echo Field Maps (same as for fMRIVolume pipeline)
  SpinEchoPhaseEncodeNegative="NONE" #For the spin echo field map volume with a negative phase encoding direction (LR in HCP data, AP in 7T HCP data), set to NONE if using regular FIELDMAP
  SpinEchoPhaseEncodePositive="NONE" #For the spin echo field map volume with a positive phase encoding direction (RL in HCP data, PA in 7T HCP data), set to NONE if using regular FIELDMAP
  DwellTime="NONE" #Echo Spacing or Dwelltime of spin echo EPI MRI image, set to NONE if not used. Dwelltime = 1/(BandwidthPerPixelPhaseEncode * # of phase encoding samples): DICOM field (0019,1028) = BandwidthPerPixelPhaseEncode, DICOM field (0051,100b) AcquisitionMatrixText first value (# of phase encoding samples).  On Siemens, iPAT/GRAPPA factors have already been accounted for.  
  SEUnwarpDir="NONE" #x or y (minus or not does not matter) "NONE" if not used 
  TopupConfig="NONE" #Config for topup or "NONE" if not used


  T1wTemplate2mm="${HCPPIPEDIR_Templates}/MNI152_T1_2mm.nii.gz" #Lowres T1w MNI template
  T2wTemplate2mm="${HCPPIPEDIR_Templates}/MNI152_T2_2mm.nii.gz" #Lowres T2w MNI Template
  Template2mmMask="${HCPPIPEDIR_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz" #Lowres MNI brain mask template

  #Templates
  T1wTemplate="${HCPPIPEDIR_Templates}/MNI152_T1_${resolution}mm.nii.gz" #Hires T1w MNI template
  T1wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T1_${resolution}mm_brain.nii.gz" #Hires brain extracted MNI template
  
  T2wTemplate="${HCPPIPEDIR_Templates}/MNI152_T2_${resolution}mm.nii.gz" #Hires T2w MNI Template
  T2wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T2_${resolution}mm_brain.nii.gz" #Hires T2w brain extracted MNI Template
  TemplateMask="${HCPPIPEDIR_Templates}/MNI152_T1_${resolution}mm_brain_mask.nii.gz" #Hires MNI brain mask template
  
  #Structural Scan Settings (set all to NONE if not doing readout distortion correction)
  T1wSampleSpacing=`cat ${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/DwellTime.txt` #"0.0000074" #DICOM field (0019,1018) in s or "NONE" if not used
  T2wSampleSpacing=`cat ${StudyFolder}/${Subject}/unprocessed/3T/T2w_SPC1/DwellTime.txt` #"0.0000021" #DICOM field (0019,1018) in s or "NONE" if not used
  UnwarpDir="z" #z appears to be best or "NONE" if not used

  #Other Config Settings
  BrainSize="150" #BrainSize in mm, 150 for humans
  FNIRTConfig="${HCPPIPEDIR_Config}/T1_2_MNI152_2mm.cnf" #FNIRT 2mm T1w Config
  # GradientDistortionCoeffs="${HCPPIPEDIR_Config}/coeff_SC72C_Skyra.grad" #Location of Coeffs file or "NONE" to skip
  GradientDistortionCoeffs="NONE" # Set to NONE to skip gradient distortion correction

  if [ -n "${command_line_specified_run_local}" ] ; then
      echo "About to run ${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh"
      queuing_command=""
  else
      echo "About to use fsl_sub to queue or run ${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh"
      queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
  fi

  ${queuing_command} ${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh \
      --path="$StudyFolder" \
      --subject="$Subject" \
      --t1="$T1wInputImages" \
      --t2="$T2wInputImages" \
      --t1template="$T1wTemplate" \
      --t1templatebrain="$T1wTemplateBrain" \
      --t1template2mm="$T1wTemplate2mm" \
      --t2template="$T2wTemplate" \
      --t2templatebrain="$T2wTemplateBrain" \
      --t2template2mm="$T2wTemplate2mm" \
      --templatemask="$TemplateMask" \
      --template2mmmask="$Template2mmMask" \
      --brainsize="$BrainSize" \
      --fnirtconfig="$FNIRTConfig" \
      --fmapmag="$MagnitudeInputName" \
      --fmapphase="$PhaseInputName" \
      --echodiff="$TE" \
      --SEPhaseNeg="$SpinEchoPhaseEncodeNegative" \
      --SEPhasePos="$SpinEchoPhaseEncodePositive" \
      --echospacing="$DwellTime" \
      --seunwarpdir="$SEUnwarpDir" \
      --t1samplespacing="$T1wSampleSpacing" \
      --t2samplespacing="$T2wSampleSpacing" \
      --unwarpdir="$UnwarpDir" \
      --gdcoeffs="$GradientDistortionCoeffs" \
      --avgrdcmethod="$AvgrdcSTRING" \
      --topupconfig="$TopupConfig" \
      --printcom=$PRINTCOM
      
  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

  echo "set -- --path=${StudyFolder} \
      --subject=${Subject} \
      --t1=${T1wInputImages} \
      --t2=${T2wInputImages} \
      --t1template=${T1wTemplate} \
      --t1templatebrain=${T1wTemplateBrain} \
      --t1template2mm=${T1wTemplate2mm} \
      --t2template=${T2wTemplate} \
      --t2templatebrain=${T2wTemplateBrain} \
      --t2template2mm=${T2wTemplate2mm} \
      --templatemask=${TemplateMask} \
      --template2mmmask=${Template2mmMask} \
      --brainsize=${BrainSize} \
      --fnirtconfig=${FNIRTConfig} \
      --fmapmag=${MagnitudeInputName} \
      --fmapphase=${PhaseInputName} \
      --echodiff=${TE} \
      --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
      --SEPhasePos=${SpinEchoPhaseEncodePositive} \
      --echospacing=${DwellTime} \
      --seunwarpdir=${SEUnwarpDir} \     
      --t1samplespacing=${T1wSampleSpacing} \
      --t2samplespacing=${T2wSampleSpacing} \
      --unwarpdir=${UnwarpDir} \
      --gdcoeffs=${GradientDistortionCoeffs} \
      --avgrdcmethod=${AvgrdcSTRING} \
      --topupconfig=${TopupConfig} \
      --printcom=${PRINTCOM}"

  echo ". ${EnvironmentScript}"

done

