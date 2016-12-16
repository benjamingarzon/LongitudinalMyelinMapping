#!/home/share/Software/anaconda/bin/python
#-!/usr/bin/python 
import dicom
import glob
import numpy as np
from os.path import splitext, basename, exists
from os import makedirs, symlink
from shutil import rmtree, copyfile
import sys

def imType(x, complex_data):
    # classify images according to their position    

    #  {1:'MAG', 2:'PHASE', 3:'RE', 0:'IM' }
    if complex_data=="3":
        return 'MAG'

    if complex_data=="2":
        imageType = {1:'RE', 0:'IM'} 
        return imageType[x%2]

    if complex_data=="1":
        imageType = {1:'MAG', 2:'RE', 0:'IM' } 
        return imageType[x%3]
       
    if complex_data=="0":
        imageType = {1:'MAG', 0:'PHASE'}
        return imageType[x%2]

def sort_dicom_GRE(origin, destination, complex_data, TE_file, 
    imaging_freq_file):
    
    if exists(destination):
        rmtree(destination)

    image_files = glob.glob(origin + "/*.dcm")
    indices = dict()
    for image_file in sorted(image_files):
        image = dicom.read_file(image_file);
        imageType = imType(int(splitext(basename(image_file))[0]), complex_data)
     
        TE = ("%06.3f")%(image.EchoTime)
        folder = '/' + imageType + '/TE' + TE 
     
        if folder in indices.keys(): 
            indices[folder] = indices[folder] + 1
        else:   
            indices[folder] = 1

        # create dir if it does not exist
        if not exists(destination + folder):
            makedirs(destination + folder)
        # create new file name
        print(image_file)
        # create symlink
        newFile = ("%s%s/%05d.dcm")%(destination, folder, indices[folder] )
        
        symlink(image_file, newFile)

    imaging_frequency = str(image.ImagingFrequency)

    TEs = np.sort(np.unique(np.array([np.float(t[-6:]) 
        for t in indices.keys()])))
    np.savetxt(TE_file, TEs, fmt='%2.3f', delimiter=' ')

    text_file = open(imaging_freq_file, "w")
    text_file.write(imaging_frequency)
    text_file.close()

def main():
    origin = sys.argv[1]
    destination = sys.argv[2]
    complex_data = sys.argv[3]
    TE_file = sys.argv[4]
    imaging_freq_file = sys.argv[5]

    sort_dicom_GRE(origin, destination, complex_data, TE_file, 
        imaging_freq_file)

if __name__ == "__main__":
    main()
