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
            --runlocal)
                command_line_specified_run_local="TRUE"
                index=$(( index + 1 ))
                ;;
        esac
    done
}

get_batch_options $@

#StudyFolder="${HOME}/projects/Pipelines_ExampleData" #Location of Subject folders (named by subjectID)
StudyFolder="/shared/Data/HCP"
Subjlist="100307" #Space delimited list of subject IDs
#EnvironmentScript="${HOME}/projects/Pipelines/Examples/Scripts/SetUpHCPPipeline.sh" #Pipeline environment script
EnvironmentScript="${HOME}/Software/HCP/Examples/Scripts/SetUpHCPPipeline.sh" #Pipeline environment script

