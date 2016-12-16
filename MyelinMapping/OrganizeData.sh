#!/bin/bash 

# Organize data to adopt the HCP raw data naming convention and folder structure

Usage() {
    echo ""
    echo "Author: Benjamin Garzon <benjamin.garzon@gmail.com>"
    echo "v 1.0, May 2015"
    echo "  Convert the raw dicom data and organize them to adopt the HCP raw data naming convention and folder structure."
    echo "  Usage: `basename $0` --subject=<SUBJECT NAME> --fieldmap=<FIELDMAP DIR NAME> --T1w=<T1w DIR NAME> --T2w=<T2w DIR NAME> --MGRE=<MGRE DIR NAME> [--overwrite --mag]"
    echo " "
    echo "  IMPORTANT: You need to set the variables DICOM_DIR and STUDY_DIR before running it, e.g."
    echo "  export DICOM_DIR=/home/MyUser/Data/DICOM/Subject1/"
    echo "  export STUDY_DIR=/home/MyUser/Data/Study/"
    echo " "
    echo "  DICOM_DIR: directory containing the dicom files in directories."
    echo "  STUDY_DIR: directory where the output will be stored in a directory <SUBJECT NAME>."
    
    echo "  With the option --overwrite the subject directory is created anew."
    echo "  The option --mag specifies that only MAGNITUDE images are available for the MGRE sequence, instead of REAL and IMAGINARY."	
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

# Default values
SUBJECT='NONE'
FIELDMAP='NONE'
T1w='NONE'
T2w='NONE'
MGRE='NONE'
OVERWRITE='N'
MGRE_TYPE=2

if [ $# -lt 2 ] ; then Usage; exit 0; fi
while [ $# -ge 1 ] ; do
    iarg=`get_opt1 $1`;
    case "$iarg"
	in
	--subject)
	    SUBJECT=`get_arg1 $1`;
	    shift;;
	--fieldmap)
	    FIELDMAP=`get_arg1 $1`;
	    shift;;
	--T1w)
	    T1w=`get_arg1 $1`;
	    shift;;
	--T2w)
	    T2w=`get_arg1 $1`;
	    shift;;
	--MGRE)
	    MGRE=`get_arg1 $1`;
	    shift;;
	--overwrite)
	    OVERWRITE='Y';
	    shift;;
	--mag)
	    MGRE_TYPE=3;
	    shift;;
	*)
	    #if [ `echo $1 | sed 's/^\(.\).*/\1/'` = "-" ] ; then 
	    echo "Unrecognised option $1" 1>&2
	    exit 1
	    #fi
	    #shift;;
    esac
done


# Create directories
if [ $OVERWRITE == "Y" ]; then
    rm -r ${STUDY_DIR}/${SUBJECT}
    mkdir ${STUDY_DIR}/${SUBJECT}
    mkdir ${STUDY_DIR}/${SUBJECT}/unprocessed
    mkdir ${STUDY_DIR}/${SUBJECT}/unprocessed/3T

else 
    if [ ! -e  "${STUDY_DIR}/${SUBJECT}" ]; then
            echo hello
            mkdir ${STUDY_DIR}/${SUBJECT}
	    mkdir ${STUDY_DIR}/${SUBJECT}/unprocessed
            mkdir ${STUDY_DIR}/${SUBJECT}/unprocessed/3T
    fi
fi


# T1 images
if [ $T1w != "NONE" ]; then
    echo "Converting T1w image."
    mkdir ${STUDY_DIR}/${SUBJECT}/unprocessed/3T/T1w_MPR1
    cd ${STUDY_DIR}/${SUBJECT}/unprocessed/3T/T1w_MPR1
    cp $DICOM_DIR/$T1w/*.dcm ${STUDY_DIR}/${SUBJECT}/unprocessed/3T/T1w_MPR1
    $MRICRON_DIR/dcm2nii -d N *.dcm
    $EXEC_DIR/ReadDwellTime.py `ls *.dcm | head -n 1` GE> ${STUDY_DIR}/${SUBJECT}/unprocessed/3T/T1w_MPR1/DwellTime.txt
    mv o*.nii.gz ${SUBJECT}_3T_T1w_MPR1.nii.gz
    rm *.dcm `ls *.nii.gz | grep -v "${SUBJECT}_3T_T1w_MPR1"`


fi

# T2 images
if [ $T2w != "NONE" ]; then
    echo "Converting T2w image."
    mkdir ${STUDY_DIR}/${SUBJECT}/unprocessed/3T/T2w_SPC1
    cd ${STUDY_DIR}/${SUBJECT}/unprocessed/3T/T2w_SPC1
    cp $DICOM_DIR/$T2w/*.dcm ${STUDY_DIR}/${SUBJECT}/unprocessed/3T/T2w_SPC1
    $MRICRON_DIR/dcm2nii -d N *.dcm
    $EXEC_DIR/ReadDwellTime.py `ls *.dcm | head -n 1` GE> ${STUDY_DIR}/${SUBJECT}/unprocessed/3T/T2w_SPC1/DwellTime.txt
    mv o*.nii.gz ${SUBJECT}_3T_T2w_SPC1.nii.gz
    rm *.dcm `ls *.nii.gz | grep -v "${SUBJECT}_3T_T2w_SPC1"`
fi 

# Creating the fieldmap
if [ $FIELDMAP != "NONE" ]; then
    echo "Creating fieldmap."
    cd $DICOM_DIR/$FIELDMAP
    $EXEC_DIR/sort_dicom_GRE.py $DICOM_DIR/$FIELDMAP $DICOM_DIR/FieldMap_${SUBJECT} 1 $DICOM_DIR/FieldMap_${SUBJECT}/TEs.txt $DICOM_DIR/FieldMap_${SUBJECT}/imaging_freq.txt
    cd $DICOM_DIR/FieldMap_${SUBJECT}

    DATA_DIRS="MAG RE IM"

    rm *.nii.gz
    for d in $DATA_DIRS;
    do
        cd $d
        for i in TE*; do echo $i; cd $i; $MRICRON_DIR/dcm2nii *.dcm; cd ..; done
        for i in TE*; do echo $i; cp $i/2*.nii.gz $i.nii.gz; done
        fslmerge -t data.nii.gz TE*.nii.gz
        rm -r TE*
        cd ..
    done 

    TE0=`cat $DICOM_DIR/FieldMap_${SUBJECT}/TEs.txt | awk 'FNR == 1 {print}'`
    TE1=`cat $DICOM_DIR/FieldMap_${SUBJECT}/TEs.txt | awk 'FNR == 2 {print}'`
    DELTA_TE=`echo "$TE1 - $TE0"| bc -l`
    echo $DELTA_TE > ${STUDY_DIR}/${SUBJECT}/unprocessed/3T/T1w_MPR1/deltaTE.txt

    fslcomplex -complex RE/data IM/data data_complex
    $EXEC_DIR/ComplexRatios.py data_complex.nii.gz data_ratio.nii.gz
    prelude -c data_ratio -o Phase_diff #-s 

    fslmaths Phase_diff -div 6.28 -div $DELTA_TE -mul -1000 FieldMap_deg # in ms

    fslroi MAG/data.nii.gz Mag0 0 1
    bet Mag0 Mag0_brain -f 0.35 -m -R

    fslmaths FieldMap_deg -sub `fslstats FieldMap_deg -k Mag0_brain_mask -P 50` FieldMap_deg 
    fslmerge -t GradientEchoFieldMap FieldMap_deg Mag0

    mv GradientEchoFieldMap.nii.gz "${STUDY_DIR}/${SUBJECT}/unprocessed/3T/T1w_MPR1/${SUBJECT}_3T_GradientEchoFieldMap.nii.gz"
    #rm -r $DICOM_DIR/FieldMap_${SUBJECT}
fi

# Converting MGRE and generating r2STAR and QSM maps
if [ $MGRE != "NONE" ]; then
    echo "Computing QSM and r2star MAPS."

    MGRE_DIR="${STUDY_DIR}/${SUBJECT}/unprocessed/3T/MGRE"
    PROCESSING_DIR="${STUDY_DIR}/${SUBJECT}/unprocessed/3T/MGRE/proc"
    cd $DICOM_DIR/$MGRE
    $EXEC_DIR/sort_dicom_GRE.py $DICOM_DIR/$MGRE $MGRE_DIR $MGRE_TYPE $MGRE_DIR/TEs.txt $MGRE_DIR/imaging_freq.txt
    cd $MGRE_DIR
    mkdir $PROCESSING_DIR
    mkdir $MGRE_DIR/MAG/

    if [ $MGRE_TYPE -eq 2 ]; then
      DATA_DIRS="RE IM"
    else
      DATA_DIRS="MAG"
    fi 

    for d in $DATA_DIRS;
    do
        cd $d
           for i in TE*; do echo $i; cd $i; $MRICRON_DIR/dcm2nii *.dcm; cd ..; done
           for i in TE*; do echo $i; cp $i/2*.nii.gz $i.nii.gz; done
           fslmerge -t data.nii.gz TE*.nii.gz
           rm -r TE*
           cd ..
    done

    if [ $MGRE_TYPE -eq 2 ]; then
      fslcomplex -complex $MGRE_DIR/RE/data $MGRE_DIR/IM/data $PROCESSING_DIR/data_complex
      fslcpgeom $MGRE_DIR/RE/data $PROCESSING_DIR/data_complex
    
      # Create magnitude images
      fslcomplex -realabs $PROCESSING_DIR/data_complex $MGRE_DIR/MAG/data
      fslcpgeom $MGRE_DIR/RE/data $MGRE_DIR/MAG/data
    fi
    
    # Brain extraction
    fslroi $MGRE_DIR/MAG/data $PROCESSING_DIR/GRE 0 4
    fslmaths $PROCESSING_DIR/GRE -sqr -Tmean -sqrt $PROCESSING_DIR/GRE0
    bet $PROCESSING_DIR/GRE0.nii.gz $PROCESSING_DIR/GRE0_brain -m -R

    # Erode mask
    fslmaths $PROCESSING_DIR/GRE0_brain_mask.nii.gz -ero -kernel sphere 2 $PROCESSING_DIR/GRE0_brain_mask.nii.gz

    if [ $MGRE_TYPE -eq 2 ]; then
    # QSM analysis
      IMAGING_FREQ=`cat $MGRE_DIR/imaging_freq.txt`
      echo "Imaging Frequency = $IMAGING_FREQ"

      # Call the QSM analysis tool
      matlab -nodesktop -nosplash -r "addpath $MEDI_TOOLBOX_PATH; addpath $RESHARP_PATH; addpath $MATLAB_FSL_PATH; QSMprocessing $PROCESSING_DIR/data_complex.nii.gz $PROCESSING_DIR/GRE0_brain_mask.nii.gz $IMAGING_FREQ $MGRE_DIR/TEs.txt $PROCESSING_DIR/QSM.nii.gz $PROCESSING_DIR/background_field.nii.gz $PROCESSING_DIR; exit;"
      fslcpgeom $PROCESSING_DIR/GRE0.nii.gz $PROCESSING_DIR/QSM.nii.gz
      mv $PROCESSING_DIR/QSM.nii.gz $MGRE_DIR
      # Clean up 
      rm $PROCESSING_DIR/RDF.mat
    fi

    # Call relaxometry
    RELAXOMETRY_CONSTANT=0
    $EXEC_DIR/relaxometry.py $MGRE_DIR/MAG/data.nii.gz $PROCESSING_DIR/GRE0_brain_mask.nii.gz $MGRE_DIR/TEs.txt $RELAXOMETRY_CONSTANT $PROCESSING_DIR/PD.nii.gz $PROCESSING_DIR/r2star.nii.gz $PROCESSING_DIR/relaxErr.nii.gz
    fslcpgeom $PROCESSING_DIR/GRE0.nii.gz $PROCESSING_DIR/r2star.nii.gz

    mv $PROCESSING_DIR/r2star.nii.gz $MGRE_DIR

fi






