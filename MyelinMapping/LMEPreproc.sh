#!/bin/sh
SUBJECTS_DIR=/home/share/Left-HandStudy/recon
FWHM=10
WORKDIR=/home/share/Left-HandStudy
STATSDIR=$WORKDIR/stats

cd $WORKDIR

SUBJECTS=LH????
QDEC_FILE=/home/share/Left-HandStudy/stats/qdec.table.ok.dat

mkdir $STATSDIR/thickness $STATSDIR/myelin $STATSDIR/QSM $STATSDIR/r2star

for HEMI in lh@L rh@R; do

  FS_HEMI=`echo $HEMI | cut -d "@" -f 1`
  WB_HEMI=`echo $HEMI | cut -d "@" -f 2`

  for BASE in $SUBJECTS; do
    for TP in 1 2 3 4; do

      SUBJECT=$BASE.$TP

      echo $SUBJECT
      ln -s $WORKDIR/$SUBJECT/MGRE/$FS_HEMI.QSM.mgz $SUBJECTS_DIR/$SUBJECT.long.$BASE.base/surf/$FS_HEMI.QSM.mgz
      ln -s $WORKDIR/$SUBJECT/MGRE/$FS_HEMI.r2star.mgz $SUBJECTS_DIR/$SUBJECT.long.$BASE.base/surf/$FS_HEMI.r2star.mgz
      rm $SUBJECTS_DIR/$SUBJECT.long.$BASE.base/surf/$FS_HEMI.myelin_map.mgz 
      mri_convert $WORKDIR/$SUBJECT/MNINonLinear/Native/$SUBJECT.$WB_HEMI.SmoothedMyelinMap_BC.native.func.gii $SUBJECTS_DIR/$SUBJECT.long.$BASE.base/surf/$FS_HEMI.myelin.mgz
 
    done
  done

  mris_preproc --qdec-long $QDEC_FILE --target fsaverage --hemi $FS_HEMI --meas QSM.mgz --out $STATSDIR/QSM/$FS_HEMI.QSM.fsaverage.mgz --fwhm $FWHM --smooth-cortex-only 
  mris_preproc --qdec-long $QDEC_FILE --target fsaverage --hemi $FS_HEMI --meas r2star.mgz --out $STATSDIR/r2star/$FS_HEMI.r2star.fsaverage.mgz --fwhm $FWHM --smooth-cortex-only
  mris_preproc --qdec-long $QDEC_FILE --target fsaverage --hemi $FS_HEMI --meas thickness --out $STATSDIR/thickness/$FS_HEMI.thickness.fsaverage.mgz --fwhm $FWHM --smooth-cortex-only
  mris_preproc --qdec-long $QDEC_FILE --target fsaverage --hemi $FS_HEMI --meas myelin.mgz --out $STATSDIR/myelin/$FS_HEMI.myelin.unorm.fsaverage.mgz


  mris_preproc --qdec-long $QDEC_FILE --target fsaverage --hemi $FS_HEMI --meas QSM.mgz --out $STATSDIR/QSM/$FS_HEMI.QSM.std.mgz  --fwhm $FWHM --smooth-cortex-only --std 
  mris_preproc --qdec-long $QDEC_FILE --target fsaverage --hemi $FS_HEMI --meas r2star.mgz --out $STATSDIR/r2star/$FS_HEMI.r2star.std.mgz --fwhm $FWHM --smooth-cortex-only --std
  mris_preproc --qdec-long $QDEC_FILE --target fsaverage --hemi $FS_HEMI --meas thickness --out $STATSDIR/thickness/$FS_HEMI.thickness.std.mgz --fwhm $FWHM --smooth-cortex-only --std
  mris_preproc --qdec-long $QDEC_FILE --target fsaverage --hemi $FS_HEMI --meas myelin.mgz --out $STATSDIR/myelin/$FS_HEMI.myelin.std.mgz --std


done

